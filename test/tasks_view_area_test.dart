// Round 34/E — area tasks in the Tasks view, grouped by area name.
// Round 37 §D1 flipped the order to match the Plan tab: areas first, the
// project's own home-note tasks ("Not in an area") last. Invented data
// throughout.

import 'package:asa/core/project.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = Project(
  name: 'Demo',
  status: 'building',
  milestone: '',
  nextStep: '',
  repoPath: '',
  updated: '2026-09-26',
  sourceFile: 'demo/demo.md',
);

void main() {
  Widget pumpTasksView(
    TaskGroup group, {
    Future<void> Function(String, Task)? onToggleAreaTask,
    void Function(ProjectOpenTarget)? onOpenProject,
    Map<String, String> folderBySlug = const {},
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TasksView(
          groups: [group],
          onToggleTask: (_, _) async {},
          onMarkAllDone: (_) async {},
          onToggleParked: (_, _) async {},
          onToggleAreaTask: onToggleAreaTask,
          onOpenProject: onOpenProject ?? (_) {},
          folderBySlug: folderBySlug,
        ),
      ),
    );
  }

  group('Round 34/E — area tasks group by area name', () {
    testWidgets("an area group shows before the project's own tasks, "
        'named in the sub-heading', (tester) async {
      const group = TaskGroup(
        project: _project,
        tasks: [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
        areaGroups: [
          AreaTaskGroup(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Sales task',
                text: 'Sales task',
                done: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(pumpTasksView(group));

      expect(find.text('Home task'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Sales task'), findsOneWidget);

      final homeY = tester.getTopLeft(find.text('Home task')).dy;
      final areaY = tester.getTopLeft(find.text('Sales task')).dy;
      expect(areaY, lessThan(homeY));
    });

    testWidgets('ticking an area task calls onToggleAreaTask with the '
        "area's own sourceFile, never the project's", (tester) async {
      String? calledSourceFile;
      const group = TaskGroup(
        project: _project,
        tasks: [],
        areaGroups: [
          AreaTaskGroup(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Sales task',
                text: 'Sales task',
                done: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        pumpTasksView(
          group,
          onToggleAreaTask: (sourceFile, _) async {
            calledSourceFile = sourceFile;
          },
        ),
      );

      await tester.tap(find.byType(Checkbox));

      expect(calledSourceFile, 'demo/plan/sales.md');
    });

    testWidgets('no parking icon on an area task — Round 34 F is checkbox '
        'state only', (tester) async {
      const group = TaskGroup(
        project: _project,
        tasks: [],
        areaGroups: [
          AreaTaskGroup(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Sales task',
                text: 'Sales task',
                done: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(pumpTasksView(group));

      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('a project with no areas shows no area heading at all', (
      tester,
    ) async {
      const group = TaskGroup(
        project: _project,
        tasks: [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
      );
      await tester.pumpWidget(pumpTasksView(group));

      expect(find.text('Home task'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '').isEmpty),
        findsNothing,
      );
    });
  });

  group("round-36 §3 — L5, L6, L7: the Tasks view's own links", () {
    testWidgets("L5 — the project's own group name opens its Plan tab", (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      const group = TaskGroup(
        project: _project,
        tasks: [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
      );
      await tester.pumpWidget(
        pumpTasksView(group, onOpenProject: (t) => opened = t),
      );

      await tester.tap(find.text('Demo'));

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, isNull);
    });

    testWidgets("L6 — an area's own sub-heading opens that one area", (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      const group = TaskGroup(
        project: _project,
        tasks: [],
        areaGroups: [
          AreaTaskGroup(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Sales task',
                text: 'Sales task',
                done: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        pumpTasksView(group, onOpenProject: (t) => opened = t),
      );

      await tester.tap(find.text('Sales'));

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, 'demo/plan/sales.md');
    });

    testWidgets('L7 — a resolvable [[project]] chip opens that project', (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      const group = TaskGroup(
        project: _project,
        tasks: [
          Task(
            rawLine: '- [ ] Depends on other — [[other-project]]',
            text: 'Depends on other',
            done: false,
            crossProjectRef: 'other-project',
          ),
        ],
      );
      await tester.pumpWidget(
        pumpTasksView(
          group,
          onOpenProject: (t) => opened = t,
          folderBySlug: const {'other-project': 'projects/other-project'},
        ),
      );

      await tester.tap(find.text('↳ other-project'));

      expect(opened?.folder, 'projects/other-project');
    });

    testWidgets('an unresolvable [[project]] chip stays inert — no crash, '
        'no navigation', (tester) async {
      var openedCount = 0;
      const group = TaskGroup(
        project: _project,
        tasks: [
          Task(
            rawLine: '- [ ] Depends on other — [[no-such-project]]',
            text: 'Depends on other',
            done: false,
            crossProjectRef: 'no-such-project',
          ),
        ],
      );
      await tester.pumpWidget(
        pumpTasksView(group, onOpenProject: (_) => openedCount++),
      );

      await tester.tap(find.text('↳ no-such-project'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(openedCount, 0);
    });
  });
}
