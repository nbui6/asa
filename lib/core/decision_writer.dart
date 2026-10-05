/// Appends a verdict to a decision file — Asa's first write to a decision
/// file, ever. ADR 0011: append only, never modify, delete or reorder a
/// single existing byte. Pure Dart, no Flutter import, same as every other
/// file in `core/`.
library;

import 'dart:io';

import 'package:asa/core/decision.dart';
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
