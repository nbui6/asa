/// Round 38 §E (ADR 0034) — the Log tab's own *What happened* timeline:
/// one merged, typed, newest-first list from six real sources, **nothing
/// written for the Log itself** — every entry is derived from a file
/// that already exists for its own reason. Pure Dart, no Flutter import.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/change_history.dart';
import 'package:asa/core/changes_file.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/session_log.dart';

/// The Log's own seven words (round-38.md §E) — never a code, never
/// re-derived from a string comparison at render time.
enum LogEntryType {
  decision,
  yourYes,
  changesAsked,
  aiWorked,
  change,
  changedWithoutNote,
  result,
}

/// One line of the Log's own timeline. [detail] is what "clicking a line
/// opens it in place" shows — the decision's own words, the round's own
/// feedback text, the change request's own words, the log line's own
/// text, the result's own text. Whatever this entry doesn't have (most
/// entries name no round, or no specific file) is null, never invented.
class LogEntry {
  const LogEntry({
    required this.type,
    required this.date,
    required this.title,
    required this.detail,
    this.hint,
    this.area,
    this.objectiveNumber,
    this.round,
    this.file,
  });

  final LogEntryType type;
  final DateTime date;
  final String title;
  final String detail;

  /// The grey hint next to the title — round-38.md §E's own line shape:
  /// *time · type pill · title · a grey hint*.
  final String? hint;

  final String? area;
  final String? objectiveNumber;
  final String? round;
  final String? file;
}

/// Every real entry across the six sources round-38.md §E names —
/// `decisions\`, `rounds\APPROVED.md`, `rounds\CHANGES.md`,
/// `sketches\APPROVED.md` (already folded into `readAllDecisions`, ADR
/// 0022 point 5), `.asa-log.md`, results in the area pages, and cp8's own
/// local history for *change*/*changed without a note* — sorted newest
/// first. [historyRoot] overrides where cp8's history lives, for a test;
/// production never passes it, so a laptop with no `%APPDATA%\Asa\`
/// history yet (asa-brief never run) just contributes nothing from that
/// one source, not an error.
Future<List<LogEntry>> readLogEntries(
  String projectFolder,
  FileAccess files, {
  String? historyRoot,
}) async {
  final entries = [
    ...await _decisionEntries(projectFolder, files),
    ...await _roundApprovalEntries(projectFolder, files),
    ...await _changeRequestEntries(projectFolder, files),
    ...await _sessionLogEntries(projectFolder, files),
    ...await _resultEntries(projectFolder),
    ...await _changeHistoryEntries(projectFolder, files, historyRoot),
  ]..sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

Future<List<LogEntry>> _decisionEntries(
  String projectFolder,
  FileAccess files,
) async {
  final entries = <LogEntry>[];
  for (final result in await readAllDecisions(projectFolder, files)) {
    if (!result.isSuccess) continue;
    final decision = result.decision!;
    final date = DateTime.tryParse(decision.date ?? '');
    if (date == null) continue;

    // ADR 0022 point 5 already folds sketches\APPROVED.md's own rows in
    // as Decision-shaped results — a sketch approval is "your yes," not
    // "decision," the same distinction round-38.md §E's own type list
    // draws between the two.
    final isSketchApproval = result.sourceFile.contains('sketches');
    entries.add(
      LogEntry(
        type: isSketchApproval ? LogEntryType.yourYes : LogEntryType.decision,
        date: date,
        title: decision.title,
        detail: decision.decision,
        hint: decision.status,
        area: decision.links.area,
        objectiveNumber: decision.links.objectives.isEmpty
            ? null
            : decision.links.objectives.first,
        round: decision.links.rounds.isEmpty
            ? null
            : decision.links.rounds.first,
        file: decision.sourceFile,
      ),
    );
  }
  return entries;
}

Future<List<LogEntry>> _roundApprovalEntries(
  String projectFolder,
  FileAccess files,
) async {
  final approvals = await readRoundApprovals(projectFolder, files);
  final entries = <LogEntry>[];
  for (final round in approvals.rounds) {
    final approval = approvals.approvalFor(round);
    if (approval == null) continue;
    final date = DateTime.tryParse(approval.date);
    if (date == null) continue;
    entries.add(
      LogEntry(
        type: LogEntryType.yourYes,
        date: date,
        title: 'Round $round approved',
        detail: approval.words,
        hint: approval.result,
        round: round,
      ),
    );
  }
  return entries;
}

Future<List<LogEntry>> _changeRequestEntries(
  String projectFolder,
  FileAccess files,
) async {
  final requests = await readChangeRequests(projectFolder, files);
  final entries = <LogEntry>[];
  for (final request in requests) {
    final date = DateTime.tryParse(request.date);
    if (date == null) continue;
    entries.add(
      LogEntry(
        type: LogEntryType.changesAsked,
        date: date,
        title: 'Round ${request.round} — changes asked',
        detail: request.what,
        round: request.round,
      ),
    );
  }
  return entries;
}

Future<List<LogEntry>> _sessionLogEntries(
  String projectFolder,
  FileAccess files,
) async {
  final log = await readSessionLog(projectFolder, files);
  return [
    for (final entry in log)
      LogEntry(
        type: LogEntryType.aiWorked,
        date: entry.date,
        title: entry.text,
        detail: entry.text,
      ),
  ];
}

Future<List<LogEntry>> _resultEntries(String projectFolder) async {
  final areas = await readAreas(projectFolder);
  final entries = <LogEntry>[];
  for (final area in areas) {
    for (final result in area.results) {
      if (result.date == null) continue;
      entries.add(
        LogEntry(
          type: LogEntryType.result,
          date: result.date!,
          title: result.text,
          detail: result.text,
          area: area.name,
          file: area.sourceFile,
        ),
      );
    }
  }
  return entries;
}

Future<List<LogEntry>> _changeHistoryEntries(
  String projectFolder,
  FileAccess files,
  String? historyRoot,
) async {
  final history = await readChangeHistory(
    projectFolder,
    historyRoot: historyRoot,
  );
  if (history.isEmpty) return const [];

  final log = await readSessionLog(projectFolder, files);
  final entries = <LogEntry>[];
  for (final record in history) {
    if (record.before == null) continue; // first seen, not a change
    final match = isLoggedChange(record, log);
    // round-38.md §E's own type list has exactly seven words, no eighth
    // for "probably" — a day-only fallback match (ADR 0048) reads as a
    // quiet *change*, same as a certain one, but says so in its own hint
    // rather than silently treating the two as equally sure.
    entries.add(
      LogEntry(
        type: match == LoggedMatch.no
            ? LogEntryType.changedWithoutNote
            : LogEntryType.change,
        date: record.timestamp,
        title: record.path,
        detail:
            '${record.linesBefore} line(s) before, '
            '${record.linesAfter} after',
        hint: match == LoggedMatch.probably ? 'probably logged' : null,
        file: record.path,
      ),
    );
  }
  return entries;
}
