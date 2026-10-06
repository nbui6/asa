/// Appends a verdict to a decision file — Asa's first write to a decision
/// file, ever. ADR 0011: append only, never modify, delete or reorder a
/// single existing byte. Pure Dart, no Flutter import, same as every other
/// file in `core/`.
library;

import 'dart:io';

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/write_log.dart';

/// Whether [sourceFile] is safe to append a verdict to.
///
/// A decisions log (`decisions.md`) holds more than one decision in a
/// single file, each one a `## NNNN - Title` section. Appending a new
/// `## Your call` heading at the *end* of that file would not attach to
/// the decision that was actually decided — `DecisionLogSource` reads
/// every `## ` line as the start of a new entry, so the appended section
/// would parse back as a bogus decision of its own titled "Your call".
/// ADR 0011 was written and approved against the ADR-folder shape (one
/// decision, one file) — this guard keeps the write inside what it was
/// actually reasoned about, rather than silently also covering a shape
/// where "append to the end of the file" stops meaning "append to the end
/// of this decision."
bool canAppendVerdict(String sourceFile) =>
    !sourceFile.toLowerCase().endsWith('decisions.md');

/// Appends a `## Your call` section recording [accepted] (or rejected)
/// with [reason] — `"No reason given."` when the reason is blank — dated
/// [date].
///
/// **Atomic:** the whole new content is written to a temp file first, then
/// the temp file is renamed over the original. A crash mid-write leaves
/// the original untouched; the rename itself is a single filesystem
/// operation, never a half-written file in between.
///
/// **Never touches an existing byte.** The block is built separately and
/// concatenated onto the file's existing content exactly as read — no
/// trimming, no reformatting of what was already there, even if that
/// leaves an extra blank line when a file already ends in one. Guardrail
/// 1 of ADR 0011 has no exception for tidiness.
Future<void> appendVerdict(
  String path, {
  required bool accepted,
  required String reason,
  required DateTime date,
}) async {
  if (!canAppendVerdict(path)) {
    throw StateError(
      'Refusing to append a verdict to a decisions log ($path) — it would '
      'parse back as a new, bogus decision. See canAppendVerdict.',
    );
  }

  final file = File(path);
  final existing = await file.readAsString();

  final verdictWord = accepted ? 'Accepted' : 'Rejected';
  final dateText = _isoDate(date);
  final reasonText = reason.trim().isEmpty ? 'No reason given.' : reason.trim();
  final block =
      '\n\n## Your call\n\n**$verdictWord** — $dateText\n\n$reasonText\n';

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(existing + block);
  await tempFile.rename(path);
}

/// Re-reads and re-parses one decision from disk. Used after
/// [appendVerdict] — the screen shows what was actually written and
/// re-read, never what the caller assumes it wrote.
Future<DecisionReadResult> rereadDecision(String sourceFile) async {
  final contents = await File(sourceFile).readAsString();
  return parseDecision(contents, sourceFile);
}

/// The [rereadDecision] [appendVerdictAnyShape] needs for whichever shape
/// [sourceFile] really is. A lone ADR file is still [rereadDecision] —
/// the whole file *is* the one decision. A shared `decisions.md` log is
/// not: re-parsing the whole file as a single [Decision] would pick up
/// whichever entry `parseDecision`'s own field-scan happens to find first,
/// not necessarily the one just decided — this re-runs the real
/// [DecisionLogSource] split and picks out the matching entry the same
/// way [appendVerdictInLog] found it to write.
Future<DecisionReadResult> rereadDecisionAnyShape(
  String sourceFile, {
  required String decisionTitle,
  String? decisionNumber,
}) async {
  if (canAppendVerdict(sourceFile)) return rereadDecision(sourceFile);

  final projectFolder = File(sourceFile).parent.path;
  final results = await const DecisionLogSource().readDecisions(
    projectFolder,
    const DiskFileAccess(),
  );
  for (final result in results) {
    if (!result.isSuccess) continue;
    final decision = result.decision!;
    if (decisionNumber != null && decision.number == decisionNumber) {
      return result;
    }
    if (decisionNumber == null &&
        decision.number == null &&
        decision.title == decisionTitle) {
      return result;
    }
  }
  return DecisionReadResult(
    sourceFile: sourceFile,
    error:
        'Wrote the verdict, but could not find "$decisionTitle" again '
        'reading $sourceFile back.',
  );
}

