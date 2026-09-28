/// Round 39 cp5 — `.asa-log.md`: one line per finished session, written by
/// whichever AI closed it (manual §7.11). Append-only; Asa only ever
/// reads it. Pure Dart, no Flutter import.
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;

/// One real line: `- 2026-09-28 14:02–14:40 · Claude Code, account B ·
/// what you did, one line · files you wrote`. Only `date` is parsed out
/// for filtering; `text` is the rest, verbatim, for a reader who just
/// wants to see what happened — real lines vary in shape after the date
/// (a dropped start time, an extra clause), and re-parsing them into
/// fields that don't always apply would invent structure that isn't
/// there.
typedef SessionLogEntry = ({DateTime date, String text});

final RegExp _leadingDate = RegExp(r'^-\s*(\d{4}-\d{2}-\d{2})\b\s*(.*)$');

/// Reads every real line of `.asa-log.md`, newest last on the page —
/// same as the file's own append-only order, so a caller wanting newest
/// first reverses it themselves (`brief.dart` does, for `--since`). No
/// file, or a file with no parseable lines yet, returns an empty list —
/// a project with no finished session yet is not an error.
Future<List<SessionLogEntry>> readSessionLog(
  String projectFolder,
  FileAccess files,
) async {
  final names = await files.listFiles(projectFolder);
  if (!names.contains('.asa-log.md')) return const [];

  final contents = await files.readFile('$projectFolder/.asa-log.md');
  final entries = <SessionLogEntry>[];

  for (final line in contents.split('\n')) {
    final match = _leadingDate.firstMatch(line.trim());
    if (match == null) continue;
    final date = DateTime.tryParse(match.group(1)!);
    if (date == null) continue;
    entries.add((date: date, text: match.group(2)!.trim()));
  }

  return entries;
}
