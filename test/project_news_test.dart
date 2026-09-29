import 'dart:io';

import 'package:asa/core/change_history.dart' show recordChanges;
import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart' show DiskFileAccess;
import 'package:asa/core/project_news.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:flutter_test/flutter_test.dart';

DecisionReadResult _decision({
  String number = '0001',
  String title = 'A decision',
  bool proposed = false,
  String? date,
}) {
  return DecisionReadResult(
    sourceFile: 'decisions/$number.md',
    decision: Decision(
      number: number,
      title: title,
      why: 'w',
      decision: 'd',
      whatWouldChangeThis: 'c',
      sourceFile: 'decisions/$number.md',
      status: proposed ? 'proposed' : 'accepted',
      date: date,
    ),
  );
}

void main() {
  group('readProjectNews', () {
    late Directory tempDir;
    late String projectFolder;
    late String historyRoot;
    const files = DiskFileAccess();

    String sep(String a, String b) => '$a${Platform.pathSeparator}$b';

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asa-project-news-test-');
      projectFolder = sep(tempDir.path, 'demo');
      Directory(projectFolder).createSync(recursive: true);
      historyRoot = sep(tempDir.path, 'history');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('never visited counts everything as new', () async {
      File(sep(projectFolder, '.asa-log.md')).writeAsStringSync(
        '- 2026-09-20 10:00-10:05 · test · did the thing · demo.md\n',
      );

      final news = await readProjectNews(projectFolder, files);
      expect(news.newCount, 1);
      expect(news.hasAnything, isTrue);
    });

    test('only counts entries after the last visit', () async {
      File(sep(projectFolder, '.asa-log.md')).writeAsStringSync(
        '- 2026-09-10 10:00-10:05 · test · old · demo.md\n'
        '- 2026-09-25 10:00-10:05 · test · new · demo.md\n',
      );

      final news = await readProjectNews(
        projectFolder,
        files,
        lastVisit: DateTime(2026, 9, 20),
      );
      expect(news.newCount, 1);
    });

    test('no news at all is ProjectNews.none-shaped', () async {
      final news = await readProjectNews(projectFolder, files);
      expect(news.newCount, 0);
      expect(news.hasUnloggedChange, isFalse);
      expect(news.hasAnything, isFalse);
    });

    test('an unlogged change sets hasUnloggedChange', () async {
      final charterPath = sep(projectFolder, 'CHARTER.md');
      File(charterPath).writeAsStringSync('## Objectives\n1. First.\n');
      await recordChanges(
        projectFolder,
        tempDir.path,
        historyRoot: historyRoot,
      );
      File(charterPath).writeAsStringSync('## Objectives\n1. Changed.\n');
      await recordChanges(
        projectFolder,
        tempDir.path,
        historyRoot: historyRoot,
      );

      final news = await readProjectNews(
        projectFolder,
        files,
        historyRoot: historyRoot,
      );
      expect(news.hasUnloggedChange, isTrue);
    });
  });

  group('waitingAcrossProjects', () {
    test('collects proposed decisions and waiting rounds, oldest first',
        () {
      final items = waitingAcrossProjects([
        (
          folder: 'projects/a',
          name: 'A',
          decisions: [
            _decision(
              title: 'Newer proposal',
              proposed: true,
              date: '2026-09-25',
            ),
          ],
          roadmap: const <Milestone>[],
          approvals: const RoundApprovals({}),
        ),
        (
          folder: 'projects/b',
          name: 'B',
          decisions: [
            _decision(
              title: 'Older proposal',
              proposed: true,
              date: '2026-09-10',
            ),
          ],
          roadmap: const <Milestone>[],
          approvals: const RoundApprovals({}),
        ),
      ]);

      expect(items, hasLength(2));
      expect(items.first.title, 'Older proposal');
      expect(items.last.title, 'Newer proposal');
    });

    test('settled decisions and rounds contribute nothing', () {
      final items = waitingAcrossProjects([
        (
          folder: 'projects/a',
          name: 'A',
          decisions: [_decision(title: 'Already settled')],
          roadmap: const <Milestone>[],
          approvals: const RoundApprovals({}),
        ),
      ]);
      expect(items, isEmpty);
    });

    test('a waiting round with no date sorts after every dated item', () {
      final items = waitingAcrossProjects([
        (
          folder: 'projects/a',
          name: 'A',
          decisions: [
            _decision(
              title: 'Dated proposal',
              proposed: true,
              date: '2026-09-20',
            ),
          ],
          roadmap: [
            const Milestone(title: 'Round 38 — the UI overhaul', done: true),
          ],
          approvals: const RoundApprovals({}),
        ),
      ]);

      expect(items, hasLength(2));
      expect(items.first.title, 'Dated proposal');
      expect(items.last.title, 'Round 38 — the UI overhaul');
    });
  });
}
