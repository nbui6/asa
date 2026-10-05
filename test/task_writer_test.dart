// Real files, real disk — the guarantee this file exists to prove is
// specifically about what dart:io actually does to a file on disk, which
// an in-memory fake cannot stand in for. Same style as
// decision_writer_test.dart.

import 'dart:io';

import 'package:asa/core/task_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-task-test-');
    path = '${tempDir.path}${Platform.pathSeparator}example.md';
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
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

        await setTaskDone(
          path,
          rawLine: '- [ ] Test forms',
          done: true,
          writeLogPath: logPath,
        );

        final updated = File(path).readAsStringSync();
        expect(updated, contains('A paragraph that must survive untouched.'));
        expect(updated, contains('- [x] Test forms'));
        expect(updated, contains('- [ ] Talk to M about design'));
      },
    );

    test('can also reopen a done task', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [x] Done already\n');

      await setTaskDone(
        path,
        rawLine: '- [x] Done already',
        done: false,
        writeLogPath: logPath,
      );

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

      await setTaskParked(
        path,
        rawLine: '- [ ] Park me',
        parked: true,
        writeLogPath: logPath,
      );

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
        writeLogPath: logPath,
      );

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [x] Done and parked'));
      expect(updated, isNot(contains('(parked)')));
    });

    test('parking an already-parked line, or unparking an already-open '
        'one, is a no-op — writes the line back unchanged', () async {
      const original = '## Tasks\n\n- [ ] Already open\n';
      File(path).writeAsStringSync(original);

      await setTaskParked(
        path,
        rawLine: '- [ ] Already open',
        parked: false,
        writeLogPath: logPath,
      );

      expect(File(path).readAsStringSync(), original);
    });

    test('a (Code) tag on the same line survives parking untouched', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Ship it (Code)\n');

      await setTaskParked(
        path,
        rawLine: '- [ ] Ship it (Code)',
        parked: true,
        writeLogPath: logPath,
      );

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

      await markAllTasksDone(path, writeLogPath: logPath);

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

      await markAllTasksDone(path, writeLogPath: logPath);

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

      await setTaskDone(
        path,
        rawLine: '- [ ] Test forms',
        done: true,
        writeLogPath: logPath,
      );
      final tasks = await rereadTasks(path);

      expect(tasks.single.done, isTrue);
    });
  });

  group('captureTask — quick capture, ADR 0014', () {
    test('appends to an existing ## Tasks section, after what is already '
        'there', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Already here\n');

      await captureTask(path, 'Something new', writeLogPath: logPath);

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

      await captureTask(path, 'First capture', writeLogPath: logPath);

      final updated = File(path).readAsStringSync();
      expect(updated, contains('A paragraph that must survive untouched.'));
      expect(updated, contains('## Tasks'));
      expect(updated, contains('- [ ] First capture'));
    });

    test('creates the file itself when it does not exist at all', () async {
      expect(File(path).existsSync(), isFalse);

      await captureTask(path, 'First ever capture', writeLogPath: logPath);

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
        writeLogPath: logPath,
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
        writeLogPath: logPath,
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

    test('Round 42 — a move where the second write fails leaves neither '
        'file changed: the destination write lands, then the source write '
        'is refused, and the destination is rolled back to what it held '
        'before this call', () async {
      const sourceBefore = '## Tasks\n\n- [ ] Move me\n';
      const destinationBefore = '## Tasks\n\n- [ ] Already there\n';
      File(path).writeAsStringSync(sourceBefore);
      File(otherPath).writeAsStringSync(destinationBefore);

      // Force the second write (removing the line from the source) to
      // fail: Windows refuses to rename a file over a read-only target.
      final attribResult = Process.runSync('attrib', ['+R', path]);
      expect(attribResult.exitCode, 0);
      addTearDown(() => Process.runSync('attrib', ['-R', path]));

      await expectLater(
        moveTask(
          fromPath: path,
          toPath: otherPath,
          rawLine: '- [ ] Move me',
          writeLogPath: logPath,
        ),
        throwsA(isA<Exception>()),
      );

      expect(File(path).readAsStringSync(), sourceBefore);
      expect(File(otherPath).readAsStringSync(), destinationBefore);
      expect(await readWriteLog(logPath: logPath), isEmpty);
    });

    test('a fresh destination file the failed move created gets deleted '
        'again, not left behind half-written', () async {
      const sourceBefore = '## Tasks\n\n- [ ] Move me\n';
      File(path).writeAsStringSync(sourceBefore);
      expect(File(otherPath).existsSync(), isFalse);

      final attribResult = Process.runSync('attrib', ['+R', path]);
      expect(attribResult.exitCode, 0);
      addTearDown(() => Process.runSync('attrib', ['-R', path]));

      await expectLater(
        moveTask(
          fromPath: path,
          toPath: otherPath,
          rawLine: '- [ ] Move me',
          writeLogPath: logPath,
        ),
        throwsA(isA<Exception>()),
      );

      expect(File(path).readAsStringSync(), sourceBefore);
      expect(File(otherPath).existsSync(), isFalse);
    });
  });

  group('addTaskAtTop — Round 42 §B, "＋ Add a task" at the top of the '
      'project', () {
    test('inserts before every existing task, not after', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Already here\n');

      await addTaskAtTop(path, 'New at the top', writeLogPath: logPath);

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [ ] New at the top'));
      expect(updated, contains('- [ ] Already here'));
      expect(
        updated.indexOf('New at the top'),
        lessThan(updated.indexOf('Already here')),
      );
    });

    test('creates the ## Tasks section when the file has none yet', () async {
      const original = '# Home\n\nA paragraph that must survive untouched.\n';
      File(path).writeAsStringSync(original);

      await addTaskAtTop(path, 'First one', writeLogPath: logPath);

      final updated = File(path).readAsStringSync();
      expect(updated, contains('A paragraph that must survive untouched.'));
      expect(updated, contains('- [ ] First one'));
    });

    test('creates the file itself when it does not exist at all', () async {
      await addTaskAtTop(path, 'Very first', writeLogPath: logPath);

      expect(File(path).readAsStringSync(), contains('- [ ] Very first'));
    });

    test('logs the new line', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Already here\n');

      await addTaskAtTop(path, 'New one', writeLogPath: logPath);

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-added');
      expect(entry.to, '- [ ] New one');
    });
  });

  group("editTaskText — Round 42 §B, \"click a task's text to edit in "
      'place"', () {
    test('changes only the sentence, leaving the checkbox alone', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Old text\n');

      await editTaskText(
        path,
        rawLine: '- [ ] Old text',
        oldText: 'Old text',
        newText: 'New text',
        writeLogPath: logPath,
      );

      expect(File(path).readAsStringSync(), contains('- [ ] New text'));
    });

    test('a done task keeps its own [x], and a trailing (Code) tag '
        'survives untouched', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [x] Ship the fix (Code)\n');

      await editTaskText(
        path,
        rawLine: '- [x] Ship the fix (Code)',
        oldText: 'Ship the fix',
        newText: 'Ship the real fix',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        contains('- [x] Ship the real fix (Code)'),
      );
    });

    test('throws when the exact line is no longer there', () {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Real line\n');

      expect(
        () => editTaskText(
          path,
          rawLine: '- [ ] A line that moved',
          oldText: 'A line that moved',
          newText: 'New text',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('logs the before and after text', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Old\n');

      await editTaskText(
        path,
        rawLine: '- [ ] Old',
        oldText: 'Old',
        newText: 'New',
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-text');
      expect(entry.from, 'Old');
      expect(entry.to, 'New');
    });
  });

  group('setTaskIndent — Round 42 §B, one subtask level, ADR 0039', () {
    test('indents a top-level task by two spaces', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Parent\n- [ ] Child\n');

      await setTaskIndent(
        path,
        rawLine: '- [ ] Child',
        indent: 1,
        writeLogPath: logPath,
      );

      expect(File(path).readAsStringSync(), contains('\n  - [ ] Child\n'));
    });

    test('un-indents a subtask back to top level', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Parent\n  - [ ] Child\n');

      await setTaskIndent(
        path,
        rawLine: '  - [ ] Child',
        indent: 0,
        writeLogPath: logPath,
      );

      final updated = File(path).readAsStringSync();
      expect(updated, contains('- [ ] Child'));
      expect(updated, isNot(contains('  - [ ] Child')));
    });

    test('throws when the exact line is no longer there', () {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Real line\n');

      expect(
        () => setTaskIndent(path, rawLine: '- [ ] Gone', indent: 1),
        throwsA(isA<StateError>()),
      );
    });

    test('logs the indent change', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Task\n');

      await setTaskIndent(
        path,
        rawLine: '- [ ] Task',
        indent: 1,
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-indent');
      expect(entry.from, '0');
      expect(entry.to, '1');
    });
  });

  group('reorderTasks — Round 42 §B, drag to reorder within one file', () {
    test('rewrites the section in the new order, byte for byte', () async {
      File(path).writeAsStringSync(
        '## Tasks\n\n- [ ] First\n- [ ] Second\n- [ ] Third\n',
      );

      await reorderTasks(
        path,
        currentOrder: ['- [ ] First', '- [ ] Second', '- [ ] Third'],
        newOrder: ['- [ ] Third', '- [ ] First', '- [ ] Second'],
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '## Tasks\n\n- [ ] Third\n- [ ] First\n- [ ] Second\n',
      );
    });

    test('refuses, unchanged, when newOrder is not a permutation of '
        'currentOrder', () async {
      const original = '## Tasks\n\n- [ ] First\n- [ ] Second\n';
      File(path).writeAsStringSync(original);

      await expectLater(
        reorderTasks(
          path,
          currentOrder: ['- [ ] First', '- [ ] Second'],
          newOrder: ['- [ ] First', '- [ ] Something else'],
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(File(path).readAsStringSync(), original);
    });

    test('refuses when the file changed on disk since it was read — a '
        'task was added since', () async {
      const original = '## Tasks\n\n- [ ] First\n- [ ] Second\n- [ ] New one\n';
      File(path).writeAsStringSync(original);

      await expectLater(
        reorderTasks(
          path,
          currentOrder: ['- [ ] First', '- [ ] Second'],
          newOrder: ['- [ ] Second', '- [ ] First'],
        ),
        throwsA(isA<StateError>()),
      );

      expect(File(path).readAsStringSync(), original);
    });

    test('logs the before and after order', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] A\n- [ ] B\n');

      await reorderTasks(
        path,
        currentOrder: ['- [ ] A', '- [ ] B'],
        newOrder: ['- [ ] B', '- [ ] A'],
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'tasks-reordered');
    });
  });

  group('the write log — ADR 0007 guardrail 3, 2026-09-13', () {
    test('setTaskDone logs the checkbox flip', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Test forms\n');

      await setTaskDone(
        path,
        rawLine: '- [ ] Test forms',
        done: true,
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.path, path);
      expect(entry.field, 'task-done');
      expect(entry.from, 'false');
      expect(entry.to, 'true');
    });

    test('setTaskParked logs the parked flip', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Park me\n');

      await setTaskParked(
        path,
        rawLine: '- [ ] Park me',
        parked: true,
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-parked');
      expect(entry.from, 'false');
      expect(entry.to, 'true');
    });

    test('captureTask logs the new line', () async {
      await captureTask(path, 'Newly captured', writeLogPath: logPath);

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-captured');
      expect(entry.from, '');
      expect(entry.to, '- [ ] Newly captured');
    });

    test('moveTask logs exactly one entry for the whole move — Round 42, '
        'ADR 0039: "a move... is one logged step," not one per file', () async {
      final otherPath = '${tempDir.path}${Platform.pathSeparator}other.md';
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Move me\n');
      File(otherPath).writeAsStringSync('## Tasks\n\n');

      await moveTask(
        fromPath: path,
        toPath: otherPath,
        rawLine: '- [ ] Move me',
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.path, otherPath);
      expect(entry.field, 'task-moved');
      expect(entry.from, path);
      expect(entry.to, '- [ ] Move me');
    });

    test('markAllTasksDone logs one entry for the whole call, not one '
        'per line', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] One\n- [ ] Two\n');

      await markAllTasksDone(path, writeLogPath: logPath);

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'tasks-marked-done');
      expect(entry.from, '2 open');
      expect(entry.to, '2 done');
    });

    test('a call that throws before writing logs nothing', () async {
      File(path).writeAsStringSync('# No tasks section\n');

      await expectLater(
        setTaskDone(
          path,
          rawLine: '- [ ] Anything',
          done: true,
          writeLogPath: logPath,
        ),
        throwsA(isA<StateError>()),
      );

      expect(await readWriteLog(logPath: logPath), isEmpty);
    });
  });

  group('removeTask — Round 43 §D, 🗑 in edit mode', () {
    test('removes the one line, leaves every other line untouched', () async {
      File(path).writeAsStringSync(
        '## Tasks\n\n'
        '- [ ] Keep me\n'
        '- [ ] Remove me\n'
        '- [ ] Keep me too\n',
      );

      await removeTask(path, rawLine: '- [ ] Remove me', writeLogPath: logPath);

      expect(
        File(path).readAsStringSync(),
        '## Tasks\n\n- [ ] Keep me\n- [ ] Keep me too\n',
      );
    });

    test('a subtask directly below is untouched — not re-parented or '
        're-indented', () async {
      File(path).writeAsStringSync(
        '## Tasks\n\n'
        '- [ ] Remove me\n'
        '  - [ ] My own subtask\n',
      );

      await removeTask(path, rawLine: '- [ ] Remove me');

      expect(
        File(path).readAsStringSync(),
        '## Tasks\n\n  - [ ] My own subtask\n',
      );
    });

    test('refuses, unchanged, when the line changed on disk since it was '
        'shown', () {
      const original = '## Tasks\n\n- [ ] Original\n';
      File(path).writeAsStringSync(original);

      expect(
        () => removeTask(path, rawLine: '- [ ] A different line entirely'),
        throwsStateError,
      );
      expect(File(path).readAsStringSync(), original);
    });

    test('logs the removed line, to empty', () async {
      File(path).writeAsStringSync('## Tasks\n\n- [ ] Gone\n');

      await removeTask(path, rawLine: '- [ ] Gone', writeLogPath: logPath);

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'task-removed');
      expect(entry.from, '- [ ] Gone');
      expect(entry.to, '');
    });
  });
}
