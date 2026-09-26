// Round 34/A — an area, read from its own plan\<area>.md page. Fixture
// shaped exactly like round-34.md's own example (invented content, no
// real project data).

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:flutter_test/flutter_test.dart';

const _fullExample = '''
# Sales

The partner registers and closes its own deals.

## Goal
Serves Objective 1 — would show: 3 deals registered by the partner this quarter.

## Plan
Two joint pitches a month from one shared account list, then the partner pitches alone.

## Tasks
- [x] Agree the shared account list
- [ ] Second demo for the account from the first pitch

## Results
- 2026-09-20 — First joint pitch. The account asked for a second demo.
- 2026-09-08 — Account list agreed: 40 accounts, 12 of them warm.

## Decisions
ADR 0003 — deals go through the partner portal. ADR 0006 — no discount beyond the standard margin.
''';

void main() {
  group('parseArea — every part present', () {
    final area = parseArea(
      _fullExample,
      sourceFile: 'sales.md',
      aspect: 'sales',
    );

    test('the name comes from the filename stem, not the H1', () {
      expect(area.name, 'Sales');
    });

    test('the summary is the first plain paragraph after the H1', () {
      expect(area.summary, 'The partner registers and closes its own deals.');
    });

    test('goal and plan are their own sections, verbatim', () {
      expect(
        area.goal,
        'Serves Objective 1 — would show: 3 deals registered by the '
        'partner this quarter.',
      );
      expect(
        area.planText,
        'Two joint pitches a month from one shared account list, then '
        'the partner pitches alone.',
      );
    });

    test('tasks come from ## Tasks, one per checkbox line', () {
      expect(area.tasks, hasLength(2));
      expect(area.tasks[0].text, 'Agree the shared account list');
      expect(area.tasks[0].done, isTrue);
      expect(area.tasks[1].done, isFalse);
    });

    test("progress is done/total of the area's own tasks", () {
      expect(area.doneCount, 1);
      expect(area.totalCount, 2);
    });

    test('results are dated, newest first', () {
      expect(area.results, hasLength(2));
      expect(area.results[0].date, DateTime(2026, 9, 20));
      expect(
        area.results[0].text,
        'First joint pitch. The account asked for a second demo.',
      );
      expect(area.results[1].date, DateTime(2026, 9, 8));
    });

    test("an Objective mentioned in the Goal section is the area's claim "
        'on it', () {
      expect(area.objectiveNumbers, ['1']);
    });

    test('every ADR named anywhere on the page is found', () {
      expect(area.decisionNumbers, ['0003', '0006']);
    });
  });

  group('parseArea — every part missing', () {
    final area = parseArea(
      '# Empty area\n\nNothing written yet.\n',
      sourceFile: 'empty.md',
      aspect: 'empty',
    );

    test('honest absence, not invented text', () {
      expect(area.goal, isNull);
      expect(area.planText, isNull);
      expect(area.tasks, isEmpty);
      expect(area.results, isEmpty);
      expect(area.decisionNumbers, isEmpty);
      expect(area.objectiveNumbers, isEmpty);
      expect(area.doneCount, 0);
      expect(area.totalCount, 0);
    });
  });

  group('naming and sort order — the number prefix', () {
    test('a number prefix sets order and is not shown', () {
      final area = parseArea(
        '# x',
        sourceFile: '1-sales.md',
        aspect: '1-sales',
      );
      expect(area.name, 'Sales');
    });

    test('a multi-word slug title-cases, space separated', () {
      final area = parseArea(
        '# x',
        sourceFile: 'customer-success.md',
        aspect: 'customer-success',
      );
      expect(area.name, 'Customer Success');
    });
  });

  group('an Objective mentioned outside the Goal section does not count', () {
    test("the area's own claim is only what its Goal section says", () {
      final area = parseArea(
        '# x\n\n## Goal\nNo goal yet.\n\n## Plan\nServes Objective 2 in '
        'passing, not a real claim.\n',
        sourceFile: 'x.md',
        aspect: 'x',
      );
      expect(area.objectiveNumbers, isEmpty);
    });
  });

  group('progress counts a checkbox anywhere on the page', () {
    test(
      "round-34.md's own note: on asa, Round checkboxes named in the "
      "page count too, because they're checkboxes like any other",
      () {
      final area = parseArea(
        '# x\n\n## Plan\n- [x] A Round-shaped checkbox outside ## Tasks\n\n'
        '## Tasks\n- [ ] A real task\n',
        sourceFile: 'x.md',
        aspect: 'x',
      );
      // tasks (## Tasks only) stays scoped — Round 34 F may only ever
      // write there — but the *progress count* looks at the whole page.
      expect(area.tasks, hasLength(1));
      expect(area.totalCount, 1);
    });
  });

  group('an undated Results line is kept verbatim, never dropped', () {
    test('a line that is not the dated shape stays, undated, after every '
        'dated one', () {
      final area = parseArea(
        '# x\n\n## Results\n- 2026-09-01 — A dated result.\n- Just a plain '
        'note with no date.\n',
        sourceFile: 'x.md',
        aspect: 'x',
      );
      expect(area.results, hasLength(2));
      expect(area.results[0].date, isNotNull);
      expect(area.results[1].date, isNull);
      expect(area.results[1].text, 'Just a plain note with no date.');
    });
  });

  group('readAreas', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asa-area-test-');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test(r'no plan\ folder at all reads as no areas, not an error', () async {
      final areas = await readAreas(tempDir.path);
      expect(areas, isEmpty);
    });

    test('sorted by number prefix first, then by name', () async {
      final planDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}plan',
      )..createSync();
      File(
        '${planDir.path}${Platform.pathSeparator}2-finance.md',
      ).writeAsStringSync('# Finance');
      File(
        '${planDir.path}${Platform.pathSeparator}1-sales.md',
      ).writeAsStringSync('# Sales');
      File(
        '${planDir.path}${Platform.pathSeparator}enablement.md',
      ).writeAsStringSync('# Enablement');

      final areas = await readAreas(tempDir.path);
      expect(areas.map((a) => a.name).toList(), [
        'Sales',
        'Finance',
        'Enablement',
      ]);
    });
  });
}
