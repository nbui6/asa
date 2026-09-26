/// A project's plan, read as data — ADR 0021 (a plan is a folder of
/// pages, `PLAN.md` its front page) and ADR 0022 (the plan holds the
/// present only; history goes to `PLAN-ARCHIVE.md`, never here).
///
/// **Read-only, and that is the whole point of this file existing rather
/// than growing an existing one.** Asa shows and links a plan; it never
/// writes a word of one — ADR 0021 point 4, hard rule 13. Nothing in this
/// file, or in anything that calls it, may write to `PLAN.md`,
/// `CHARTER.md`, or any `plan\*.md`.
///
/// Round 26's own scope line: `core/` only, no screen, no writes, no new
/// frontmatter field on any file, anywhere. Cross-project backlinks are
/// not this round.
library;

import 'dart:io';

import 'package:asa/core/markdown.dart';

/// A project's whole plan. [pages] is empty when the project has neither
/// `PLAN.md` nor a `plan\` folder — **no plan at all**, distinct from a
/// plan whose one page happens to be empty (that project still has one
/// [PlanPage], just with no sections and no links).
class Plan {
  const Plan({required this.pages});

  final List<PlanPage> pages;

  bool get isEmpty => pages.isEmpty;
}

/// One page of a plan — `PLAN.md` itself (the front page, [aspect] null),
/// or one file under `plan\` (keyed by its filename stem — ADR 0021's
/// 2026-09-14 revision, "answered the same day: a plan page is keyed to a
/// named aspect").
class PlanPage {
  const PlanPage({
    required this.aspect,
    required this.sourceFile,
    required this.sections,
    required this.links,
  });

  /// The filename stem (`budget.md` → `budget`) for a page under `plan\`;
  /// null for the front page, `PLAN.md`.
  final String? aspect;

  /// Where this page was read from, so a caller can say where a value
  /// came from and open it in the OS editor — same reasoning as
  /// `Project.sourceFile`.
  final String sourceFile;

  /// This page's own headings, in file order — see [parseSections]. Empty
  /// when the page has no heading at all, not an error.
  final List<Section> sections;

  /// Every reference this page makes to another page, a project, an ADR,
  /// or a Round — see [deriveLinks]. Empty when the page makes none, not
  /// an error and not null.
  final List<PlanLink> links;
}

/// What a [PlanLink] points at. Only [wikilink] targets another page in
/// this same plan — an [adr], [round] or [objective] link points outside
/// the plan entirely, at `decisions\`, a Round, or `CHARTER.md`'s own
/// `## Objectives`, so none of them participate in [pagesLinkingTo].
enum PlanLinkKind { wikilink, adr, round, objective }

/// One reference a plan page makes, derived from its own text — never
/// typed, never maintained (ADR 0008's 2026-09-14 amendment: "derived by
/// default"). Carries the sentence it sits in, not just the target — ADR
/// 0021's revision #2: "a derived link is rendered as the sentence it came
/// from, never as a bare 'related' row." A [PlanLink] with no context
/// sentence has not met that spec.
class PlanLink {
  const PlanLink({
    required this.kind,
    required this.target,
    required this.sentence,
  });

  final PlanLinkKind kind;

  /// A `[[wikilink]]`'s inner text, an ADR's four-digit number (the word
  /// form, the bare filename, and the `decisions\` path form all resolve
  /// to the same number — "match the number," per the round's own spec),
  /// or a Round's bare number.
  final String target;

  /// The sentence this reference sits in, verbatim.
  final String sentence;
}

