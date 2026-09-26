// Tests for the parent-chain nesting rule — no disk touched, a fake
// FileAccess stands in, same as decisions_reader_test.dart.

import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileAccess implements FileAccess {
  FakeFileAccess(this.files, [this.folders = const {}]);

  final Map<String, String> files;

  /// Round 34/E — folder path to the bare filenames "inside" it, for
  /// `readAreasVia`'s own `listFiles('<project>/plan')` call. Empty by
  /// default: every test that does not name an area keeps seeing no
  /// `plan\` folder, same as before this existed.
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

ProjectSummary _summary({
  required String folder,
  required String name,
  String? parent,
}) {
  return ProjectSummary(
    project: Project(
      name: name,
      status: 'in progress',
      milestone: '',
      nextStep: '',
      repoPath: '',
      updated: '2026-09-07',
      sourceFile: '$folder/$name.md',
      parent: parent,
    ),
    git: _emptyGit,
    folder: folder,
  );
}

void main() {
  group('buildTaskGroups — the 2026-09-07 parent-chain nesting rule', () {
    test('real chain: other (no tasks, never shows) -> asa (has tasks, top '
        'level) -> vibe-coding-kit (parent asa, no tasks yet — nothing to '
        'nest)', () async {
      final other = _summary(folder: 'projects/other', name: 'other');
      final asa = _summary(
        folder: 'projects/asa',
        name: 'asa',
        parent: 'other',
      );
      final vibe = _summary(
        folder: 'projects/vibe-coding-kit',
        name: 'vibe-coding-kit',
        parent: 'asa',
      );

      final files = FakeFileAccess({
        other.project.sourceFile: '# Other\n\nNo tasks section at all.\n',
        asa.project.sourceFile: '## Tasks\n\n- [ ] Build the Tasks view\n',
        vibe.project.sourceFile: '# Vibe Coding Kit\n\nNo tasks yet.\n',
      });

      final groups = await buildTaskGroups([other, asa, vibe], files);

      expect(groups, hasLength(1));
      expect(groups.single.project.name, 'asa');
      expect(groups.single.children, isEmpty);
    });

    test(
      'a project nests under its parent when the parent also has tasks',
      () async {
        final parent = _summary(folder: 'projects/parent', name: 'parent');
        final child = _summary(
          folder: 'projects/child',
          name: 'child',
          parent: 'parent',
        );

        final files = FakeFileAccess({
          parent.project.sourceFile: '## Tasks\n\n- [ ] Parent task\n',
          child.project.sourceFile: '## Tasks\n\n- [ ] Child task\n',
        });

        final groups = await buildTaskGroups([parent, child], files);

        expect(groups, hasLength(1));
        expect(groups.single.project.name, 'parent');
        expect(groups.single.children, hasLength(1));
        expect(groups.single.children.single.project.name, 'child');
      },
    );

    test('a project whose parent slug does not exist in this scan at all '
        'still becomes a root, rather than being dropped', () async {
      final orphan = _summary(
        folder: 'projects/orphan',
        name: 'orphan',
        parent: 'no-such-project',
      );
      final files = FakeFileAccess({
        orphan.project.sourceFile: '## Tasks\n\n- [ ] Do the thing\n',
      });

      final groups = await buildTaskGroups([orphan], files);

      expect(groups, hasLength(1));
      expect(groups.single.project.name, 'orphan');
    });

    test(
      'a project with no ## Tasks section contributes no row at all',
      () async {
        final empty = _summary(folder: 'projects/empty', name: 'empty');
        final files = FakeFileAccess({empty.project.sourceFile: '# Empty\n'});

        expect(await buildTaskGroups([empty], files), isEmpty);
      },
    );

    test('an empty project list yields an empty list', () async {
      expect(await buildTaskGroups([], FakeFileAccess({})), isEmpty);
    });
  });

  group('Round 34/E — area tasks group by area name, after the home '
      "note's own", () {
    test('an area with tasks gets its own group, in area order', () async {
      final project = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess(
        {
          project.project.sourceFile: '## Tasks\n\n- [ ] Home task\n',
          'projects/demo/plan/1-sales.md':
              '# Sales\n\n## Tasks\n- [ ] Sales task\n',
          'projects/demo/plan/finance.md':
              '# Finance\n\n## Tasks\n- [ ] Finance task\n',
        },
        {
          'projects/demo/plan': ['1-sales.md', 'finance.md'],
        },
      );

      final groups = await buildTaskGroups([project], files);

      expect(groups, hasLength(1));
      expect(groups.single.tasks.single.text, 'Home task');
      expect(groups.single.areaGroups, hasLength(2));
      expect(groups.single.areaGroups[0].name, 'Sales');
      expect(groups.single.areaGroups[0].tasks.single.text, 'Sales task');
      expect(groups.single.areaGroups[1].name, 'Finance');
    });

    test('an area with no tasks at all gets no group — nothing to show, '
        'no row, same rule as a project with none', () async {
      final project = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess(
        {
          project.project.sourceFile: '## Tasks\n\n- [ ] Home task\n',
          'projects/demo/plan/empty.md': '# Empty\n\nNothing yet.\n',
        },
        {
          'projects/demo/plan': ['empty.md'],
        },
      );

      final groups = await buildTaskGroups([project], files);
      expect(groups.single.areaGroups, isEmpty);
    });

    test('a project with no home tasks but a real area task still gets a '
        'row — it has real, actionable tasks, just under an area', () async {
      final project = _summary(folder: 'projects/demo', name: 'demo');
      final files = FakeFileAccess(
        {
          project.project.sourceFile: '# Demo\n\nNo ## Tasks at all.\n',
          'projects/demo/plan/sales.md':
              '# Sales\n\n## Tasks\n- [ ] Sales task\n',
        },
        {
          'projects/demo/plan': ['sales.md'],
        },
      );

      final groups = await buildTaskGroups([project], files);
      expect(groups, hasLength(1));
      expect(groups.single.tasks, isEmpty);
      expect(groups.single.areaGroups.single.name, 'Sales');
    });

    test(
      r'no plan\ folder at all — the existing behaviour, unchanged',
      () async {
        final project = _summary(folder: 'projects/demo', name: 'demo');
        final files = FakeFileAccess({
          project.project.sourceFile: '## Tasks\n\n- [ ] Home task\n',
        });

        final groups = await buildTaskGroups([project], files);
        expect(groups.single.areaGroups, isEmpty);
      },
    );
  });
}
