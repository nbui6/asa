import 'dart:io';

import 'package:asa/core/changes_file.dart';
import 'package:asa/core/decisions_reader.dart' show DiskFileAccess;
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_call_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectFolder;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-round-call-test-');
    projectFolder = tempDir.path;
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('approveRound', () {
    test('creates APPROVED.md from scratch with the neutral header', () async {
      await approveRound(
        projectFolder,
        '38',
        roundTitle: 'Round 38 — the UI overhaul',
        writeLogPath: logPath,
        now: DateTime(2026, 9, 29),
      );

      final approvals = await readRoundApprovals(
        projectFolder,
        const DiskFileAccess(),
      );
      expect(approvals.hasApprovalFor('38'), isTrue);
      final approval = approvals.approvalFor('38')!;
      expect(approval.date, '2026-09-29');
      expect(approval.words, 'in Asa');
      expect(approval.result, 'Round 38 — the UI overhaul');
    });

    test('a typed feedback becomes the quoted words, not "in Asa"', () async {
      await approveRound(
        projectFolder,
        '38',
        roundTitle: 'Round 38',
        feedback: 'looks right',
        writeLogPath: logPath,
        now: DateTime(2026, 9, 29),
      );

      final approvals = await readRoundApprovals(
        projectFolder,
        const DiskFileAccess(),
      );
      expect(approvals.approvalFor('38')!.words, '"looks right"');
    });

    test('appends without touching an existing row', () async {
      final sep = Platform.pathSeparator;
      final path = '$projectFolder${sep}rounds${sep}APPROVED.md';
      await Directory('$projectFolder${Platform.pathSeparator}rounds').create();
      const original =
          '| date | round | their exact words | the result, in one line |\n'
          '|---|---|---|---|\n'
          '| 2026-09-01 | 37 | "yes" | Round 37 shipped |\n';
      File(path).writeAsStringSync(original);

      await approveRound(
        projectFolder,
        '38',
        roundTitle: 'Round 38',
        writeLogPath: logPath,
        now: DateTime(2026, 9, 29),
      );

      final text = File(path).readAsStringSync();
      expect(text, startsWith(original));
      expect(text, contains('| 2026-09-29 | 38 | in Asa | Round 38 |'));
    });

    test('logs the write', () async {
      await approveRound(
        projectFolder,
        '38',
        roundTitle: 'Round 38',
        writeLogPath: logPath,
      );

      final log = await readWriteLog(logPath: logPath);
      expect(log, hasLength(1));
      expect(log.first.field, 'round-approved');
    });
  });

  group('requestRoundChanges', () {
    test('creates CHANGES.md from scratch and appends the row', () async {
      await requestRoundChanges(
        projectFolder,
        '38',
        what: 'move the button left',
        writeLogPath: logPath,
        now: DateTime(2026, 9, 29),
      );

      final requests = await readChangeRequests(
        projectFolder,
        const DiskFileAccess(),
      );
      expect(requests, hasLength(1));
      expect(requests.first.round, '38');
      expect(requests.first.what, '"move the button left"');
    });

    test('logs the write', () async {
      await requestRoundChanges(
        projectFolder,
        '38',
        what: 'something',
        writeLogPath: logPath,
      );

      final log = await readWriteLog(logPath: logPath);
      expect(log, hasLength(1));
      expect(log.first.field, 'round-changes-requested');
    });
  });
}
