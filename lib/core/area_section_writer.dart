/// Round 43 §D, ADR 0042 — fills (＋) or edits (✎) one free-text section of
/// an area page, `## Goal` or `## Plan`, where the user typed it. Never
/// touches any other section. Same atomic-write and write-log discipline
/// as `task_writer.dart`; pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/markdown.dart';
import 'package:asa/core/write_log.dart';

/// Sets [heading]'s body to [text]. [expectedCurrent] is what the caller
/// was showing when the user started typing — null or empty for an empty
/// place (＋), the old text for an edit (✎). If the file no longer says
/// that, nothing is written and a [StateError] says why: the file changed
/// on disk since it was shown, and overwriting what is there now would be
/// worse than refusing.
///
/// A missing `## [heading]` section is created at the end of the file.
Future<void> setAreaSection(
  String path, {
  required String heading,
  required String text,
  String? expectedCurrent,
  String? writeLogPath,
}) async {
  final newText = text.trim();
  if (newText.isEmpty) {
    throw StateError('Nothing to write — a section needs some words.');
  }

  final content = await File(path).readAsString();
  final range = sectionRange(content, heading);

  final current = range == null
      ? null
      : _nullIfEmpty(content.substring(range.$1, range.$2).trim());
  final expected = _nullIfEmpty(expectedCurrent?.trim());
  if (current != expected) {
    throw StateError(
      'The $heading section changed on disk since it was shown — '
      'reload before editing it.',
    );
  }

  final String newContent;
  if (range == null) {
    final prefix = content.trimRight();
    newContent = prefix.isEmpty
        ? '## $heading\n\n$newText\n'
        : '$prefix\n\n## $heading\n\n$newText\n';
  } else {
    final (start, end) = range;
    final hasNextSection = end < content.length;
    // The heading pattern's own trailing `\s*` may already have swallowed
    // blank lines, so the body always starts from the trimmed heading.
    newContent =
        '${content.substring(0, start).trimRight()}\n\n$newText\n'
        '${hasNextSection ? '\n' : ''}${content.substring(end)}';
  }

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(newContent);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: 'area-${heading.toLowerCase()}-set',
    from: current ?? '',
    to: newText,
    logPath: writeLogPath,
  );
}

/// Round 43 §D — 🗑 in a filled section's own edit mode: clears the body
/// back to empty, the same state [setAreaSection] itself refuses to write
/// (a section needs some words to be *set*, but this is the one place
/// "no words" is exactly the point). The `## [heading]` line itself stays
/// — `sectionText` already reads an empty body the same as no section at
/// all, so the Plan tab shows its own heading-and-＋ again, same as a
/// section that was never filled. Same drift refusal as [setAreaSection].
Future<void> clearAreaSection(
  String path, {
  required String heading,
  required String expectedCurrent,
  String? writeLogPath,
}) async {
  final content = await File(path).readAsString();
  final range = sectionRange(content, heading);
  if (range == null) {
    throw StateError('No $heading section in $path — nothing to clear.');
  }

  final current = _nullIfEmpty(
    content.substring(range.$1, range.$2).trim(),
  );
  final expected = _nullIfEmpty(expectedCurrent.trim());
  if (current != expected) {
    throw StateError(
      'The $heading section changed on disk since it was shown — '
      'reload before clearing it.',
    );
  }

  final (start, end) = range;
  final hasNextSection = end < content.length;
  final newContent =
      '${content.substring(0, start).trimRight()}\n'
      '${hasNextSection ? '\n' : ''}${content.substring(end)}';

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(newContent);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: 'area-${heading.toLowerCase()}-removed',
    from: current ?? '',
    to: '',
    logPath: writeLogPath,
  );
}

String? _nullIfEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;
