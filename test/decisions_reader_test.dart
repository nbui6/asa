// Tests for finding decisions on disk — both real shapes, and the merge.
//
// No disk is touched: FakeFileAccess is the in-memory stand-in the
// dependency-inversion rule in HANDOVER.md asks for, so these tests behave
// identically on any machine.

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileAccess implements FileAccess {
  FakeFileAccess({this.folders = const {}, this.files = const {}});

  final Map<String, List<String>> folders;
  final Map<String, String> files;

  @override
  Future<List<String>> listFiles(String folder) async => folders[folder] ?? [];

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    if (contents == null) {
      throw StateError('No fake file at $path');
    }
    return contents;
  }
}

void main() {
  group('AdrFolderSource', () {
    test('reads every .md file in decisions/, sorted by name', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/decisions': ['0002-second.md', '0001-first.md', 'notes.txt'],
        },
        files: {
          'proj/decisions/0001-first.md': '# ADR 0001 - First\n',
          'proj/decisions/0002-second.md': '# ADR 0002 - Second\n',
        },
      );

      final results = await const AdrFolderSource().readDecisions(
        'proj',
        files,
      );

      expect(results.length, 2);
      expect(results[0].decision!.title, 'First');
      expect(results[1].decision!.title, 'Second');
    });

    test('a folder that does not exist yields an empty list', () async {
      final results = await const AdrFolderSource().readDecisions(
        'proj',
        FakeFileAccess(),
      );
      expect(results, isEmpty);
    });
  });

  group('DecisionLogSource', () {
    test('splits a log into one result per ## section', () async {
      final files = FakeFileAccess(
        folders: {
          'proj': ['decisions.md', 'other.md'],
        },
        files: {
          'proj/decisions.md':
              '# Decisions - Example\n\nIntro text.\n\n'
              '---\n\n## 0001 - First\n\n**Date:** 2026-09-01 - **Status:** '
              'accepted\n\n**Decision:** One.\n\n---\n\n## 0002 - Second\n\n'
              '**Date:** 2026-09-01 - **Status:** accepted\n\n**Decision:** '
              'Two.\n',
        },
      );

      final results = await const DecisionLogSource().readDecisions(
        'proj',
        files,
      );

      expect(results.length, 2);
      expect(results[0].decision!.title, 'First');
      expect(results[1].decision!.title, 'Second');
      expect(results[0].sourceFile, 'proj/decisions.md');
    });

    test('no decisions.md yields an empty list, not an error', () async {
      final files = FakeFileAccess(
        folders: {
          'proj': ['other.md'],
        },
      );
      final results = await const DecisionLogSource().readDecisions(
        'proj',
        files,
      );
      expect(results, isEmpty);
    });
  });

  group('readAllDecisions — the merge', () {
    test('a project with both shapes yields one list, each item naming its '
        'own file', () async {
      final files = FakeFileAccess(
        folders: {
          'proj': ['decisions.md'],
          'proj/decisions': ['0001-folder-one.md'],
        },
        files: {
          'proj/decisions/0001-folder-one.md': '# ADR 0001 - From the folder\n',
          'proj/decisions.md':
              '# Decisions\n\n## 0001 - From the log\n\n'
              '**Date:** 2026-09-01 - **Status:** accepted\n\n**Decision:** '
              'Logged.\n',
        },
      );

      final results = await readAllDecisions('proj', files);

      expect(results.length, 2);
      expect(
        results.map((r) => r.decision!.title),
        containsAll(['From the folder', 'From the log']),
      );
      expect(
        results.map((r) => r.sourceFile),
        contains('proj/decisions/0001-folder-one.md'),
      );
      expect(results.map((r) => r.sourceFile), contains('proj/decisions.md'));
    });

    test('a project with neither yields an empty list, not an error', () async {
      final results = await readAllDecisions('proj', FakeFileAccess());
      expect(results, isEmpty);
    });
  });

  group('sortDecisionsNewestFirst', () {
    DecisionReadResult withDate(String title, String? date) {
      return parseDecision(
        '# $title\n\n**Date:** ${date ?? ''} · **Status:** accepted\n',
        '$title.md',
      );
    }

    test('newest date first', () {
      final sorted = sortDecisionsNewestFirst([
        withDate('old', '2026-01-01'),
        withDate('new', '2026-08-01'),
        withDate('middle', '2026-04-01'),
      ]);
      expect(sorted.map((r) => r.decision!.title), ['new', 'middle', 'old']);
    });

    test('an undated decision sorts after every dated one', () {
      final sorted = sortDecisionsNewestFirst([
        withDate('undated', null),
        withDate('dated', '2026-01-01'),
      ]);
      expect(sorted.map((r) => r.decision!.title), ['dated', 'undated']);
    });

    test('an unreadable result is kept, always last', () {
      final unreadable = parseDecision('no heading here', 'bad.md');
      final sorted = sortDecisionsNewestFirst([
        unreadable,
        withDate('dated', '2026-01-01'),
      ]);
      expect(sorted.last, same(unreadable));
      expect(sorted.length, 2);
    });

    test('an empty list stays an empty list', () {
      expect(sortDecisionsNewestFirst([]), isEmpty);
    });
  });
}
