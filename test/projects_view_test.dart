// Round 32/C — the status pill can't break the row (ADR 0017). One real
// note had a whole paragraph as its status; this proves the pill clips
// instead of widening or wrapping the card.

import 'package:asa/core/area.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_news.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project({required String status}) {
  return Project(
    name: 'Demo',
    status: status,
    milestone: '',
    nextStep: '',
    repoPath: '',
    updated: '2026-09-25',
    sourceFile: 'demo/demo.md',
  );
}

const _emptyGit = GitState(command: '', rawOutput: '');

Future<void> _pump(
  WidgetTester tester,
  List<ProjectNode> forest, {
  void Function(ProjectOpenTarget target)? onOpenProject,
  Map<String, ProjectNews> news = const {},
  List<ProjectSummary> hidden = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectsView(
          forest: forest,
          onOpenProject: onOpenProject ?? (_) {},
          onAssignTask: (_, _) async {},
          news: news,
          hidden: hidden,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a whole-paragraph status clips to one line, never wraps or overflows',
    (tester) async {
      const longStatus =
          'This is a whole paragraph masquerading as a status value, the '
          'exact real shape found in one project note before this round, '
          'long enough that an unbounded pill would widen or wrap the '
          'entire row rather than stay a small pill next to the others.';
      final node = ProjectNode(
        project: _project(status: longStatus),
        folder: 'demo',
      );

      await _pump(tester, [node]);

      expect(tester.takeException(), isNull);

      final pillText = tester.widget<Text>(find.text(longStatus));
      expect(pillText.maxLines, 1);
      expect(pillText.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets('an unrecognized status word still renders, neutral emphasis', (
    tester,
  ) async {
    final node = ProjectNode(
      project: _project(status: 'archived'),
      folder: 'demo',
    );

    await _pump(tester, [node]);

    expect(tester.takeException(), isNull);
    expect(find.text('archived'), findsOneWidget);
  });

  testWidgets('every ADR 0017 word renders without throwing', (tester) async {
    for (final status in [
      'idea',
      'discovery-done',
      'building',
      'shipped',
      'ongoing',
      'paused',
      'dropped',
    ]) {
      final node = ProjectNode(
        project: _project(status: status),
        folder: 'demo',
      );
      await _pump(tester, [node]);
      expect(tester.takeException(), isNull, reason: status);
      expect(find.text(status), findsOneWidget);
    }
  });

  testWidgets(
    'Round 33/E — a child and a grandchild of a work-bucket project both '
    'render, not just the root',
    (tester) async {
      Project named(String name) => Project(
        name: name,
        status: 'building',
        milestone: '',
        nextStep: '',
        repoPath: '',
        updated: '2026-09-25',
        sourceFile: '$name/$name.md',
      );

      final grandchild = ProjectNode(
        project: named('Grandchild'),
        folder: 'grandchild',
      );
      final child = ProjectNode(
        project: named('Child'),
        folder: 'child',
        children: [grandchild],
      );
      final root = ProjectNode(
        project: named('Parent'),
        folder: 'parent',
        children: [child],
      );

      await _pump(tester, [root]);

      expect(tester.takeException(), isNull);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
      expect(find.text('Grandchild'), findsOneWidget);
    },
  );

  testWidgets("Round 33/E, cp0's own done-when: every scanned project appears "
      'exactly once, work bucket and Other alike', (tester) async {
    const git = GitState(command: '', rawOutput: '');
    ProjectSummary summary({
      required String folder,
      required String name,
      String? parent,
    }) {
      return ProjectSummary(
        project: Project(
          name: name,
          status: 'building',
          milestone: '',
          nextStep: '',
          repoPath: '',
          updated: '2026-09-25',
          sourceFile: '$folder/$name.md',
          parent: parent,
        ),
        git: git,
        folder: folder,
      );
    }

    final scanned = [
      summary(folder: 'work-root', name: 'Work root'),
      summary(folder: 'work-child', name: 'Work child', parent: 'work-root'),
      summary(folder: 'other', name: 'Other project'),
      summary(folder: 'asa-like', name: 'Asa-like', parent: 'other'),
      summary(
        folder: 'kit-like',
        name: 'Kit-like',
        parent: 'asa-like',
      ), // Other's grandchild — the real vibe-coding-kit shape.
    ];
    final forest = buildProjectForest(scanned);
    final split = splitByBucket(forest);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectsView(
            forest: forest,
            onOpenProject: (_) {},
            onAssignTask: (_, _) async {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Work root'), findsOneWidget);
    expect(find.text('Work child'), findsOneWidget);
    // Other's own subtree is collapsed by default — expand it first,
    // same as a person would, rather than assert on hidden widgets.
    expect(find.text('Other project'), findsOneWidget);
    await tester.tap(find.text('Other project'));
    await tester.pumpAndSettle();
    expect(find.text('Asa-like'), findsOneWidget);
    expect(find.text('Kit-like'), findsOneWidget);

    // Every one of the 5 scanned projects is a root or nested exactly
    // once — never both a root and someone's child at the same time.
    expect(split.work.length, 1);
    expect(countDescendants(split.other!), 2);

    // Round 35/G — the summary line asa-front2 draws and the build
    // dropped: N projects, split work vs. not-work, counting a subtree
    // (child + grandchild) as part of its own root's side of the split.
    expect(find.text('5 projects · 2 work · 3 not work'), findsOneWidget);
  });

  group('round-36 §2 f — the overview reads areas too', () {
    testWidgets('one bar segment per area, in place of the phase bar', (
      tester,
    ) async {
      final node = ProjectNode(
        project: _project(status: 'building'),
        folder: 'demo',
        areas: const [
          Area(
            name: 'Sales',
            sourceFile: 'plan/sales.md',
            tasks: [
              Task(rawLine: '- [x] a', text: 'a', done: true),
              Task(rawLine: '- [ ] b', text: 'b', done: false),
            ],
            results: [],
            decisionNumbers: [],
            objectiveNumbers: [],
          ),
          Area(
            name: 'Finance',
            sourceFile: 'plan/finance.md',
            tasks: [],
            results: [],
            decisionNumbers: [],
            objectiveNumbers: [],
          ),
        ],
      );

      await _pump(tester, [node]);

      expect(tester.takeException(), isNull);
      // "Sales 1/2" — asa-areas-everywhere-v1's own segment label pairs
      // the area's name with its own fraction.
      expect(find.text('Sales 1/2'), findsOneWidget);
      expect(find.text('Finance 0/0'), findsOneWidget);
    });

    testWidgets("the row's own next step falls further to an area's open task, "
        'same chain the Plan tab already uses', (tester) async {
      final node = ProjectNode(
        project: _project(status: 'building'),
        folder: 'demo',
        areas: const [
          Area(
            name: 'Sales',
            sourceFile: 'plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Sales next task',
                text: 'Sales next task',
                done: false,
              ),
            ],
            results: [],
            decisionNumbers: [],
            objectiveNumbers: [],
          ),
        ],
      );

      await _pump(tester, [node]);

      expect(find.text('Sales next task'), findsOneWidget);
    });
  });

  group("round-36 §3 — L1, L2, L3: the overview's own links", () {
    testWidgets('L1 — a plain row tap builds a bare target, just the folder', (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      final node = ProjectNode(
        project: _project(status: 'building'),
        folder: 'demo',
      );

      await _pump(tester, [node], onOpenProject: (t) => opened = t);
      await tester.tap(find.text('Demo'));

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, isNull);
      expect(opened?.openHome, isFalse);
      expect(opened?.highlightRawLine, isNull);
    });

    testWidgets("L2 — an area's bar segment opens that one area", (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      const area = Area(
        name: 'Sales',
        sourceFile: 'plan/sales.md',
        tasks: [],
        results: [],
        decisionNumbers: [],
        objectiveNumbers: [],
      );
      final node = ProjectNode(
        project: _project(status: 'building'),
        folder: 'demo',
        areas: const [area],
      );

      await _pump(tester, [node], onOpenProject: (t) => opened = t);
      await tester.tap(find.text('Sales 0/0'));

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, 'plan/sales.md');
    });

    testWidgets('L3 — the next step text opens the area holding that '
        'task, and highlights it', (tester) async {
      ProjectOpenTarget? opened;
      const task = Task(
        rawLine: '- [ ] Sales next task',
        text: 'Sales next task',
        done: false,
      );
      const area = Area(
        name: 'Sales',
        sourceFile: 'plan/sales.md',
        tasks: [task],
        results: [],
        decisionNumbers: [],
        objectiveNumbers: [],
      );
      final node = ProjectNode(
        project: _project(status: 'building'),
        folder: 'demo',
        areas: const [area],
      );

      await _pump(tester, [node], onOpenProject: (t) => opened = t);
      await tester.tap(find.text('Sales next task'));

      expect(opened?.areaSourceFile, 'plan/sales.md');
      expect(opened?.openHome, isFalse);
      expect(opened?.highlightRawLine, task.rawLine);
    });

    testWidgets('L3 — a home task with no area opens "Not in an area" '
        'instead', (tester) async {
      ProjectOpenTarget? opened;
      const task = Task(
        rawLine: '- [ ] Home task',
        text: 'Home task',
        done: false,
      );
      const node = ProjectNode(
        project: Project(
          name: 'Demo',
          status: 'building',
          milestone: '',
          nextStep: '',
          repoPath: '',
          updated: '2026-09-25',
          sourceFile: 'demo/demo.md',
          tasks: [task],
        ),
        folder: 'demo',
      );

      await _pump(tester, [node], onOpenProject: (t) => opened = t);
      await tester.tap(find.text('Home task'));

      expect(opened?.areaSourceFile, isNull);
      expect(opened?.openHome, isTrue);
      expect(opened?.highlightRawLine, task.rawLine);
    });
  });

  group("Round 38 §E — the overview's own news markers", () {
    testWidgets('a project with new entries shows a blue "N new"', (
      tester,
    ) async {
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );

      await _pump(
        tester,
        [node],
        news: const {
          'demo': ProjectNews(newCount: 3, hasUnloggedChange: false),
        },
      );

      expect(find.text('3 new'), findsOneWidget);
    });

    testWidgets(
      'an unlogged change shows amber "changed without a note" instead, '
      'even when there is also new activity',
      (tester) async {
        final node = ProjectNode(
          project: _project(status: 'in-progress'),
          folder: 'demo',
        );

        await _pump(
          tester,
          [node],
          news: const {
            'demo': ProjectNews(newCount: 2, hasUnloggedChange: true),
          },
        );

        expect(find.text('changed without a note'), findsOneWidget);
        expect(find.text('2 new'), findsNothing);
      },
    );

    testWidgets('a project with no news shows no marker at all', (
      tester,
    ) async {
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );

      await _pump(tester, [node]);

      expect(find.text('changed without a note'), findsNothing);
      expect(find.textContaining(' new'), findsNothing);
    });

    testWidgets(
      'L25 — clicking the marker opens the project on its Log, not just '
      'the row default',
      (tester) async {
        ProjectOpenTarget? opened;
        final node = ProjectNode(
          project: _project(status: 'in-progress'),
          folder: 'demo',
        );

        await _pump(
          tester,
          [node],
          onOpenProject: (target) => opened = target,
          news: const {
            'demo': ProjectNews(newCount: 3, hasUnloggedChange: false),
          },
        );

        await tester.tap(find.text('3 new'));

        expect(opened?.folder, 'demo');
        expect(opened?.openLog, isTrue);
      },
    );
  });

  group('Round 38 §F, ADR 0036 — the hidden line', () {
    ProjectSummary hiddenSummary({
      required String name,
      required String status,
      required String folder,
      String updated = '2026-09-01',
    }) {
      return ProjectSummary(
        project: Project(
          name: name,
          status: status,
          milestone: '',
          nextStep: '',
          repoPath: '',
          updated: updated,
          sourceFile: '$folder/$folder.md',
        ),
        git: _emptyGit,
        folder: folder,
      );
    }

    testWidgets('no hidden line at all when nothing is hidden', (
      tester,
    ) async {
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );
      await _pump(tester, [node]);

      expect(find.textContaining('show ›'), findsNothing);
    });

    testWidgets('folded by default: "On hold N · Done N · Canceled N · '
        'show ›", one project each', (tester) async {
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );
      await _pump(
        tester,
        [node],
        hidden: [
          hiddenSummary(name: 'Paused', status: 'on-hold', folder: 'paused'),
          hiddenSummary(name: 'Finished', status: 'done', folder: 'finished'),
          hiddenSummary(name: 'Dropped', status: 'canceled', folder: 'dropped'),
        ],
      );

      expect(
        find.textContaining('On hold 1 · Done 1 · Canceled 1'),
        findsOneWidget,
      );
      expect(find.text('Paused'), findsNothing);
      expect(find.text('Finished'), findsNothing);
      expect(find.text('Dropped'), findsNothing);
    });

    testWidgets('only the statuses actually present are named — one '
        'on-hold project shows only "On hold 1"', (tester) async {
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );
      await _pump(
        tester,
        [node],
        hidden: [
          hiddenSummary(name: 'Paused', status: 'on-hold', folder: 'paused'),
        ],
      );

      expect(find.textContaining('On hold 1'), findsOneWidget);
      expect(find.textContaining('Done'), findsNothing);
      expect(find.textContaining('Canceled'), findsNothing);
    });

    testWidgets('tapping "show ›" opens one group per status, newest '
        'first by updated:, and a row opens the whole project', (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      final node = ProjectNode(
        project: _project(status: 'in-progress'),
        folder: 'demo',
      );
      await _pump(
        tester,
        [node],
        onOpenProject: (target) => opened = target,
        hidden: [
          hiddenSummary(
            name: 'Older hold',
            status: 'on-hold',
            folder: 'older-hold',
            updated: '2026-08-01',
          ),
          hiddenSummary(
            name: 'Newer hold',
            status: 'on-hold',
            folder: 'newer-hold',
            updated: '2026-09-20',
          ),
          hiddenSummary(name: 'Finished', status: 'done', folder: 'finished'),
        ],
      );

      await tester.tap(find.textContaining('show ›'));
      await tester.pump();

      expect(find.text('Older hold'), findsOneWidget);
      expect(find.text('Newer hold'), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);

      final onHoldY = tester.getTopLeft(find.text('Newer hold')).dy;
      final olderY = tester.getTopLeft(find.text('Older hold')).dy;
      expect(onHoldY, lessThan(olderY));

      await tester.tap(find.text('Finished'));
      expect(opened?.folder, 'finished');
    });
  });
}
