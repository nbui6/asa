import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('slugOf', () {
    test('works with a forward-slash test fixture path', () {
      expect(slugOf('projects/asa'), 'asa');
    });

    test('works with a real Windows backslash path', () {
      expect(slugOf(r'C:\Users\nico.bui\workspace\projects\asa'), 'asa');
    });
  });

  group('buildProjectForest', () {
    test('real chain: other -> asa -> vibe-coding-kit, each one level '
        'deeper than its parent', () {
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

      final forest = buildProjectForest([other, asa, vibe]);

      expect(forest, hasLength(1));
      expect(forest.single.project.name, 'other');
      expect(forest.single.children, hasLength(1));
      expect(forest.single.children.single.project.name, 'asa');
      expect(
        forest.single.children.single.children.single.project.name,
        'vibe-coding-kit',
      );
    });

    test('a project with no parent at all is a root', () {
      final standalone = _summary(
        folder: 'projects/kundenakte',
        name: 'kundenakte',
      );
      final forest = buildProjectForest([standalone]);

      expect(forest, hasLength(1));
      expect(forest.single.children, isEmpty);
    });

    test('a project whose parent slug is not in this scan becomes a root '
        'rather than being dropped', () {
      final orphan = _summary(
        folder: 'projects/orphan',
        name: 'orphan',
        parent: 'no-such-project',
      );
      final forest = buildProjectForest([orphan]);

      expect(forest, hasLength(1));
      expect(forest.single.project.name, 'orphan');
    });

    test('an empty project list yields an empty forest', () {
      expect(buildProjectForest([]), isEmpty);
    });
  });
}
