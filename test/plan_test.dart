// Round 26 — read the plan, and the links inside it. `core/` only, no
// screen, no writes. `readPlan` touches real disk (same reasoning as
// `project_writer_test.dart`: only dart:io proves what a real folder scan
// actually finds); `parseSections` and `deriveLinks` are pure text in,
// data out, and are tested directly.

import 'dart:io';

import 'package:asa/core/markdown.dart';
import 'package:asa/core/plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSections', () {
    test('a ## section containing ### subsections comes back whole — '
        'regression test for the 2026-09-13 heading-level bug', () {
      const text = '''
## Roadmap

### Foundation

- [ ] Round 1
- [ ] Round 2

### Next

- [ ] Round 3

## Tasks

- [ ] something else
''';
      final sections = parseSections(text);

      final roadmap = sections.firstWhere((s) => s.heading == 'Roadmap');
      expect(roadmap.body, contains('### Foundation'));
      expect(roadmap.body, contains('### Next'));
      expect(roadmap.body, contains('Round 3'));
      expect(roadmap.body, isNot(contains('## Tasks')));

      final foundation = sections.firstWhere((s) => s.heading == 'Foundation');
      expect(foundation.level, 3);
      expect(foundation.body, contains('Round 1'));
      expect(foundation.body, isNot(contains('Round 3')));
    });

    test('a heading inside a fenced code example is not a section', () {
      const text = '''
## Real section

Some text.

```
## Not a real heading
```

## Another real section
''';
      final headings = parseSections(text).map((s) => s.heading).toList();
      expect(headings, ['Real section', 'Another real section']);
    });

    test('no heading at all returns an empty list, not an error', () {
      expect(parseSections('just a paragraph, no headings'), isEmpty);
    });
  });

  group('deriveLinks', () {
    test('one ADR referenced three different ways produces one link to '
        '0007, three times, each with its own sentence', () {
      const text = r'''
## Why

This follows ADR 0007 directly. See also `0007-asa-writes-fields.md` for
the original text. The full path is `decisions\0007-asa-writes-fields.md`
if you want to open it.
''';
      final links = deriveLinks(text);
      final adrLinks = links.where((l) => l.kind == PlanLinkKind.adr).toList();

      expect(adrLinks, hasLength(3));
      expect(adrLinks.every((l) => l.target == '0007'), isTrue);
      expect(adrLinks.map((l) => l.sentence).toSet(), hasLength(3));
    });

    test('a filename date is not mistaken for an ADR number', () {
      const text =
          'Written after `RESEARCH-PLANNING-LAYER-2026-09-14.md`, '
          "at Nico's instruction.";
      final adrLinks = deriveLinks(text)
          .where((l) => l.kind == PlanLinkKind.adr);
      expect(adrLinks, isEmpty);
    });

    test('a page with no references produces an empty link list, not '
        'null and not an error', () {
      final links = deriveLinks(
        'Just a plain paragraph with nothing to '
        'link.',
      );
      expect(links, isEmpty);
    });

    test('a sentence is captured verbatim for every link', () {
      const text = 'Round 26 reads the plan. It links to [[budget]] too.';
      final links = deriveLinks(text);

      final round = links.firstWhere((l) => l.kind == PlanLinkKind.round);
      expect(round.target, '26');
      expect(round.sentence, 'Round 26 reads the plan.');

      final wikilink = links.firstWhere((l) => l.kind == PlanLinkKind.wikilink);
      expect(wikilink.target, 'budget');
      expect(wikilink.sentence, 'It links to [[budget]] too.');
    });

    test('Round 34/A — an Objective N mention derives an objective link', () {
      const text = 'Serves Objective 1 — would show: 3 deals this quarter.';
      final links = deriveLinks(text);

      final objective = links.firstWhere(
        (l) => l.kind == PlanLinkKind.objective,
      );
      expect(objective.target, '1');
      expect(objective.sentence, text);
    });

    test('a reference inside a fenced code example is not derived', () {
      const text = '''
Some real text mentions ADR 0007.

```
Example: ADR 0099 would go here.
```
''';
      final targets = deriveLinks(text).map((l) => l.target).toList();
      expect(targets, ['0007']);
    });
  });

  group('readPlan', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asa-plan-test-');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test(r'a project with PLAN.md and no plan\ folder reads as a '
        'one-page plan', () async {
      File('${tempDir.path}${Platform.pathSeparator}PLAN.md')
          .writeAsStringSync('# Plan\n\nSomething about ADR 0007.');

      final plan = await readPlan(tempDir.path);

      expect(plan.isEmpty, isFalse);
      expect(plan.pages, hasLength(1));
      expect(plan.pages.single.aspect, isNull);
      expect(plan.pages.single.links.single.target, '0007');
    });

    test(r'a project with neither PLAN.md nor plan\ reads as no plan at '
        'all — distinguishable from an empty plan', () async {
      final plan = await readPlan(tempDir.path);
      expect(plan.isEmpty, isTrue);
      expect(plan.pages, isEmpty);
    });

    test('an existing PLAN.md with no content is an empty plan, not no '
        'plan at all — the two are distinguishable', () async {
      File('${tempDir.path}${Platform.pathSeparator}PLAN.md')
          .writeAsStringSync('');

      final plan = await readPlan(tempDir.path);

      expect(plan.isEmpty, isFalse);
      expect(plan.pages, hasLength(1));
      expect(plan.pages.single.sections, isEmpty);
      expect(plan.pages.single.links, isEmpty);
    });

    test(r'a plan\ folder is read as one PlanPage per file, keyed by its '
        'filename stem', () async {
      File('${tempDir.path}${Platform.pathSeparator}PLAN.md')
          .writeAsStringSync('# Plan\n\nSee [[budget]].');
      final planDir = Directory('${tempDir.path}${Platform.pathSeparator}plan')
        ..createSync();
      File('${planDir.path}${Platform.pathSeparator}budget.md')
          .writeAsStringSync('# Budget\n\nNothing to link here.');
      File('${planDir.path}${Platform.pathSeparator}marketing.md')
          .writeAsStringSync('# Marketing\n\nSee [[budget]] for the split.');

      final plan = await readPlan(tempDir.path);

      expect(plan.pages, hasLength(3));
      final aspects = plan.pages.map((p) => p.aspect).toList();
      expect(aspects, [null, 'budget', 'marketing']);

      final budget = plan.pages.firstWhere((p) => p.aspect == 'budget');
      final marketing = plan.pages.firstWhere((p) => p.aspect == 'marketing');
      final backlinks = pagesLinkingTo(plan, budget);

      expect(backlinks, containsAll([marketing]));
      expect(backlinks, isNot(contains(budget)));
    });

    test('a project folder that does not exist reads as no plan, not '
        'an error', () async {
      final missing = '${tempDir.path}${Platform.pathSeparator}gone';
      final plan = await readPlan(missing);
      expect(plan.isEmpty, isTrue);
    });
  });

  group("the real fixture — Asa's own PLAN.md", () {
    test('parses without error and finds real ADR/Round links', () {
      final path =
          '${Directory.current.path}${Platform.pathSeparator}'
          '..${Platform.pathSeparator}projects${Platform.pathSeparator}asa'
          '${Platform.pathSeparator}PLAN.md';
      final file = File(path);
      if (!file.existsSync()) {
        // Gate 2: this repo never carries real project content. This test
        // only runs on a machine where `projects\asa\PLAN.md` exists
        // alongside this repo, per the workspace layout in AGENTS.md.
        return;
      }

      final contents = file.readAsStringSync();
      final sections = parseSections(contents);
      final links = deriveLinks(contents);

      expect(sections, isNotEmpty);
      expect(links, isNotEmpty);
      expect(links.any((l) => l.kind == PlanLinkKind.adr), isTrue);
      expect(links.any((l) => l.kind == PlanLinkKind.round), isTrue);
      for (final link in links) {
        expect(link.sentence, isNotEmpty);
      }
    });
  });
}
