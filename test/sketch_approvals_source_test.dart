// Round 29 — sketch approvals become a third DecisionSource. No disk is
// touched here except in the real-fixture group at the end (Gate 2: Asa's
// own sketches\APPROVED.md, never another project's).

import 'dart:io';

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

const _approved = r'''
# Approved sketches — demo

| Date | By | Image | Source | Covers | What it must look like, in one line |
|---|---|---|---|---|---|
| 2026-09-07 | Nico | `projects\proj\sketches\x.png` | `projects\proj\sketches\x.html` | The thing | *"yes looks good, go."* |

## Trial builds — authorised to build, not yet approved

| Date | Image | Source | Covers | Authorised by | What happens next |
|---|---|---|---|---|---|
| 2026-09-08 | `projects\proj\sketches\y.png` | `projects\proj\sketches\y.html` | The other thing | Nico | Try it live, then judge |

## Rejected, kept on purpose

| Date | Image | Why it was rejected |
|---|---|---|
| 2026-09-01 | `projects\proj\sketches\z.png` | *"It looks bad."* |
''';

void main() {
  group('SketchApprovalsSource — the three tables', () {
    test('an approved row maps to accepted, verdict byte-identical to its '
        'own last column', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/sketches': [
            'APPROVED.md',
            'x.png',
            'x.html',
            'y.png',
            'y.html',
            'z.png',
          ],
        },
        files: {'proj/sketches/APPROVED.md': _approved},
      );

      final results = await const SketchApprovalsSource().readDecisions(
        'proj',
        files,
      );

      final approved = results.firstWhere(
        (r) => r.decision?.status == 'accepted',
      );
      expect(approved.decision!.title, 'The thing');
      expect(approved.decision!.verdict!.accepted, isTrue);
      expect(approved.decision!.verdict!.reason, '*"yes looks good, go."*');
    });

    test('a trial row maps to proposed, with no verdict yet', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/sketches': [
            'APPROVED.md',
            'x.png',
            'x.html',
            'y.png',
            'y.html',
            'z.png',
          ],
        },
        files: {'proj/sketches/APPROVED.md': _approved},
      );

      final results = await const SketchApprovalsSource().readDecisions(
        'proj',
        files,
      );

      final trial = results.firstWhere((r) => r.decision?.status == 'proposed');
      expect(trial.decision!.title, 'The other thing');
      expect(trial.decision!.verdict, isNull);
      expect(trial.decision!.isProposed, isTrue);
      expect(trial.decision!.decision, 'Try it live, then judge');
    });

    test('a rejected row maps to rejected, verdict byte-identical to its '
        'own reason column', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/sketches': [
            'APPROVED.md',
            'x.png',
            'x.html',
            'y.png',
            'y.html',
            'z.png',
          ],
        },
        files: {'proj/sketches/APPROVED.md': _approved},
      );

      final results = await const SketchApprovalsSource().readDecisions(
        'proj',
        files,
      );

      final rejected = results.firstWhere(
        (r) => r.decision?.status == 'rejected',
      );
      expect(rejected.decision!.title, 'z');
      expect(rejected.decision!.verdict!.accepted, isFalse);
      expect(rejected.decision!.verdict!.reason, '*"It looks bad."*');
    });

    test(
      'no sketches/APPROVED.md yields an empty list, not an error',
      () async {
        final results = await const SketchApprovalsSource().readDecisions(
          'proj',
          FakeFileAccess(),
        );
        expect(results, isEmpty);
      },
    );

    test('a row whose image does not resolve surfaces with its reason, '
        'never silently dropped', () async {
      final files = FakeFileAccess(
        folders: {
          // x.png deliberately missing — everything else present.
          'proj/sketches': [
            'APPROVED.md',
            'x.html',
            'y.png',
            'y.html',
            'z.png',
          ],
        },
        files: {'proj/sketches/APPROVED.md': _approved},
      );

      final results = await const SketchApprovalsSource().readDecisions(
        'proj',
        files,
      );

      final broken = results.firstWhere((r) => !r.isSuccess);
      expect(broken.error, contains('Image not found'));
      expect(broken.error, contains('x.png'));
      expect(broken.rawText, contains('The thing'));
    });

    test('readAllDecisions merges ADR-folder and sketch-approval results '
        "from one project — AdrFolderSource's own tests are untouched, "
        'checked separately', () async {
      final files = FakeFileAccess(
        folders: {
          'proj/decisions': ['0001-first.md'],
          'proj/sketches': [
            'APPROVED.md',
            'x.png',
            'x.html',
            'y.png',
            'y.html',
            'z.png',
          ],
        },
        files: {
          'proj/decisions/0001-first.md': '# ADR 0001 - First\n',
          'proj/sketches/APPROVED.md': _approved,
        },
      );

      final results = await readAllDecisions('proj', files);
      expect(results.length, 4); // 1 ADR + 3 sketch rows
      expect(
        results.map((r) => r.decision?.title),
        containsAll(['First', 'The thing', 'The other thing', 'z']),
      );
    });
  });

  group("the real fixture — Asa's own sketches/APPROVED.md", () {
    test('parses without error, every real path resolves', () async {
      final projectFolder =
          '${Directory.current.path}${Platform.pathSeparator}..'
          '${Platform.pathSeparator}projects${Platform.pathSeparator}asa';
      if (!Directory(projectFolder).existsSync()) {
        return; // Gate 2: only runs where projects\asa exists locally.
      }

      final results = await const SketchApprovalsSource().readDecisions(
        projectFolder,
        const DiskFileAccess(),
      );

      expect(results, isNotEmpty);
      for (final result in results) {
        expect(
          result.isSuccess,
          isTrue,
          reason: 'every real row should resolve: ${result.error}',
        );
      }
      expect(
        results.map((r) => r.decision!.status).toSet(),
        containsAll(['accepted', 'rejected']),
      );
    });
  });
}
