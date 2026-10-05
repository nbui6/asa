// Widget-level tests for "parked" — PLAN.md v0.3, "the rule of two".
// Invented data throughout: no real project has a (parked) tag yet.
//
// Round 42 — the parked bookmark icon is gone from the Tasks screen
// itself: `asa-tasks-v3.html` §2-§4 (approved) draws no such icon
// anywhere on the rebuilt screen, and ADR 0039's own scope (add, edit,
// reorder, move, indent) never names it either. The underlying feature
// is unchanged — `setTaskParked`, `Task.parked` and this file's own
// `ProjectsView` "N parked" badge below all still work; only the Tasks
// view's own row lost its icon, a real, sketch-driven omission named
// here rather than silently dropped.

import 'package:asa/core/project.dart';
import 'package:asa/core/project_create_writer.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectsView — the "N parked" badge', () {
    Widget pumpView(Project project) {
      return MaterialApp(
        home: Scaffold(
          body: ProjectsView(
            forest: [_nodeFor(project)],
            onOpenProject: (_) {},
            onAssignTask: (_, _) async {},
            onCreateProject: (_) async => const ProjectCreateResult(),
          ),
        ),
      );
    }

    testWidgets('no parked tasks — no badge at all', (tester) async {
      const project = Project(
        name: 'Demo',
        status: 'building',
        milestone: '',
        nextStep: '',
        repoPath: '',
        updated: '2026-09-13',
        sourceFile: 'demo/demo.md',
        tasks: [Task(rawLine: '- [ ] Open', text: 'Open', done: false)],
      );
      await tester.pumpWidget(pumpView(project));

      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('one parked task — the plain badge', (tester) async {
      const project = Project(
        name: 'Demo',
        status: 'building',
        milestone: '',
        nextStep: '',
        repoPath: '',
        updated: '2026-09-13',
        sourceFile: 'demo/demo.md',
        tasks: [
          Task(rawLine: '- [ ] One', text: 'One', done: false, parked: true),
        ],
      );
      await tester.pumpWidget(pumpView(project));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('two parked tasks — the rule of two, same badge shows 2', (
      tester,
    ) async {
      const project = Project(
        name: 'Demo',
        status: 'building',
        milestone: '',
        nextStep: '',
        repoPath: '',
        updated: '2026-09-13',
        sourceFile: 'demo/demo.md',
        tasks: [
          Task(rawLine: '- [ ] One', text: 'One', done: false, parked: true),
          Task(rawLine: '- [ ] Two', text: 'Two', done: false, parked: true),
        ],
      );
      await tester.pumpWidget(pumpView(project));

      expect(find.text('2'), findsOneWidget);
    });
  });
}

/// A `ProjectNode` with no children — enough to hand `ProjectsView` one
/// row without the full forest-building machinery.
ProjectNode _nodeFor(Project project) =>
    ProjectNode(project: project, folder: project.sourceFile);
