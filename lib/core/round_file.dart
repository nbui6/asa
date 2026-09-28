/// Round 39 cp2 — a round's own spec file (`rounds\round-N.md`, or
/// `rounds\N-slug.md`), read for the one link it declares: which area it
/// belongs to. Distinct from `roadmap.dart`, which reads a project's own
/// `## Roadmap` milestone list — a round spec is a separate file this app
/// did not read at all before this round.
///
/// Pure Dart, no Flutter import, same discipline as every other file in
/// `core/`.
library;

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
