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
}
