// Round 42 — no disk touched, a fake FileAccess stands in, same pattern
// tasks_reader_test.dart already uses.

import 'dart:io';

import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_board.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileAccess implements FileAccess {
  FakeFileAccess(this.files, [this.folders = const {}]);

  final Map<String, String> files;
  final Map<String, List<String>> folders;

  @override
  Future<List<String>> listFiles(String folder) async => folders[folder] ?? [];

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    if (contents == null) throw StateError('No fake file at $path');
    return contents;
  }
}

const _emptyGit = GitState(command: '', rawOutput: '');
final _sep = Platform.pathSeparator;

ProjectSummary _summary({
  required String folder,
  required String name,
  String nextStep = '',
}) {
  return ProjectSummary(
    project: Project(
      name: name,
      status: 'in progress',
      milestone: '',
      nextStep: nextStep,
      repoPath: '',
      updated: '2026-09-07',
      sourceFile: '$folder/$name.md',
    ),
    git: _emptyGit,
    folder: folder,
  );
}

void main() {
  group('buildProjectTasksSnapshots', () {
    test('reads home tasks and every area, even one with zero tasks of '
        'its own', () async {
      final summary = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess(
        {
          'projects/demo/demo.md': '## Tasks\n\n- [ ] Home task\n',
          'projects/demo${_sep}plan${_sep}sales.md': '# Sales\n',
        },
        {
          'projects/demo${_sep}plan': ['sales.md'],
        },
      );

      final snapshots = await buildProjectTasksSnapshots([summary], files);

      expect(snapshots, hasLength(1));
      expect(snapshots.single.homeTasks, hasLength(1));
      expect(snapshots.single.areas, hasLength(1));
      expect(snapshots.single.areas.single.name, 'Sales');
      expect(snapshots.single.areas.single.tasks, isEmpty);
    });

    test('openCount adds the home note and every area together', () async {
      final summary = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess(
        {
          'projects/demo/demo.md':
              '## Tasks\n\n- [ ] Open\n- [x] Done\n',
          'projects/demo${_sep}plan${_sep}sales.md':
              '# Sales\n\n## Tasks\n- [ ] Sales open\n- [ ] Sales open 2\n',
        },
        {
          'projects/demo${_sep}plan': ['sales.md'],
        },
      );

      final snapshot = (await buildProjectTasksSnapshots(
        [summary],
        files,
      )).single;

      expect(snapshot.openCount, 3);
    });

    test('a project with no plan folder at all gets an empty areas list, '
        'not an error', () async {
      final summary = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess({
        'projects/demo/demo.md': '## Tasks\n\n- [ ] Only task\n',
      });

      final snapshot = (await buildProjectTasksSnapshots(
        [summary],
        files,
      )).single;

      expect(snapshot.areas, isEmpty);
      expect(snapshot.homeTasks, hasLength(1));
    });
  });

  group('buildNextUp — Round 42 §A', () {
    test(
      'one row per project with a real open task, home task first',
      () async {
      final withHomeTask = _summary(folder: 'projects/a', name: 'A');
      final withAreaTask = _summary(folder: 'projects/b', name: 'B');
      final files = FakeFileAccess(
        {
          'projects/a/A.md': '## Tasks\n\n- [ ] A open task\n',
          'projects/b/B.md': '## Tasks\n\n',
          'projects/b${_sep}plan${_sep}sales.md':
              '# Sales\n\n## Tasks\n- [ ] B area task\n',
        },
        {
          'projects/b${_sep}plan': ['sales.md'],
        },
      );

      final snapshots = await buildProjectTasksSnapshots(
        [withHomeTask, withAreaTask],
        files,
      );
      final nextUp = buildNextUp(snapshots);

      expect(nextUp, hasLength(2));
      expect(nextUp[0].projectName, 'A');
      expect(nextUp[0].text, 'A open task');
      expect(nextUp[0].area, isNull);
      expect(nextUp[1].projectName, 'B');
      expect(nextUp[1].text, 'B area task');
      expect(nextUp[1].area?.name, 'Sales');
      },
    );

    test('a project with every task done and no typed next step '
        'contributes no row', () async {
      final summary = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess({
        'projects/demo/demo.md': '## Tasks\n\n- [x] Already done\n',
      });

      final snapshots = await buildProjectTasksSnapshots([summary], files);
      expect(buildNextUp(snapshots), isEmpty);
    });

    test('the task itself is carried, so ticking it is possible from the '
        'Next up row directly', () async {
      final summary = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess({
        'projects/demo/demo.md': '## Tasks\n\n- [ ] Real one\n',
      });

      final snapshots = await buildProjectTasksSnapshots([summary], files);
      final item = buildNextUp(snapshots).single;

      expect(item.task, isA<Task>());
      expect(item.task.rawLine, '- [ ] Real one');
    });
  });
}
