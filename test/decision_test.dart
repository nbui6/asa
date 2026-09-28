// Tests for the decision parser, against real files.
//
// Every fixture below is copied verbatim (trimmed to the parts that matter)
// from a real file in one of two projects: this one's `decisions/` folder,
// and a second project that keeps a single `decisions.md` log. The projects
// are named in the round note outside this repository - project material
// does not belong in source. Rule 8 — test against the real contract, not
// an invented one.
//
// WHAT IS REAL HERE AND WHAT IS NOT, because the difference matters:
//
// The STRUCTURE of every fixture is verbatim - the plain hyphen after the
// number, a header line packing Date, Status and Decided by together, the
// inline **Decision:** / **Why:** / **What would change this:** labels, the
// trailing **Update yyyy-mm-dd:** block, a quoted sentence followed by more
// prose. Those quirks are what broke the first implementation, and they are
// what rule 8 exists for.
//
// The PROSE has been replaced with neutral sentences. The real ones were
// internal business decisions, and no assertion here depends on their
// meaning. Test against the real SHAPE, never the real CONTENT. Where a
// real file disagreed with the contract as first written, the file won;
// see the notes on each test.

import 'package:asa/core/decision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the heading', () {
    test('reads an ADR file heading with an em dash — asa/0001', () {
      final result = parseDecision(
        '# ADR 0001 — Start in Obsidian; build an app only for what '
            'Obsidian cannot do\n\n**Date:** 2026-08-22 · **Status:** '
            '**accepted 2026-08-22**\n',
        '0001.md',
      );
      expect(result.isSuccess, isTrue);
      expect(result.decision!.number, '0001');
      expect(
        result.decision!.title,
        'Start in Obsidian; build an app only for what Obsidian cannot do',
      );
    });

    test('reads a log heading with a plain hyphen — real log 0001', () {
      final result = parseDecision(
        '## 0001 - The first option, not the second\n\n'
            '**Date:** 2026-09-01 - **Status:** accepted - **Decided by:** '
            'Nico\n',
        'decisions.md',
      );
      expect(result.decision!.number, '0001');
      expect(result.decision!.title, 'The first option, not the second');
    });

    test('accepts a title with no number at all', () {
      final result = parseDecision('# Just a title, no ADR number\n', 'x.md');
      expect(result.decision!.number, isNull);
      expect(result.decision!.title, 'Just a title, no ADR number');
    });

    test('Round 35/D — a title with real markdown emphasis strips it, same '
        'as every other markdown-sourced text in the app', () {
      final result = parseDecision(
        '## 0001 - **The Plan tab as the areas of a project** — goal '
            'from `plan\\*.md`\n\n**Date:** 2026-09-26 - **Status:** accepted\n',
        'decisions.md',
      );
      expect(
        result.decision!.title,
        r'The Plan tab as the areas of a project — goal from plan\*.md',
      );
    });

    test('an unheaded file is unreadable, not silently skipped', () {
      final result = parseDecision('Just some prose, no heading.', 'bad.md');
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
      expect(result.rawText, 'Just some prose, no heading.');
      expect(result.sourceFile, 'bad.md');
    });

    test('an empty file is unreadable', () {
      final result = parseDecision('', 'empty.md');
      expect(result.isSuccess, isFalse);
    });
  });

  group('date and status sharing a line', () {
    test('separated by " · ", status value bolded — asa/0001', () {
      final result = parseDecision(
        '# ADR 0001 — Title\n\n'
            '**Date:** 2026-08-22 · **Status:** **accepted 2026-08-22**\n',
        '0001.md',
      );
      expect(result.decision!.date, '2026-08-22');
      expect(result.decision!.status, 'accepted 2026-08-22');
    });

    test('separated by " - ", status value plain — asa/0007', () {
      final result = parseDecision(
        '# ADR 0007 - Title\n\n'
            "**Date:** 2026-09-01 - **Status:** proposed - needs Nico's "
            'decision\n',
        '0007.md',
      );
      expect(result.decision!.date, '2026-09-01');
      expect(result.decision!.status, "proposed - needs Nico's decision");
    });

    test('status value unbolded, no separator around it — asa/0006', () {
      final result = parseDecision(
        '# ADR 0006 — Title\n\n**Date:** 2026-09-01 · **Status:** accepted '
            '2026-09-01\n',
        '0006.md',
      );
      expect(result.decision!.date, '2026-09-01');
      expect(result.decision!.status, 'accepted 2026-09-01');
    });

    test('a log line that also carries Decided by — real log 0001', () {
      final result = parseDecision(
        '## 0001 - Title\n\n**Date:** 2026-09-01 - **Status:** accepted - '
            '**Decided by:** Nico\n',
        'decisions.md',
      );
      expect(result.decision!.date, '2026-09-01');
      expect(result.decision!.status, 'accepted');
    });
  });

  group('supersession, parsed out of the status text', () {
    test('superseded by — real log 0005', () {
      final result = parseDecision(
        '## 0005 - The earlier approach\n\n**Date:** '
            '2026-09-01 - **Status:** superseded by 0008 - **Decided by:** '
            'Nico\n',
        'decisions.md',
      );
      expect(result.decision!.supersededBy, '0008');
      expect(result.decision!.supersedes, isNull);
    });

    test('accepted (supersedes N) — real log 0008', () {
      final result = parseDecision(
        '## 0008 - Reuse what is already there\n\n**Date:** '
            '2026-09-01 - **Status:** accepted (supersedes 0005) - '
            '**Decided by:** Nico\n',
        'decisions.md',
      );
      expect(result.decision!.supersedes, '0005');
      expect(result.decision!.supersededBy, isNull);
    });
  });

  group('why — verbatim first paragraph, never a summary', () {
    test('an exact ## Why heading — asa/0001', () {
      final result = parseDecision(
        '# ADR 0001 — Title\n\n**Date:** 2026-08-22 · **Status:** accepted'
            '\n\n## Decision\n\nSomething.\n\n## Why\n\n**The two things '
            'Obsidian cannot do are exactly the two things the roadmap '
            'ranked highest.** That is not a coincidence.\n\nThe staged '
            "route follows the kit's own rules rather than contradicting "
            'them.\n\n## Consequences\n\nMore text.\n',
        '0001.md',
      );
      expect(
        result.decision!.why,
        '**The two things Obsidian cannot do are exactly the two things '
        'the roadmap ranked highest.** That is not a coincidence.',
      );
    });

    test('a heading named "Why ..." rather than "Why" is not the Why section '
        '— asa/0003 has no exact ## Why', () {
      final result = parseDecision(
        '# ADR 0003 — Title\n\n**Date:** 2026-08-25 · **Status:** '
            'accepted\n\n## Decision\n\nAsa has an Explain mode.\n\n'
            '## Why the toggle is off by default\n\nThree reasons.\n',
        '0003.md',
      );
      expect(result.decision!.why, isEmpty);
    });

    test('an inline **Why:** paragraph in a log — real log 0001', () {
      final result = parseDecision(
        '## 0001 - The first option, not the second\n\n'
            '**Date:** 2026-09-01 - **Status:** accepted - **Decided by:** '
            'Nico\n\n**Decision:** The first option is used '
            'everywhere.\n\n**Why:** "It already works this way." '
            'Confirmed in practice.\n\n**Update '
            '2026-09-01:** Confirmed nothing else depends on it.'
            '\n',
        'decisions.md',
      );
      expect(
        result.decision!.why,
        '"It already works this way." Confirmed in practice.',
      );
    });
  });

  group('decision — falls back rather than crashing', () {
    test('## Recommendation stands in for ## Decision — asa/0005', () {
      final result = parseDecision(
        '# ADR 0005 — The stack, reopened\n\n**Date:** 2026-09-01 · '
            '**Status:** proposed\n\n## Recommendation\n\n**Stay with '
            'Flutter (A)** — and set a decision point rather than closing '
            'the question.\n\n## What would change this\n\nSomething.\n',
        '0005.md',
      );
      expect(
        result.decision!.decision,
        '**Stay with Flutter (A)** — and set a decision point rather than '
        'closing the question.',
      );
    });

    test('missing entirely falls back to the title — asa/0006', () {
      final result = parseDecision(
        '# ADR 0006 — One workspace root: asa / projects / workshop\n\n'
            '**Date:** 2026-09-01 · **Status:** accepted\n\n## Context\n\n'
            'Some context, no Decision or Recommendation heading at all.\n',
        '0006.md',
      );
      expect(
        result.decision!.decision,
        'One workspace root: asa / projects / workshop',
      );
    });

    test('a trailing qualifier on the Decision heading does not fall back to '
        'the title — the real bug found on ADR 0012: "## Decision — proposed, '
        'three parts, in this order"', () {
      final result = parseDecision(
        '# ADR 0012 — What Asa is: the missing piece is a doorman\n\n'
            '**Date:** 2026-09-07 · **Status:** proposed\n\n'
            '## Decision — proposed, three parts, in this order\n\n'
            '**1. Build the doorman.**\n\n'
            '## What this does NOT decide\n\nSomething else.\n',
        '0012.md',
      );
      expect(result.decision!.decision, contains('Build the doorman'));
      expect(
        result.decision!.decision,
        isNot(contains('What Asa is')),
        reason: 'must read the real section, not fall back to the title',
      );
    });
  });

  group('what would change this', () {
    test('a heading section with a bulleted list — asa/0002', () {
      final result = parseDecision(
        '# ADR 0002 — Title\n\n**Date:** 2026-08-24 · **Status:** accepted'
            '\n\n## Decision\n\nSomething.\n\n## What would change this\n\n'
            '- If Asa is ever found editing roadmap content, this decision '
            'has been misread.\n- If the two-week test comes back '
            "negative, Asa's existence is the question.\n",
        '0002.md',
      );
      expect(
        result.decision!.whatWouldChangeThis,
        '- If Asa is ever found editing roadmap content, this decision has '
        'been misread.\n- If the two-week test comes back negative, '
        "Asa's existence is the question.",
      );
    });

    test('absent is valid, and stays empty — asa/0004 has none', () {
      final result = parseDecision(
        '# ADR 0004 — Title\n\n**Date:** 2026-08-31 · **Status:** '
            'accepted\n\n## Decision\n\nSomething.\n\n## Consequences\n\n'
            'More text, and no What would change this section.\n',
        '0004.md',
      );
      expect(result.decision!.whatWouldChangeThis, isEmpty);
    });

    test('an inline label in a log, stopping before the next entry', () {
      final result = parseDecision(
        '## 0008 - Title\n\n**Date:** 2026-09-01 - **Status:** accepted '
            '(supersedes 0005) - **Decided by:** Nico\n\n**Decision:** '
            'The existing field is reused.\n\n**Why:** Simpler '
            'than adding something new.\n\n**What would change this:** '
            'A later project may collide with this.\n',
        'decisions.md',
      );
      expect(
        result.decision!.whatWouldChangeThis,
        'A later project may collide with this.',
      );
    });
  });

  test('the source file is carried through on both success and failure', () {
    final ok = parseDecision('# ADR 0001 — Title\n', r'C:\proj\0001.md');
    expect(ok.sourceFile, r'C:\proj\0001.md');

    final bad = parseDecision('no heading', r'C:\proj\bad.md');
    expect(bad.sourceFile, r'C:\proj\bad.md');
  });

  group('isProposed — the one status signal groupForReview reuses', () {
    test('true for a plain "proposed" status', () {
      final result = parseDecision(
        '# ADR 0005 — Title\n\n**Date:** 2026-09-01 · **Status:** proposed\n',
        '0005.md',
      );
      expect(result.decision!.isProposed, isTrue);
    });

    test('true for status text longer than the one word — real shape', () {
      final result = parseDecision(
        '# ADR 0007 - Title\n\n**Date:** 2026-09-01 - **Status:** proposed '
            "- needs Nico's decision\n",
        '0007.md',
      );
      expect(result.decision!.isProposed, isTrue);
    });

    test('false for accepted', () {
      final result = parseDecision(
        '# ADR 0001 — Title\n\n**Date:** 2026-08-22 · **Status:** accepted\n',
        '0001.md',
      );
      expect(result.decision!.isProposed, isFalse);
    });

    test('false for superseded by — not proposed, even though it is a '
        'kind of open question', () {
      final result = parseDecision(
        '## 0005 - Title\n\n**Date:** 2026-09-01 - **Status:** superseded '
            'by 0008\n',
        'decisions.md',
      );
      expect(result.decision!.isProposed, isFalse);
    });

    test('false when there is no status at all', () {
      final result = parseDecision('# ADR 0001 — Title\n', '0001.md');
      expect(result.decision!.isProposed, isFalse);
    });
  });

  group('verdict — ADR 0011\'s appended "## Your call" section', () {
    test('a "## Your call" example inside a fenced code block is not read as '
        'a real verdict — the actual bug found using this feature on '
        "ADR 0011's own file, which documents its own shape this way", () {
      final result = parseDecision(
        '# ADR 0011 - Title\n\n**Date:** 2026-09-07 · **Status:** '
            'accepted\n\n## Decision\n\nShape, always appended:\n\n'
            '```\n## Your call\n\n**Accepted** — 2026-09-07\n\n'
            '<the typed reason, verbatim, or "No reason given." if left '
            'empty>\n```\n\n`**Rejected**` for the other verdict.\n',
        '0011.md',
      );
      expect(result.decision!.verdict, isNull);
      expect(
        result.decision!.decision,
        contains('## Your call'),
        reason: 'the example must still read as ordinary Decision text',
      );
    });

    test('an accepted verdict is parsed, and overrides isProposed', () {
      final result = parseDecision(
        '# ADR 0005 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'proposed\n\n## Your call\n\n**Accepted** — 2026-09-07\n\n'
            'Windows was always the real target.\n',
        '0005.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-07');
      expect(verdict.reason, 'Windows was always the real target.');
      expect(result.decision!.isProposed, isFalse);
    });

    test('a rejected verdict is parsed', () {
      final result = parseDecision(
        '# ADR 0005 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'proposed\n\n## Your call\n\n**Rejected** — 2026-09-07\n\n'
            'No reason given.\n',
        '0005.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isFalse);
      expect(verdict.reason, 'No reason given.');
    });

    test('no ## Your call section leaves verdict null', () {
      final result = parseDecision(
        '# ADR 0005 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'proposed\n',
        '0005.md',
      );
      expect(result.decision!.verdict, isNull);
      expect(result.decision!.isProposed, isTrue);
    });

    test('displayStatus shows the header status when there is no verdict', () {
      final result = parseDecision(
        '# ADR 0001 — Title\n\n**Date:** 2026-08-22 · **Status:** accepted\n',
        '0001.md',
      );
      expect(result.decision!.displayStatus, 'accepted');
    });

    test('displayStatus shows the verdict, not the stale proposed header — '
        'ADR 0011: the header is never corrected', () {
      final result = parseDecision(
        '# ADR 0005 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'proposed\n\n## Your call\n\n**Accepted** — 2026-09-07\n\n'
            'A reason.\n',
        '0005.md',
      );
      expect(result.decision!.status, 'proposed');
      expect(result.decision!.displayStatus, 'accepted');
    });
  });

  group('Round 35/E — real "## Your call" shapes, exact first lines of '
      "asa's own ADRs 0008, 0021, 0024, 0025 and 0026 (product decisions, "
      'no work content)', () {
    test('0008 — the date and the whole reason live inside the bold, '
        'heading carries no date of its own', () {
      final result = parseDecision(
        '# ADR 0008 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'accepted\n\n## Your call\n\n**Accepted — 2026-09-14, with one '
            'amendment: typed links are the exception, not the default.**'
            '\n\nMore prose below.\n',
        '0008.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-14');
      expect(result.decision!.isProposed, isFalse);
      expect(result.decision!.verdictUnreadable, isFalse);
    });

    test('0021 — date inside the bold, a period closing it, the real '
        'reason in the paragraph after', () {
      final result = parseDecision(
        '# ADR 0021 - Title\n\n**Date:** 2026-09-14 · **Status:** '
            'accepted\n\n## Your call\n\n**Accepted — 2026-09-14.** Nico '
            'said so.\n',
        '0021.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-14');
    });

    test('0024 — heading carries the date, body is a bare **Accepted**,', () {
      final result = parseDecision(
        '# ADR 0024 - Title\n\n**Date:** 2026-09-14 · **Status:** '
            'accepted\n\n## Your call — 2026-09-26\n\n**Accepted**, with '
            'the revision.\n',
        '0024.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-26');
    });

    test('0025 — heading carries the date, body is **Accepted.** with '
        'the period inside the bold', () {
      final result = parseDecision(
        '# ADR 0025 - Title\n\n**Date:** 2026-09-14 · **Status:** '
            'accepted\n\n## Your call — 2026-09-14\n\n**Accepted.** '
            'Substantial confirmation was already on the record.\n',
        '0025.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-14');
    });

    test('0026 — heading carries the date, body is a bare **Accepted**, '
        'comma straight after', () {
      final result = parseDecision(
        '# ADR 0026 - Title\n\n**Date:** 2026-09-14 · **Status:** '
            'accepted\n\n## Your call — 2026-09-14\n\n**Accepted**, '
            'including the one thing left open above.\n',
        '0026.md',
      );
      final verdict = result.decision!.verdict!;
      expect(verdict.accepted, isTrue);
      expect(verdict.date, '2026-09-14');
    });

    test('no date anywhere at all reads as "undated", never a crash', () {
      final result = parseDecision(
        '# ADR 0099 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'accepted\n\n## Your call\n\n**Accepted**, no date anywhere.\n',
        '0099.md',
      );
      expect(result.decision!.verdict!.date, 'undated');
    });

    test('a "## Your call" section that exists but matches none of the '
        'known shapes reads as "verdict unreadable", never silently '
        '"proposed"', () {
      final result = parseDecision(
        '# ADR 0100 - Title\n\n**Date:** 2026-09-01 · **Status:** '
            'proposed\n\n## Your call\n\nSomeone typed a decision here '
            'without ever writing Accepted or Rejected.\n',
        '0100.md',
      );
      expect(result.decision!.verdict, isNull);
      expect(result.decision!.verdictUnreadable, isTrue);
      expect(result.decision!.displayStatus, 'verdict unreadable');
      expect(
        result.decision!.isProposed,
        isTrue,
        reason: 'still needs a look, just not for the header-word reason',
      );
    });
  });

  group('Round 39 cp2 — the **Links:** line', () {
    test("reads area, objective, round and supersedes, in the manual's own "
        'worked example', () {
      final result = parseDecision(
        '# ADR 0009 - Title\n\n**Date:** 2026-09-28 · **Status:** '
            'accepted\n**Links:** Area: Sales · Serves: Objective 2 · '
            'Round: 38 · Supersedes: 0005\n\n## Decision\nSomething.\n',
        '0009.md',
      );
      final links = result.decision!.links;
      expect(links.area, 'Sales');
      expect(links.objective, '2');
      expect(links.round, '38');
      expect(links.supersedes, '0005');
      expect(links.scopeAlways, isFalse);
    });

    test('Scope: always is read as a bool, not a string to compare later', () {
      final result = parseDecision(
        '# ADR 0012 - Title\n\n**Status:** accepted\n**Links:** Scope: '
            'always\n\n## Decision\nSomething.\n',
        '0012.md',
      );
      expect(result.decision!.links.scopeAlways, isTrue);
      expect(result.decision!.links.area, isNull);
    });

    test('a decision with no Links line reads as DecisionLinks.none, and '
        'keeps working everywhere else', () {
      final result = parseDecision(
        '# ADR 0001 - Title\n\n**Status:** accepted\n\n## Decision\n'
            'Something.\n',
        '0001.md',
      );
      expect(result.decision!.links, same(DecisionLinks.none));
      expect(result.decision!.links.area, isNull);
    });

    test("a subset of fields is fine - leaving one out means it doesn't "
        'apply, not a parse failure', () {
      final result = parseDecision(
        '# ADR 0010 - Title\n\n**Status:** accepted\n**Links:** Area: '
            'Finance\n\n## Decision\nSomething.\n',
        '0010.md',
      );
      final links = result.decision!.links;
      expect(links.area, 'Finance');
      expect(links.objective, isNull);
      expect(links.round, isNull);
      expect(links.supersedes, isNull);
    });

    test('Supersedes: on the Links line merges into the same supersedes '
        'field the status text already fills, never a second field to '
        'check', () {
      // Status text names no supersession at all - only the Links line
      // does, and Decision.supersedes still reads it.
      final result = parseDecision(
        '# ADR 0011 - Title\n\n**Status:** accepted\n**Links:** '
            'Supersedes: 0005\n\n## Decision\nSomething.\n',
        '0011.md',
      );
      expect(result.decision!.supersedes, '0005');
    });

    test('the status text\'s own "supersedes NNNN" still wins when both '
        'are somehow present, since it was read first', () {
      final result = parseDecision(
        '# ADR 0013 - Title\n\n**Status:** accepted (supersedes 0003)\n'
            '**Links:** Supersedes: 0005\n\n## Decision\nSomething.\n',
        '0013.md',
      );
      expect(result.decision!.supersedes, '0003');
    });

    test('"Serves: Objective 2" extracts the bare number, the same shape '
        "area.dart's own objectiveNumbers already uses", () {
      final result = parseDecision(
        '# ADR 0014 - Title\n\n**Status:** accepted\n**Links:** Serves: '
            'Objective 2\n\n## Decision\nSomething.\n',
        '0014.md',
      );
      expect(result.decision!.links.objective, '2');
    });
  });
}
