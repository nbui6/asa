// Round 39 cp5 — `.asa-log.md`'s own reader.

import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/session_log.dart';
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
  group('readSessionLog', () {
    test('no .asa-log.md at all reads as no entries, not an error', () async {
      final entries = await readSessionLog('proj', FakeFileAccess());
      expect(entries, isEmpty);
    });

    test(
      "the real shape, including a real line's own dropped start time",
      () async {
        final files = FakeFileAccess(
          folders: {
            'proj': ['.asa-log.md'],
          },
          files: {
            'proj/.asa-log.md':
                '- 2026-09-28 14:02–14:40 · Claude Code, account B · what '
                'you did, one line · files you wrote\n'
                '- 2026-09-28 –15:09 · Claude, desktop app · a line missing '
                'its own start time · docs\\plan\n',
          },
        );
        final entries = await readSessionLog('proj', files);
        expect(entries, hasLength(2));
        expect(entries[0].date, DateTime(2026, 9, 28));
        expect(
          entries[0].text,
          '14:02–14:40 · Claude Code, account B · what you did, one line · '
          'files you wrote',
        );
        expect(entries[1].text, contains('a line missing its own start time'));
      },
    );

    test(
      'a line with no parseable leading date is skipped, not guessed at',
      () async {
        final files = FakeFileAccess(
          folders: {
            'proj': ['.asa-log.md'],
          },
          files: {'proj/.asa-log.md': '# Session log\n\nNothing logged yet.\n'},
        );
        final entries = await readSessionLog('proj', files);
        expect(entries, isEmpty);
      },
    );

    test("kept in file order — newest-first is the caller's own job", () async {
      final files = FakeFileAccess(
        folders: {
          'proj': ['.asa-log.md'],
        },
        files: {
          'proj/.asa-log.md':
              '- 2026-09-01 · older · x\n'
              '- 2026-09-28 · newer · y\n',
        },
      );
      final entries = await readSessionLog('proj', files);
      expect(entries.map((e) => e.date).toList(), [
        DateTime(2026, 9),
        DateTime(2026, 9, 28),
      ]);
    });
  });
}
