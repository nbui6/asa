/// Appends a verdict to a decision file — Asa's first write to a decision
/// file, ever. ADR 0011: append only, never modify, delete or reorder a
/// single existing byte. Pure Dart, no Flutter import, same as every other
/// file in `core/`.
library;

import 'dart:io';

import 'package:asa/core/decision.dart';

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

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
