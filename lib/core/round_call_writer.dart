/// Round 38 §C — a round's own "Your call" screen writes through here:
/// **Yes** appends one row to `rounds\APPROVED.md`; **Needs changes**
/// appends one row to `rounds\CHANGES.md`. Same atomic-write-plus-write-log
/// discipline as every other writer in `core/` (`task_writer.dart`,
/// `project_writer.dart`) — an exact append, never a rewrite of an
/// existing row, ADR 0021/0026's own narrow amendment (2026-09-28).
///
/// **The "in Asa" convention (Round 39 cp9):** Asa never writes a name
/// into a file. When the person types nothing into the optional feedback
/// box, the "their exact words" column reads the fixed, neutral `in Asa`
/// rather than a name or an invented quote — cp9's own instruction,
/// applied here rather than only described there.
///
/// **A judgment call, flagged rather than silently guessed:** the
/// "result, one line" column has nothing Asa could honestly derive about
/// *what actually changed for the person* — that is exactly the kind of
/// summary ADR 0021 point 4 keeps out of Asa's own hands. This writer
/// uses the round's own title instead (`RoundFile.title`, `round_file.dart`
/// — a fact already written by whoever specced the round, never invented
/// here) rather than leave the column blank or fabricate a description.
library;

import 'dart:io';

import 'package:asa/core/write_log.dart';

// Rule 16 — the tool is neutral, never a name — matters here specifically:
// this header is only ever written once, the first time this writer
// creates a brand new APPROVED.md/CHANGES.md for a project that doesn't
// have one yet. AGENTS.md §7.6/§7.7's own generic shape, not the
// asa project's own hand-written, personalised header.
const _approvedHeader =
    '| date | round | their exact words | the result, in one line |\n'
    '|---|---|---|---|\n';

const _changesHeader =
    '| date | round | what they want changed |\n'
    '|---|---|\n';

/// Appends one row to `rounds\APPROVED.md`. [feedback] is the optional
/// text typed in the Yes dialog's own box — empty or null writes `in
/// Asa` instead, never a guessed quote.
Future<void> approveRound(
  String projectFolder,
  String roundNumber, {
  required String roundTitle,
  String? feedback,
  String? writeLogPath,
  DateTime? now,
}) async {
  final sep = Platform.pathSeparator;
  final path = '$projectFolder${sep}rounds${sep}APPROVED.md';
  final date = _isoDate(now ?? DateTime.now());
  final words = (feedback == null || feedback.trim().isEmpty)
      ? 'in Asa'
      : '"${feedback.trim()}"';
  final row = '| $date | $roundNumber | $words | $roundTitle |\n';

  await _appendRow(path, row, header: _approvedHeader);
  await appendWriteLogEntry(
    path: path,
    field: 'round-approved',
    from: '',
    to: 'Round $roundNumber',
    logPath: writeLogPath,
  );
}

/// Appends one row to `rounds\CHANGES.md`. [what] is required — "needs
/// changes" with nothing said is not a usable row, and the caller (the
/// "Your call" screen) is expected to require the box filled in before
/// this is ever called.
Future<void> requestRoundChanges(
  String projectFolder,
  String roundNumber, {
  required String what,
  String? writeLogPath,
  DateTime? now,
}) async {
  final sep = Platform.pathSeparator;
  final path = '$projectFolder${sep}rounds${sep}CHANGES.md';
  final date = _isoDate(now ?? DateTime.now());
  final row = '| $date | $roundNumber | "${what.trim()}" |\n';

  await _appendRow(path, row, header: _changesHeader);
  await appendWriteLogEntry(
    path: path,
    field: 'round-changes-requested',
    from: '',
    to: 'Round $roundNumber',
    logPath: writeLogPath,
  );
}

Future<void> _appendRow(
  String path,
  String row, {
  required String header,
}) async {
  final file = File(path);
  final existing = file.existsSync() ? await file.readAsString() : header;
  final content = existing.endsWith('\n') ? '$existing$row' : '$existing\n$row';
  await file.parent.create(recursive: true);
  await _writeAtomically(path, content);
}

String _isoDate(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

Future<void> _writeAtomically(String path, String contents) async {
  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(contents);
  await tempFile.rename(path);
}
