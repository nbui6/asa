/// One decision, parsed from text. Pure Dart, no Flutter import — the same
/// rule `project.dart` follows, and for the same reason: this is where the
/// rules live, and rules are where things go wrong quietly.
///
/// The contract below was checked against every real file in two projects -
/// this one's `decisions/` folder, and a second project that keeps a single
/// `decisions.md` log - not invented from the template alone. The projects
/// are named in the round note outside this repository; project material
/// does not belong in source.

/// Two shapes, and reality only partly matches the template. Two things
/// the template implies but reality does not provide:
///
/// - Most real ADR files have no section literally named `## Why` — they
///   have `## Why the toggle is off by default`, `## Why this is safe
///   enough`, or no "why" heading at all. Only an exact `## Why` counts;
///   anything else leaves the field empty rather than guessing which prose
///   is "the why".
/// - `## What would change this` is absent from at least one real, accepted
///   ADR (`0006-workspace-structure.md`). Absent is valid, same as `##
///   Decision` falling back to the title.
library;

import 'package:asa/core/markdown.dart';

/// The recorded answer to a proposed decision — ADR 0011. Appended by Asa,
/// never edited by it; reading it back is the only way to learn it exists.
class Verdict {
  const Verdict({
    required this.accepted,
    required this.date,
    required this.reason,
  });

  final bool accepted;
  final String date;

  /// Verbatim as typed, or `"No reason given."` — `decision_writer.dart`
  /// writes that literal fallback, so an empty reason never round-trips
  /// as an empty string.
  final String reason;
}

/// Round 39 cp2 — the optional `**Links:**` line on a decision:
/// `**Links:** Area: Sales · Serves: Objective 2 · Round: 38 · Supersedes:
/// 0005`. Every field is optional; leaving one out means it doesn't apply,
/// never a guess. `Scope: always` marks a rule that holds everywhere, not
/// tied to one area.
class DecisionLinks {
  const DecisionLinks({
    this.area,
    this.objective,
    this.round,
    this.supersedes,
    this.scopeAlways = false,
  });

  final String? area;

  /// The bare objective number (`"2"`), the same shape `area.dart`'s own
  /// `objectiveNumbers` already uses — parsed out of `Serves: Objective 2`
  /// (or kept as the raw value when it isn't that exact shape).
  final String? objective;
  final String? round;
  final String? supersedes;
  final bool scopeAlways;

  static const DecisionLinks none = DecisionLinks();
}

/// A decision. Every field but [title] and [sourceFile] may be empty or
/// null — absence is normal, not an error. See the notes at the top of
/// this file for why.
class Decision {
  const Decision({
    required this.title,
    required this.why,
    required this.decision,
    required this.whatWouldChangeThis,
    required this.sourceFile,
    this.number,
    this.date,
    this.status,
    this.supersedes,
    this.supersededBy,
    this.verdict,
    this.verdictUnreadable = false,
    this.links = DecisionLinks.none,
  });

  final String? number;
  final String title;
  final String? date;
  final String? status;

  /// The ADR number this one replaces — from the status text
  /// (`accepted (supersedes 0005)`) or, Round 39, the `**Links:**` line's
  /// own `Supersedes:` value. `parseDecision` already merges the two; this
  /// is always the effective answer, never a second field to check.
  final String? supersedes;

  /// Round 39 cp2 — the parsed `**Links:**` line, [DecisionLinks.none] when
  /// there isn't one. Old decisions without it keep working everywhere
  /// else; they are simply not found by area, objective or round.
  final DecisionLinks links;

  /// The ADR number that replaced this one, read out of the status text —
  /// `superseded by 0008`.
  final String? supersededBy;

  /// Verbatim first paragraph of the `## Why` section (or the `**Why:**`
  /// paragraph, in a log). Empty when the file has no exact match for
  /// either — never a summary written to fill the gap.
  final String why;

  /// The `## Decision` section, or `## Recommendation` where that is what
  /// the file has, or the title itself when neither exists.
  final String decision;

  /// The `## What would change this` section, or its `**...:**` paragraph
  /// in a log. The highest-value field in the file when it is there at
  /// all, and it is routinely not.
  final String whatWouldChangeThis;

  /// The file this was read from, so the screen can say where a value
  /// came from — the same obligation the provenance block already carries.
  final String sourceFile;

  /// The `## Your call` section, if Asa has appended one — ADR 0011. The
  /// header's own `**Status:**` line is never corrected to match; this is
  /// the effective answer, read from the end of the file, not the top.
  final Verdict? verdict;

