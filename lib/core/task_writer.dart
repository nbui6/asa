/// Writes checkbox changes back into a project note's own `## Tasks`
/// section — nothing else in the file is touched, byte for byte. Same
/// atomic-write discipline as `decision_writer.dart`: a crash mid-write
/// must never leave a half-written file.
library;

import 'dart:io';

import 'package:asa/core/markdown.dart';
import 'package:asa/core/task.dart';

/// Sets one task's checkbox to done or open, matched by its exact original
/// [Task.rawLine]. Rewrites only that line; every other byte in the file,
/// including every other line in the same `## Tasks` section, is
/// untouched.
///
/// Throws a [StateError] if the file has no `## Tasks` section, or if
/// [rawLine] can no longer be found in it — the file changed on disk since
/// it was read, and guessing which line was meant would be worse than
/// refusing.
Future<void> setTaskDone(
  String path, {
  required String rawLine,
  required bool done,
}) async {
  final content = await File(path).readAsString();

  final range = sectionRange(content, 'Tasks');
  if (range == null) {
    throw StateError('No ## Tasks section in $path — nothing to update.');
  }
  final (start, end) = range;
  final section = content.substring(start, end);

  final index = section.indexOf(rawLine);
  if (index == -1) {
    throw StateError(
      'That task line was not found in $path — it may have changed on '
      'disk since it was read.',
    );
  }

  final newLine = rawLine.replaceFirst(
    RegExp(r'\[[ xX]\]'),
    done ? '[x]' : '[ ]',
  );
  final newSection = section.replaceRange(
    index,
    index + rawLine.length,
    newLine,
  );

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );
}

/// Marks every open task in this project's own `## Tasks` section done.
/// Already-done tasks, and every other line in the file, are untouched.
/// Writes nothing at all when there is no `## Tasks` section, or every
/// task in it is already done.
Future<void> markAllTasksDone(String path) async {
  final content = await File(path).readAsString();

  final range = sectionRange(content, 'Tasks');
  if (range == null) return;
  final (start, end) = range;
  final section = content.substring(start, end);

  final newSection = section.replaceAllMapped(
    RegExp(r'^(\s*-\s*)\[ \]', multiLine: true),
    (match) => '${match.group(1)}[x]',
  );
  if (newSection == section) return;

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );
}

/// Re-reads a project note's tasks from disk — never trust what this
/// session assumes it just wrote, the same discipline `decision_writer.dart`
/// follows for a recorded verdict.
Future<List<Task>> rereadTasks(String path) async {
  final contents = await File(path).readAsString();
  return parseTasks(contents);
}

Future<void> _writeAtomically(String path, String contents) async {
  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(contents);
  await tempFile.rename(path);
}
