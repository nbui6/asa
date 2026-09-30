/// Round 43 §A/§B, ADR 0042 — writes one new dated line into an area's
/// own `## Results` section, or the home note's own (a task with no
/// area). Same atomic-write and write-log discipline as `task_writer.dart`
/// and `area_writer.dart`; pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/area.dart' show ResultLink;
import 'package:asa/core/markdown.dart';
import 'package:asa/core/write_log.dart';

/// Writes one new line, newest first — ticking a task (naming it via
/// [taskText]), or the Log's own "＋ Result" button (round-43.md §C,
/// [taskText] left null: nothing was ticked, so there is no task to
/// name). Round 43 §B — an optional link to the file, folder or web page
/// it produced. Never edits an old line (7.4 of the manual: "a correction
/// is a new line"), so there is nothing to refuse on drift — this only
/// ever adds, the same shape as `task_writer.dart`'s own `captureTask`.
Future<void> writeResult(
  String path, {
  required String text,
  required DateTime date,
  String? taskText,
  ResultLink? link,
  String? writeLogPath,
}) async {
  final line = _buildLine(
    text: text,
    taskText: taskText,
    link: link,
    date: date,
  );
  await _prependResultLine(path, line);
  await appendWriteLogEntry(
    path: path,
    field: 'result-added',
    from: '',
    to: line,
    logPath: writeLogPath,
  );
}

String _buildLine({
  required String text,
  required String? taskText,
  required ResultLink? link,
  required DateTime date,
}) {
  final segments = [
    text.trim(),
    if (taskText != null) 'task: $taskText',
    if (link != null) '[${link.label}](${link.target})',
  ];
  return '- ${_isoDate(date)} — ${segments.join(' · ')}';
}

/// Same shape as `task_writer.dart`'s own private `_prependTaskLine`, one
/// section name over — kept as its own copy rather than a shared,
/// section-name-parameterised helper: the two sections' own creation
/// rules already read identically today, but `## Tasks` is a checkbox
/// list and `## Results` is prose: the moment one of them needs to differ
/// (a blank line rule, an ordering rule), sharing the function would mean
/// threading a branch through it instead of just editing the one that
/// changed.
Future<void> _prependResultLine(String path, String line) async {
  final file = File(path);
  final content = file.existsSync() ? await file.readAsString() : '';
  final range = sectionRange(content, 'Results');

  final String newContent;
  if (range == null) {
    final prefix = content.trimRight();
    newContent = prefix.isEmpty
        ? '## Results\n\n$line\n'
        : '$prefix\n\n## Results\n\n$line\n';
  } else {
    final (start, end) = range;
    final section = content.substring(start, end);
    final trimmedStart = section.trimLeft();
    final leadingBlank = section.substring(
      0,
      section.length - trimmedStart.length,
    );
    final body = trimmedStart.trimRight();
    final newSection = body.isEmpty
        ? '$leadingBlank$line\n'
        : '$leadingBlank$line\n$body\n';
    newContent =
        content.substring(0, start) + newSection + content.substring(end);
  }

  await _writeAtomically(path, newContent);
}

Future<void> _writeAtomically(String path, String content) async {
  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(content);
  await tempFile.rename(path);
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
