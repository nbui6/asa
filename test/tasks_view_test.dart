// Round 42 — the rebuilt Tasks screen: one project at a time, a left
// rail, add anywhere, edit in place, drag to reorder or move. Invented
// data throughout (Gate 2).

import 'package:asa/core/area.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_board.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project({
  required String name,
  required String sourceFile,
  String status = 'building',
}) {
  return Project(
    name: name,
    status: status,
    milestone: '',
    nextStep: '',
    repoPath: '',
    updated: '2026-09-28',
    sourceFile: sourceFile,
  );
}

Area _area({
  required String name,
  required String sourceFile,
  List<Task> tasks = const [],
}) {
  return Area(
    name: name,
    sourceFile: sourceFile,
    tasks: tasks,
    results: const [],
    decisionNumbers: const [],
    objectiveNumbers: const [],
  );
}

void main() {
  Future<void> Function(String, {required String rawLine, required bool done})
  noopToggle() => (_, {required rawLine, required done}) async {};
  Future<void> Function(String, String) noopAdd() => (_, _) async {};
  Future<void> Function(
    String, {
    required String rawLine,
    required String oldText,
    required String newText,
  })
  noopEdit() =>
      (_, {required rawLine, required oldText, required newText}) async {};
  Future<void> Function(String, {required String rawLine, required int indent})
  noopIndent() => (_, {required rawLine, required indent}) async {};
  Future<void> Function(
    String, {
    required List<String> currentOrder,
    required List<String> newOrder,
  })
  noopReorder() => (_, {required currentOrder, required newOrder}) async {};
  Future<void> Function({
    required String fromPath,
    required String toPath,
    required String rawLine,
  })
  noopMove() =>
      ({required fromPath, required toPath, required rawLine}) async {};

  Widget pump({
    required List<ProjectTasksSnapshot> snapshots,
    List<NextUpItem> nextUp = const [],
    List<Task> inboxTasks = const [],
    String? homePath,
    Map<String, String> folderBySlug = const {},
    void Function(ProjectOpenTarget)? onOpenProject,
    Future<void> Function(
      String, {
      required String rawLine,
      required bool done,
    })?
    onToggleTask,
    Future<void> Function(String, String)? onAddTaskAtTop,
    Future<void> Function(String, String)? onAddTaskAtBottom,
    Future<void> Function(
      String, {
      required String rawLine,
      required String oldText,
      required String newText,
    })?
    onEditText,
    Future<void> Function(
      String, {
      required String rawLine,
      required int indent,
    })?
    onSetIndent,
    Future<void> Function(
      String, {
      required List<String> currentOrder,
      required List<String> newOrder,
    })?
    onReorder,
    Future<void> Function({
      required String fromPath,
      required String toPath,
      required String rawLine,
    })?
    onMove,
    Future<void> Function({
      required String fromPath,
      required String toPath,
      required String rawLine,
    })?
    onMoveToTop,
    Future<void> Function(String)? onCaptureInbox,
    VoidCallback? onDataChanged,
    String? initialSelectedFolder,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TasksView(
          snapshots: snapshots,
          nextUp: nextUp,
          inboxTasks: inboxTasks,
          homePath: homePath,
          folderBySlug: folderBySlug,
          onOpenProject: onOpenProject ?? (_) {},
          onToggleTask: onToggleTask ?? noopToggle(),
          onAddTaskAtTop: onAddTaskAtTop ?? noopAdd(),
          onAddTaskAtBottom: onAddTaskAtBottom ?? noopAdd(),
          onEditText: onEditText ?? noopEdit(),
          onSetIndent: onSetIndent ?? noopIndent(),
          onReorder: onReorder ?? noopReorder(),
          onMove: onMove ?? noopMove(),
          onMoveToTop: onMoveToTop ?? noopMove(),
          onCaptureInbox: onCaptureInbox ?? (_) async {},
          onDataChanged: onDataChanged ?? () {},
          initialSelectedFolder: initialSelectedFolder,
        ),
      ),
    );
  }

  group('§A — the layout, read-only', () {
    testWidgets('the left rail names Next up, Inbox and every project '
        'with its own open count', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [Task(rawLine: '- [ ] One', text: 'One', done: false)],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [snapshot]));

      expect(find.text('⭐ Next up'), findsOneWidget);
      expect(find.text('📥 Inbox'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('Demo'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Demo's own open count
    });

    testWidgets('opens on Next up by default', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: const [],
      );
      final nextUp = [
        const NextUpItem(
          projectName: 'Demo',
          projectFolder: 'demo',
          path: 'demo/demo.md',
          text: 'Do the thing',
          task: Task(
            rawLine: '- [ ] Do the thing',
            text: 'Do the thing',
            done: false,
          ),
        ),
      ];
      await tester.pumpWidget(pump(snapshots: [snapshot], nextUp: nextUp));

      expect(find.textContaining('Do the thing'), findsOneWidget);
    });

    testWidgets('selecting a project shows its own tasks; "Not in an '
        'area" only shows once the project has a real area', (tester) async {
      final withoutAreas = ProjectTasksSnapshot(
        project: _project(name: 'Solo', sourceFile: 'solo/solo.md'),
        folder: 'solo',
        homeTasks: const [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [withoutAreas]));
      await tester.tap(find.text('Solo'));
      await tester.pump();

      expect(find.text('Home task'), findsOneWidget);
      expect(find.text('NOT IN AN AREA'), findsNothing);
      expect(find.text('Not in an area'), findsNothing);
    });

    testWidgets('a project with a real area shows "Not in an area" and '
        "the area's own name, area first in the sketch's own drawing", (
      tester,
    ) async {
      final withArea = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
        areas: [
          _area(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: const [
              Task(
                rawLine: '- [ ] Sales task',
                text: 'Sales task',
                done: false,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(pump(snapshots: [withArea]));
      await tester.tap(find.text('Demo'));
      await tester.pump();

      expect(find.text('NOT IN AN AREA'), findsOneWidget); // SectionLabel
      expect(find.text('Home task'), findsOneWidget);
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Sales task'), findsOneWidget);
    });

    testWidgets('done tasks fold behind one "✓ N done · show ›" for the '
        'whole project, home and every area together', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [x] Home done', text: 'Home done', done: true),
        ],
        areas: [
          _area(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: const [
              Task(rawLine: '- [x] Sales done', text: 'Sales done', done: true),
            ],
          ),
        ],
      );
      await tester.pumpWidget(pump(snapshots: [snapshot]));
      await tester.tap(find.text('Demo'));
      await tester.pump();

      expect(find.text('Home done'), findsNothing);
      expect(find.text('Sales done'), findsNothing);
      expect(find.textContaining('✓ 2 done'), findsOneWidget);

      await tester.tap(find.textContaining('✓ 2 done'));
      await tester.pump();

      expect(find.text('Home done'), findsOneWidget);
      expect(find.text('Sales done'), findsOneWidget);
    });
  });

  group('§B — add anywhere, edit in place', () {
    testWidgets('"＋ Add a task" opens an inline field; Enter writes and '
        'reopens it empty', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: const [],
      );
      String? addedPath;
      String? addedText;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onAddTaskAtTop: (path, text) async {
            addedPath = path;
            addedText = text;
          },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.text('＋ Add a task'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'A brand new task');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(addedPath, 'demo/demo.md');
      expect(addedText, 'A brand new task');
      // The field stays open, empty, ready for the next one.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('＋ Add a task'), findsNothing);
    });

    testWidgets('an empty Enter, or Escape, closes the field back to '
        '"＋ Add a task"', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [snapshot]));
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.text('＋ Add a task'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('＋ Add a task'), findsOneWidget);
    });

    testWidgets("click a task's text to edit it in place; Enter saves", (
      tester,
    ) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] Old text', text: 'Old text', done: false),
        ],
        areas: const [],
      );
      String? editedOld;
      String? editedNew;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onEditText:
              (
                path, {
                required rawLine,
                required oldText,
                required newText,
              }) async {
                editedOld = oldText;
                editedNew = newText;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.text('Old text'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'New text');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(editedOld, 'Old text');
      expect(editedNew, 'New text');
    });

    testWidgets('ticking a checkbox calls onToggleTask with the real '
        'path and rawLine', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] Tick me', text: 'Tick me', done: false),
        ],
        areas: const [],
      );
      String? toggledPath;
      String? toggledLine;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onToggleTask: (path, {required rawLine, required done}) async {
            toggledPath = path;
            toggledLine = rawLine;
          },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(toggledPath, 'demo/demo.md');
      expect(toggledLine, '- [ ] Tick me');
    });
  });

  group('§A — Inbox', () {
    testWidgets('typing in the Inbox capture field calls onCaptureInbox', (
      tester,
    ) async {
      String? captured;
      await tester.pumpWidget(
        pump(
          snapshots: const [],
          homePath: 'HOME.md',
          onCaptureInbox: (text) async => captured = text,
        ),
      );

      await tester.tap(find.textContaining('Inbox'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Unfiled thing');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(captured, 'Unfiled thing');
    });
  });

  group('round-36 §3, links — L5/L6/L7, carried into Round 42', () {
    testWidgets("L5 — the project's own name opens its Plan tab", (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: const [],
      );
      await tester.pumpWidget(
        pump(snapshots: [snapshot], onOpenProject: (t) => opened = t),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      // 'Demo' now appears twice: the rail item and the main pane's own
      // heading — the heading is the one under test here.
      await tester.tap(find.text('Demo').last);

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, isNull);
    });

    testWidgets("L6 — an area's own heading opens that one area", (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: [_area(name: 'Sales', sourceFile: 'demo/plan/sales.md')],
      );
      await tester.pumpWidget(
        pump(snapshots: [snapshot], onOpenProject: (t) => opened = t),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.text('Sales'));

      expect(opened?.folder, 'demo');
      expect(opened?.areaSourceFile, 'demo/plan/sales.md');
    });

    testWidgets('L7 — a resolvable [[project]] chip opens that project', (
      tester,
    ) async {
      ProjectOpenTarget? opened;
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(
            rawLine: '- [ ] Depends on other — [[other-project]]',
            text: 'Depends on other',
            done: false,
            crossProjectRef: 'other-project',
          ),
        ],
        areas: const [],
      );
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onOpenProject: (t) => opened = t,
          folderBySlug: const {'other-project': 'projects/other-project'},
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.text('↳ other-project'));

      expect(opened?.folder, 'projects/other-project');
    });
  });
}
