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
import 'package:flutter/material.dart';
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

    Future<void> pumpAreas(
      WidgetTester tester, {
      required List<Area> areas,
      List<Task> homeTasks = const [],
      Strategy? strategy,
      VoidCallback? onOpenStrategy,
      Future<void> Function(String, Task)? onToggleTask,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: areas,
              decisions: const [],
              homeTasks: homeTasks,
              strategy: strategy,
              onOpenStrategy: onOpenStrategy,
              onToggleTask: onToggleTask,
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );
    }

    testWidgets('an area row is collapsed by default: name, next task, '
        'done/total and a result label, no Goal/Plan/Tasks text yet', (
      tester,
    ) async {
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
        // A home task diverts the Next line's own area chip elsewhere, so
        // this area's name is not also duplicated by that chip — the
        // Next line is round-36 §2 b's concern, not this test's.
        homeTasks: [
          const Task(rawLine: '- [ ] home', text: 'Home task', done: false),
        ],
      );

      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('next b'), findsOneWidget);
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('no result yet'), findsOneWidget);
      expect(find.text('Serves Objective 1.'), findsNothing);
    });

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

      await tester.tap(find.text('Sales'));
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
        areas: [area(summary: null, goal: null, planText: null)],
      );
      await tester.tap(find.text('Sales'));
      await tester.pump();

      expect(find.text('No goal yet'), findsOneWidget);
      expect(find.text('No plan yet'), findsOneWidget);
      expect(find.text('Nothing yet'), findsWidgets); // Tasks and Results
      expect(find.text('None yet'), findsOneWidget); // Decisions
    });

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
      await tester.tap(find.text('Sales'));
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
        // The Next line already surfaces this same open task at the top
        // of the tab (round-36 §2 b), so one copy is expected even before
        // "Not in an area" itself is opened.
        expect(find.text('c'), findsOneWidget);

        await tester.tap(find.text('Not in an area'));
        await tester.pump();
        expect(find.text('c'), findsNWidgets(2));
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
          'What this project is for: Grow the partner '
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

  group('round-36 §2 b — the Next line', () {
    Area area({
      String name = 'Sales',
      String sourceFile = 'plan/sales.md',
      List<Task> tasks = const [],
      String? goal,
    }) {
      return Area(
        name: name,
        sourceFile: sourceFile,
        goal: goal,
        tasks: tasks,
        results: const [],
        decisionNumbers: const [],
        objectiveNumbers: const [],
      );
    }

    testWidgets('a home task names no area chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [area()],
              decisions: const [],
              homeTasks: const [
                Task(rawLine: '- [ ] home', text: 'Home task', done: false),
              ],
              projectSourceFile: 'demo.md',
              projectName: 'Demo',
              projectFolder: 'C:/demo',
            ),
          ),
        ),
      );

      expect(find.text('Home task'), findsOneWidget);
      // The area's own row heading still shows "Sales" — just not a
      // second copy from the Next line's own area chip.
      expect(find.text('Sales'), findsOneWidget);
    });

    testWidgets('an open area task names its area as a small chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [
                area(
                  tasks: [
                    const Task(
                      rawLine: '- [ ] sales task',
                      text: 'Sales task',
                      done: false,
                    ),
                  ],
                ),
              ],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );

      expect(find.text('Sales task'), findsOneWidget);
      // One "Sales" from the area's own row heading, one from the Next
      // line's own area chip naming the same area.
      expect(find.text('Sales'), findsNWidgets(2));
    });

    testWidgets('no task and no typed field — honest "No next step"', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [area()],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );

      expect(find.text('No next step'), findsOneWidget);
    });

    testWidgets('tapping the Next line opens the area holding that task', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [
                area(
                  goal: 'Serves Objective 1.',
                  tasks: [
                    const Task(
                      rawLine: '- [ ] sales task',
                      text: 'Sales task',
                      done: false,
                    ),
                  ],
                ),
              ],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );

      // Collapsed: the area's own goal is not shown yet.
      expect(find.text('Serves Objective 1.'), findsNothing);

      await tester.tap(find.text('Sales task').first);
      await tester.pump();

      expect(find.text('Serves Objective 1.'), findsOneWidget);

      // The tap also arms the highlight timer (round-36 §3, L9) — flush it
      // rather than leave a pending Timer when the widget tree is torn down.
      await tester.pump(const Duration(seconds: 2));
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

    testWidgets('shows one chip per objective number the Goal names, tap '
        'switches to Strategy with that objective', (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [
                area(objectiveNumbers: const ['1']),
              ],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
              onOpenObjective: (n) => opened = n,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sales'));
      await tester.pump();

      expect(find.text('Objective 1'), findsOneWidget);
      await tester.tap(find.text('Objective 1'));
      expect(opened, '1');
    });

    testWidgets('no objective named at all shows no chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
              plan: const Plan(pages: []),
              areas: [area()],
              decisions: const [],
              homeTasks: const [],
              projectSourceFile: 'demo.md',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sales'));
      await tester.pump();

      expect(find.text('Objective 1'), findsNothing);
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanView(
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
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sales'));
      await tester.pump();
      await tester.tap(find.text('ADR 0003'));
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsOneWidget);
      expect(find.text('Deals go through the partner portal'), findsOneWidget);

      // Back returns to Plan, this same area still open.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(find.text('No goal yet'), findsOneWidget);
    });
  });
}
