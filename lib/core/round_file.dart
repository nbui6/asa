/// Round 39 cp2 — a round's own spec file (`rounds\round-N.md`, or
/// `rounds\N-slug.md`), read for the one link it declares: which area it
/// belongs to. Distinct from `roadmap.dart`, which reads a project's own
/// `## Roadmap` milestone list — a round spec is a separate file this app
/// did not read at all before this round.
///
/// Pure Dart, no Flutter import, same discipline as every other file in
/// `core/`.
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/markdown.dart' show sectionText;

/// Reads `rounds\round-<roundNumber>.md`'s own text. Null when there is no
/// such file — a round number with no spec file, or a typo, is not an
/// error `asa-brief` should crash on.
Future<String?> readRoundFileText(
  String projectFolder,
  String roundNumber,
  FileAccess files,
) async {
  final name = 'round-$roundNumber.md';
  final names = await files.listFiles('$projectFolder/rounds');
  if (!names.contains(name)) return null;
  return files.readFile('$projectFolder/rounds/$name');
}

/// `**Area:** App`, near the top of the file — the manual's own §6 shape.
/// Null when the file names none, which is normal: not every round
/// belongs to one area.
final RegExp _areaLine = RegExp(r'\*\*Area:\*\*\s*(.+)', caseSensitive: false);

/// Parses a round file's own `**Area:**` line out of [roundFileText].
/// Looked for in the file's first 20 lines only — "near the top," per the
/// manual, not a mention anywhere in the body that happens to use the
/// same two words.
String? parseRoundArea(String roundFileText) {
  final lines = roundFileText.split('\n').take(20).join('\n');
  final match = _areaLine.firstMatch(lines);
  if (match == null) return null;
  final value = match.group(1)!.trim();
  return value.isEmpty ? null : value;
}

final RegExp _heading = RegExp(r'^#{2,3}\s*(.+)$', multiLine: true);

/// The body of the first `##`/`###` heading whose own text contains
/// [keyword] (case-insensitive) — real round files number and word their
/// headings differently (`## The finish line`, `## 1. The finish line —
/// what "done" means`), so neither an exact match nor a prefix match
/// survives contact with more than one file. Null when no heading
/// mentions it at all.
String? sectionTextContaining(String roundFileText, String keyword) {
  final lower = keyword.toLowerCase();
  for (final match in _heading.allMatches(roundFileText)) {
    final headingText = match.group(1)!.trim();
    if (headingText.toLowerCase().contains(lower)) {
      return sectionText(roundFileText, headingText);
    }
  }
  return null;
}

/// The round's own finish line — "what done means" — wherever its
/// heading actually says so.
String? parseRoundFinishLine(String roundFileText) =>
    sectionTextContaining(roundFileText, 'finish line');

/// How the round is tested — its own heading is worded differently file to
/// file ("The click-through", or the user's own name on it); whichever
/// mentions testing first, in file order, is the one asa-brief shows.
String? parseRoundTest(String roundFileText) =>
    sectionTextContaining(roundFileText, 'test');

final RegExp _h1 = RegExp(r'^#\s+(.+)$', multiLine: true);

/// Round 38 §C — the round's own `# Round N — …` heading, markers
/// stripped by the caller if needed. Used by the "Your call" screen's own
/// title and by `round_call_writer.dart`'s `approveRound`, which reuses
/// it verbatim as `APPROVED.md`'s own "result" column when Asa itself
/// writes the row — a derived fact, never an invented summary of what
/// changed. [fallback] when the file has no top-level heading at all.
String parseRoundTitle(String roundFileText, {required String fallback}) {
  final match = _h1.firstMatch(roundFileText);
  if (match == null) return fallback;
  return match.group(1)!.trim();
}

/// The first [maxLines] non-empty lines of [text] — "cut to about five
/// lines," round-38.md §C's own words for the finish line and the test
/// section on the "Your call" screen — with an honest count of what's
/// left, never a silent truncation. Null in, null out: nothing to cut is
/// not the same as an empty section.
String? cutToLines(String? text, int maxLines) {
  if (text == null) return null;
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length <= maxLines) return lines.join('\n');
  final shown = lines.take(maxLines).join('\n');
  final more = lines.length - maxLines;
  return '$shown\n… $more more line${more == 1 ? '' : 's'}, see the round file';
}