/// Reads [projectFolder]'s plan: `PLAN.md`, if present, then every
/// `plan\*.md` beside it, if that folder exists. A project with neither
/// has no plan at all — [Plan.isEmpty], not an error and not a page
/// invented to hold nothing.
Future<Plan> readPlan(String projectFolder) async {
  final pages = <PlanPage>[];

  final frontPage = File('$projectFolder${Platform.pathSeparator}PLAN.md');
  if (frontPage.existsSync()) {
    pages.add(await _readPage(aspect: null, file: frontPage));
  }

  final planDir = Directory('$projectFolder${Platform.pathSeparator}plan');
  if (planDir.existsSync()) {
    final files = <File>[];
    await for (final entry in planDir.list(followLinks: false)) {
      if (entry is File && entry.path.toLowerCase().endsWith('.md')) {
        files.add(entry);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      pages.add(await _readPage(aspect: _stemOf(file.path), file: file));
    }
  }

  return Plan(pages: pages);
}

Future<PlanPage> _readPage({
  required String? aspect,
  required File file,
}) async {
  final contents = await file.readAsString();
  return PlanPage(
    aspect: aspect,
    sourceFile: file.path,
    sections: parseSections(contents),
    links: deriveLinks(contents),
  );
}

String _stemOf(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}

final RegExp _wikilink = RegExp(r'\[\[([^\]]+)\]\]');
final RegExp _adrWord = RegExp(r'ADR\s*(\d{4})', caseSensitive: false);

// A 4-digit ADR number at the *start* of a `.md` basename — the filename
// and `decisions\`/`decisions/` path forms both end in exactly this shape.
// The boundary before the digits must not be a letter, digit or hyphen, or
// this matches the date buried inside an unrelated filename — found while
// building this round: `RESEARCH-PLANNING-LAYER-2026-09-14.md` contains
// "2026-09-14.md", which looks identical to an ADR filename unless the
// character before the digits is checked.
final RegExp _adrFile = RegExp(
  r'(?:^|[\s`(/\\])(\d{4})-[a-z0-9-]+\.md',
  caseSensitive: false,
);
final RegExp _round = RegExp(r'Round\s*(\d+)', caseSensitive: false);
final RegExp _objective = RegExp(r'Objective\s*(\d+)', caseSensitive: false);

/// Every reference [pageText] makes — a `[[wikilink]]`, an ADR (matched by
/// number, however it is written), or a Round — each with the sentence it
/// sits in. Fenced code examples are excluded first, same reasoning as
/// `markdown.dart`'s own library note: a shape shown as an example is not
/// a real reference.
List<PlanLink> deriveLinks(String pageText) {
  final links = <PlanLink>[];

  for (final sentence in _sentences(withoutFencedBlocks(pageText))) {
    for (final match in _wikilink.allMatches(sentence)) {
      links.add(
        PlanLink(
          kind: PlanLinkKind.wikilink,
          target: match.group(1)!.trim(),
          sentence: sentence,
        ),
      );
    }
    for (final match in _adrWord.allMatches(sentence)) {
      links.add(
        PlanLink(
          kind: PlanLinkKind.adr,
          target: match.group(1)!,
          sentence: sentence,
        ),
      );
    }
    for (final match in _adrFile.allMatches(sentence)) {
      links.add(
        PlanLink(
          kind: PlanLinkKind.adr,
          target: match.group(1)!,
          sentence: sentence,
        ),
      );
    }
    for (final match in _round.allMatches(sentence)) {
      links.add(
        PlanLink(
          kind: PlanLinkKind.round,
          target: match.group(1)!,
          sentence: sentence,
        ),
      );
    }
    for (final match in _objective.allMatches(sentence)) {
      links.add(
        PlanLink(
          kind: PlanLinkKind.objective,
          target: match.group(1)!,
          sentence: sentence,
        ),
      );
    }
  }
  return links;
}

/// A naive sentence split, good enough for engineering prose: heading
/// lines are dropped (a heading names a section, it is not itself a
/// sentence to link from), the remaining lines are joined so a sentence
/// wrapped across lines is not cut in half, then split on `.`/`!`/`?`.
///
/// **Inline code spans are masked first.** Found while building this
/// round: an ADR's filename form (`` `0007-asa-writes-fields.md` ``) has
/// its own period, right before "md", and a naive split reads that as a
/// sentence ending — cutting the very reference this round exists to
/// find in half. Every real occurrence of a filename in this project's
/// prose is backtick-wrapped, so masking a `` `code span` `` before
/// splitting and restoring it after is enough; it is not a general
/// sentence-boundary detector and does not try to be one.
List<String> _sentences(String text) {
  final codeSpans = <String>[];
  final masked = text.replaceAllMapped(RegExp('`[^`\n]+`'), (match) {
    codeSpans.add(match.group(0)!);
    return ' ${codeSpans.length - 1} ';
  });

  final joined = masked
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .join(' ');

  final sentences = <String>[];
  for (final match in RegExp('[^.!?]+[.!?]*').allMatches(joined)) {
    final sentence = match.group(0)!.trim();
    if (sentence.isEmpty) continue;
    sentences.add(
      sentence.replaceAllMapped(
        RegExp(' ([0-9]+) '),
        (m) => codeSpans[int.parse(m.group(1)!)],
      ),
    );
  }
  return sentences;
}

/// The reverse of [PlanPage.links]: every page in [plan] that names
/// [target] with a `[[wikilink]]` — an ADR or Round link never counts,
/// since neither points at a page in this plan. Scans only [plan]'s own
/// pages; cross-project backlinks are not this round.
List<PlanPage> pagesLinkingTo(Plan plan, PlanPage target) {
  final name = target.aspect;
  if (name == null) return const [];

  return [
    for (final page in plan.pages)
      if (!identical(page, target) &&
          page.links.any(
            (link) =>
                link.kind == PlanLinkKind.wikilink &&
                link.target.toLowerCase() == name.toLowerCase(),
          ))
        page,
  ];
}
