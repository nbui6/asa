// Round 39 cp8 (ADR 0033) — Asa's own local change history. Real disk,
// always a sandboxed history root — never the real %APPDATA%\Asa\.

import 'dart:io';

import 'package:asa/core/change_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectsRoot;
  late String historyRoot;
  late String projectFolder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-change-history-test-');
    projectsRoot = '${tempDir.path}${Platform.pathSeparator}projects';
    historyRoot = '${tempDir.path}${Platform.pathSeparator}history';
    projectFolder = '$projectsRoot${Platform.pathSeparator}demo';
    Directory(projectFolder).createSync(recursive: true);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void writeCharter(String content) {
    File('$projectFolder${Platform.pathSeparator}CHARTER.md')
        .writeAsStringSync(content);
  }

  group('recordChanges', () {
    test(
      'the very first look establishes a baseline — before is null',
      () async {
        writeCharter('# Charter\nv1\n');
        final records = await recordChanges(
          projectFolder,
          projectsRoot,
          historyRoot: historyRoot,
          now: DateTime(2026, 9, 28),
        );
        expect(records, hasLength(1));
        expect(records.single.path, 'demo${Platform.pathSeparator}CHARTER.md');
        expect(records.single.before, isNull);
        expect(records.single.after, '# Charter\nv1\n');
      },
    );

    test('an unchanged file since the last look records nothing', () async {
      writeCharter('# Charter\nv1\n');
      await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 28),
      );
      final second = await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 29),
      );
      expect(second, isEmpty);
    });

    test('a real edit is captured with both before and after', () async {
      writeCharter('# Charter\nv1\n');
      await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 28),
      );
      writeCharter('# Charter\nv2, edited\n');
      final second = await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 29),
      );
      expect(second, hasLength(1));
      expect(second.single.before, '# Charter\nv1\n');
      expect(second.single.after, '# Charter\nv2, edited\n');
      // A trailing newline means split('\n') has one extra, empty
      // element at the end — '# Charter\nv1\n'.split('\n') has 3.
      expect(second.single.linesBefore, 3);
      expect(second.single.linesAfter, 3);
    });

    test('never stores a file from outside the projects root', () async {
      // The home note and CHARTER.md are the only watched files here;
      // nothing outside projectFolder is ever touched.
      writeCharter('# Charter\n');
      await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 28),
      );
      final historyDir = Directory(historyRoot);
      final allSnapshotPaths = historyDir
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .toList();
      for (final path in allSnapshotPaths) {
        expect(path.startsWith(historyRoot), isTrue, reason: path);
      }
    });

    test('with isRoot: true, watches BOSS.md/AGENTS.md at the projects '
        'root instead', () async {
      File('$projectsRoot${Platform.pathSeparator}BOSS.md')
          .writeAsStringSync('# BOSS.md\n');
      final records = await recordChanges(
        projectsRoot,
        projectsRoot,
        isRoot: true,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 28),
      );
      expect(records, hasLength(1));
      expect(records.single.path, 'BOSS.md');
    });
  });

  group('readChangeHistory', () {
    test('reads back exactly what recordChanges wrote, oldest first', () async {
      writeCharter('# Charter\nv1\n');
      await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 28),
      );
      writeCharter('# Charter\nv2\n');
      await recordChanges(
        projectFolder,
        projectsRoot,
        historyRoot: historyRoot,
        now: DateTime(2026, 9, 29),
      );

      final history = await readChangeHistory(
        projectFolder,
        historyRoot: historyRoot,
      );
      expect(history, hasLength(2));
      expect(history[0].timestamp, DateTime(2026, 9, 28));
      expect(history[0].before, isNull);
      expect(history[1].timestamp, DateTime(2026, 9, 29));
      expect(history[1].before, '# Charter\nv1\n');
      expect(history[1].after, '# Charter\nv2\n');
    });

    test('no history at all reads as no records, not an error', () async {
      final history = await readChangeHistory(
        projectFolder,
        historyRoot: historyRoot,
      );
      expect(history, isEmpty);
    });
  });

  group('isLoggedChange — ADR 0048, matches by file and day', () {
    test('a same-day line naming this exact file is a real match', () {
      final record = ChangeRecord(
        path: 'CHARTER.md',
        timestamp: DateTime(2026, 9, 28, 15, 30),
        before: 'a',
        after: 'b',
      );
      final log = [
        (date: DateTime(2026, 9, 28), text: 'did something · CHARTER.md'),
      ];
      expect(isLoggedChange(record, log), LoggedMatch.yes);
    });

    test(
      'a same-day line naming only a different file is changed, not '
      'logged — the exact gap the drill found',
      () {
        final record = ChangeRecord(
          path: 'CHARTER.md',
          timestamp: DateTime(2026, 9, 28, 15, 30),
          before: 'a',
          after: 'b',
        );
        final log = [
          (
            date: DateTime(2026, 9, 28),
            text: r'confirmed the webinar month · plan\1-marketing.md',
          ),
        ];
        expect(isLoggedChange(record, log), LoggedMatch.no);
      },
    );

    test(
      'a same-day line that names no file at all falls back to '
      'probably logged, not a certain yes',
      () {
        final record = ChangeRecord(
          path: 'CHARTER.md',
          timestamp: DateTime(2026, 9, 28, 15, 30),
          before: 'a',
          after: 'b',
        );
        final log = [(date: DateTime(2026, 9, 28), text: 'did something')];
        expect(isLoggedChange(record, log), LoggedMatch.probably);
      },
    );

    test('a change with no log line that day is changed, not logged', () {
      final record = ChangeRecord(
        path: 'CHARTER.md',
        timestamp: DateTime(2026, 9, 28, 15, 30),
        before: 'a',
        after: 'b',
      );
      final log = [(date: DateTime(2026, 9, 20), text: 'a different day')];
      expect(isLoggedChange(record, log), LoggedMatch.no);
    });

    test('no log lines at all is never logged', () {
      final record = ChangeRecord(
        path: 'CHARTER.md',
        timestamp: DateTime(2026, 9, 28),
        before: 'a',
        after: 'b',
      );
      expect(isLoggedChange(record, const []), LoggedMatch.no);
    });

    test("matches by the file's own bare name, not its full path", () {
      final record = ChangeRecord(
        path: r'plan\1-marketing.md',
        timestamp: DateTime(2026, 9, 28, 15, 30),
        before: 'a',
        after: 'b',
      );
      final log = [
        (
          date: DateTime(2026, 9, 28),
          text: 'confirmed the month · 1-marketing.md',
        ),
      ];
      expect(isLoggedChange(record, log), LoggedMatch.yes);
    });
  });
}
