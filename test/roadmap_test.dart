// Fixtures below are the real ## Roadmap sections, copied verbatim, from
// the two real project notes that carry one today: asa.md and
// partner-trial-process.md. Rule 8 — test the real contract, not an
// invented one.

import 'package:asa/core/roadmap.dart';
import 'package:flutter_test/flutter_test.dart';

const _asaRoadmap = r'''
## Roadmap

**Unit: Round** — same word Code already uses in its own commit messages (`Round 0`, `Round 1`,
`Round 2`, real `git log`). **Unit: Version** — reserved only for a Round actually pushed to
GitHub for someone else to test (`origin` is `github.com/nbui6/asa`). Not every Round becomes a
Version; Rounds 3, 4, 6, 8 below are internal work with nothing (yet) pushed for outside testing.
**A Round's number is permanent once given, built or not** — Rounds 0–4 kept their identity when
`v0.1` work jumped ahead of them on 2026-09-01, and that rule continues here rather than getting
renumbered.

**The big goal right now: make Asa a place you can trust before you act on what it shows you** —
Round 6 below, "Foundation."

- [x] **Round 0 — the shell** — shipped `2026-08-24` (`12ea498`)
- [x] **Round 1 — one project's state** — shipped `2026-08-24` (`9b9ee26`)
- [ ] **Round 2 — every project on one screen (Home)** — code shipped `2026-08-24` (`0fd717c`); the
  visual rebuild against the signed sketch (`asa-front2`) is still open
- [ ] **Round 3 — the handoff** — not built (open in VS Code, opener copied to clipboard)
- [ ] **Round 4 — the stage, measured not typed** — not built · **&rarr; Version v0.2 once pushed**
  · full spec: `rounds\round-4.md`
- [x] **Round 5 — decisions become findable** — shipped &amp; pushed `2026-09-07`/`08` · **Version
  v0.1** · full record: `rounds\v0.1-decisions.md`
  - [x] Accept/reject flow (ADR 0011)
  - [x] Front-page Tasks view
- [ ] **Round 6 — Foundation: the record can be trusted before anyone acts on it** — in progress,
  internal, no version planned
  - [x] ADR 0012 decided — the doorman built as its own kit skill, not an extension of chief-of-staff
  - [x] Reachability decided — closed by ADR 0013, laptop-only, Gate 2 upheld
  - [ ] The doorman fires unprompted in a fresh conversation and catches one real stale thing (ADR 0012's own "done when" bar)
  - [ ] Surfaces retired into the door — `HOME.md` fixed; `HANDOVER.md`'s split still open;
    `PROCESS-PROJECT-SHAPE-2026-09-01.md` and `RETRO-2026-09-01.md` still unfiled (two of the
    original five 2026-09-01 analyses; three others already point back in from elsewhere)
  - [ ] Home matches the signed sketch, the five UI items built, the exe rebuilt and confirmed
- [ ] **Round 7 — the seam for a second developer** — not started · **&rarr; Version v0.1.1 once
  pushed**
  - [ ] `Project.extra` keeps her frontmatter keys
  - [ ] `lib/local/` — a seam upstream never writes in again
  - [ ] `FOR-YOUR-FORK.md` marked shipped, with the commit hash
- [ ] **Round 8 — quick capture: the inbox, drag to assign** — not started, per ADR 0014's
  2026-09-08 addendum
- [ ] **Round 9 — the everyday features** — not started · **&rarr; Version v0.3–v0.7**
  - [ ] Parked items, and the rule of two
  - [ ] The process view, derived from the folder
  - [ ] Project relations — parent/child, "shared with"
  - [ ] Tabs that appear with their content
  - [ ] Priority and deadlines
- [ ] **Round 10 — the HR tab: skills and agents as staff** — not started · **&rarr; Version v0.8**
  (this session's "Asa HR")
  - [ ] The registry — kind, how it fires, who uses it, last fired
  - [ ] "About Asa" split into kit / this build / workshop
- [ ] **Round 11 — packaged for install without a Flutter toolchain** — not started, gated on Gate 1
  · **&rarr; Version v1.0**

## Tasks

- [x] Show Nico the accept/reject fix, get a yes
''';

const _partnerTrialRoadmap = '''
## Roadmap

**Converted from the "Build order" section below, per ADR 0014** — same eight steps, as
milestones. Full detail (fields, values, why) stays down there; not repeated here.

- [ ] Create the License object — name, License Name as display property, no unique identifier
- [ ] Create the License properties
- [ ] Create the two association label pairs
- [ ] Add the two Organisation properties and fill them per partner
- [ ] Add Engagement Type to Project and create the Partner pipeline
- [ ] Build the first partner's form — one only, to test end to end
- [ ] Build the workflow — form &rarr; License &rarr; associations &rarr; both emails &rarr; Retention Status
- [ ] Test one real referral through end to end, with no manual email

## Tasks

- [ ] Test forms
''';

