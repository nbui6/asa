// Real files, real disk — same style as task_writer_test.dart and
// decision_writer_test.dart.

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/result_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-result-test-');
    path = '${tempDir.path}${Platform.pathSeparator}sales.md';
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('writeResult', () {
    test('prepends the new line, newest first, before what was already '
        'there', () async {
      const original =
          '# Sales\n\n'
          '## Results\n'
          '- 2026-09-20 — First joint pitch.\n';
      File(path).writeAsStringSync(original);

      await writeResult(
        path,
        text: 'A copy keeps its own period, 24 months',
        taskText: 'Ask legal the RC-16 question',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(File(path).readAsStringSync(), '''
# Sales

## Results
- 2026-09-28 — A copy keeps its own period, 24 months · task: Ask legal the RC-16 question
- 2026-09-20 — First joint pitch.
''');
    });

    test('no task at all — round-43.md §C, the Log\'s own "＋ Result" '
        'button, nothing was ticked', () async {
      File(path).writeAsStringSync('# Sales\n\n## Results\n');

      await writeResult(
        path,
        text: 'A plain result, no task behind it',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Results\n'
        '- 2026-09-28 — A plain result, no task behind it\n',
      );
    });

    test("carries a link, task first then the link, matching the manual's "
        'own worked example', () async {
      File(path).writeAsStringSync('# Sales\n\n## Results\n');

      await writeResult(
        path,
        text: 'A copy keeps its own period, 24 months',
        taskText: 'Ask legal the RC-16 question',
        link: const ResultLink(
          label: 'rc16-answer.pdf',
          target: r'C:\path\to\rc16-answer.pdf',
        ),
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\n## Results\n'
        '- 2026-09-28 — A copy keeps its own period, 24 months · '
        'task: Ask legal the RC-16 question · '
        r'[rc16-answer.pdf](C:\path\to\rc16-answer.pdf)'
        '\n',
      );
    });

    test('creates the ## Results section when the file has none yet, '
        'touching nothing else in it', () async {
      File(path).writeAsStringSync('# Sales\n\nThe partner registers.\n');

      await writeResult(
        path,
        text: 'First result',
        taskText: 'A task',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# Sales\n\nThe partner registers.\n\n## Results\n\n'
        '- 2026-09-28 — First result · task: A task\n',
      );
    });

    test('logs the new line, from empty', () async {
      File(path).writeAsStringSync('# Sales\n\n## Results\n');

      await writeResult(
        path,
        text: 'First result',
        taskText: 'A task',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      final entries = await readWriteLog(logPath: logPath);
      final entry = entries.single;
      expect(entry.field, 'result-added');
      expect(entry.from, '');
      expect(entry.to, '- 2026-09-28 — First result · task: A task');
    });
  });
}
