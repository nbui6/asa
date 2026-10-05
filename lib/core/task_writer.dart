/// Writes checkbox changes back into a project note's own `## Tasks`
/// section — nothing else in the file is touched, byte for byte. Same
/// atomic-write discipline as `decision_writer.dart`: a crash mid-write
/// must never leave a half-written file.
///
/// **2026-09-13 — every function here also logs**, via
/// `write_log.dart`'s `appendWriteLogEntry` — ADR 0007 guardrail 3, unmet
/// for these four since Rounds 8 and 9 shipped them. `writeLogPath`
/// overrides where, for tests; production code never passes it.
library;

import 'dart:io';

import 'package:asa/core/markdown.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/write_log.dart';

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
  String? writeLogPath,
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

  final wasDone = RegExp(r'\[[xX]\]').hasMatch(rawLine);
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

  await appendWriteLogEntry(
    path: path,
    field: 'task-done',
    from: wasDone.toString(),
    to: done.toString(),
    logPath: writeLogPath,
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
  String? writeLogPath,
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

  await appendWriteLogEntry(
    path: path,
    field: 'task-parked',
    from: alreadyParked.toString(),
    to: parked.toString(),
    logPath: writeLogPath,
  );
}

/// Marks every open task in this project's own `## Tasks` section done.
/// Already-done tasks, and every other line in the file, are untouched.
/// Writes nothing at all when there is no `## Tasks` section, or every
/// task in it is already done.
///
/// **2026-09-13:** not one of the four functions the write-log round
/// named, but the same guardrail — "every write is logged" — applies
/// just as much to marking several tasks done at once. Logs one entry
/// for the whole call, not one per line: `from` is how many were open,
/// `to` is how many just got marked.
Future<void> markAllTasksDone(String path, {String? writeLogPath}) async {
  final content = await File(path).readAsString();

  final range = sectionRange(content, 'Tasks');
  if (range == null) return;
  final (start, end) = range;
  final section = content.substring(start, end);

  final openPattern = RegExp(r'^(\s*-\s*)\[ \]', multiLine: true);
  final openCount = openPattern.allMatches(section).length;
  if (openCount == 0) return;

  final newSection = section.replaceAllMapped(
    openPattern,
    (match) => '${match.group(1)}[x]',
  );

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );

  await appendWriteLogEntry(
    path: path,
    field: 'tasks-marked-done',
    from: '$openCount open',
    to: '$openCount done',
    logPath: writeLogPath,
  );
}

/// Re-reads a project note's tasks from disk — never trust what this
/// session assumes it just wrote, the same discipline `decision_writer.dart`
/// follows for a recorded verdict.
Future<List<Task>> rereadTasks(String path) async {
  final contents = await File(path).readAsString();
  return parseTasks(contents);
}

/// Round 42 §B, ADR 0039 — the Tasks view's own "＋ Add a task", at the
/// top of "Not in an area": a new, open, top-level line, first in the
/// `## Tasks` section rather than last (an area's own add lands at the
/// bottom instead — [captureTask] already does that, unchanged). Creates
/// the section, or the whole file, exactly as [captureTask] does when
/// neither exists yet.
Future<void> addTaskAtTop(
  String path,
  String text, {
  String? writeLogPath,
}) async {
  final line = '- [ ] $text';
  await _prependTaskLine(path, line);
  await appendWriteLogEntry(
    path: path,
    field: 'task-added',
    from: '',
    to: line,
    logPath: writeLogPath,
  );
}

/// Round 42 §B, ADR 0039 — "click a task's text to edit in place." Only
/// the human-readable sentence changes; [oldText] (the task's own
/// [Task.text], tags already stripped) is matched as a literal substring
/// of [rawLine] — everything around it (the checkbox, leading
/// indentation, a trailing `(Code)`/`(parked)` tag, a `[[project]]`
/// reference) sits outside that substring and travels untouched. Throws a
/// [StateError] if [rawLine] (or [oldText] within it) can no longer be
/// found — the same drift refusal every writer here already gives.
Future<void> editTaskText(
  String path, {
  required String rawLine,
  required String oldText,
  required String newText,
  String? writeLogPath,
}) async {
  final content = await File(path).readAsString();

  final range = sectionRange(content, 'Tasks');
  if (range == null) {
    throw StateError('No ## Tasks section in $path — nothing to update.');
  }
  final (start, end) = range;
  final section = content.substring(start, end);

  final lineIndex = section.indexOf(rawLine);
  if (lineIndex == -1) {
    throw StateError(
      'That task line was not found in $path — it may have changed on '
      'disk since it was read.',
    );
  }

  final textIndex = rawLine.indexOf(oldText);
  if (textIndex == -1) {
    throw StateError(
      "That task's own text was not found on its line in $path — it may "
      'have changed on disk since it was read.',
    );
  }

  final newLine = rawLine.replaceRange(
    textIndex,
    textIndex + oldText.length,
    newText,
  );
  final newSection = section.replaceRange(
    lineIndex,
    lineIndex + rawLine.length,
    newLine,
  );

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );

  await appendWriteLogEntry(
    path: path,
    field: 'task-text',
    from: oldText,
    to: newText,
    logPath: writeLogPath,
  );
}

