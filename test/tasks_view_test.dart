// Round 42 — the rebuilt Tasks screen: one project at a time, a left
// rail, add anywhere, edit in place, drag to reorder or move. Invented
// data throughout (Gate 2).

import 'package:asa/core/area.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_board.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Future<void> Function({
      required String path,
      required String taskText,
      required String text,
      ResultLink? link,
    })?
    onWriteResult,
    Future<void> Function({
      required String projectFolder,
      required String decisionText,
      String? area,
      List<String> objectives,
      String? taskText,
      ResultLink? link,
    })?
    onCreateDecision,
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
          onWriteResult:
              onWriteResult ??
              ({
                required path,
                required taskText,
                required text,
                link,
              }) async {},
          onCreateDecision:
              onCreateDecision ??
              ({
                required projectFolder,
                required decisionText,
                area,
                objectives = const [],
                taskText,
                link,
              }) async {},
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

    testWidgets('round 42 §B — the Code-tasks filter menu hides (Code) tasks '
        'everywhere by default is on, off hides them', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] Human task', text: 'Human task', done: false),
          Task(
            rawLine: '- [ ] Robot task (Code)',
            text: 'Robot task',
            done: false,
            isCode: true,
          ),
        ],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [snapshot]));
      await tester.tap(find.text('Demo'));
      await tester.pump();

      // Shown by default, same as the old per-screen switch.
      expect(find.text('Robot task'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Code tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Robot task'), findsNothing);
      expect(find.text('Human task'), findsOneWidget);
    });
  });

  group('§B — drag ⋮⋮ (round-42.md\'s own Tests bullet: "widget tests for '
      '... drag targets")', () {
    testWidgets(
      'dragging a later task onto an earlier one reorders, via onReorder',
      (tester) async {
        final snapshot = ProjectTasksSnapshot(
          project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
          folder: 'demo',
          homeTasks: const [
            Task(rawLine: '- [ ] First', text: 'First', done: false),
            Task(rawLine: '- [ ] Second', text: 'Second', done: false),
          ],
          areas: const [],
        );
        List<String>? capturedCurrent;
        List<String>? capturedNew;
        await tester.pumpWidget(
          pump(
            snapshots: [snapshot],
            onReorder:
                (
                  path, {
                  required List<String> currentOrder,
                  required List<String> newOrder,
                }) async {
                  capturedCurrent = currentOrder;
                  capturedNew = newOrder;
                },
          ),
        );
        await tester.tap(find.text('Demo'));
        await tester.pump();

        final from = tester.getCenter(find.text('Second'));
        final to = tester.getCenter(find.text('First'));
        final gesture = await tester.startGesture(from);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(to);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(capturedCurrent, ['- [ ] First', '- [ ] Second']);
        expect(capturedNew, ['- [ ] Second', '- [ ] First']);
      },
    );

    testWidgets(
      'dragging a task onto another project in the rail moves it there, '
      'via onMoveToTop',
      (tester) async {
        final demo = ProjectTasksSnapshot(
          project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
          folder: 'demo',
          homeTasks: const [
            Task(rawLine: '- [ ] Move me', text: 'Move me', done: false),
          ],
          areas: const [],
        );
        final other = ProjectTasksSnapshot(
          project: _project(name: 'Other', sourceFile: 'other/other.md'),
          folder: 'other',
          homeTasks: const [],
          areas: const [],
        );
        String? capturedFrom;
        String? capturedTo;
        String? capturedLine;
        await tester.pumpWidget(
          pump(
            snapshots: [demo, other],
            onMoveToTop:
                ({
                  required String fromPath,
                  required String toPath,
                  required String rawLine,
                }) async {
                  capturedFrom = fromPath;
                  capturedTo = toPath;
                  capturedLine = rawLine;
                },
          ),
        );
        await tester.tap(find.text('Demo'));
        await tester.pump();

        final from = tester.getCenter(find.text('Move me'));
        final to = tester.getCenter(find.text('Other'));
        final gesture = await tester.startGesture(from);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.moveTo(to);
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(capturedFrom, 'demo/demo.md');
        expect(capturedTo, 'other/other.md');
        expect(capturedLine, '- [ ] Move me');
      },
    );
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

  group('Round 43 §A — ticking a task opens a Result/Decision line', () {
    testWidgets('ticking a home task opens a Result line; Enter writes '
        'via onWriteResult, naming the task', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(
            rawLine: '- [ ] Ask legal a question',
            text: 'Ask legal a question',
            done: false,
          ),
        ],
        areas: const [],
      );
      String? writtenPath;
      String? writtenTask;
      String? writtenText;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onWriteResult:
              ({required path, required taskText, required text, link}) async {
                writtenPath = path;
                writtenTask = taskText;
                writtenText = text;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('Result'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'It works now');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenPath, 'demo/demo.md');
      expect(writtenTask, 'Ask legal a question');
      expect(writtenText, 'It works now');
      expect(find.text('Result'), findsNothing); // closed after writing
    });

    testWidgets("ticking a task in an area writes into that area's own "
        'file, with its area name and objectives, when it starts with '
        '"Decide"', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [],
        areas: [
          const Area(
            name: 'Sales',
            sourceFile: 'demo/plan/sales.md',
            tasks: [
              Task(
                rawLine: '- [ ] Decide the pricing model',
                text: 'Decide the pricing model',
                done: false,
              ),
            ],
            results: [],
            decisionNumbers: [],
            objectiveNumbers: ['2'],
          ),
        ],
      );
      String? writtenProjectFolder;
      String? writtenDecisionText;
      String? writtenArea;
      List<String>? writtenObjectives;
      String? writtenTaskText;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onCreateDecision:
              ({
                required projectFolder,
                required decisionText,
                area,
                objectives = const [],
                taskText,
                link,
              }) async {
                writtenProjectFolder = projectFolder;
                writtenDecisionText = decisionText;
                writtenArea = area;
                writtenObjectives = objectives;
                writtenTaskText = taskText;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('Decision'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Flat fee it is');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenProjectFolder, 'demo');
      expect(writtenDecisionText, 'Flat fee it is');
      expect(writtenArea, 'Sales');
      expect(writtenObjectives, ['2']);
      expect(writtenTaskText, 'Decide the pricing model');
    });

    testWidgets('Esc closes the line without writing', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] A task', text: 'A task', done: false),
        ],
        areas: const [],
      );
      var written = false;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onWriteResult:
              ({required path, required taskText, required text, link}) async {
                written = true;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('Result'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Ignored');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Result'), findsNothing);
      expect(written, isFalse);
    });

    testWidgets('ticking a different task closes the first prompt, '
        'without writing — at most one open', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] First', text: 'First', done: false),
          Task(rawLine: '- [ ] Second', text: 'Second', done: false),
        ],
        areas: const [],
      );
      var writeCount = 0;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onWriteResult:
              ({required path, required taskText, required text, link}) async {
                writeCount++;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      expect(find.text('Result'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();

      expect(find.text('Result'), findsOneWidget); // still exactly one
      expect(writeCount, 0);
    });

    testWidgets('un-ticking closes its own open prompt without writing', (
      tester,
    ) async {
      final notDone = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] A task', text: 'A task', done: false),
        ],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [notDone]));
      await tester.tap(find.text('Demo'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(find.text('Result'), findsOneWidget);

      // A real tick's own write would land on disk and reload with the
      // task now done — simulated here by re-pumping with that same
      // task, done, since this widget only ever renders what it's given.
      final nowDone = ProjectTasksSnapshot(
        project: notDone.project,
        folder: notDone.folder,
        homeTasks: const [
          Task(rawLine: '- [x] A task', text: 'A task', done: true),
        ],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [nowDone]));
      await tester.pump();
      // Now the only task in the list, done and folded — expand to reach
      // its checkbox again.
      await tester.tap(find.textContaining('done'));
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('Result'), findsNothing);
    });

    testWidgets('📎 reveals a link field; a plain path becomes a label '
        'from its own last segment', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] A task', text: 'A task', done: false),
        ],
        areas: const [],
      );
      ResultLink? capturedLink;
      await tester.pumpWidget(
        pump(
          snapshots: [snapshot],
          onWriteResult:
              ({required path, required taskText, required text, link}) async {
                capturedLink = link;
              },
        ),
      );
      await tester.tap(find.text('Demo'));
      await tester.pump();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('📎'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).last,
        r'C:\path\to\rc16-answer.pdf',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // The link field alone doesn't submit the whole prompt — the main
      // Result text still needs a value, per "ignoring it costs nothing"
      // never applying to a half-filled line the user is still typing.
      expect(find.text('Result'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Done');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(capturedLink?.label, 'rc16-answer.pdf');
      expect(capturedLink?.target, r'C:\path\to\rc16-answer.pdf');
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

    testWidgets('L30 — a left-list project opens its own list', (tester) async {
      final snapshot = ProjectTasksSnapshot(
        project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
        folder: 'demo',
        homeTasks: const [
          Task(rawLine: '- [ ] Home task', text: 'Home task', done: false),
        ],
        areas: const [],
      );
      await tester.pumpWidget(pump(snapshots: [snapshot]));

      // Next up is open by default — the rail is the only place 'Demo'
      // shows before it's selected.
      await tester.tap(find.text('Demo'));
      await tester.pump();

      expect(find.text('Home task'), findsOneWidget);
    });

    testWidgets(
      "L31 — a Next up row's project name opens that project's own list",
      (tester) async {
        final snapshot = ProjectTasksSnapshot(
          project: _project(name: 'Demo', sourceFile: 'demo/demo.md'),
          folder: 'demo',
          homeTasks: const [
            Task(
              rawLine: '- [ ] Do the thing',
              text: 'Do the thing',
              done: false,
            ),
          ],
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

        await tapInlineSpan(tester, '  · Demo');

        // Same destination as L30 — the project's own list, in this same
        // Tasks view, not a different screen.
        expect(find.text('Do the thing'), findsOneWidget);
        expect(find.text('⭐ Next up'), findsOneWidget); // rail unaffected
      },
    );
  });
}

/// Invokes an inline `TextSpan`'s own `TapGestureRecognizer` directly,
/// rather than simulating a pixel-precise tap — same technique
/// `links_test.dart`'s `tapObjectiveLink` uses for `plan_view.dart`'s own
/// inline "Objective N" link, needed here for the Next-up row's own
/// project-name span (round-42's L31).
Future<void> tapInlineSpan(WidgetTester tester, String label) async {
  void searchSpan(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text == label && span.recognizer is TapGestureRecognizer) {
        (span.recognizer! as TapGestureRecognizer).onTap!();
        return;
      }
      span.children?.forEach(searchSpan);
    }
  }

  final richTexts = tester.widgetList<RichText>(find.byType(RichText));
  for (final richText in richTexts) {
    searchSpan(richText.text);
  }
  await tester.pumpAndSettle();
}
