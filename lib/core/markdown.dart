/// Fence-aware markdown section reading, shared by anything that reads a
/// `## Heading` section out of free-form project or decision text.
///
/// Extracted after a real bug: `0011-append-only-verdicts.md` documents its
/// own appended-verdict shape inside a fenced code example, and the
/// section reader in `decision.dart` matched it as a live section — the
/// fenced example was read as a recorded verdict. One fence-aware
/// implementation, reused everywhere a `##` section is read, rather than
/// every reader growing its own copy of the same fix.
library;

/// The exact text of a `## Heading` or `### Heading` section — from the
/// line after the heading to the next heading, `---` rule, or end of
/// text — or null if the heading is not present outside a fenced code
/// block. Case-insensitive on the heading name.
String? sectionText(String text, String heading) {
  final range = sectionRange(text, heading);
  if (range == null) return null;
  return text.substring(range.$1, range.$2).trim();
}

/// Same as [sectionText], but the raw start/end offsets into [text] —
/// untrimmed, and unlike [sectionText] not stopped at the heading's own
/// line — for a caller that needs to rewrite only the bytes inside the
/// section (e.g. checking off a task) while leaving everything else in the
/// file byte-identical.
(int, int)? sectionRange(String text, String heading) {
  final pattern = RegExp(
    '^#{2,3}\\s*${RegExp.escape(heading)}\\s*\$',
    multiLine: true,
    caseSensitive: false,
  );
  final match = firstUnfencedMatch(pattern, text);
  if (match == null) return null;

  final rest = text.substring(match.end);
  var end = rest.length;

  final nextHeading = firstUnfencedMatch(
    RegExp(r'^#{1,6}\s', multiLine: true),
    rest,
  );
  if (nextHeading != null && nextHeading.start < end) end = nextHeading.start;

  final rule = firstUnfencedMatch(RegExp(r'^---\s*$', multiLine: true), rest);
  if (rule != null && rule.start < end) end = rule.start;

  return (match.end, match.end + end);
}

/// The first match of [pattern] in [text] that does not sit inside a
/// fenced code block. A `## Your call` (or any other heading) written as
/// an *example*, inside triple backticks, is not a real section — see the
/// library note above.
RegExpMatch? firstUnfencedMatch(RegExp pattern, String text) {
  final fences = _fencedRanges(text);
  for (final candidate in pattern.allMatches(text)) {
    if (!_isFenced(candidate.start, fences)) return candidate;
  }
  return null;
}

/// Start/end offsets of every ```` ``` ````-fenced block in [text].
List<(int, int)> _fencedRanges(String text) {
  final ranges = <(int, int)>[];
  for (final match in RegExp(r'```[\s\S]*?```').allMatches(text)) {
    ranges.add((match.start, match.end));
  }
  return ranges;
}

bool _isFenced(int position, List<(int, int)> fences) {
  for (final fence in fences) {
    if (position >= fence.$1 && position < fence.$2) return true;
  }
  return false;
}
