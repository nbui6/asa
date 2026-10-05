// Invented phases throughout — Gate 2: no real project has a ### heading
// in its ## Roadmap yet.

import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_create_writer.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:asa/hubs/product/ui/phase_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyGit = GitState(command: '', rawOutput: '');

const _foundation = [
  Milestone(title: 'Round 0', done: true, phase: 'Foundation'),
  Milestone(title: 'Round 1', done: true, phase: 'Foundation'),
  Milestone(title: 'Round 2', done: false, phase: 'Foundation'),
];
const _everyday = [
  Milestone(title: 'Round 3', done: false, phase: 'Everyday features'),
  Milestone(title: 'Round 4', done: false, phase: 'Everyday features'),
];
const _phases = [
  Phase(name: 'Foundation', milestones: _foundation),
  Phase(name: 'Everyday features', milestones: _everyday),
];

void main() {
  group('PhaseBar', () {
    testWidgets('shows one segment and one label per phase, in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhaseBar(phases: _phases)),
        ),
      );

      expect(find.text('Foundation'), findsOneWidget);
      expect(find.text('Everyday features'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is FractionallySizedBox),
        findsNWidgets(2),
      );
    });

    testWidgets("a segment's fill fraction is doneCount over totalCount", (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhaseBar(phases: _phases)),
        ),
      );

      final boxes = tester
          .widgetList<FractionallySizedBox>(
            find.byWidgetPredicate((w) => w is FractionallySizedBox),
          )
          .toList();

      expect(boxes[0].widthFactor, closeTo(2 / 3, 0.0001));
      expect(boxes[1].widthFactor, 0);
    });

    testWidgets('a finished phase (doneCount == totalCount) fills fully', (
      tester,
    ) async {
      const allDone = [
        Phase(
          name: 'Done phase',
          milestones: [
            Milestone(title: 'Round 0', done: true, phase: 'Done phase'),
          ],
        ),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PhaseBar(phases: allDone)),
        ),
      );

      final box = tester.widget<FractionallySizedBox>(
        find.byWidgetPredicate((w) => w is FractionallySizedBox),
      );
      expect(box.widthFactor, 1);
    });
  });

  group('ProjectsView — the bar only shows up when there is one', () {
    ProjectSummary summary({
      required String folder,
      required String name,
      List<Milestone> roadmap = const [],
    }) {
      return ProjectSummary(
        project: Project(
          name: name,
          status: 'in progress',
          milestone: '',
          nextStep: '',
          repoPath: '',
          updated: '2026-09-13',
          sourceFile: '$folder/$name.md',
          roadmap: roadmap,
        ),
        git: _emptyGit,
        folder: folder,
      );
    }

    Widget pumpView(List<ProjectSummary> projects) {
      return MaterialApp(
        home: Scaffold(
          body: ProjectsView(
            forest: buildProjectForest(projects),
            onOpenProject: (_) {},
            onAssignTask: (_, _) async {},
            onCreateProject: (_) async => const ProjectCreateResult(),
          ),
        ),
      );
    }

    testWidgets('a project with a flat roadmap (no ### heading) — every real '
        "project's shape today — shows no bar at all", (tester) async {
      const flatRoadmap = [
        Milestone(title: 'Round 0', done: true),
        Milestone(title: 'Round 1', done: false),
      ];
      await tester.pumpWidget(
        pumpView([summary(folder: 'flat', name: 'flat', roadmap: flatRoadmap)]),
      );

      expect(find.byType(PhaseBar), findsNothing);
    });

    testWidgets('a project with no roadmap at all also shows no bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpView([summary(folder: 'bare', name: 'bare')]),
      );

      expect(find.byType(PhaseBar), findsNothing);
    });

    testWidgets('a project whose roadmap has ### phases shows the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpView([
          summary(folder: 'grouped', name: 'grouped', roadmap: _foundation),
        ]),
      );

      expect(find.byType(PhaseBar), findsOneWidget);
      expect(find.text('Foundation'), findsOneWidget);
    });
  });
}