/// Delivery v2, item A1 — one seam for both real shapes, so the Log's own
/// Yes button and the decision detail screen's Accept/Reject go through
/// the same write rather than each re-deciding which shape [sourceFile]
/// is. [decisionNumber]/[decisionTitle] are only used to find the right
/// entry inside a shared `decisions.md` log — unused, and safe to leave
/// null, for the one-decision-per-file shape.
Future<void> appendVerdictAnyShape(
  String sourceFile, {
  required String decisionTitle,
  required bool accepted,
  required String reason,
  required DateTime date,
  String? decisionNumber,
  String? writeLogPath,
}) {
  if (canAppendVerdict(sourceFile)) {
    return appendVerdict(
      sourceFile,
      accepted: accepted,
      reason: reason,
      date: date,
    );
  }
  return appendVerdictInLog(
    sourceFile,
    decisionNumber: decisionNumber,
    decisionTitle: decisionTitle,
    accepted: accepted,
    reason: reason,
    date: date,
    writeLogPath: writeLogPath,
  );
}

/// The same heading shape `decisions_reader.dart`'s own `DecisionLogSource`
/// splits a `decisions.md` log on — kept in sync by eye, not shared code,
/// since the two files read the same bytes for different reasons (finding
/// every entry to parse, versus finding one entry to write inside).
final RegExp _logHeading = RegExp(r'^##\s+\S.*$', multiLine: true);

/// `## 0001 - Title` / `## Title` — the number, when the heading has one;
/// `decision.dart`'s own `_headingPattern`, duplicated for the same reason
/// as [_logHeading] (one small regex, not worth a shared export across a
/// reader/writer pair that already don't share code).
final RegExp _logHeadingFields = RegExp(
  r'^#{1,2}\s*(?:ADR\s+)?(?:(\d{3,5})\s*[-—]\s*)?(.+)$',
);

/// Appends a `## Your call` section **inside one entry** of a shared
/// `decisions.md` log — at the end of that entry's own content, before its
/// closing `---` separator (if the next entry has one) or the next `## `
/// heading, never at the true end of the file the way [appendVerdict]
/// does for a lone ADR file. Every byte before and after the insertion
/// point is carried over unchanged, exactly as read — the same "never
/// touch an existing byte" guardrail [appendVerdict] follows, just at a
/// different splice point.
///
/// The entry is found by [decisionNumber] first (most real log entries
/// are numbered, `## 0001 - Title`); a heading with no number falls back
/// to an exact match on [decisionTitle]. Throws a [StateError], writing
/// nothing, when no entry matches — a silent no-op would be worse than a
/// loud refusal here, same reasoning [canAppendVerdict] already uses.
Future<void> appendVerdictInLog(
  String path, {
  required String decisionTitle,
  required bool accepted,
  required String reason,
  required DateTime date,
  String? decisionNumber,
  String? writeLogPath,
}) async {
  final content = await File(path).readAsString();
  final headings = _logHeading.allMatches(content).toList();

  int? entryIndex;
  for (var i = 0; i < headings.length; i++) {
    final headingLine = content.substring(headings[i].start, headings[i].end);
    final fields = _logHeadingFields.firstMatch(headingLine);
    if (fields == null) continue;
    final number = fields.group(1);
    final title = fields.group(2)!.trim();
    if (decisionNumber != null && number == decisionNumber) {
      entryIndex = i;
      break;
    }
    if (decisionNumber == null && number == null && title == decisionTitle) {
      entryIndex = i;
      break;
    }
  }
  if (entryIndex == null) {
    throw StateError(
      'No entry for "$decisionTitle" ($decisionNumber) found in $path.',
    );
  }

  final entryStart = headings[entryIndex].start;
  final entryEnd = entryIndex + 1 < headings.length
      ? headings[entryIndex + 1].start
      : content.length;
  final entryText = content.substring(entryStart, entryEnd);

  // The blank-line-then-"---"-then-blank-line separator a real log puts
  // between two entries sits inside *this* entry's own span (it comes
  // before the next heading) — insert ahead of it, not after, so it
  // keeps separating this entry from the next rather than orphaning
  // itself between this entry's old content and its own new verdict.
  final trailingSeparator = RegExp(r'\n-{3,}\s*\n+$').firstMatch(entryText);
  final insertAt =
      entryStart +
      (trailingSeparator != null ? trailingSeparator.start : entryText.length);

  final verdictWord = accepted ? 'Accepted' : 'Rejected';
  final dateText = _isoDate(date);
  final reasonText = reason.trim().isEmpty ? 'No reason given.' : reason.trim();
  final block =
      '\n\n## Your call\n\n**$verdictWord** — $dateText\n\n$reasonText\n';

  final newContent =
      content.substring(0, insertAt) + block + content.substring(insertAt);

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(newContent);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: 'decision-log-your-call',
    from: '',
    to: '$verdictWord — $reasonText',
    logPath: writeLogPath,
  );
}