  /// Round 35/E — a `## Your call` section exists (Asa found the heading),
  /// but nothing inside it matched any recognized `**Accepted**`/
  /// `**Rejected**` shape. Distinct from "no verdict yet": that silent
  /// gap is exactly how six of seven real "Needs a look" rows turned out
  /// to already be decided — the parser stayed quiet instead of saying it
  /// couldn't read the file.
  final bool verdictUnreadable;

  /// Whether this decision still wants something from you: the header
  /// says `proposed`, **and** nothing has been recorded yet — or a
  /// `## Your call` section exists that Asa still can't read, which is
  /// exactly as unresolved as no verdict at all, just for a different
  /// reason. A verdict overrides the header rather than the other way
  /// round — ADR 0011 is explicit that the header is never corrected. The
  /// other half of "wants something from you" — an accepted decision with
  /// a fired condition — has no data source yet: [whatWouldChangeThis] is
  /// raw prose, and nothing records whether one of its conditions has
  /// actually happened. See `asa-v01b-NOT-IN-V0.1.md`. The one canonical
  /// place this check is made — `project_screen.dart`'s status pill uses
  /// it too, rather than re-deriving its own.
  bool get isProposed =>
      verdictUnreadable ||
      ((status ?? '').toLowerCase().contains('proposed') && verdict == null);

  /// What to show as the status, accounting for a recorded verdict — never
  /// the raw [status] directly. Falls back to [status] (or `''`) when
  /// there is no verdict, so callers do not need to null-check twice.
  /// Round 35/E: a `## Your call` section Asa can't parse says so plainly
  /// rather than silently trusting the header's own possibly-stale word.
  String get displayStatus {
    final recorded = verdict;
    if (recorded != null) return recorded.accepted ? 'accepted' : 'rejected';
    if (verdictUnreadable) return 'verdict unreadable';
    return status ?? '';
  }
}

/// What happened when we tried to parse one decision file, or one section of
/// a decision log.
///
/// Mirrors `ProjectReadResult`: a result object rather than an exception or
/// a null, because a decision that could not be read must still be shown,
/// with its path and its raw text. Silent skipping is banned.
class DecisionReadResult {
  const DecisionReadResult({
    required this.sourceFile,
    this.decision,
    this.error,
    this.rawText = '',
  });

  final Decision? decision;
  final String? error;

  /// The text this was parsed from, verbatim — shown when parsing failed,
  /// so a human can see what the file actually said.
  final String rawText;

  final String sourceFile;

  bool get isSuccess => decision != null;
}

/// Parses one decision out of [text] — a whole ADR file, or one `##`
/// section of a decisions log. [sourceFile] is carried through untouched,
/// even on failure.
DecisionReadResult parseDecision(String text, String sourceFile) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return DecisionReadResult(
      error: 'Empty — nothing to parse',
      rawText: text,
      sourceFile: sourceFile,
    );
  }

  final headingMatch = _headingPattern.firstMatch(trimmed);
  if (headingMatch == null) {
    return DecisionReadResult(
      error: 'No heading found — expected a line starting with # or ##',
      rawText: text,
      sourceFile: sourceFile,
    );
  }

  // Round 35/D — every other markdown-sourced text in the app (task text,
  // next-step) already strips these before display; the title was missed
  // when decisions got a place users actually read them (Round 26).
  final title = stripCodeSpanMarkers(
    stripEmphasisMarkers((headingMatch.group(2) ?? '').trim()),
  );
  if (title.isEmpty) {
    return DecisionReadResult(
      error: 'Heading has no title',
      rawText: text,
      sourceFile: sourceFile,
    );
  }

  final number = headingMatch.group(1);
  final afterHeading = trimmed.substring(headingMatch.end);

  final status = _statusFrom(afterHeading);
  final date = _dateFrom(afterHeading);

  final why = _firstParagraph(_section(afterHeading, 'Why') ?? '');
  final decisionText =
      _sectionByPrefix(afterHeading, 'Decision') ??
      _sectionByPrefix(afterHeading, 'Recommendation') ??
      title;
  final whatWouldChangeThis =
      _section(afterHeading, 'What would change this') ?? '';
  // Round 35/E — real files write "## Your call — 2026-09-14", the date
  // sharing the heading line. An exact-match heading (_section) never
  // finds that line at all; _sectionByPrefix does, and _yourCallHeadingDate
  // recovers the date the heading itself carries, for when the body below
  // it doesn't repeat one.
  final yourCall = _sectionByPrefix(afterHeading, 'Your call');
  final headingDate = _yourCallHeadingDate(afterHeading);
  final verdict = yourCall == null
      ? null
      : _parseVerdict(yourCall, headingDate: headingDate);
  // A "## Your call" section that exists but still can't be read must not
  // read as "proposed" — that is exactly how six of seven already-decided
  // rows went unnoticed. Distinct from "no verdict yet" (yourCall == null).
  final verdictUnreadable = yourCall != null && verdict == null;
  final links = _parseLinks(afterHeading);

  return DecisionReadResult(
    decision: Decision(
      number: number,
      title: title,
      date: date,
      status: status,
      supersedes: _supersedes(status) ?? links.supersedes,
      supersededBy: _supersededBy(status),
      why: why,
      decision: decisionText,
      whatWouldChangeThis: whatWouldChangeThis,
      sourceFile: sourceFile,
      verdict: verdict,
      verdictUnreadable: verdictUnreadable,
      links: links,
    ),
    rawText: text,
    sourceFile: sourceFile,
  );
}

