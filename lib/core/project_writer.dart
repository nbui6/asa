/// Writes Asa's own five whitelisted frontmatter fields into a project
/// note — ADR 0007, accepted 2026-09-01, executed here for the first time.
/// Sibling of `task_writer.dart` and `decision_writer.dart`; same atomic
/// temp-file-then-rename discipline.
library;

import 'dart:io';

import 'package:asa/core/project.dart'
    show extractRawFrontmatter, parseFrontmatter;
import 'package:asa/core/write_log.dart';

/// The five fields ADR 0007 whitelists — the whole list, in code rather
/// than a comment. Reaching ten is the ADR's own tripwire to re-decide
/// this, not to extend it quietly.
const projectWritableFields = {
  'parent',
  'status',
  'priority',
  'deadline',
  'jira',
};

/// Writes [value] into [field] of the frontmatter block in [path].
///
/// A [field] not in [projectWritableFields] is refused with a
/// [StateError] naming it — ADR 0007 guardrail 1, a whitelist enforced in
/// code, not a comment. A key not yet present in the frontmatter gets
/// added (right before the closing `---`); a key present with an empty
/// value, or a real one, is replaced in place. An empty [value] clears
/// the field rather than removing its line — `deadline: ` with nothing
/// after it already parses back as absent (`project.dart`'s
/// `optionalField`), so the line stays, honestly blank.
///
/// [expectedFrontmatter] is the raw frontmatter block (`---` lines
/// included — `extractRawFrontmatter`'s own shape) as it was when last
/// read. If the file's frontmatter has changed since, this throws a
/// [StateError] and writes nothing — ADR 0007 guardrail 2: his editor may
/// be open on the same file at the same time.
///
/// Every other byte — every other frontmatter line (a second developer's
/// own `extra` keys included, Round 7's fork seam), and the whole body —
/// is untouched. Logs the change via `appendWriteLogEntry`
/// ([writeLogPath] overrides where, for tests) — ADR 0007 guardrail 3.
Future<void> setProjectField(
  String path, {
  required String field,
  required String value,
  required String expectedFrontmatter,
  String? writeLogPath,
}) async {
  if (!projectWritableFields.contains(field)) {
    throw StateError(
      '"$field" is not a writable field — only '
      '${projectWritableFields.join(', ')} may be written (ADR 0007).',
    );
  }

  final content = await File(path).readAsString();
  final currentFrontmatter = extractRawFrontmatter(content);

  if (currentFrontmatter != expectedFrontmatter) {
    throw StateError(
      'The frontmatter in $path has changed since it was read — refusing '
      'to write over a change this session has not seen. Re-read and try '
      'again.',
    );
  }
  if (currentFrontmatter.isEmpty) {
    throw StateError(
      'No frontmatter block found in $path — nothing to write to.',
    );
  }

  final oldValue = parseFrontmatter(content)[field] ?? '';

  final lines = currentFrontmatter.split('\n');
  final keyPattern = RegExp('^$field\\s*:');
  var found = false;
  for (var i = 1; i < lines.length - 1; i++) {
    if (keyPattern.hasMatch(lines[i])) {
      lines[i] = '$field: $value';
      found = true;
      break;
    }
  }
  if (!found) {
    lines.insert(lines.length - 1, '$field: $value');
  }

  final newFrontmatter = lines.join('\n');
  final newContent =
      newFrontmatter + content.substring(currentFrontmatter.length);

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(newContent);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: field,
    from: oldValue,
    to: value,
    logPath: writeLogPath,
  );
}
