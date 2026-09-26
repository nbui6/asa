// Widget-level tests for "parked" — PLAN.md v0.3, "the rule of two".
// Invented data throughout: no real project has a (parked) tag yet.

import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = Project(
  name: 'Demo',
  status: 'building',
  milestone: '',
  nextStep: '',
  repoPath: '',
  updated: '2026-09-13',
  sourceFile: 'demo/demo.md',
);

void main() {
  group('TasksView — the parked toggle', () {
    Widget pumpTasksView(List<Task> tasks) {
      return MaterialApp(
        home: Scaffold(
          body: TasksView(
            groups: [TaskGroup(project: _project, tasks: tasks)],
            onToggleTask: (_, _) async {},
            onMarkAllDone: (_) async {},
            onToggleParked: (_, _) async {},
            onOpenProject: (_) {},
            folderBySlug: const {},
          ),
        ),
      );
    }

    testWidgets('an open task shows the outline bookmark icon', (tester) async {
      const task = Task(rawLine: '- [ ] Do it', text: 'Do it', done: false);
      await tester.pumpWidget(pumpTasksView([task]));

      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('a parked task shows the filled bookmark icon instead', (
      tester,
    ) async {
      const task = Task(
        rawLine: '- [ ] Do it (parked)',
        text: 'Do it',
        done: false,
        parked: true,
      );
      await tester.pumpWidget(pumpTasksView([task]));

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('tapping the bookmark calls onToggleParked with that task', (
      tester,
    ) async {
      const task = Task(rawLine: '- [ ] Do it', text: 'Do it', done: false);
      Task? toggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasksView(
              groups: const [
                TaskGroup(project: _project, tasks: [task]),
              ],
              onToggleTask: (_, _) async {},
              onMarkAllDone: (_) async {},
              onToggleParked: (_, t) async => toggled = t,
              onOpenProject: (_) {},
              folderBySlug: const {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();

      expect(toggled, isNotNull);
      expect(toggled!.rawLine, task.rawLine);
    });
  });

  group('ProjectsView — the "N parked" badge', () {
    Widget pumpView(Project project) {
      return MaterialApp(
        home: Scaffold(
          body: ProjectsView(
            forest: [_nodeFor(project)],
            onOpenProject: (_) {},
            onAssignTask: (_, _) async {},
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
