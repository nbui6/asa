// Real files, real disk — same style as area_writer_test.dart.

import 'dart:io';

import 'package:asa/core/area_section_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-area-section-test-');
    path = '${tempDir.path}${Platform.pathSeparator}sales.md';
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('setAreaSection', () {
    test('fills an empty heading, touching no other section', () async {
      File(path).writeAsStringSync(
        '# Sales\n\n## Goal\n\n## Plan\nTwo pitches a month.\n\n'
        '## Tasks\n- [ ] A task\n',
      );

      await setAreaSection(
        path,
        heading: 'Goal',
        text: 'Serves Objective 1.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Goal\n\nServes Objective 1.\n\n## Plan\n'
        'Two pitches a month.\n\n## Tasks\n- [ ] A task\n',
      );
    });

    test('creates the section at the end when the file has none', () async {
      File(path).writeAsStringSync('# Sales\n\n## Tasks\n- [ ] A task\n');

      await setAreaSection(
        path,
        heading: 'Plan',
        text: 'First, the webinar.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Tasks\n- [ ] A task\n\n## Plan\n\n'
        'First, the webinar.\n',
      );
    });

    test('edits existing text when expectedCurrent matches', () async {
      File(path).writeAsStringSync('# Sales\n\n## Plan\nOld plan.\n');

      await setAreaSection(
        path,
        heading: 'Plan',
        text: 'New plan.',
        expectedCurrent: 'Old plan.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Plan\n\nNew plan.\n',
      );
    });

    test('refuses, unchanged, when the file changed since it was shown', () {
      const original = '# Sales\n\n## Plan\nSomeone else wrote this.\n';
      File(path).writeAsStringSync(original);

      expect(
        () => setAreaSection(
          path,
          heading: 'Plan',
          text: 'Mine',
          writeLogPath: logPath,
        ),
        throwsStateError,
      );
      expect(File(path).readAsStringSync(), original);
    });

    test('refuses empty text', () {
      File(path).writeAsStringSync('# Sales\n');
      expect(
        () => setAreaSection(path, heading: 'Goal', text: '  '),
        throwsStateError,
      );
    });

    test('logs the before and after', () async {
      File(path).writeAsStringSync('# Sales\n\n## Plan\nOld.\n');

      await setAreaSection(
        path,
        heading: 'Plan',
        text: 'New.',
        expectedCurrent: 'Old.',
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'area-plan-set');
      expect(entry.from, 'Old.');
      expect(entry.to, 'New.');
    });

    test("ADR 0050 — fieldPrefix logs this as the caller's own kind of file, "
        'not "area", when it is not one (CHARTER.md reuses this writer '
        'directly rather than duplicating it)', () async {
      File(path).writeAsStringSync('# Charter\n\n## Pain points\nOld.\n');

      await setAreaSection(
        path,
        heading: 'Pain points',
        text: 'New.',
        expectedCurrent: 'Old.',
        writeLogPath: logPath,
        fieldPrefix: 'charter',
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'charter-pain points-set');
    });
  });

  group('clearAreaSection — Round 43 §D, 🗑 in edit mode', () {
    test('clears the body back to empty, the heading itself stays, no '
        'other section touched', () async {
      File(path).writeAsStringSync(
        '# Sales\n\n## Goal\n\nServes Objective 1.\n\n## Plan\n'
        'Two pitches a month.\n\n## Tasks\n- [ ] A task\n',
      );

      await clearAreaSection(
        path,
        heading: 'Goal',
        expectedCurrent: 'Serves Objective 1.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Goal\n\n## Plan\n'
        'Two pitches a month.\n\n## Tasks\n- [ ] A task\n',
      );
    });

    test('a section with nothing after it in the file', () async {
      File(path).writeAsStringSync('# Sales\n\n## Plan\nOld plan.\n');

      await clearAreaSection(
        path,
        heading: 'Plan',
        expectedCurrent: 'Old plan.',
      );

      expect(File(path).readAsStringSync(), '# Sales\n\n## Plan\n');
    });

    test('refuses, unchanged, when the file changed since it was shown', () {
      const original = '# Sales\n\n## Plan\nSomeone else wrote this.\n';
      File(path).writeAsStringSync(original);

      expect(
        () => clearAreaSection(
          path,
          heading: 'Plan',
          expectedCurrent: 'What this screen was showing',
        ),
        throwsStateError,
      );
      expect(File(path).readAsStringSync(), original);
    });

    test('logs the removed text, to empty', () async {
      File(path).writeAsStringSync('# Sales\n\n## Plan\nOld.\n');

      await clearAreaSection(
        path,
        heading: 'Plan',
        expectedCurrent: 'Old.',
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'area-plan-removed');
      expect(entry.from, 'Old.');
      expect(entry.to, '');
    });
  });
}