/// Round 43 §D — the human's own ✎ on a decision's own `## Decision` or
/// `## Why` text. [heading] is `'Decision'` (tolerant of a trailing
/// qualifier, same as `Decision.decision`'s own parse) or `'Why'` (exact
/// match only — `decision.dart`'s own header explains why the two need
/// opposite tolerances).
///
/// **Refuses outright on a decisions log** (`decisions.md`) — same reason
/// [canAppendVerdict] already refuses a verdict there: more than one
/// decision shares the file, each its own `## NNNN - Title` section, and
/// rewriting "the first `## Decision`/`## Why` found" would not reliably
/// mean "this one's."  Editing a decision's own text through the app's ✎
/// is scoped to the ADR-folder shape (one decision, one file) until a
/// real need asks for the other.
///
/// [expectedCurrent] (trimmed) must still match what is on disk, same
/// drift discipline as `area_section_writer.dart`'s `setAreaSection` —
/// null/empty is never valid here, since both `## Decision` and `## Why`
/// are only ever reached already holding real text.
Future<void> editDecisionText(
  String path, {
  required String heading,
  required String newText,
  required String expectedCurrent,
  String? writeLogPath,
}) async {
  if (!canAppendVerdict(path)) {
    throw StateError(
      'Refusing to edit a decisions log ($path) — more than one decision '
      'shares the file; see canAppendVerdict.',
    );
  }

  final trimmedNew = newText.trim();
  if (trimmedNew.isEmpty) {
    throw StateError('Nothing to write — a decision needs some words.');
  }

  final content = await File(path).readAsString();
  final range = heading.toLowerCase() == 'decision'
      ? sectionRangeByPrefix(content, heading)
      : sectionRange(content, heading);
  if (range == null) {
    throw StateError('No ## $heading section in $path — nothing to edit.');
  }
  final (start, end) = range;
  final current = content.substring(start, end).trim();
  if (current != expectedCurrent.trim()) {
    throw StateError(
      'The $heading section changed on disk since it was shown — reload '
      'before editing it.',
    );
  }

  final hasNextSection = end < content.length;
  final newContent =
      '${content.substring(0, start).trimRight()}\n\n$trimmedNew\n'
      '${hasNextSection ? '\n' : ''}${content.substring(end)}';

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(newContent);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: 'decision-$heading-edited'.toLowerCase(),
    from: current,
    to: trimmedNew,
    logPath: writeLogPath,
  );
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
