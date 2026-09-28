/// Round 39 cp3 — `rounds\CHANGES.md`: one row per time the user presses
/// *Needs changes* on a round, or tells a session the same thing. Read-only,
/// same shape as `round_approvals.dart`'s own `APPROVED.md` reader.
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;

/// One row, newest last on the page — [readChangeRequests] reverses that,
/// so callers get newest first without re-sorting.
typedef ChangeRequest = ({String date, String round, String what});

/// Reads every real row of `rounds\CHANGES.md`, newest first. No file, or
/// a file with no real rows yet, returns an empty list — a round with no
/// change request against it is not an error, it is the common case.
Future<List<ChangeRequest>> readChangeRequests(
  String projectFolder,
  FileAccess files,
) async {
  final names = await files.listFiles('$projectFolder/rounds');
  if (!names.contains('CHANGES.md')) return const [];

  final contents = await files.readFile('$projectFolder/rounds/CHANGES.md');
  final rows = <ChangeRequest>[];

  for (final cells in _tableRows(contents)) {
    if (cells.length < 3) continue;
    final date = cells[0];
    final round = cells[1];
    final what = cells[2];
    if (date.isEmpty && round.isEmpty && what.isEmpty) continue;
    rows.add((date: date, round: round, what: what));
  }

  return rows.reversed.toList();
}

/// Header and separator skipped; one entry per data row's trimmed cells.
/// Same reasoning as `round_approvals.dart`'s own `_tableRows` — every
/// real row here is one physical line, not a general markdown-table parser.
List<List<String>> _tableRows(String contents) {
  final lines = contents
      .split('\n')
      .where((line) => line.trim().startsWith('|'))
      .toList();
  if (lines.length < 2) return [];
  return [for (final line in lines.skip(2)) _splitRow(line)];
}

List<String> _splitRow(String line) {
  var trimmed = line.trim();
  if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
  if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
  return trimmed.split('|').map((cell) => cell.trim()).toList();
}