/// Round 39 cp2 — `**Links:** Area: Sales · Serves: Objective 2 · Round:
/// 38 · Supersedes: 0005 · Scope: always`, in any order, any subset. A
/// segment with no `:` is ignored rather than guessed at; an unrecognised
/// key is ignored the same way, so a future key never becomes silent
/// corruption of an existing one.
final RegExp _objectiveInServes = RegExp(
  r'Objective\s*(\d+)',
  caseSensitive: false,
);

DecisionLinks _parseLinks(String afterHeading) {
  final raw = _inlineLabel(afterHeading, 'Links');
  if (raw == null) return DecisionLinks.none;

  String? area;
  String? objective;
  String? round;
  String? supersedes;
  var scopeAlways = false;

  // The line itself may end at the first real line break; a segment never
  // spans what `_inlineLabel` already cut off at the next field/heading.
  final firstLine = raw.split('\n').first;

  for (final part in firstLine.split('·')) {
    final segment = part.trim();
    if (segment.isEmpty) continue;
    final colon = segment.indexOf(':');
    if (colon == -1) continue;
    final key = segment.substring(0, colon).trim().toLowerCase();
    final value = segment.substring(colon + 1).trim();
    if (value.isEmpty) continue;

    switch (key) {
      case 'area':
        area = value;
      case 'serves':
        objective = _objectiveInServes.firstMatch(value)?.group(1) ?? value;
      case 'round':
        round = value;
      case 'supersedes':
        supersedes = value;
      case 'scope':
        if (value.toLowerCase() == 'always') scopeAlways = true;
    }
  }

  return DecisionLinks(
    area: area,
    objective: objective,
    round: round,
    supersedes: supersedes,
    scopeAlways: scopeAlways,
  );
}

/// Round 35/E — the date `## Your call — 2026-09-14` carries on its own
/// heading line, for a body below that doesn't repeat one (`**Accepted**,`
/// with nothing else date-shaped in it). Fence-aware, same as every other
/// heading search in this file, even though no real file has hidden one
/// inside a fence yet — a search that only works until the first exception
/// is not a search this codebase trusts (see the fenced-example test).
String? _yourCallHeadingDate(String text) {
  final heading = firstUnfencedMatch(
    RegExp(r'^#{2,3}\s*Your call\b.*$', multiLine: true, caseSensitive: false),
    text,
  );
  if (heading == null) return null;
  return RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(heading[0]!)?.group(0);
}

