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

final RegExp _trailingParkedTag = RegExp(r'\s*\(parked\)\s*$');

/// Toggles a task's trailing `(parked)` tag, matched by its exact original
/// [Task.rawLine] — same discipline as [setTaskDone]: rewrites only that
/// line, refuses with a [StateError] if [rawLine] can no longer be found
/// (the file changed on disk since it was read). Every other byte on the
/// line — the checkbox, a `(Code)` tag, a `[[project]]` reference — is
/// untouched; parking is orthogonal to all three.
Future<void> setTaskParked(
  String path, {
  required String rawLine,
  required bool parked,
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

  final alreadyParked = _trailingParkedTag.hasMatch(rawLine);
  final String newLine;
  if (parked == alreadyParked) {
    newLine = rawLine;
  } else if (parked) {
    newLine = '$rawLine (parked)';
  } else {
    newLine = rawLine.replaceFirst(_trailingParkedTag, '');
  }

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

/// Appends one new, open task — quick capture, ADR 0014's "one input, type
/// anything, it lands in `## Tasks`, always". Creates the `## Tasks`
/// section, at the end of the file, if the file has none yet — `HOME.md`'s
/// inbox starts out exactly that way. The file itself is created if it
/// does not exist at all. Every other byte already in the file, including
/// every other task line, is untouched.
Future<void> captureTask(String path, String text) =>
    _appendTaskLine(path, '- [ ] $text');

/// Moves one task line from one file's `## Tasks` section to another's —
/// the write half of "drag it onto a project" (ADR 0014's addendum, "one
/// inbox, assignment is a drag too"). The line's exact text — done state,
/// a trailing `(Code)` tag, a `[[project]]` reference — travels unchanged;
/// only which file's `## Tasks` section holds it changes.
///
/// Writes the destination **before** touching the source: if anything
/// fails partway (a bad path, a full disk), the task ends up duplicated in
/// both files rather than deleted from the one it started in — the same
/// "fail by keeping too much, never by losing" choice every other write in
/// this app makes.
///
/// Throws a [StateError] if [rawLine] can no longer be found in
/// [fromPath]'s `## Tasks` section — same discipline as [setTaskDone]: the
/// file changed on disk since it was read, and guessing which line was
/// meant would be worse than refusing.
Future<void> moveTask({
  required String fromPath,
  required String toPath,
  required String rawLine,
}) async {
  final fromContent = await File(fromPath).readAsString();
  final range = sectionRange(fromContent, 'Tasks');
  if (range == null) {
    throw StateError('No ## Tasks section in $fromPath — nothing to move.');
  }
  final (start, end) = range;
  final section = fromContent.substring(start, end);

  final index = section.indexOf(rawLine);
  if (index == -1) {
    throw StateError(
      'That task line was not found in $fromPath — it may have changed on '
      'disk since it was read.',
    );
  }

  await _appendTaskLine(toPath, rawLine.trim());

  // Remove the line and the one newline that follows it, if any — leaves
  // no blank line behind, same as if it had never been there.
  var lineEnd = index + rawLine.length;
  if (lineEnd < section.length && section[lineEnd] == '\n') lineEnd += 1;
  final newSection = section.substring(0, index) + section.substring(lineEnd);

  await _writeAtomically(
    fromPath,
    fromContent.substring(0, start) + newSection + fromContent.substring(end),
  );
}

Future<void> _appendTaskLine(String path, String line) async {
  final file = File(path);
  final content = file.existsSync() ? await file.readAsString() : '';
  final range = sectionRange(content, 'Tasks');

  final String newContent;
  if (range == null) {
    final prefix = content.trimRight();
    newContent = prefix.isEmpty
        ? '## Tasks\n\n$line\n'
        : '$prefix\n\n## Tasks\n\n$line\n';
  } else {
    final (start, end) = range;
    final section = content.substring(start, end).trimRight();
    final newSection = section.isEmpty ? '\n$line\n' : '$section\n$line\n';
    newContent =
        content.substring(0, start) + newSection + content.substring(end);
  }

  await _writeAtomically(path, newContent);
}

Future<void> _writeAtomically(String path, String contents) async {
  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(contents);
  await tempFile.rename(path);
}
