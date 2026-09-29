// Round 39 cp3 — `asa-brief`'s own golden test: run against a temp copy of
// the committed `test\fixtures\round-36\` fixture (never the committed
// copy itself — same discipline `integration_test\click_through_test.dart`
// already follows), and check the numbers and names it prints are the
// real ones a person reading the fixture by hand would find, the same
// contract Asa's own screens already have.

import 'dart:io';

import 'package:asa/core/brief.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String root;

  setUpAll(() {
    // Relative to the repo root, which is `flutter test`'s own working
    // directory — portable across machines, unlike a hardcoded absolute
    // path baked in with one contributor's own username.
    final pristineFixture = Directory(
      '${Directory.current.path}/test/fixtures/round-36',
    );
    tempDir = Directory.systemTemp.createTempSync('asa-brief-test-');
    root = tempDir.path;
    _copyDir(pristineFixture, Directory(root));
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  String northwind() => '$root${Platform.pathSeparator}northwind';

  group('briefProject — the always slice', () {
    test('names the project and its literal "(not set)" next step — the '
        'fixture has no next-step field, and asa-brief must not invent '
        'one', () async {
      final text = await briefProject(northwind());
      expect(text, contains('# Northwind partnership'));
      expect(text, contains('- Status: building'));
      expect(text, contains('- Next step: (not set)'));
    });

    test('the one proposed decision (ADR 0011) is the only one shown — '
        '0003 and 0006 are both accepted, not proposed', () async {
      final text = await briefProject(northwind());
      expect(text, contains('## Decisions waiting, or always in scope'));
      expect(text, contains('ADR 0011 (proposed)'));
      expect(text, isNot(contains('ADR 0003 (proposed)')));
      expect(text, isNot(contains('ADR 0006')));
    });

    test('every area appears, at a glance, when neither --area nor --round '
        'is given', () async {
      final text = await briefProject(northwind());
      expect(text, contains('## Areas, at a glance'));
      expect(text, contains('Marketing:'));
      expect(text, contains('Sales:'));
      expect(text, contains('Enablement:'));
      expect(text, contains('Finance:'));
    });

    test('an unreadable project folder says why, not a stack trace', () async {
      final text = await briefProject('$root${Platform.pathSeparator}nope');
      expect(text, contains('No folder at'));
    });
  });

  group('briefProject --area — the real Sales page', () {
    test('goal, open tasks, results, objective and linked decisions all '
        'match the real fixture file by hand', () async {
      final text = await briefProject(northwind(), area: 'Sales');
      expect(text, contains('## Area: Sales'));
      expect(text, contains('Serves Objective 1'));

      // Five tasks total, two already checked off — three open.
      expect(
        text,
        contains('Second demo for the account from the first pitch'),
      );
      expect(text, contains('Show the partner how deal registration works'));
      expect(text, contains('Partner pitches one account alone'));
      expect(text, isNot(contains('Agree the shared account list')));

      expect(text, contains('2026-09-20 — First joint pitch'));
      expect(text, contains('2026-09-08 — Account list agreed'));

      expect(
        text,
        contains('Objective 1: The partner brings its own customers'),
      );

      expect(text, contains('ADR 0003'));
      expect(text, contains('ADR 0006'));
    });

    test('an area name with no matching page says so plainly', () async {
      final text = await briefProject(northwind(), area: 'Nonexistent');
      expect(text, contains('No area page found with that name.'));
    });
  });

  group(r'briefProject --round — no rounds\ folder in this fixture', () {
    test('a project with no rounds folder at all says the file is missing, '
        "not that the round doesn't exist", () async {
      final text = await briefProject(northwind(), round: '99');
      expect(text, contains('No `rounds/round-99.md` file found.'));
    });
  });

  group('briefAll — every project in the fixture', () {
    test('every real project folder is named, and a skipped one is too, '
        'never silently dropped', () async {
      final text = await briefAll(root);
      expect(text, contains('## Northwind partnership'));
      expect(text, contains('Waiting for the user: 1 decision(s)'));
    });
  });

  group('briefAll — Round 38 §F, ADR 0036 — hidden statuses collapse to '
      'one line', () {
    late Directory hiddenRoot;

    setUpAll(() {
      hiddenRoot = Directory.systemTemp.createTempSync(
        'asa-brief-hidden-test-',
      );
      final active = Directory(
        '${hiddenRoot.path}${Platform.pathSeparator}active-project',
      )..createSync();
      File(
        '${active.path}${Platform.pathSeparator}active-project.md',
      ).writeAsStringSync('''
---
project: Active Project
status: building
updated: 2026-09-13
---

## Tasks
''');
      final paused = Directory(
        '${hiddenRoot.path}${Platform.pathSeparator}paused-project',
      )..createSync();
      File(
        '${paused.path}${Platform.pathSeparator}paused-project.md',
      ).writeAsStringSync('''
---
project: Paused Project
status: on-hold
updated: 2026-09-13
---

## Tasks
''');
      final canceled = Directory(
        '${hiddenRoot.path}${Platform.pathSeparator}canceled-project',
      )..createSync();
      File(
        '${canceled.path}${Platform.pathSeparator}canceled-project.md',
      ).writeAsStringSync('''
---
project: Canceled Project
status: canceled
updated: 2026-09-13
---

## Tasks
''');
    });

    tearDownAll(() {
      hiddenRoot.deleteSync(recursive: true);
    });

    test('an active project keeps its own full section; on-hold and '
        'canceled collapse into one "Out of sight" line instead', () async {
      final text = await briefAll(hiddenRoot.path);

      expect(text, contains('## Active Project'));
      expect(text, isNot(contains('## Paused Project')));
      expect(text, isNot(contains('## Canceled Project')));

      expect(text, contains('## Out of sight'));
      expect(text, contains('On hold 1'));
      expect(text, contains('Canceled 1'));
    });
  });

  group('briefSince', () {
    test('a date after every real decision finds nothing', () async {
      final text = await briefSince(root, DateTime(2030));
      expect(text, contains('Nothing recorded since then.'));
    });

    test('a date before ADR 0011 (2026-09-24, proposed) finds it', () async {
      final text = await briefSince(root, DateTime(2026, 9, 20));
      expect(text, contains('Northwind partnership'));
      expect(text, contains('ADR 0011'));
    });

    test("a date after ADR 0011's own date, before nothing else, finds "
        'nothing for Northwind', () async {
      final text = await briefSince(root, DateTime(2026, 9, 25));
      expect(text, isNot(contains('Northwind partnership')));
    });

    test('a recent .asa-log.md line is included, newest first', () async {
      final logFile = File('${northwind()}${Platform.pathSeparator}.asa-log.md')
        ..writeAsStringSync(
          '- 2026-09-20 09:00–09:30 · Claude Code · older line · x\n'
          '- 2026-09-26 10:00–10:30 · Claude Code · newer line · y\n',
        );
      addTearDown(logFile.deleteSync);

      final text = await briefSince(root, DateTime(2026, 9, 25));
      expect(text, contains('Northwind partnership'));
      expect(text, contains('newer line'));
      expect(text, isNot(contains('older line')));
    });
  });

  group(r"projects\BOSS.md's own Read this first and Your rules — invented "
      'content only, never the real file (round-39.md, ADR 0043)', () {
    late Directory bossDir;

    setUp(() {
      bossDir = Directory.systemTemp.createTempSync('asa-brief-boss-test-');
      final demo = Directory('${bossDir.path}${Platform.pathSeparator}demo')
        ..createSync();
      File('${demo.path}${Platform.pathSeparator}demo.md')
          .writeAsStringSync('---\nproject: Demo\nstatus: idea\n---\n# Demo\n');
      File('${bossDir.path}${Platform.pathSeparator}BOSS.md')
          .writeAsStringSync('''
# BOSS.md — invented for this test, never the real file

## Read this first — the short version
1. Invented fact one, for this test only.
2. Invented fact two.

## Your rules — the second half of the list
1. 2026-09-01 — Invented rule one, for this test only.

## The rest of the file
Not part of either section, and never printed by asa-brief.
''');
    });

    tearDown(() => bossDir.deleteSync(recursive: true));

    test('prints both sections at the top of a project briefing', () async {
      final text = await briefProject(
        '${bossDir.path}${Platform.pathSeparator}demo',
      );
      expect(text, contains('## Working with you'));
      expect(text, contains('Invented fact one, for this test only.'));
      expect(text, contains('Invented rule one, for this test only.'));
      expect(text, isNot(contains('never printed by asa-brief')));
    });

    test('prints at the top of --all too', () async {
      final text = await briefAll(bossDir.path);
      expect(text, contains('## Working with you'));
      expect(text, contains('Invented fact two.'));
      expect(text, contains('Invented rule one, for this test only.'));
    });

    test('no BOSS.md at all is silently absent, never invented', () async {
      File('${bossDir.path}${Platform.pathSeparator}BOSS.md').deleteSync();
      final text = await briefProject(
        '${bossDir.path}${Platform.pathSeparator}demo',
      );
      expect(text, isNot(contains('Working with you')));
    });
  });

  group(r'Round 39 cp8 — recording is opt-in, never the real %APPDATA%\Asa\ '
      'by accident', () {
    late Directory historyDir;

    setUp(() {
      historyDir = Directory.systemTemp.createTempSync(
        'asa-brief-history-test-',
      );
    });

    tearDown(() => historyDir.deleteSync(recursive: true));

    test('recordHistory defaults to false — nothing is ever written, '
        'even with a historyRoot given', () async {
      await briefProject(northwind(), historyRoot: historyDir.path);
      expect(historyDir.listSync(), isEmpty);
    });

    test('recordHistory: true actually records, into the given '
        'sandboxed root only', () async {
      await briefProject(
        northwind(),
        recordHistory: true,
        historyRoot: historyDir.path,
      );
      expect(historyDir.listSync(), isNotEmpty);
    });

    test('--since shows a recorded change as changed, not logged, when '
        'no .asa-log.md entry matches its date', () async {
      final charterFile = File(
        '${northwind()}${Platform.pathSeparator}CHARTER.md',
      );
      final originalCharter = charterFile.readAsStringSync();
      addTearDown(() => charterFile.writeAsStringSync(originalCharter));

      await briefProject(
        northwind(),
        recordHistory: true,
        historyRoot: historyDir.path,
        now: DateTime(2026, 9, 20),
      );
      charterFile.writeAsStringSync('# Changed for this test\n');
      await briefProject(
        northwind(),
        recordHistory: true,
        historyRoot: historyDir.path,
        now: DateTime(2026, 9, 27),
      );

      final text = await briefSince(
        root,
        DateTime(2026, 9, 25),
        historyRoot: historyDir.path,
      );
      expect(text, contains('CHARTER.md changed'));
      expect(text, contains('changed, not logged'));
    });
  });
}

void _copyDir(Directory src, Directory dst) {
  dst.createSync(recursive: true);
  for (final entity in src.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final newPath = '${dst.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      _copyDir(entity, Directory(newPath));
    } else if (entity is File) {
      entity.copySync(newPath);
    }
  }
}