/// Reads a `## Your call` section's own verdict — ADR 0011's appended
/// shape, but real files have never agreed on exactly one punctuation
/// pattern. Accepts: `**Accepted** — 2026-09-07` (the original); the date
/// living *inside* the bold, with or without a reason continuing in the
/// same sentence (`**Accepted — 2026-09-14, with one amendment: ...**`);
/// a bare `**Accepted.**` or `**Accepted**,` with no date in the body at
/// all, relying on [headingDate]. Null only when the text does not start
/// with `**Accepted**`/`**Rejected**` in any of these shapes — a real
/// "can't read this" rather than a guess.
Verdict? _parseVerdict(String sectionText, {String? headingDate}) {
  final trimmedSection = sectionText.trim();
  final match = RegExp(
    r'^\*\*(Accepted|Rejected)\b(.*?)\*\*',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(trimmedSection);
  if (match == null) return null;

  final inner = match.group(2) ?? '';
  final rest = trimmedSection.substring(match.end);
  final combined = '$inner$rest'.trim();

  final date =
      RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(combined)?.group(0) ??
      headingDate ??
      'undated';

  var reason = combined
      .replaceFirst(RegExp(r'^[—-]?\s*\d{4}-\d{2}-\d{2}\s*'), '')
      .trim()
      .replaceFirst(RegExp(r'^[.,]\s*'), '')
      .trim();
  if (reason.isEmpty) reason = 'No reason given.';

  return Verdict(
    accepted: match.group(1)!.toLowerCase() == 'accepted',
    date: date,
    reason: reason,
  );
}

/// `# ADR 0004 — Title`, `## 0001 - Title`, or a heading with no number at
/// all — the number is optional, the title is not.
final RegExp _headingPattern = RegExp(
  r'^#{1,2}\s*(?:ADR\s+)?(?:(\d{3,5})\s*[-—]\s*)?(.+)$',
  multiLine: true,
);

/// Everything after `**Status:**`, with the surrounding `**` stripped if
/// the whole value was bolded — some files bold it
/// (`**accepted 2026-08-22**`), some do not.
String? _statusFrom(String text) {
  final value = _fieldValue(text, 'Status');
  return value == null ? null : _unbold(value);
}

/// Everything after `**Date:**`, cut off at the next `**Field:**` marker
/// when several share a line — this does not need to know which field
/// comes next, or whether it is separated by ` · ` or ` - `, only that
/// another bold label means the date's own value has ended.
String? _dateFrom(String text) => _fieldValue(text, 'Date');

/// The text after `**Label:**`, up to the next `**Other:**` marker on the
/// same line or the end of the line. Real header lines pack several
/// fields together — `Date`, `Status` and `Decided by` all on one line in
/// the real decision log this was checked against — and any of them may
/// come last.
String? _fieldValue(String text, String label) {
  final marker = RegExp('\\*\\*${RegExp.escape(label)}:\\*\\*');
  final lineMatch = RegExp(
    '^.*${marker.pattern}.*\$',
    multiLine: true,
  ).firstMatch(text);
  if (lineMatch == null) return null;

  final line = lineMatch.group(0)!;
  final markerMatch = marker.firstMatch(line)!;
  var value = line.substring(markerMatch.end);

  final nextMarker = RegExp(r'\*\*[A-Za-z][^*\n]*:\*\*').firstMatch(value);
  if (nextMarker != null) {
    value = value.substring(0, nextMarker.start);
  }

  final cleaned = value.trim().replaceAll(RegExp(r'[\s·-]+$'), '').trim();
  return cleaned.isEmpty ? null : cleaned;
}

String _unbold(String value) {
  if (value.length >= 4 && value.startsWith('**') && value.endsWith('**')) {
    return value.substring(2, value.length - 2);
  }
  return value;
}

String? _supersededBy(String? status) {
  if (status == null) return null;
  final match = RegExp(
    r'superseded by (\d+)',
    caseSensitive: false,
  ).firstMatch(status);
  return match?.group(1);
}

String? _supersedes(String? status) {
  if (status == null) return null;
  final match = RegExp(
    r'\bsupersedes (\d+)',
    caseSensitive: false,
  ).firstMatch(status);
  return match?.group(1);
}

/// A named section: either a `## Heading` on its own line, running to the
/// next heading or `---`, or a `**Heading:**` paragraph in a log, running
/// to the next blank-line-separated bold label, heading, or `---`.
///
/// Tried as a heading first because it is the more structured of the two
/// real shapes; falls back to the inline label because that is the only
/// shape a decisions log uses.
String? _section(String text, String heading) {
  return sectionText(text, heading) ?? _inlineLabel(text, heading);
}

/// Same as [_section], but tolerates a trailing qualifier on the heading
/// line — see [sectionTextByPrefix] for why `Decision` needs this and
/// `Why` deliberately does not.
String? _sectionByPrefix(String text, String heading) {
  return sectionTextByPrefix(text, heading) ?? _inlineLabel(text, heading);
}

String? _inlineLabel(String text, String label) {
  final pattern = RegExp(
    '\\*\\*${RegExp.escape(label)}:\\*\\*\\s*',
    caseSensitive: false,
  );
  final match = firstUnfencedMatch(pattern, text);
  if (match == null) return null;

  final rest = text.substring(match.end);
  final next = firstUnfencedMatch(
    RegExp(r'\n\s*\n\s*(?:\*\*[^*\n]+:\*\*|#{1,6}\s|---\s*$)', multiLine: true),
    rest,
  );

  final end = next?.start ?? rest.length;
  return rest.substring(0, end).trim();
}

String _firstParagraph(String sectionText) {
  final blankLine = sectionText.indexOf('\n\n');
  final paragraph = blankLine == -1
      ? sectionText
      : sectionText.substring(0, blankLine);
  return paragraph.trim();
}
