// Real files, real disk — same reasoning as task_writer_test.dart: the
// guarantee here is specifically about what dart:io's append mode does.

import 'dart:io';

import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-write-log-test-');
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('appendWriteLogEntry', () {
    test('creates the file and its folder on the first entry', () async {
      expect(File(logPath).existsSync(), isFalse);

      await appendWriteLogEntry(
        path: 'demo.md',
        field: 'status',
        from: 'idea',
        to: 'building',
        timestamp: DateTime(2026, 9, 13, 12),
        logPath: logPath,
      );

      expect(File(logPath).existsSync(), isTrue);
    });

    test('appends, never overwrites — a second entry sits after the '
        'first, both readable back', () async {
      await appendWriteLogEntry(
        path: 'demo.md',
        field: 'status',
        from: 'idea',
        to: 'building',
        timestamp: DateTime(2026, 9, 13, 12),
        logPath: logPath,
      );
      await appendWriteLogEntry(
        path: 'demo.md',
        field: 'priority',
        from: '',
        to: 'high',
        timestamp: DateTime(2026, 9, 13, 13),
        logPath: logPath,
      );

      final entries = await readWriteLog(logPath: logPath);
      expect(entries, hasLength(2));
      expect(entries[0].field, 'status');
      expect(entries[1].field, 'priority');
    });

    test('round-trips every field exactly, including the timestamp', () async {
      final when = DateTime(2026, 9, 13, 14, 30);
      await appendWriteLogEntry(
        path: r'C:\workspace\projects\demo\demo.md',
        field: 'deadline',
        from: '2026-08',
        to: '2026-12',
        timestamp: when,
        logPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.path, r'C:\workspace\projects\demo\demo.md');
      expect(entry.field, 'deadline');
      expect(entry.from, '2026-08');
      expect(entry.to, '2026-12');
      expect(entry.timestamp, when);
    });
  });

  group('readWriteLog', () {
    test('a log that has never been written to reads as no entries, not '
        'an error', () async {
      expect(await readWriteLog(logPath: logPath), isEmpty);
    });
  });
}
