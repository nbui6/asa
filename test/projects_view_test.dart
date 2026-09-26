// Round 32/C — the status pill can't break the row (ADR 0017). One real
// note had a whole paragraph as its status; this proves the pill clips
// instead of widening or wrapping the card.

import 'package:asa/core/area.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
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

Future<void> _pump(WidgetTester tester, List<ProjectNode> forest) async {
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
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
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
}
