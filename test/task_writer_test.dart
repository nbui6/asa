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

  group('setTaskParked — PLAN.md v0.3, "the rule of two"', () {
    test('appends (parked), touching no other line', () async {
      File(path)
          .writeAsStringSync('## Tasks\n\n- [ ] Untouched\n- [ ] Park me\n');

      await setTaskParked(path, rawLine: '- [ ] Park me', parked: true);

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [ ] Untouched\n'));
      expect(updated, contains('- [ ] Park me (parked)'));
    });

    test('removes (parked), leaving the checkbox and everything else '
        'alone', () async {
      File(path)
          .writeAsStringSync('## Tasks\n\n- [x] Done and parked (parked)\n');

      await setTaskParked(
        path,
        rawLine: '- [x] Done and parked (parked)',
        parked: false,
      );

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [x] Done and parked'));
      expect(updated, isNot(contains('(parked)')));
    });

    test('parking an already-parked line, or unparking an already-open '
        'one, is a no-op — writes the line back unchanged', () async {
      const original = '## Tasks\n\n- [ ] Already open\n';
      File(path).writeAsStringSync(original);

      await setTaskParked(path, rawLine: '- [ ] Already open', parked: false);

      expect(File(path).readAsStringSync(), original);
    });

    test('a (Code) tag on the same line survives parking untouched', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Ship it (Code)\n');

      await setTaskParked(path, rawLine: '- [ ] Ship it (Code)', parked: true);

      expect(
        File(path).readAsStringSync(),
        contains('- [ ] Ship it (Code) (parked)'),
      );
    });

    test('throws when there is no ## Tasks section', () {
      File(path).writeAsStringSync('# Example\n\nNothing here.\n');

      expect(
        () => setTaskParked(path, rawLine: '- [ ] Anything', parked: true),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when the exact line is no longer there', () {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Test forms\n');

      expect(
        () => setTaskParked(
          path,
          rawLine: '- [ ] A different task',
          parked: true,
        ),
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

  group('captureTask — quick capture, ADR 0014', () {
    test('appends to an existing ## Tasks section, after what is already '
        'there', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Already here\n');

      await captureTask(path, 'Something new');

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [ ] Already here'));
      expect(updated, contains('- [ ] Something new'));
      expect(
        updated.indexOf('Already here'),
        lessThan(updated.indexOf('Something new')),
      );
    });

    test('creates the ## Tasks section when the file has none yet, without '
        'touching what is already there', () async {
      const original = '# Home\n\nA paragraph that must survive untouched.\n';
      File(path).writeAsStringSync(original);

      await captureTask(path, 'First capture');

      final updated = File(path).readAsStringSync();
      expect(updated, contains('A paragraph that must survive untouched.'));
      expect(updated, contains('## Tasks'));
      expect(updated, contains('- [ ] First capture'));
    });

    test('creates the file itself when it does not exist at all', () async {
      expect(File(path).existsSync(), isFalse);

      await captureTask(path, 'First ever capture');

      expect(
        File(path).readAsStringSync(),
        contains(
          '- [ ] First ever '
          'capture',
        ),
      );
    });
  });

  group('moveTask — the write half of "drag it onto a project", ADR 0014', () {
    late String otherPath;

    setUp(() {
      otherPath = '${tempDir.path}${Platform.pathSeparator}other.md';
    });

    test('removes the line from the source and appends it to the '
        'destination, unchanged', () async {
      File(path).writeAsStringSync(
        '## Tasks\n\n- [ ] Stays behind\n- [x] Move me (Code)\n',
      );
      File(otherPath).writeAsStringSync('## Tasks\n\n- [ ] Already there\n');

      await moveTask(
        fromPath: path,
        toPath: otherPath,
        rawLine: '- [x] Move me (Code)',
      );

      final source = File(path).readAsStringSync();
      expect(source, contains('- [ ] Stays behind'));
      expect(source, isNot(contains('Move me')));

      final destination = File(otherPath).readAsStringSync();
      expect(destination, contains('- [ ] Already there'));
      expect(destination, contains('- [x] Move me (Code)'));
    });

    test('creates a ## Tasks section in the destination if it has none yet '
        '— a project note may not have started one', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Unfiled thing\n');
      File(otherPath).writeAsStringSync('# A project with no tasks yet\n');

      await moveTask(
        fromPath: path,
        toPath: otherPath,
        rawLine: '- [ ] Unfiled thing',
      );

      expect(
        File(otherPath).readAsStringSync(),
        contains('- [ ] Unfiled thing'),
      );
    });

    test('throws when there is no ## Tasks section in the source', () {
      File(path).writeAsStringSync('# Nothing here\n');
      File(otherPath).writeAsStringSync('## Tasks\n\n');

      expect(
        () => moveTask(
          fromPath: path,
          toPath: otherPath,
          rawLine: '- [ ] Anything',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when the exact line is no longer there in the source, and '
        'leaves the destination untouched', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Real line\n');
      const destinationBefore = '## Tasks\n\n- [ ] Already there\n';
      File(otherPath).writeAsStringSync(destinationBefore);

      await expectLater(
        moveTask(
          fromPath: path,
          toPath: otherPath,
          rawLine: '- [ ] A line that is not there',
        ),
        throwsA(isA<StateError>()),
      );

      expect(File(otherPath).readAsStringSync(), destinationBefore);
    });
  });
}
