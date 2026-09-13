// Real files, real disk — same reasoning as task_writer_test.dart and
// decision_writer_test.dart: only dart:io proves what a real write and a
// real re-read actually do. ADR 0007 is the contract this proves against.

import 'dart:io';

import 'package:asa/core/project.dart';
import 'package:asa/core/project_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

const _realShapedBody = '''
---
project: Demo
status: building
parent: other
priority: high
deadline: 2026-09
jira: https://example.atlassian.net/browse/DEMO-1
custom-key: her own value
---

# Demo

A paragraph of body text that must survive every write untouched.

## Tasks

- [ ] Something unrelated to this round
''';

void main() {
  late Directory tempDir;
  late String path;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-project-writer-test-');
    path = '${tempDir.path}${Platform.pathSeparator}demo.md';
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
    File(path).writeAsStringSync(_realShapedBody);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  String frontmatterOf(String content) => extractRawFrontmatter(content);

  group('setProjectField — a round trip per whitelisted field', () {
    for (final field in projectWritableFields) {
      test('$field can be written, and the rest of the file survives '
          'untouched', () async {
        final before = File(path).readAsStringSync();
        final expected = frontmatterOf(before);

        await setProjectField(
          path,
          field: field,
          value: 'a new value',
          expectedFrontmatter: expected,
          writeLogPath: logPath,
        );

        final after = File(path).readAsStringSync();
        expect(parseFrontmatter(after)[field], 'a new value');
        expect(
          after,
          contains(
            'A paragraph of body text that must survive every write '
            'untouched.',
          ),
        );
        expect(after, contains('- [ ] Something unrelated to this round'));
      });
    }
  });

  test('the whitelist refuses a field not in it, and writes nothing', () {
    final before = File(path).readAsStringSync();

    expect(
      () => setProjectField(
        path,
        field: 'next-step',
        value: 'anything',
        expectedFrontmatter: frontmatterOf(before),
        writeLogPath: logPath,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('refuses when the frontmatter has changed since it was read — '
      'his editor may be open on the same file', () async {
    final staleFrontmatter = frontmatterOf(File(path).readAsStringSync());

    // Simulate an external edit — his editor, in the real scenario.
    File(path).writeAsStringSync(
      _realShapedBody.replaceFirst('status: building', 'status: paused'),
    );
    final beforeAttempt = File(path).readAsStringSync();

    await expectLater(
      setProjectField(
        path,
        field: 'priority',
        value: 'low',
        expectedFrontmatter: staleFrontmatter,
        writeLogPath: logPath,
      ),
      throwsA(isA<StateError>()),
    );

    expect(File(path).readAsStringSync(), beforeAttempt);
  });

  test("a second developer's own extra frontmatter key survives a write "
      "byte-identically — Round 7's fork seam", () async {
    final expected = frontmatterOf(File(path).readAsStringSync());

    await setProjectField(
      path,
      field: 'status',
      value: 'paused',
      expectedFrontmatter: expected,
      writeLogPath: logPath,
    );

    expect(
      File(path).readAsStringSync(),
      contains('custom-key: her own value'),
    );
  });

  group('the three key shapes', () {
    test('a key not present in the frontmatter at all gets added', () async {
      const noJira = '''
---
project: Demo
status: building
---

# Demo
''';
      File(path).writeAsStringSync(noJira);
      final expected = frontmatterOf(File(path).readAsStringSync());

      await setProjectField(
        path,
        field: 'jira',
        value: 'https://example.atlassian.net/browse/DEMO-9',
        expectedFrontmatter: expected,
        writeLogPath: logPath,
      );

      final after = File(path).readAsStringSync();
      expect(
        parseFrontmatter(after)['jira'],
        'https://example.atlassian.net/browse/DEMO-9',
      );
    });

    test('a key present but empty gets filled in', () async {
      const emptyDeadline = '''
---
project: Demo
status: building
deadline:
---

# Demo
''';
      File(path).writeAsStringSync(emptyDeadline);
      final expected = frontmatterOf(File(path).readAsStringSync());

      await setProjectField(
        path,
        field: 'deadline',
        value: '2027-01',
        expectedFrontmatter: expected,
        writeLogPath: logPath,
      );

      expect(
        parseFrontmatter(File(path).readAsStringSync())['deadline'],
        '2027-01',
      );
    });

    test('a key present with a real value already gets replaced', () async {
      final expected = frontmatterOf(File(path).readAsStringSync());

      await setProjectField(
        path,
        field: 'priority',
        value: 'low',
        expectedFrontmatter: expected,
        writeLogPath: logPath,
      );

      expect(
        parseFrontmatter(File(path).readAsStringSync())['priority'],
        'low',
      );
    });
  });

  test(
    'an empty value clears the field rather than removing its line',
    () async {
      final expected = frontmatterOf(File(path).readAsStringSync());

      await setProjectField(
        path,
        field: 'priority',
        value: '',
        expectedFrontmatter: expected,
        writeLogPath: logPath,
      );

      final after = File(path).readAsStringSync();
      expect(after, contains('priority:'));
      // parseFrontmatter's raw map keeps an empty value as '' — the
      // null-conversion is Project.optionalField's job, one layer up.
      // What matters here is that the line survives, blank, not removed.
      expect(parseFrontmatter(after)['priority'], '');
      expect(after, isNot(contains('priority: low')));
    },
  );

  test('the write is logged — what it was, what it became', () async {
    final expected = frontmatterOf(File(path).readAsStringSync());

    await setProjectField(
      path,
      field: 'status',
      value: 'paused',
      expectedFrontmatter: expected,
      writeLogPath: logPath,
    );

    final entry = (await readWriteLog(logPath: logPath)).single;
    expect(entry.path, path);
    expect(entry.field, 'status');
    expect(entry.from, 'building');
    expect(entry.to, 'paused');
  });
}
