// Round 27 — the Plan tab. Pure widget tests: a Plan is built by hand in
// memory (Round 26 already proves parsing against real files), so these
// only check what this screen does with data it is handed.

import 'package:asa/core/area.dart';
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/plan_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Section _section(String heading, {int level = 2, String body = ''}) {
  return Section(level: level, heading: heading, body: body);
}

Future<void> _pump(WidgetTester tester, Plan plan) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PlanView(
          plan: plan,
          areas: const [],
          decisions: const [],
          homeTasks: const [],
          projectSourceFile: 'asa.md',
        ),
      ),
    ),
  );
}

void main() {
  group('the outline — collapsed by default', () {
    testWidgets('a section with children starts collapsed; the child is '
        'not shown until the chevron is tapped', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('Parent section'),
          _section('Child section', level: 3),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('Parent section'), findsOneWidget);
      expect(find.text('Child section'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Child section'), findsOneWidget);
    });

    testWidgets('a leaf section (no children) shows no expand chevron at '
        'all', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [_section('A section with nothing nested under it')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('more than 6 top-level groups shows only 6, with a '
        '"more, collapsed" reveal — persona-check, real screen: row count '
        'alone can overwhelm even when every row is collapsed', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [for (var i = 1; i <= 8; i++) _section('Section $i')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      for (var i = 1; i <= 6; i++) {
        expect(find.text('Section $i'), findsOneWidget);
      }
      expect(find.text('Section 7'), findsNothing);
      expect(find.text('Section 8'), findsNothing);
      expect(find.text('+ 2 more, collapsed ↓'), findsOneWidget);

      await tester.tap(find.text('+ 2 more, collapsed ↓'));
      await tester.pump();

      expect(find.text('Section 7'), findsOneWidget);
      expect(find.text('Section 8'), findsOneWidget);
    });

    testWidgets('an aspect page gets its own top-level group, collapsed, '
        'named by its aspect', (tester) async {
      const front = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [],
        links: [],
      );
      final budget = PlanPage(
        aspect: 'budget',
        sourceFile: 'plan/budget.md',
        sections: [_section('Q4 spend')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [front, budget]));

      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Q4 spend'), findsNothing); // collapsed by default

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Q4 spend'), findsOneWidget);
    });
  });

  group('what changed — the date sort', () {
    testWidgets('newest date first, and among equal dates the one later '
        'in the file wins', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('2026-09-01 — oldest'),
          _section('2026-09-14 — earlier the same day'),
          _section('2026-09-14 — later the same day'),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();

      final laterIndex = order.indexOf('later the same day');
      final earlierIndex = order.indexOf('earlier the same day');
      final oldestIndex = order.indexOf('oldest');

      expect(laterIndex, greaterThanOrEqualTo(0));
      expect(laterIndex, lessThan(earlierIndex));
      expect(earlierIndex, lessThan(oldestIndex));
    });

    testWidgets('only the 3 most recent show; the rest sit behind one '
        '"older" line until tapped', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('2026-09-01 — first'),
          _section('2026-09-02 — second'),
          _section('2026-09-03 — third'),
          _section('2026-09-04 — fourth'),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      // Exact match: the stripped "what changed" text ("fourth"), not the
      // outline's own unstripped heading ("2026-09-04 — fourth") — the
      // outline always shows every heading, so a substring match here
      // would pass regardless of whether "what changed" truncates at all.
      expect(find.text('fourth'), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
      expect(find.text('older (1) ↓'), findsOneWidget);

      await tester.tap(find.text('older (1) ↓'));
      await tester.pump();

      expect(find.text('first'), findsOneWidget);
    });

    testWidgets('a chip renders for an ADR or a Round link, never for a '
        'wikilink', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section(
            '2026-09-14 — shipped',
            body:
                'This follows ADR 0007, closes Round 26, and mentions '
                '[[budget]].',
          ),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('ADR 0007'), findsOneWidget);
      expect(find.text('Round 26'), findsOneWidget);
      expect(find.textContaining('budget'), findsNothing);
    });

    testWidgets('a page with nothing dated shows a plain empty state, not '
        'a crash', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [_section('No date in this heading at all')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('Nothing dated yet.'), findsOneWidget);
    });

    testWidgets(
      'Round 35/C — an entry with many links caps its chips at 3 and shows '
      '"+N", never squeezing its own sentence to nothing',
      (tester) async {
        final page = PlanPage(
          aspect: null,
          sourceFile: 'PLAN.md',
          sections: [
            _section(
              '2026-09-07 — the goal narrowed: one working overview of all '
              '13 projects, kept current by Claude',
              body:
                  'Round 2 Round 6 Round 3 Round 28 Round 14 Round 10 '
                  'Round 31 Round 32',
            ),
          ],
          links: const [],
        );
        await _pump(tester, Plan(pages: [page]));

        expect(tester.takeException(), isNull);
        // The sentence itself must still be one real, un-mangled Text —
        // not sliced into single characters by a starved Expanded.
        expect(
          find.text(
            'the goal narrowed: one working overview of all 13 projects, '
            'kept current by Claude',
          ),
          findsOneWidget,
        );
        expect(find.text('Round 2'), findsOneWidget);
        expect(find.text('Round 6'), findsOneWidget);
        expect(find.text('Round 3'), findsOneWidget);
        expect(find.text('Round 28'), findsNothing);
        expect(find.text('+5'), findsOneWidget);
      },
    );
  });

  group(r'Round 34/B — areas, when a project has any plan\*.md page', () {
    Area area({
      String name = 'Sales',
      String sourceFile = 'plan/sales.md',
      String? summary = 'The partner registers and closes its own deals.',
      String? goal = 'Serves Objective 1.',
      String? planText = 'Two joint pitches a month.',
      List<Task> tasks = const [],
      List<AreaResult> results = const [],
      List<String> decisionNumbers = const [],
    }) {
      return Area(
        name: name,
        sourceFile: sourceFile,
        summary: summary,
        goal: goal,
        planText: planText,
        tasks: tasks,
        results: results,
        decisionNumbers: decisionNumbers,
        objectiveNumbers: const ['1'],
      );
    }

    // Round 38 §B — `selectedAreaTab` is now a controlled prop, owned by
    // whoever hosts `PlanView` (`ProjectScreen`, for real); this harness
    // plays that same role for a test, so tapping an area row in "All"
    // (or "All" itself) actually switches what's shown, same as before
    // the prop moved out of this widget's own state.
    Future<void> pumpAreas(
      WidgetTester tester, {
      required List<Area> areas,
      List<Task> homeTasks = const [],
      Strategy? strategy,
      VoidCallback? onOpenStrategy,
      Future<void> Function(String, Task)? onToggleTask,
      Future<void> Function(
        String sourceFile,
        String heading,
        String oldValue,
        String newText,
      )?
      onSetAreaSection,
      Future<void> Function(String sourceFile, String heading)?
      onClearAreaSection,
      Future<void> Function(
        String sourceFile,
        AreaResult result,
        String newText,
      )?
      onEditResultText,
      Future<void> Function(String sourceFile, AreaResult result)?
      onRemoveResultText,
    }) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PlanView(
                  plan: const Plan(pages: []),
                  areas: areas,
                  decisions: const [],
                  homeTasks: homeTasks,
                  strategy: strategy,
                  onOpenStrategy: onOpenStrategy,
                  onToggleTask: onToggleTask,
                  onSetAreaSection: onSetAreaSection,
                  onClearAreaSection: onClearAreaSection,
                  onEditResultText: onEditResultText,
                  onRemoveResultText: onRemoveResultText,
                  projectSourceFile: 'demo.md',
                  selectedAreaTab: selected,
                  onSelectAreaTab: (sourceFile) =>
                      setState(() => selected = sourceFile),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
      '"All" shows a plain summary row: name, next task, done/total and a '
      'result label, no Goal/Plan/Tasks text yet (Round 38 §B — that '
      "whole page is now the area's own tab, not shown inline)",
      (tester) async {
        await pumpAreas(
          tester,
          areas: [
            area(
              tasks: [
                const Task(rawLine: '- [x] a', text: 'a', done: true),
                const Task(rawLine: '- [ ] b', text: 'b', done: false),
              ],
            ),
          ],
          homeTasks: [
            const Task(rawLine: '- [ ] home', text: 'Home task', done: false),
          ],
        );

        // One "Sales" in the area tab strip, one in "All"'s own summary row.
        expect(find.text('Sales'), findsNWidgets(2));
        expect(find.text('next b'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.text('no result yet'), findsOneWidget);
        expect(find.text('Serves Objective 1.'), findsNothing);
      },
    );

    testWidgets('opening a row shows Goal, Plan, Tasks, Results and '
        'Decisions, in that order', (tester) async {
      await pumpAreas(
        tester,
        areas: [
          area(
            tasks: [const Task(rawLine: '- [ ] a', text: 'a', done: false)],
            results: [
              AreaResult(date: DateTime(2026, 9, 20), text: 'A result.'),
            ],
            decisionNumbers: ['0003'],
          ),
        ],
        homeTasks: [
          const Task(rawLine: '- [ ] home', text: 'Home task', done: false),
        ],
      );

      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      expect(find.text('Serves Objective 1.'), findsOneWidget);
      expect(find.text('Two joint pitches a month.'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('A result.'), findsOneWidget);
      expect(find.text('ADR 0003'), findsOneWidget);

      final goalIndex = tester.getTopLeft(find.text('GOAL')).dy;
      final planIndex = tester.getTopLeft(find.text('PLAN')).dy;
      final tasksIndex = tester.getTopLeft(find.text('TASKS')).dy;
      final resultsIndex = tester.getTopLeft(find.text('RESULTS')).dy;
      final decisionsIndex = tester.getTopLeft(find.text('DECISIONS')).dy;
      expect(goalIndex, lessThan(planIndex));
      expect(planIndex, lessThan(tasksIndex));
      expect(tasksIndex, lessThan(resultsIndex));
      expect(resultsIndex, lessThan(decisionsIndex));
    });

    testWidgets('missing parts are honest absence, never invented text', (
      tester,
    ) async {
      await pumpAreas(
        tester,
        // Not fully empty (one task) — this is the "some parts missing"
        // case; a fully empty area gets Round 38 §B's own single "Empty
        // so far" message instead (see the dedicated test for that).
        areas: [
          area(
            summary: null,
            goal: null,
            planText: null,
            tasks: [const Task(rawLine: '- [ ] a', text: 'a', done: false)],
          ),
        ],
      );
      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      expect(find.text('No goal yet'), findsOneWidget);
      expect(find.text('No plan yet'), findsOneWidget);
      expect(find.text('a'), findsOneWidget); // the one real task
      expect(find.text('Nothing yet'), findsOneWidget); // Results only
      expect(find.text('None yet'), findsOneWidget); // Decisions
    });

    testWidgets('Round 43 §D — an empty Goal/Plan shows ＋; tapping it opens an '
        'inline field, Enter writes via onSetAreaSection', (tester) async {
      String? writtenFile;
      String? writtenHeading;
      String? writtenText;
      await pumpAreas(
        tester,
        areas: [
          area(
            summary: null,
            goal: null,
            planText: null,
            tasks: [const Task(rawLine: '- [ ] a', text: 'a', done: false)],
          ),
        ],
        onSetAreaSection: (sourceFile, heading, oldValue, text) async {
          writtenFile = sourceFile;
          writtenHeading = heading;
          writtenText = text;
        },
      );
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      expect(find.text('No goal yet'), findsNothing);
      expect(find.text('＋'), findsNWidgets(2)); // Goal and Plan

      await tester.tap(find.text('＋').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Serves Objective 1.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenHeading, 'Goal');
      expect(writtenText, 'Serves Objective 1.');
      expect(writtenFile, isNotNull);
    });

    testWidgets('Esc closes the empty-place field without writing', (
      tester,
    ) async {
      var written = false;
      await pumpAreas(
        tester,
        areas: [
          area(
            summary: null,
            goal: null,
            planText: null,
            tasks: [const Task(rawLine: '- [ ] a', text: 'a', done: false)],
          ),
        ],
        onSetAreaSection: (sourceFile, heading, oldValue, text) async {
          written = true;
        },
      );
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      await tester.tap(find.text('＋').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ignored');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      // Back to "heading and ＋ only" — once a writer is wired in, the
      // old plain "No goal yet" line is never shown again, replaced by
      // the ＋ affordance itself (round-43.md §D's own wording).
      expect(find.text('＋'), findsNWidgets(2));
      expect(written, isFalse);
    });

    testWidgets('Round 43 §D — ✎ on hover of a filled Goal edits it in place, '
        'pre-filled, Enter writes the new text', (tester) async {
      String? writtenHeading;
      String? writtenOldValue;
      String? writtenText;
      await pumpAreas(
        tester,
        areas: [area()],
        onSetAreaSection: (sourceFile, heading, oldValue, text) async {
          writtenHeading = heading;
          writtenOldValue = oldValue;
          writtenText = text;
        },
      );
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      // The pencil is invisible until hovered, same discipline
      // TaskRow's own park icon already uses.
      expect(find.byIcon(Icons.edit), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('Serves Objective 1.')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Serves Objective 1.');

      await tester.enterText(find.byType(TextField), 'Serves Objective 2.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenHeading, 'Goal');
      // The real bug this guards: a missing `oldValue` makes the real
      // `setAreaSection` writer's own drift check refuse every edit of
      // non-empty text (it only ever matched the empty-place case before
      // this was threaded through) — found while wiring 🗑 onto this same
      // submit path, fixed the same session.
      expect(writtenOldValue, 'Serves Objective 1.');
      expect(writtenText, 'Serves Objective 2.');
    });

    testWidgets(
      "Round 43 §D — 🗑 in a filled Goal's own edit mode clears it, closes "
      'back to ＋',
      (tester) async {
        String? clearedSourceFile;
        String? clearedHeading;
        await pumpAreas(
          tester,
          areas: [area()],
          onSetAreaSection: (sourceFile, heading, oldValue, text) async {},
          onClearAreaSection: (sourceFile, heading) async {
            clearedSourceFile = sourceFile;
            clearedHeading = heading;
          },
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(find.text('Serves Objective 1.')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();

        expect(clearedSourceFile, isNotNull);
        expect(clearedHeading, 'Goal');
      },
    );

    testWidgets(
      'Round 43 §D — the ＋ path never shows 🗑 — nothing to remove yet',
      (tester) async {
        await pumpAreas(
          tester,
          areas: [
            area(
              summary: null,
              goal: null,
              planText: null,
              tasks: [const Task(rawLine: '- [ ] a', text: 'a', done: false)],
            ),
          ],
          onSetAreaSection: (sourceFile, heading, oldValue, text) async {},
          onClearAreaSection: (sourceFile, heading) async {},
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        await tester.tap(find.text('＋').first);
        await tester.pump();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
      },
    );

    testWidgets(
      'Round 43 §D — ✎ on hover of a result edits its own text, keeping '
      'its date; an undated result stays read-only',
      (tester) async {
        String? writtenSourceFile;
        AreaResult? writtenResult;
        String? writtenText;
        await pumpAreas(
          tester,
          areas: [
            area(
              results: [
                const AreaResult(
                  date: null,
                  text: 'Undated',
                  rawLine: '- Undated',
                ),
                AreaResult(
                  date: DateTime(2026, 9, 20),
                  text: 'A real result',
                  rawLine: '- 2026-09-20 — A real result',
                ),
              ],
            ),
          ],
          onEditResultText: (sourceFile, result, newText) async {
            writtenSourceFile = sourceFile;
            writtenResult = result;
            writtenText = newText;
          },
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // The undated result never shows a pencil at all.
        await gesture.moveTo(tester.getCenter(find.text('Undated')));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.edit), findsNothing);

        await gesture.moveTo(tester.getCenter(find.text('A real result')));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.edit), findsOneWidget);

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'An edited result');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(writtenSourceFile, isNotNull);
        expect(writtenResult?.text, 'A real result');
        expect(writtenText, 'An edited result');
      },
    );

    testWidgets(
      "Round 43 §D — 🗑 in a result's own edit mode removes it",
      (tester) async {
        String? removedSourceFile;
        AreaResult? removedResult;
        await pumpAreas(
          tester,
          areas: [
            area(
              results: [
                AreaResult(
                  date: DateTime(2026, 9, 20),
                  text: 'A real result',
                  rawLine: '- 2026-09-20 — A real result',
                ),
              ],
            ),
          ],
          onEditResultText: (sourceFile, result, newText) async {},
          onRemoveResultText: (sourceFile, result) async {
            removedSourceFile = sourceFile;
            removedResult = result;
          },
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.text('A real result')));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();

        expect(removedSourceFile, isNotNull);
        expect(removedResult?.text, 'A real result');
      },
    );

    testWidgets(
      'Round 38 §F — done tasks fold into "✓ N done · show ›", tapping it '
      'reveals them',
      (tester) async {
        await pumpAreas(
          tester,
          areas: [
            area(
              tasks: [
                const Task(
                  rawLine: '- [ ] open one',
                  text: 'open one',
                  done: false,
                ),
                const Task(
                  rawLine: '- [x] done one',
                  text: 'done one',
                  done: true,
                ),
                const Task(
                  rawLine: '- [x] done two',
                  text: 'done two',
                  done: true,
                ),
              ],
            ),
          ],
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        expect(find.text('open one'), findsOneWidget);
        expect(find.text('done one'), findsNothing);
        expect(find.text('done two'), findsNothing);
        expect(find.textContaining('✓ 2 done'), findsOneWidget);

        await tester.tap(find.textContaining('✓ 2 done'));
        await tester.pump();

        expect(find.text('done one'), findsOneWidget);
        expect(find.text('done two'), findsOneWidget);
      },
    );

    testWidgets(
      'Round 38 §F — results show only the newest two, then "N older ›"',
      (tester) async {
        await pumpAreas(
          tester,
          areas: [
            area(
              results: [
                AreaResult(date: DateTime(2026, 9, 20), text: 'newest'),
                AreaResult(date: DateTime(2026, 9, 15), text: 'second'),
                AreaResult(date: DateTime(2026, 9, 10), text: 'third'),
                AreaResult(date: DateTime(2026, 9), text: 'oldest'),
              ],
            ),
          ],
        );
        await tester.tap(find.text('Sales').first);
        await tester.pump();

        expect(find.text('newest'), findsOneWidget);
        expect(find.text('second'), findsOneWidget);
        expect(find.text('third'), findsNothing);
        expect(find.text('oldest'), findsNothing);
        expect(find.textContaining('2 older'), findsOneWidget);

        await tester.tap(find.textContaining('2 older'));
        await tester.pump();

        expect(find.text('third'), findsOneWidget);
        expect(find.text('oldest'), findsOneWidget);
      },
    );

    testWidgets("ticking a task calls onToggleTask with the area's own "
        'sourceFile', (tester) async {
      String? calledWith;
      Task? calledTask;
      const task = Task(rawLine: '- [ ] b', text: 'b', done: false);

      await pumpAreas(
        tester,
        areas: [
          area(tasks: [task]),
        ],
        homeTasks: [
          const Task(rawLine: '- [ ] home', text: 'Home task', done: false),
        ],
        onToggleTask: (sourceFile, t) async {
          calledWith = sourceFile;
          calledTask = t;
        },
      );
      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(calledWith, 'plan/sales.md');
      expect(calledTask, task);
    });

    testWidgets(
      '"Not in an area" is the last row — the home note\'s own ## Tasks, '
      'open count shown collapsed',
      (tester) async {
        await pumpAreas(
          tester,
          areas: [area()],
          homeTasks: [
            const Task(rawLine: '- [ ] c', text: 'c', done: false),
            const Task(rawLine: '- [x] d', text: 'd', done: true),
          ],
        );

        expect(find.text('Not in an area'), findsOneWidget);
        expect(find.text('1 open'), findsOneWidget);
        // Round 38 §A moved the Next line into ProjectScreen's own
        // header (out of PlanView) — this test mounts PlanView alone, so
        // no header exists here to surface a second copy of "c" before
        // "Not in an area" is opened.
        expect(find.text('c'), findsNothing);

        await tester.tap(find.text('Not in an area'));
        await tester.pump();
        expect(find.text('c'), findsOneWidget);
        // Round 38 §F — the one done task folds into "✓ 1 done · show ›",
        // not shown until that link itself is tapped.
        expect(find.text('d'), findsNothing);
        expect(find.textContaining('1 done'), findsOneWidget);

        await tester.tap(find.textContaining('1 done'));
        await tester.pump();
        expect(find.text('d'), findsOneWidget);
      },
    );

    testWidgets('"What this project is for" shows the first objective and '
        'opens Strategy on tap — only when a real strategy exists', (
      tester,
    ) async {
      var opened = false;
      await pumpAreas(
        tester,
        areas: [area()],
        strategy: const Strategy(
          origin: 'o',
          whoItsFor: 'w',
          painPoints: 'p',
          objectives: [
            Objective(
              title: 'Grow the partner channel',
              evidence: 'e',
              sentence: 's',
            ),
          ],
        ),
        onOpenStrategy: () => opened = true,
      );

      expect(
        find.textContaining(
          'What this project is for — Grow the partner '
          'channel',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Strategy →'));
      expect(opened, isTrue);
    });

    testWidgets('no CHARTER.md — "What this project is for" does not show '
        'at all', (tester) async {
      await pumpAreas(tester, areas: [area()]);
      expect(find.textContaining('What this project is for'), findsNothing);
    });

    testWidgets('Overview only shows when PLAN.md itself exists as a page', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(
                pages: [
                  PlanPage(
                    aspect: null,
                    sourceFile: 'PLAN.md',
                    sections: [],
                    links: [],
                  ),
                ],
              ),
              areas: [area()],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );
      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('no PLAN.md at all — no Overview row', (tester) async {
      await pumpAreas(tester, areas: [area()]);
      expect(find.text('Overview'), findsNothing);
    });
  });

  group("round-36 §3, L12 — an area's Objective chip", () {
    Area area({List<String> objectiveNumbers = const []}) {
      return Area(
        name: 'Sales',
        sourceFile: 'plan/sales.md',
        goal: 'Serves Objective 1.',
        objectiveNumbers: objectiveNumbers,
        tasks: const [],
        results: const [],
        decisionNumbers: const [],
      );
    }

    /// Round-37 §D4 — "Objective N" is now an inline link inside the
    /// Goal sentence's own `Text.rich`, not a separate widget a plain
    /// `tester.tap(find.text(...))` can land on. Invokes the matching
    /// span's own `TapGestureRecognizer` directly.
    void tapObjectiveLink(WidgetTester tester, String label) {
      void searchSpan(InlineSpan span) {
        if (span is TextSpan) {
          if (span.text == label && span.recognizer is TapGestureRecognizer) {
            (span.recognizer! as TapGestureRecognizer).onTap!();
            return;
          }
          span.children?.forEach(searchSpan);
        }
      }

      for (final richText in tester.widgetList<RichText>(
        find.byType(RichText),
      )) {
        searchSpan(richText.text);
      }
    }

    testWidgets('the Goal sentence\'s own "Objective N" mention is the '
        'link, tap switches to Strategy with that objective', (tester) async {
      String? opened;
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PlanView(
                plan: const Plan(pages: []),
                areas: [
                  area(objectiveNumbers: const ['1']),
                ],
                decisions: const [],
                homeTasks: const [],
                projectSourceFile: 'demo.md',
                onOpenObjective: (n) => opened = n,
                selectedAreaTab: selected,
                onSelectAreaTab: (s) => setState(() => selected = s),
              ),
            ),
          ),
        ),
      );

      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      expect(find.text('Serves Objective 1.'), findsOneWidget);
      tapObjectiveLink(tester, 'Objective 1');
      expect(opened, '1');
    });

    testWidgets('no objective named at all leaves "Objective 1" as plain text, '
        'not a link', (tester) async {
      String? opened;
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PlanView(
                plan: const Plan(pages: []),
                areas: [area()],
                decisions: const [],
                homeTasks: const [],
                projectSourceFile: 'demo.md',
                onOpenObjective: (n) => opened = n,
                selectedAreaTab: selected,
                onSelectAreaTab: (s) => setState(() => selected = s),
              ),
            ),
          ),
        ),
      );

      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();

      expect(find.text('Serves Objective 1.'), findsOneWidget);
      tapObjectiveLink(tester, 'Objective 1');
      expect(opened, isNull);
    });
  });

  group("round-36 §3, L13 — an area's ADR chip opens decision detail", () {
    Area area(List<String> decisionNumbers) {
      return Area(
        name: 'Sales',
        sourceFile: 'plan/sales.md',
        decisionNumbers: decisionNumbers,
        tasks: const [],
        results: const [],
        objectiveNumbers: const [],
      );
    }

    const decision = Decision(
      title: 'Deals go through the partner portal',
      why: 'w',
      decision: 'd',
      whatWouldChangeThis: 'c',
      sourceFile: 'decisions/0003.md',
      number: '0003',
    );

    testWidgets('a loaded decision opens the real in-app detail screen, '
        'not the raw file', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PlanView(
                plan: const Plan(pages: []),
                areas: [
                  area(const ['0003']),
                ],
                decisions: const [
                  DecisionReadResult(
                    sourceFile: 'decisions/0003.md',
                    decision: decision,
                  ),
                ],
                homeTasks: const [],
                projectSourceFile: 'demo.md',
                selectedAreaTab: selected,
                onSelectAreaTab: (s) => setState(() => selected = s),
              ),
            ),
          ),
        ),
      );

      // Round 38 §B — "Sales" now names both the area's own tab-strip
      // label and its "All" summary row; either one selects the same
      // area, so `.first` is unambiguous here.
      await tester.tap(find.text('Sales').first);
      await tester.pump();
      // Round 37 §D3 — both show both: the chip itself names the loaded
      // decision's own title, not just "ADR 0003".
      await tester.tap(find.text('0003 · Deals go through the partner portal'));
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsOneWidget);
      // Round 37 §D3 — both show both: the header names the number with
      // the title now, same as the Decisions tab row and the ADR chip.
      expect(
        find.text('0003 · Deals go through the partner portal'),
        findsOneWidget,
      );

      // Back returns to Plan, this same area still open.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(find.text('No goal yet'), findsOneWidget);
    });
  });
}
