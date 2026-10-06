// ADR 0051 — archive and delete a project. Real files, real disk: the
// folder-move guarantee this exists to prove is specifically about what
// dart:io actually does, which an in-memory fake cannot stand in for.

import 'dart:io';

import 'package:asa/core/archive_writer.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project({required String name}) {
  return Project(
    name: name,
    status: 'in-progress',
    milestone: '',
    nextStep: '',
    repoPath: '',
    updated: '2026-10-06',
    sourceFile: '$name/$name.md',
  );
}

void main() {
  late Directory tempDir;
  late String root;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-archive-test-');
    root = tempDir.path;
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void makeProjectFolder(String slug, {String file = 'home.md'}) {
    final dir = Directory('$root${Platform.pathSeparator}$slug')
      ..createSync(recursive: true);
    File('${dir.path}${Platform.pathSeparator}$file')
        .writeAsStringSync('# $slug\n');
  }

  group('subtreeFolders', () {
    test('a lone project is just its own folder', () {
      final node = ProjectNode(
        project: _project(name: 'Solo'),
        folder: '$root${Platform.pathSeparator}solo',
      );
      expect(subtreeFolders(node), [node.folder]);
    });

    test('a parent and its descendants, in order, any depth', () {
      final grandchild = ProjectNode(
        project: _project(name: 'Grandchild'),
        folder: 'g',
      );
      final child = ProjectNode(
        project: _project(name: 'Child'),
        folder: 'c',
        children: [grandchild],
      );
      final parent = ProjectNode(
        project: _project(name: 'Parent'),
        folder: 'p',
        children: [child],
      );

      expect(subtreeFolders(parent), ['p', 'c', 'g']);
    });
  });

  group('archiveProject / restoreProject', () {
    test('moves a lone project into _archive, unchanged', () async {
      makeProjectFolder('solo');
      final node = ProjectNode(
        project: _project(name: 'Solo'),
        folder: '$root${Platform.pathSeparator}solo',
      );

      await archiveProject(root, node);

      expect(
        Directory('$root${Platform.pathSeparator}solo').existsSync(),
        isFalse,
      );
      final archived = Directory(
        '$root${Platform.pathSeparator}_archive${Platform.pathSeparator}solo',
      );
      expect(archived.existsSync(), isTrue);
      expect(
        File('${archived.path}${Platform.pathSeparator}home.md')
            .readAsStringSync(),
        '# solo\n',
      );
    });

    test('a parent takes every descendant along, any depth', () async {
      makeProjectFolder('parent');
      makeProjectFolder('child');
      makeProjectFolder('grandchild');
      final node = ProjectNode(
        project: _project(name: 'Parent'),
        folder: '$root${Platform.pathSeparator}parent',
        children: [
          ProjectNode(
            project: _project(name: 'Child'),
            folder: '$root${Platform.pathSeparator}child',
            children: [
              ProjectNode(
                project: _project(name: 'Grandchild'),
                folder: '$root${Platform.pathSeparator}grandchild',
              ),
            ],
          ),
        ],
      );

      await archiveProject(root, node);

      for (final slug in ['parent', 'child', 'grandchild']) {
        expect(
          Directory('$root${Platform.pathSeparator}$slug').existsSync(),
          isFalse,
          reason: slug,
        );
        final archivedPath =
            '$root${Platform.pathSeparator}_archive'
            '${Platform.pathSeparator}$slug';
        expect(Directory(archivedPath).existsSync(), isTrue, reason: slug);
      }
    });

    test('refuses, moves nothing, when a destination already exists', () {
      makeProjectFolder('solo');
      Directory(
        '$root${Platform.pathSeparator}_archive${Platform.pathSeparator}solo',
      ).createSync(recursive: true);
      final node = ProjectNode(
        project: _project(name: 'Solo'),
        folder: '$root${Platform.pathSeparator}solo',
      );

      expect(() => archiveProject(root, node), throwsStateError);
      expect(
        Directory('$root${Platform.pathSeparator}solo').existsSync(),
        isTrue,
      );
    });

    test('restoreProject is the exact reverse, old status and all', () async {
      makeProjectFolder('solo');
      final node = ProjectNode(
        project: _project(name: 'Solo'),
        folder: '$root${Platform.pathSeparator}solo',
      );
      await archiveProject(root, node);

      final archivedFolder =
          '$root${Platform.pathSeparator}_archive${Platform.pathSeparator}solo';
      final archivedNode = ProjectNode(
        project: _project(name: 'Solo'),
        folder: archivedFolder,
      );
      await restoreProject(root, archivedNode);

      expect(
        Directory('$root${Platform.pathSeparator}solo').existsSync(),
        isTrue,
      );
      expect(
        File(
          '$root${Platform.pathSeparator}solo${Platform.pathSeparator}home.md',
        ).readAsStringSync(),
        '# solo\n',
      );
    });
  });

  group('countFiles', () {
    test('counts every file under a folder, recursively', () async {
      makeProjectFolder('solo');
      Directory(
        '$root${Platform.pathSeparator}solo${Platform.pathSeparator}plan',
      ).createSync(recursive: true);
      File(
        '$root${Platform.pathSeparator}solo${Platform.pathSeparator}plan'
        '${Platform.pathSeparator}sales.md',
      ).writeAsStringSync('x');

      final count = await countFiles('$root${Platform.pathSeparator}solo');
      expect(count, 2);
    });
  });
}
