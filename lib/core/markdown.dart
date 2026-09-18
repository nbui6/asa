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
  return _sectionRangeForPattern(text, pattern);
}

/// Same as [sectionText], but the heading line may carry more after the
/// heading name — `## Decision — proposed, three parts, in this order`
/// still matches `Decision`. A real ADR 0012 heading shape the exact
/// matcher does not survive. **Deliberately not used for `Why`**, which
/// stays exact-match only — see `decision.dart`'s own note on why `##
/// Why this is open` is correctly *not* read as `## Why`. The two fields
/// need opposite tolerances: a qualified `Decision` heading still names
/// the decision; a qualified `Why` heading may be answering a different
/// question entirely.
String? sectionTextByPrefix(String text, String heading) {
  final range = sectionRangeByPrefix(text, heading);
  if (range == null) return null;
  return text.substring(range.$1, range.$2).trim();
}

(int, int)? sectionRangeByPrefix(String text, String heading) {
  final pattern = RegExp(
    '^#{2,3}\\s*${RegExp.escape(heading)}\\b.*\$',
    multiLine: true,
    caseSensitive: false,
  );
  return _sectionRangeForPattern(text, pattern);
}

(int, int)? _sectionRangeForPattern(String text, RegExp pattern) {
  final match = firstUnfencedMatch(pattern, text);
  if (match == null) return null;

  final rest = text.substring(match.end);
  var end = rest.length;

  // Only a heading at the same level or shallower ends the section — a
  // deeper one (more `#`s) is a sub-heading and stays part of its
  // content. Found 2026-09-13: `roadmap.dart`'s phases are `###` headings
  // inside `## Roadmap`, and the old fixed `#{1,6}` bound treated that
  // `###` as ending the `##` section it was actually nested in — no real
  // decision file had a `###` inside a `##` section for this to surface
  // on before now.
  final level = RegExp('^#+').firstMatch(match[0]!)!.group(0)!.length;
  final nextHeading = firstUnfencedMatch(
    RegExp('^#{1,$level}\\s', multiLine: true),
    rest,
  );
  if (nextHeading != null && nextHeading.start < end) end = nextHeading.start;

  final rule = firstUnfencedMatch(RegExp(r'^---\s*$', multiLine: true), rest);
  if (rule != null && rule.start < end) end = rule.start;

  return (match.end, match.end + end);
}

/// Removes `**bold**`/`__bold__` markdown emphasis markers for display,
/// keeping the enclosed text. This app shows prose as plain text
/// everywhere — `SelectableText`, no markdown renderer — so a literal
/// `**` on screen is a rendering defect, not raw data worth preserving.
/// Found on ADR 0012's real content: `- **The doorman ships...** → …`
/// rendered with the asterisks still in it. The parsed `Decision` fields
/// themselves stay verbatim; this is applied only where text is about to
/// be shown, never inside the parser.
///
/// **`dotAll`, found 2026-09-14 on `CHARTER.md`'s real "Pain points"
/// section:** a `**bold span**` that happens to wrap onto a second line
/// in the source file — ordinary soft-wrapped prose, not a paragraph
/// break — left both asterisks on screen, because `.` does not match a
/// newline by default and the closing `**` was one line down. Every
/// other real fixture this was checked against has each bold span on one
/// physical line, so this was never hit until Round 16's Strategy tab
/// read a section with a longer wrapped one.
String stripEmphasisMarkers(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*', dotAll: true),
        (m) => m.group(1)!,
      )
      .replaceAllMapped(RegExp('__(.+?)__', dotAll: true), (m) => m.group(1)!);
}

/// Removes single-backtick code-span markers (`` `like this` ``) for
/// display, keeping the enclosed text — same reasoning as
/// [stripEmphasisMarkers]: a literal backtick on screen is a rendering
/// defect, not raw data worth preserving. Found 2026-09-13 on real `##
/// Tasks` lines in `asa.md` itself: `"Fix \`decision_detail_screen_test
/// .dart\`'s flakiness"` rendered with the backticks still in it, in the
/// Tasks view. Line-scoped, not fence-aware — a task line is one line by
/// definition, so [firstUnfencedMatch]'s multi-line fence handling does
/// not apply here.
String stripCodeSpanMarkers(String text) {
  return text.replaceAllMapped(RegExp('`(.+?)`'), (m) => m.group(1)!);
}

/// One heading anywhere in a document, and everything between it and the
/// next heading at the same level or shallower — Round 26 (`plan.dart`):
/// a plan page's structure is arbitrary prose with headings nobody names
/// in advance, unlike `## Roadmap`/`## Tasks`, which look for one known
/// heading string. [parseSections] reads every heading in one pass, reusing
/// the same same-level-or-shallower, fence-aware boundary rule
/// [_sectionRangeForPattern] already established (the 2026-09-13 phase
/// bugfix) rather than a second implementation of that rule.
class Section {
  const Section({
    required this.level,
    required this.heading,
    required this.body,
  });

  /// The number of leading `#` characters.
  final int level;

  final String heading;

  /// Trimmed; empty when the heading is immediately followed by another
  /// heading of the same level or shallower.
  final String body;
}

/// Every heading in [text], outermost or nested, each with its own body —
/// never just the ones a caller already knows the name of. Order is file
/// order. An empty list when [text] has no heading at all, not an error.
List<Section> parseSections(String text) {
  final headingLine = RegExp(r'^(#{1,6})\s*(.+?)\s*$', multiLine: true);
  final fences = _fencedRanges(text);
  final matches = [
    for (final match in headingLine.allMatches(text))
      if (!_isFenced(match.start, fences)) match,
  ];

  final sections = <Section>[];
  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final level = match.group(1)!.length;

    var end = text.length;
    for (var j = i + 1; j < matches.length; j++) {
      if (matches[j].group(1)!.length <= level) {
        end = matches[j].start;
        break;
      }
    }

    final rule = firstUnfencedMatch(
      RegExp(r'^---\s*$', multiLine: true),
      text.substring(match.end, end),
    );
    if (rule != null) end = match.end + rule.start;

    sections.add(
      Section(
        level: level,
        heading: match.group(2)!.trim(),
        body: text.substring(match.end, end).trim(),
      ),
    );
  }
  return sections;
}

/// [text] with every fenced ```` ``` ````-delimited block removed —
/// same fence rule as [firstUnfencedMatch], for a caller (Round 26's link
/// derivation) that needs to scan plain prose rather than test each match
/// individually.
String withoutFencedBlocks(String text) {
  return text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
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