/// Round 43 §D — 🗑 in a task's own edit mode: removes that one line
/// outright, same trailing-newline handling as [_moveTaskInternal]'s own
/// "take it out of `fromPath`" half. A subtask directly below an indented
/// parent is untouched — only the one line named by [rawLine] goes; it is
/// never re-parented or re-indented as a side effect of its own parent
/// going.
Future<void> removeTask(
  String path, {
  required String rawLine,
  String? writeLogPath,
}) async {
  final content = await File(path).readAsString();

  final range = sectionRange(content, 'Tasks');
  if (range == null) {
    throw StateError('No ## Tasks section in $path — nothing to remove.');
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

  var lineEnd = index + rawLine.length;
  if (lineEnd < section.length && section[lineEnd] == '\n') lineEnd += 1;
  final newSection = section.substring(0, index) + section.substring(lineEnd);

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );

  await appendWriteLogEntry(
    path: path,
    field: 'task-removed',
    from: rawLine.trim(),
    to: '',
    logPath: writeLogPath,
  );
}

/// Round 42 §B, ADR 0039 — one subtask level, set by dragging a task to
/// the right (indent 1) or left again (indent 0, undoing it). Rewrites
/// only [rawLine]'s own leading whitespace — the checkbox, its text and
/// any trailing tag are untouched. Throws a [StateError] if [rawLine] can
/// no longer be found, same drift refusal as every writer here.
Future<void> setTaskIndent(
  String path, {
  required String rawLine,
  required int indent,
  String? writeLogPath,
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

  final wasIndent = (rawLine.length - rawLine.trimLeft().length) >= 2 ? 1 : 0;
  final newLine = '${'  ' * indent}${rawLine.trimLeft()}';
  final newSection = section.replaceRange(
    index,
    index + rawLine.length,
    newLine,
  );

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );

  await appendWriteLogEntry(
    path: path,
    field: 'task-indent',
    from: wasIndent.toString(),
    to: indent.toString(),
    logPath: writeLogPath,
  );
}

/// Round 42 §B, ADR 0039 — reordering within one section: [currentOrder]
/// must name every raw line the section holds **right now**, in the order
/// the caller last saw them; a mismatch (any line changed, added or
/// removed since) refuses with a [StateError] rather than reorder against
/// stale data. [newOrder] must be the same lines, permuted — an unequal
/// set is refused too, since this writer only ever reorders, it never
/// adds or drops a line.
Future<void> reorderTasks(
  String path, {
  required List<String> currentOrder,
  required List<String> newOrder,
  String? writeLogPath,
}) async {
  // Sorted-copy comparison, not a Set — two tasks can genuinely share the
  // exact same text, and a Set would silently collapse them.
  final sortedCurrent = [...currentOrder]..sort();
  final sortedNew = [...newOrder]..sort();
  if (!_sameOrder(sortedCurrent, sortedNew)) {
    throw ArgumentError(
      'reorderTasks: newOrder must be a permutation of currentOrder.',
    );
  }

  final content = await File(path).readAsString();
  final range = sectionRange(content, 'Tasks');
  if (range == null) {
    throw StateError('No ## Tasks section in $path — nothing to reorder.');
  }
  final (start, end) = range;
  final section = content.substring(start, end);

  final trimmedSection = section.trim();
  final actualLines = trimmedSection.isEmpty
      ? const <String>[]
      : trimmedSection.split('\n');
  if (!_sameOrder(actualLines, currentOrder)) {
    throw StateError(
      'The task list in $path changed on disk since it was read — refusing '
      'to reorder against stale data.',
    );
  }

  final newSection = section.replaceFirst(trimmedSection, newOrder.join('\n'));

  await _writeAtomically(
    path,
    content.substring(0, start) + newSection + content.substring(end),
  );

  await appendWriteLogEntry(
    path: path,
    field: 'tasks-reordered',
    from: currentOrder.join(' | '),
    to: newOrder.join(' | '),
    logPath: writeLogPath,
  );
}

