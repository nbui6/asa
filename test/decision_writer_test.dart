// Tests for the write side of ADR 0011 - append only, never touch an
// existing byte. Real files, real disk: the guarantee this file exists to
// prove is specifically about what dart:io actually does to a file on
// disk, which an in-memory fake cannot stand in for.

import 'dart:io';

import 'package:asa/core/decision_writer.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;
  late String logPathFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-verdict-test-');
    path = '${tempDir.path}${Platform.pathSeparator}0001-example.md';
    logPathFile = '${tempDir.path}${Platform.pathSeparator}decisions.md';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('appendVerdict — the byte-preservation guarantee', () {
    test('every byte before the new section is unchanged, accepted', () async {
      const original =
          '# ADR 0001 - Example\n\n'
          '**Date:** 2026-09-01 · **Status:** proposed\n\n'
          '## Why\n\nBecause.\n';
      File(path).writeAsStringSync(original);

      await appendVerdict(
        path,
        accepted: true,
        reason: 'A real reason.',
        date: DateTime(2026, 9, 7),
      );

      final updated = File(path).readAsStringSync();
      expect(updated.startsWith(original), isTrue);
      expect(updated, contains('## Your call'));
      expect(updated, contains('**Accepted** — 2026-09-07'));
      expect(updated, contains('A real reason.'));
    });

    test('rejected writes **Rejected**', () async {
      File(path).writeAsStringSync('# ADR 0001 - Example\n');

      await appendVerdict(
        path,
        accepted: false,
        reason: 'Not this one.',
        date: DateTime(2026, 9, 7),
      );

      expect(File(path).readAsStringSync(), contains('**Rejected**'));
    });

    test('an empty reason is written as "No reason given."', () async {
      File(path).writeAsStringSync('# ADR 0001 - Example\n');

      await appendVerdict(
        path,
        accepted: true,
        reason: '   ',
        date: DateTime(2026, 9, 7),
      );

      expect(File(path).readAsStringSync(), contains('No reason given.'));
    });

    test('round-trips through parseDecision: write, re-read, verdict '
        'matches what was written', () async {
      const original =
          '# ADR 0005 - Title\n\n**Date:** 2026-09-01 · **Status:** '
          'proposed\n';
      File(path).writeAsStringSync(original);

      await appendVerdict(
        path,
        accepted: true,
        reason: 'Because it works.',
        date: DateTime(2026, 9, 7),
      );

      final reread = await rereadDecision(path);
      expect(reread.isSuccess, isTrue);
      final verdict = reread.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-07');
      expect(verdict.reason, 'Because it works.');
      expect(reread.decision!.isProposed, isFalse);
    });

    test('refuses to write to a shared decisions.md log', () async {
      final logPath = '${tempDir.path}${Platform.pathSeparator}decisions.md';
      File(logPath).writeAsStringSync('# Decisions\n\n## 0001 - One\n');

      expect(
        () => appendVerdict(
          logPath,
          accepted: true,
          reason: 'x',
          date: DateTime(2026, 9, 7),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('appendVerdictInLog — Delivery v2 A1, the decisions.md shape', () {
    late String writeLogPath;

    setUp(() {
      writeLogPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
    });

    const twoEntries =
        '# Decisions - Example\n\nIntro text.\n\n'
        '---\n\n## 0001 - First\n\n**Date:** 2026-09-01 - **Status:** '
        'proposed\n\n**Decision:** One.\n\n---\n\n## 0002 - Second\n\n'
        '**Date:** 2026-09-01 - **Status:** proposed\n\n**Decision:** '
        'Two.\n';

    test('inserts inside the right entry, before its own trailing --- — the '
        "other entry's own bytes are untouched", () async {
      File(logPathFile).writeAsStringSync(twoEntries);

      await appendVerdictInLog(
        logPathFile,
        decisionNumber: '0001',
        decisionTitle: 'First',
        accepted: true,
        reason: '',
        date: DateTime(2026, 10, 6),
        writeLogPath: writeLogPath,
      );

      final updated = File(logPathFile).readAsStringSync();
      expect(updated, contains('## Your call'));
      expect(updated, contains('**Accepted** — 2026-10-06'));
      expect(updated, contains('No reason given.'));
      // The whole second entry, byte for byte, is still there unchanged.
      expect(
        updated,
        contains(
          '## 0002 - Second\n\n**Date:** 2026-09-01 - **Status:** '
          'proposed\n\n**Decision:** Two.\n',
        ),
      );
      // The inserted block lands before 0001's own closing separator,
      // so it stays inside 0001's own entry, ahead of 0002's heading.
      final yourCallAt = updated.indexOf('## Your call');
      final entry2At = updated.indexOf('## 0002');
      expect(yourCallAt, lessThan(entry2At));
    });

    test('a log with several entries — only the named one changes, re-read '
        'through the real parser confirms it', () async {
      File(logPathFile).writeAsStringSync(twoEntries);

      await appendVerdictInLog(
        logPathFile,
        decisionNumber: '0002',
        decisionTitle: 'Second',
        accepted: false,
        reason: 'Not now.',
        date: DateTime(2026, 10, 6),
        writeLogPath: writeLogPath,
      );

      final results = await const DecisionLogSource().readDecisions(
        tempDir.path,
        const DiskFileAccess(),
      );
      final first = results.firstWhere((r) => r.decision!.number == '0001');
      final second = results.firstWhere((r) => r.decision!.number == '0002');
      expect(first.decision!.verdict, isNull);
      expect(first.decision!.isProposed, isTrue);
      expect(second.decision!.verdict!.accepted, isFalse);
      expect(second.decision!.verdict!.reason, 'Not now.');
    });

    test('the entry is the last in the file — appends at the true end, same '
        'as a single-entry log', () async {
      File(logPathFile).writeAsStringSync(twoEntries);

      await appendVerdictInLog(
        logPathFile,
        decisionNumber: '0002',
        decisionTitle: 'Second',
        accepted: true,
        reason: '',
        date: DateTime(2026, 10, 6),
      );

      final updated = File(logPathFile).readAsStringSync();
      expect(updated.endsWith('No reason given.\n'), isTrue);
    });

    test('an empty reason is written as "No reason given."', () async {
      File(logPathFile).writeAsStringSync('## 0001 - Only\n\nText.\n');

      await appendVerdictInLog(
        logPathFile,
        decisionNumber: '0001',
        decisionTitle: 'Only',
        accepted: true,
        reason: '   ',
        date: DateTime(2026, 10, 6),
      );

      expect(
        File(logPathFile).readAsStringSync(),
        contains('No reason given.'),
      );
    });

    test('throws, writes nothing, when no entry matches', () async {
      const original = '## 0001 - Only\n\nText.\n';
      File(logPathFile).writeAsStringSync(original);

      await expectLater(
        () => appendVerdictInLog(
          logPathFile,
          decisionNumber: '9999',
          decisionTitle: 'Nothing',
          accepted: true,
          reason: '',
          date: DateTime(2026, 10, 6),
        ),
        throwsStateError,
      );
      expect(File(logPathFile).readAsStringSync(), original);
    });

    test('logs the write', () async {
      File(logPathFile).writeAsStringSync(twoEntries);

      await appendVerdictInLog(
        logPathFile,
        decisionNumber: '0001',
        decisionTitle: 'First',
        accepted: true,
        reason: '',
        date: DateTime(2026, 10, 6),
        writeLogPath: writeLogPath,
      );

      final entry = (await readWriteLog(logPath: writeLogPath)).single;
      expect(entry.field, 'decision-log-your-call');
      expect(entry.to, contains('Accepted'));
    });
  });

  group('appendVerdictAnyShape — one seam for both shapes', () {
    test('an ADR-folder file goes through appendVerdict', () async {
      File(path).writeAsStringSync('# ADR 0001 - Example\n');

      await appendVerdictAnyShape(
        path,
        decisionTitle: 'Example',
        accepted: true,
        reason: 'Because.',
        date: DateTime(2026, 10, 6),
      );

      expect(File(path).readAsStringSync(), contains('Because.'));
    });

    test('a decisions.md log goes through appendVerdictInLog', () async {
      File(logPathFile).writeAsStringSync('## 0001 - Only\n\nText.\n');

      await appendVerdictAnyShape(
        logPathFile,
        decisionNumber: '0001',
        decisionTitle: 'Only',
        accepted: true,
        reason: '',
        date: DateTime(2026, 10, 6),
      );

      expect(
        File(logPathFile).readAsStringSync(),
        contains('No reason given.'),
      );
    });
  });

  group('canAppendVerdict', () {
    test('true for a standalone ADR file', () {
      expect(canAppendVerdict(r'C:\proj\decisions\0001-example.md'), isTrue);
    });

    test('false for a shared decisions.md log, case-insensitively', () {
      expect(canAppendVerdict(r'C:\proj\decisions.md'), isFalse);
      expect(canAppendVerdict(r'C:\proj\DECISIONS.MD'), isFalse);
    });
  });

  group("editDecisionText — Round 43 §D, the human's own ✎", () {
    late String logPath;

    setUp(() {
      logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
    });

    test('rewrites the ## Decision body, heading and everything after '
        'untouched', () async {
      File(path).writeAsStringSync(
        '# ADR 0001 - Example\n\n'
        '**Date:** 2026-09-01 · **Status:** accepted\n\n'
        '## Decision\n\nOld text.\n\n'
        '## Why\n\nBecause.\n',
      );

      await editDecisionText(
        path,
        heading: 'Decision',
        newText: 'New text.',
        expectedCurrent: 'Old text.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# ADR 0001 - Example\n\n'
        '**Date:** 2026-09-01 · **Status:** accepted\n\n'
        '## Decision\n\nNew text.\n\n'
        '## Why\n\nBecause.\n',
      );
    });

    test('rewrites ## Why, exact heading only', () async {
      File(path).writeAsStringSync(
        '# ADR 0001 - Example\n\n## Decision\n\nText.\n\n'
        '## Why\n\nOld reason.\n',
      );

      await editDecisionText(
        path,
        heading: 'Why',
        newText: 'New reason.',
        expectedCurrent: 'Old reason.',
        writeLogPath: logPath,
      );

      expect(
        File(path).readAsStringSync(),
        '# ADR 0001 - Example\n\n## Decision\n\nText.\n\n'
        '## Why\n\nNew reason.\n',
      );
    });

    test('refuses a decisions.md log outright, writes nothing', () {
      final logFile = '${tempDir.path}${Platform.pathSeparator}decisions.md';
      const original = '# Decisions\n\n## 0001 - x\n\n## Decision\n\nText.\n';
      File(logFile).writeAsStringSync(original);

      expect(
        () => editDecisionText(
          logFile,
          heading: 'Decision',
          newText: 'New',
          expectedCurrent: 'Text.',
        ),
        throwsStateError,
      );
      expect(File(logFile).readAsStringSync(), original);
    });

    test('refuses, unchanged, when the section changed on disk since it '
        'was shown', () {
      const original = '# ADR 0001 - Example\n\n## Decision\n\nReal text.\n';
      File(path).writeAsStringSync(original);

      expect(
        () => editDecisionText(
          path,
          heading: 'Decision',
          newText: 'New',
          expectedCurrent: 'Something else entirely',
        ),
        throwsStateError,
      );
      expect(File(path).readAsStringSync(), original);
    });

    test('logs the before and after', () async {
      File(path)
          .writeAsStringSync('# ADR 0001 - Example\n\n## Decision\n\nOld.\n');

      await editDecisionText(
        path,
        heading: 'Decision',
        newText: 'New.',
        expectedCurrent: 'Old.',
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'decision-decision-edited');
      expect(entry.from, 'Old.');
      expect(entry.to, 'New.');
    });
  });
}
