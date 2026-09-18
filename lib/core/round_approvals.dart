/// `rounds\APPROVED.md` — ADR 0026's own open question, closed 2026-09-14:
/// how a Round's approval is recorded. One table, same shape as Round 29's
/// `sketches\APPROVED.md` reader, structurally simpler — one table, not
/// three.
///
/// Written by Nico, never by Asa — ADR 0026 rule 5, unchanged. This file
/// only reads it.
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;

/// One row: Nico's own words and the one-line result, dated. Never derived
/// — `RoundState.completed` depends on a row existing, and inventing one
/// would be exactly the thing ADR 0026 exists to stop.
typedef RoundApproval = ({String date, String words, String result});

class RoundApprovals {
  const RoundApprovals(this._byRound);

  final Map<String, RoundApproval> _byRound;

  bool hasApprovalFor(String? roundNumber) =>
      roundNumber != null && _byRound.containsKey(roundNumber);

  RoundApproval? approvalFor(String? roundNumber) =>
      roundNumber == null ? null : _byRound[roundNumber];
}

/// Reads every real row of `rounds\APPROVED.md`. No file, or a file with
/// no real rows yet (today's actual state) returns an empty
/// [RoundApprovals] — every Round then reads as not yet approved, which is
/// correct, not a gap in this reader.
Future<RoundApprovals> readRoundApprovals(
  String projectFolder,
  FileAccess files,
) async {
  final names = await files.listFiles('$projectFolder/rounds');
  if (!names.contains('APPROVED.md')) return const RoundApprovals({});

  final contents = await files.readFile('$projectFolder/rounds/APPROVED.md');
  final byRound = <String, RoundApproval>{};

  for (final cells in _tableRows(contents)) {
    if (cells.length < 4) continue;
    final date = cells[0];
    final roundCell = cells[1];
    final words = cells[2];
    final result = cells[3];
    if (date.isEmpty && roundCell.isEmpty && words.isEmpty && result.isEmpty) {
      continue; // the empty placeholder row this file starts with
    }

    final number = RegExp(r'\d+').firstMatch(roundCell)?.group(0);
    if (number == null) continue;
    byRound[number] = (date: date, words: words, result: result);
  }

  return RoundApprovals(byRound);
}

/// Header and separator skipped; one entry per data row's trimmed cells.
/// Not a general markdown-table parser — every real row here is one
/// physical line, same reasoning `decisions_reader.dart`'s own table
/// reader already relies on for `sketches\APPROVED.md`.
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