/// Appends one new, open task — quick capture, ADR 0014's "one input, type
/// anything, it lands in `## Tasks`, always". Creates the `## Tasks`
/// section, at the end of the file, if the file has none yet — `HOME.md`'s
/// inbox starts out exactly that way. The file itself is created if it
/// does not exist at all. Every other byte already in the file, including
/// every other task line, is untouched.
Future<void> captureTask(
  String path,
  String text, {
  String? writeLogPath,
}) async {
  final line = '- [ ] $text';
  await _appendTaskLine(path, line);
  await appendWriteLogEntry(
    path: path,
    field: 'task-captured',
    from: '',
    to: line,
    logPath: writeLogPath,
  );
}

/// Moves one task line from one file's `## Tasks` section to another's —
/// the write half of "drag it onto a project" (ADR 0014's addendum, "one
/// inbox, assignment is a drag too"; Round 42, ADR 0039, drag onto another
/// project or area). The line's exact text — done state, a trailing
/// `(Code)` tag, a `[[project]]` reference — travels unchanged; only which
/// file's `## Tasks` section holds it changes.
///
/// **Round 42 supersedes this function's own older "destination first,
/// duplicate rather than lose" tradeoff** — round-42.md's own tests ask
/// for the stronger promise directly: "a move where the second write
/// fails → neither file changed." Both new file contents are computed
/// before either write touches disk; if [toPath] is written but
/// [fromPath] then fails, [toPath] is put back to exactly what it held
/// before this call (a fresh file it created is deleted instead) and the
/// error is rethrown — one logged step either way, never a half-moved
/// task.
///
/// Throws a [StateError] if [rawLine] can no longer be found in
/// [fromPath]'s `## Tasks` section — same discipline as [setTaskDone]: the
/// file changed on disk since it was read, and guessing which line was
/// meant would be worse than refusing. Logs **one** entry for the whole
/// move (ADR 0039: "a move... is one logged step"), not one per file.
Future<void> moveTask({
  required String fromPath,
  required String toPath,
  required String rawLine,
  String? writeLogPath,
}) => _moveTaskInternal(
  fromPath: fromPath,
  toPath: toPath,
  rawLine: rawLine,
  insert: _appendTaskLine,
  writeLogPath: writeLogPath,
);

/// Same as [moveTask], but the line lands **first** in the destination's
/// own `## Tasks` section, not last — round-42.md §A: "drop it on a
/// project [in the left rail]: it goes to the top of that project's
/// tasks." Dropping onto an area or another project's own task list
/// instead still uses [moveTask]'s own bottom placement.
Future<void> moveTaskToTop({
  required String fromPath,
  required String toPath,
  required String rawLine,
  String? writeLogPath,
}) => _moveTaskInternal(
  fromPath: fromPath,
  toPath: toPath,
  rawLine: rawLine,
  insert: _prependTaskLine,
  writeLogPath: writeLogPath,
);

Future<void> _moveTaskInternal({
  required String fromPath,
  required String toPath,
  required String rawLine,
  required Future<void> Function(String path, String line) insert,
  String? writeLogPath,
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

  // Remove the line and the one newline that follows it, if any — leaves
  // no blank line behind, same as if it had never been there.
  var lineEnd = index + rawLine.length;
  if (lineEnd < section.length && section[lineEnd] == '\n') lineEnd += 1;
  final newSection = section.substring(0, index) + section.substring(lineEnd);
  final newFromContent =
      fromContent.substring(0, start) + newSection + fromContent.substring(end);

  final trimmedLine = rawLine.trim();
  final toFile = File(toPath);
  final toExistedBefore = toFile.existsSync();
  final originalToContent = toExistedBefore
      ? await toFile.readAsString()
      : null;

  await insert(toPath, trimmedLine);

  try {
    await _writeAtomically(fromPath, newFromContent);
  } on Object {
    if (originalToContent == null) {
      if (toFile.existsSync()) await toFile.delete();
    } else {
      await _writeAtomically(toPath, originalToContent);
    }
    rethrow;
  }

  await appendWriteLogEntry(
    path: toPath,
    field: 'task-moved',
    from: fromPath,
    to: trimmedLine,
    logPath: writeLogPath,
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

/// Same as [_appendTaskLine], first instead of last — [addTaskAtTop] and
/// [moveTaskToTop] share this rather than each rebuilding the section
/// themselves.
Future<void> _prependTaskLine(String path, String line) async {
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
    final section = content.substring(start, end);
    final trimmedStart = section.trimLeft();
    final leadingBlank = section.substring(
      0,
      section.length - trimmedStart.length,
    );
    final newSection = trimmedStart.isEmpty
        ? '\n$line\n'
        : '$leadingBlank$line\n$trimmedStart';
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

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
