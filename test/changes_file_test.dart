// Round 39 cp3 — `rounds\CHANGES.md`'s own reader.

import 'package:asa/core/changes_file.dart';
import 'package:asa/core/decisions_reader.dart' show FileAccess;
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
    if (contents == null) throw StateError('No fake file at $path');
    return contents;
  }
}

void main() {
  group('readChangeRequests', () {
    test(
      'no rounds/CHANGES.md at all reads as no rows, not an error',
      () async {
        final rows = await readChangeRequests('proj', FakeFileAccess());
        expect(rows, isEmpty);
      },
    );

    test('a real row, in the shape CHANGES.md actually uses', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/rounds': ['CHANGES.md'],
        },
        files: {
          'proj/rounds/CHANGES.md':
              '# Round change requests — Asa\n\n'
              '| Date | Round | What the user wants changed |\n'
              '|---|---|---|\n'
              '| 2026-09-28 | 36, 37 | Strategy before Plan; tabs for '
              'different areas → Round 38 |\n',
        },
      );
      final rows = await readChangeRequests('proj', files);
      expect(rows, hasLength(1));
      expect(rows.single.date, '2026-09-28');
      expect(rows.single.round, '36, 37');
      expect(
        rows.single.what,
        'Strategy before Plan; tabs for different areas → Round 38',
      );
    });

    test('newest first, even though the file itself is append-only', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/rounds': ['CHANGES.md'],
        },
        files: {
          'proj/rounds/CHANGES.md':
              '| Date | Round | What the user wants changed |\n'
              '|---|---|---|\n'
              '| 2026-09-01 | 30 | First one |\n'
              '| 2026-09-28 | 38 | Latest one |\n',
        },
      );
      final rows = await readChangeRequests('proj', files);
      expect(rows.map((r) => r.round).toList(), ['38', '30']);
    });

    test('a fully empty row is skipped, same as APPROVED.md', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/rounds': ['CHANGES.md'],
        },
        files: {
          'proj/rounds/CHANGES.md':
              '| Date | Round | What the user wants changed |\n'
              '|---|---|---|\n'
              '| | | |\n',
        },
      );
      final rows = await readChangeRequests('proj', files);
      expect(rows, isEmpty);
    });
  });
}
