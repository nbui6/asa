// Round 32/A — the right-hand value on a project row.

import 'dart:io';

import 'package:asa/core/freshness.dart';
import 'package:asa/core/git_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _noGit = GitState(command: '(not run)', rawOutput: '');

void main() {
  group('lastTouchedOf', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asa-freshness-test-');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('git wins when it is readable', () async {
      File('${tempDir.path}${Platform.pathSeparator}note.md')
          .writeAsStringSync('x');
      final gitDate = DateTime(2026, 9);
      final git = GitState(
        command: 'git log',
        rawOutput: '2026-09-01',
        lastCommit: gitDate,
      );

      final touched = await lastTouchedOf(tempDir.path, git);
      expect(touched, gitDate);
    });

    test(
      'falls back to the newest file mtime when git has no answer',
      () async {
        final older = File('${tempDir.path}${Platform.pathSeparator}old.md')
          ..writeAsStringSync('old');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final newer = File('${tempDir.path}${Platform.pathSeparator}new.md')
          ..writeAsStringSync('new');

        final touched = await lastTouchedOf(tempDir.path, _noGit);
        final newerStat = newer.statSync().modified;
        final olderStat = older.statSync().modified;

        expect(touched, isNotNull);
        expect(touched!.difference(newerStat).inSeconds.abs(), lessThan(2));
        expect(touched.isAfter(olderStat) || touched == olderStat, isTrue);
      },
    );

    test(
      'recurses into subfolders, skipping `_`- and `.`-prefixed ones',
      () async {
        final visible = Directory('${tempDir.path}${Platform.pathSeparator}sub')
          ..createSync();
        File('${visible.path}${Platform.pathSeparator}deep.md')
            .writeAsStringSync('deep');

        final hiddenDot = Directory(
          '${tempDir.path}${Platform.pathSeparator}.hidden',
        )..createSync();
        // Make the hidden file's own mtime far in the future so a bug that
        // fails to skip it would be obvious rather than accidentally masked
        // by real clock timing.
        File('${hiddenDot.path}${Platform.pathSeparator}secret.md')
          ..writeAsStringSync('secret')
          ..setLastModifiedSync(DateTime(2099));

        final hiddenUnderscore = Directory(
          '${tempDir.path}${Platform.pathSeparator}_archive',
        )..createSync();
        File('${hiddenUnderscore.path}${Platform.pathSeparator}old-thing.md')
          ..writeAsStringSync('archived')
          ..setLastModifiedSync(DateTime(2099));

        final touched = await lastTouchedOf(tempDir.path, _noGit);
        expect(touched, isNotNull);
        expect(touched!.year, isNot(2099));
      },
    );

    test('an empty, newly-created folder with no git has no answer', () async {
      final empty = Directory('${tempDir.path}${Platform.pathSeparator}empty')
        ..createSync();
      final touched = await lastTouchedOf(empty.path, _noGit);
      expect(touched, isNull);
    });

    test('a folder that does not exist has no answer, not a crash', () async {
      final touched = await lastTouchedOf(
        '${tempDir.path}${Platform.pathSeparator}gone',
        _noGit,
      );
      expect(touched, isNull);
    });
  });

  group('freshnessText', () {
    final now = DateTime(2026, 9, 25);

    test('the deadline wins when there is one', () {
      final text = freshnessText(
        humanizedDeadline: 'Oct 2026',
        lastTouched: DateTime(2026, 9),
        now: now,
      );
      expect(text, 'Oct 2026');
    });

    test('today, when last touched is today', () {
      final text = freshnessText(
        humanizedDeadline: null,
        lastTouched: now,
        now: now,
      );
      expect(text, 'today');
    });

    test('1 day, singular, not "1 days"', () {
      final text = freshnessText(
        humanizedDeadline: null,
        lastTouched: now.subtract(const Duration(days: 1)),
        now: now,
      );
      expect(text, '1 day');
    });

    test('N days for anything further back', () {
      final text = freshnessText(
        humanizedDeadline: null,
        lastTouched: now.subtract(const Duration(days: 21)),
        now: now,
      );
      expect(text, '21 days');
    });

    test('null when there is neither a deadline nor a touch date', () {
      final text = freshnessText(
        humanizedDeadline: null,
        lastTouched: null,
        now: now,
      );
      expect(text, isNull);
    });
  });
}
