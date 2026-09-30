// Real files, real disk — same style as area_writer_test.dart and
// task_writer_test.dart.

import 'dart:io';

import 'package:asa/core/decision_create_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectFolder;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-decision-create-test-');
    projectFolder = tempDir.path;
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('createDecision — the ADR-folder shape (no decisions.md)', () {
    test(
      r'writes decisions\0001-slug.md when there is no decision yet',
      () async {
        final result = await createDecision(
          projectFolder,
          decisionText: 'The register goes to legal as one PDF',
          date: DateTime(2026, 9, 28),
          writeLogPath: logPath,
        );

        expect(result.isSuccess, isTrue);
        expect(result.number, '0001');
        final file = File(result.sourceFile!);
        expect(file.path, endsWith('0001-the-register-goes-to-legal-as.md'));
        expect(file.readAsStringSync(), '''
# ADR 0001 — The register goes to legal as one PDF

**Date:** 2026-09-28 · **Status:** accepted
**Decided by:** the user

## Decision
The register goes to legal as one PDF
''');
      },
    );

    test('the next number is one past the highest existing file, not a '
        'count of them', () async {
      final decisionsDir = Directory(
        '$projectFolder${Platform.pathSeparator}decisions',
      )..createSync();
      File('${decisionsDir.path}${Platform.pathSeparator}0003-older.md')
          .writeAsStringSync('# ADR 0003 — Older\n');
      File('${decisionsDir.path}${Platform.pathSeparator}0009-newer.md')
          .writeAsStringSync('# ADR 0009 — Newer\n');

      final result = await createDecision(
        projectFolder,
        decisionText: 'A new one',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(result.number, '0010');
    });

    test(
      'Why and Links (area, objective, task, file) all show, in order',
      () async {
        final result = await createDecision(
          projectFolder,
          decisionText: 'A copy keeps its own period',
          date: DateTime(2026, 9, 28),
          why: 'Legal asked for it in writing.',
          area: 'Legal',
          objectives: ['2'],
          tasks: ['Ask legal the RC-16 question'],
          files: ['rc16-answer.pdf'],
          writeLogPath: logPath,
        );

        expect(File(result.sourceFile!).readAsStringSync(), '''
# ADR 0001 — A copy keeps its own period

**Date:** 2026-09-28 · **Status:** accepted
**Decided by:** the user
**Links:** Area: Legal · Serves: Objective 2 · Task: Ask legal the RC-16 question · File: rc16-answer.pdf

## Why
Legal asked for it in writing.

## Decision
A copy keeps its own period
''');
      },
    );

    test(
      'refuses a decision with no letters or numbers, writes nothing',
      () async {
        final result = await createDecision(
          projectFolder,
          decisionText: '   ',
          date: DateTime(2026, 9, 28),
          writeLogPath: logPath,
        );

        expect(result.isSuccess, isFalse);
        expect(
          Directory('$projectFolder${Platform.pathSeparator}decisions')
              .existsSync(),
          isFalse,
        );
      },
    );

    test('logs the write', () async {
      final result = await createDecision(
        projectFolder,
        decisionText: 'A new one',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      final entries = await readWriteLog(logPath: logPath);
      final entry = entries.single;
      expect(entry.field, 'decision-created');
      expect(entry.from, '');
      expect(entry.to, '${result.number} — A new one');
    });
  });

  group('createDecision — the decisions.md log shape', () {
    test('appends a new ## NNNN - Title section', () async {
      final logFile =
          File('$projectFolder${Platform.pathSeparator}decisions.md')
            ..writeAsStringSync('''
# Decisions

## 0001 - First one

**Date:** 2026-09-01 · **Status:** accepted
''');

      final result = await createDecision(
        projectFolder,
        decisionText: 'A new one',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(result.sourceFile, logFile.path);
      expect(result.number, '0002');
      expect(logFile.readAsStringSync(), '''
# Decisions

## 0001 - First one

**Date:** 2026-09-01 · **Status:** accepted

## 0002 - A new one

**Date:** 2026-09-28 · **Status:** accepted
**Decided by:** the user
''');
    });

    test(r'never writes decisions\ once decisions.md exists', () async {
      File('$projectFolder${Platform.pathSeparator}decisions.md')
          .writeAsStringSync('# Decisions\n');

      await createDecision(
        projectFolder,
        decisionText: 'A new one',
        date: DateTime(2026, 9, 28),
        writeLogPath: logPath,
      );

      expect(
        Directory('$projectFolder${Platform.pathSeparator}decisions')
            .existsSync(),
        isFalse,
      );
    });
  });
}
