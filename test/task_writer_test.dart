// Real files, real disk — the guarantee this file exists to prove is
// specifically about what dart:io actually does to a file on disk, which
// an in-memory fake cannot stand in for. Same style as
// decision_writer_test.dart.

import 'dart:io';

import 'package:asa/core/task_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-task-test-');
    path = '${tempDir.path}${Platform.pathSeparator}example.md';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('setTaskDone', () {
    test(
      'checks one task without touching any other line in the file',
      () async {
        const original =
            '# Example\n\n'
            '## Where it stands\n\n'
            'A paragraph that must survive untouched.\n\n'
            '## Tasks\n\n'
            '- [ ] Test forms\n'
            '- [ ] Talk to M about design\n';
        File(path).writeAsStringSync(original);

        await setTaskDone(path, rawLine: '- [ ] Test forms', done: true);

        final updated = File(path).readAsStringSync();
        expect(updated, contains('A paragraph that must survive untouched.'));
        expect(updated, contains('- [x] Test forms'));
        expect(updated, contains('- [ ] Talk to M about design'));
      },
    );

    test('can also reopen a done task', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [x] Done already\n');

      await setTaskDone(path, rawLine: '- [x] Done already', done: false);

      expect(File(path).readAsStringSync(), contains('- [ ] Done already'));
    });

    test('throws when there is no ## Tasks section', () {
      File(path).writeAsStringSync('# Example\n\nNothing here.\n');

      expect(
        () => setTaskDone(path, rawLine: '- [ ] Anything', done: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when the exact line is no longer there', () {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Test forms\n');

      expect(
        () => setTaskDone(path, rawLine: '- [ ] A different task', done: true),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('markAllTasksDone', () {
    test('checks every open task, leaves already-done tasks alone', () async {
      File(path).writeAsStringSync(
        '## Tasks\n\n'
        '- [ ] One\n'
        '- [x] Two\n'
        '- [ ] Three\n',
      );

      await markAllTasksDone(path);

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [x] One'));
      expect(updated, contains('- [x] Two'));
      expect(updated, contains('- [x] Three'));
    });

    test("does not touch a second project's file — only ever called with "
        "that project's own path, and only ever touches that path", () async {
      final otherPath = '${tempDir.path}${Platform.pathSeparator}other.md';
      const otherContent = '## Tasks\n\n- [ ] Untouched\n';
      File(otherPath).writeAsStringSync(otherContent);
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Mine\n');

      await markAllTasksDone(path);

      expect(File(otherPath).readAsStringSync(), otherContent);
    });

    test('does nothing when there is no ## Tasks section', () async {
      const original = '# Example\n\nNothing here.\n';
      File(path).writeAsStringSync(original);

      await markAllTasksDone(path);

      expect(File(path).readAsStringSync(), original);
    });

    test('writes nothing at all when every task is already done', () async {
      const original = '## Tasks\n\n- [x] Already done\n';
      File(path).writeAsStringSync(original);
      final before = File(path).lastModifiedSync();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await markAllTasksDone(path);

      expect(File(path).readAsStringSync(), original);
      expect(File(path).lastModifiedSync(), before);
    });
  });

  group('rereadTasks', () {
    test('reads back what was just written, not what was assumed', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Test forms\n');

      await setTaskDone(path, rawLine: '- [ ] Test forms', done: true);
      final tasks = await rereadTasks(path);

      expect(tasks.single.done, isTrue);
    });
  });
}