void main() {
  group(
    'parseRoadmap — asa.md, the real fixture with bold titles and nesting',
    () {
      final milestones = parseRoadmap(_asaRoadmap);

      test('reads all twelve real milestones, in file order', () {
        expect(milestones, hasLength(12));
        expect(milestones.first.title, 'Round 0 — the shell');
        expect(milestones.last.title, contains('Round 11'));
      });

      test('a bold-wrapped title is extracted, trailing detail text after '
          'the bold span is discarded', () {
        expect(milestones[0].title, 'Round 0 — the shell');
        expect(milestones[0].title, isNot(contains('shipped')));
      });

      test('a line with two bold spans keeps only the first — Round 4 has a '
          'second bold "Version v0.2" fragment that is not the title', () {
        final round4 = milestones.firstWhere(
          (m) => m.title.contains('Round 4'),
        );
        expect(round4.title, 'Round 4 — the stage, measured not typed');
      });

      test('done reads from the checkbox — Round 0, 1 and 5 are the three '
          'real done milestones', () {
        final done = milestones.where((m) => m.done).map((m) => m.title);
        expect(done, hasLength(3));
        expect(
          done,
          containsAll([
            'Round 0 — the shell',
            "Round 1 — one project's state",
            contains('Round 5'),
          ]),
        );
      });

      test(
        'nested tasks under a milestone are read, at the real indentation',
        () {
          final round5 = milestones.firstWhere(
            (m) => m.title.contains('Round 5'),
          );
          expect(round5.tasks, hasLength(2));
          expect(round5.tasks[0].text, 'Accept/reject flow (ADR 0011)');
          expect(round5.tasks[0].done, isTrue);

          final round9 = milestones.firstWhere(
            (m) => m.title.contains('Round 9'),
          );
          expect(round9.tasks, hasLength(5));
          expect(round9.tasks.every((t) => !t.done), isTrue);
        },
      );

      test('a milestone with no nested tasks has an empty list, not an '
          'error — Round 0 has none', () {
        expect(milestones[0].tasks, isEmpty);
      });

      test("a wrapped continuation line of the milestone's own description "
          '— indented the same as a real task, but with no checkbox syntax '
          "— is not mistaken for one. Real shape: Round 2's second line", () {
        final round2 = milestones.firstWhere(
          (m) => m.title.contains('Round 2'),
        );
        expect(round2.tasks, isEmpty);
      });

      test('stops at the next ## heading — the Tasks section is not read '
          'as more roadmap milestones', () {
        expect(
          milestones.any((m) => m.title.contains('accept/reject')),
          isFalse,
        );
      });
    },
  );

  group('parseRoadmap — partner-trial-process.md, no bold, no nesting', () {
    final milestones = parseRoadmap(_partnerTrialRoadmap);

    test('reads all eight real milestones', () {
      expect(milestones, hasLength(8));
    });

    test('with no bold span at all, the whole line is the title', () {
      expect(
        milestones.first.title,
        'Create the License object — name, License Name as display '
        'property, no unique identifier',
      );
    });

    test('none are done, and none have nested tasks', () {
      expect(milestones.every((m) => !m.done), isTrue);
      expect(milestones.every((m) => m.tasks.isEmpty), isTrue);
    });
  });

  test('no ## Roadmap section yields an empty list, not an error', () {
    expect(
      parseRoadmap('# A project\n\n## Tasks\n\n- [ ] Something\n'),
      isEmpty,
    );
  });

  group('effectiveMilestone', () {
    test('an empty roadmap falls back to the typed milestone, unchanged', () {
      expect(effectiveMilestone(const [], 'Typed value'), 'Typed value');
    });

    test('the first undone milestone, in file order — partner-trial-process, '
        'where every one is undone, so it is simply the first', () {
      final milestones = parseRoadmap(_partnerTrialRoadmap);
      expect(
        effectiveMilestone(milestones, 'ignored'),
        'Create the License object — name, License Name as display '
        'property, no unique identifier',
      );
    });

    test('every milestone done: the last one, with a "— done" suffix', () {
      const milestones = [
        Milestone(title: 'First', done: true),
        Milestone(title: 'Second', done: true),
      ];
      expect(effectiveMilestone(milestones, 'ignored'), 'Second — done');
    });

    test('against the real asa.md fixture as it reads right now, the first '
        'undone milestone is Round 2 — not Round 6. Recorded as-is: the '
        'HANDOVER.md correction entry\'s own "Done when" bar names Round 6, '
        'against an earlier version of this file with fewer, further-along '
        'milestones. The file has since grown (12 rounds, 3 done, not the '
        '7/1 the spec described) — this is the algorithm run honestly '
        'against what the file says today, not a guess reverse-engineered '
        'to match a since-stale example. Flagged back to Nico/Cowork rather '
        'than silently building to match the old example.', () {
      final milestones = parseRoadmap(_asaRoadmap);
      expect(
        effectiveMilestone(milestones, 'ignored'),
        'Round 2 — every project on one screen (Home)',
      );
    });
  });
}
