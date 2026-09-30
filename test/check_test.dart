// Round 39 cp4 — `asa-check`'s own tests. Real disk, temp folders, same
// discipline as `area_test.dart`'s own `readAreas` tests.

import 'dart:io';

import 'package:asa/core/change_history.dart';
import 'package:asa/core/check.dart';
import 'package:flutter_test/flutter_test.dart';

/// `checkProject`'s own "note behind the work" finding compares a real
/// file's real mtime — always today, whenever the suite actually runs —
/// against a fixture's own `updated:` field. A frozen calendar-date
/// literal there rots the moment real time moves past it; every fixture
/// and `now:` override below is built from this instead, so the suite
/// stays green on whatever day it runs, not just the day it was written.
final DateTime _now = DateTime.now();
String get _today => _now.toIso8601String().split('T').first;

void main() {
  late Directory tempDir;
  late String root;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-check-test-');
    root = tempDir.path;
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  String sep(String a, String b) => '$a${Platform.pathSeparator}$b';

  void writeSetup() {
    File(sep(root, '.asa-setup.md')).writeAsStringSync('set-up: 2026-09-28\n');
  }

  void writeFilledBoss() {
    File(sep(root, 'BOSS.md')).writeAsStringSync('''
# BOSS.md — Jamie

## Read this first — the short version

1. **How I like to get information:** One thing at a time.
2. **What makes me stop using a tool:** A pile of open items.
3. **What I decide myself, and what the AI can just do:** Everything mechanical is the AI's.
4. **How I work:** Evenings, most days.
5. **My language:** Plain English.

## Your rules — the second half of the list
''');
  }

  Directory makeProject(String name, String noteBody) {
    final dir = Directory(sep(root, name))..createSync(recursive: true);
    File(sep(dir.path, '$name.md')).writeAsStringSync(noteBody);
    return dir;
  }

  final wellShapedNote =
      '''
---
project: Demo
status: in-progress
updated: $_today
---
# Demo

## Tasks
- [ ] The next thing
''';

  group('a well-shaped project, laptop fully set up', () {
    test('OK — nothing to report', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);

      final findings = await checkProject(dir.path, now: DateTime(2026, 9, 28));
      expect(findings, isEmpty);
    });
  });

  group('setup and BOSS.md', () {
    test('missing .asa-setup.md is a finding', () async {
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains("Asa isn't set up here")),
      );
    });

    test('missing BOSS.md is a finding', () async {
      writeSetup();
      final dir = makeProject('demo', wellShapedNote);
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains('BOSS.md is missing')),
      );
    });

    test(r'the real, unfilled templates\BOSS.md reads as still the empty '
        'template', () async {
      writeSetup();
      final realTemplate = File('templates${Platform.pathSeparator}BOSS.md')
          .readAsStringSync();
      File(sep(root, 'BOSS.md')).writeAsStringSync(realTemplate);
      final dir = makeProject('demo', wellShapedNote);

      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains('still the empty template')),
      );
    });

    test('a filled-in BOSS.md is not a finding', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        isNot(contains(contains('BOSS.md'))),
      );
    });
  });

  group('status words', () {
    test('an old status word is a finding, naming the new one', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject(
        'demo',
        wellShapedNote.replaceFirst('status: in-progress', 'status: building'),
      );
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains('old status word "building" — write "in-progress"')),
      );
    });

    test('an unrecognized status word is its own finding', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject(
        'demo',
        wellShapedNote.replaceFirst('status: in-progress', 'status: planning'),
      );
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains('unknown status word "planning"')),
      );
    });
  });

  group("Asa's shape (manual §13)", () {
    test('a note with no ## Tasks section is a finding', () async {
      writeSetup();
      writeFilledBoss();
      const noTasks = '''
---
project: Demo
status: idea
updated: 2026-09-28
---
# Demo
Nothing yet.
''';
      final dir = makeProject('demo', noTasks);
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains("not in Asa's shape")),
      );
    });

    test('an old-style section name is a finding', () async {
      writeSetup();
      writeFilledBoss();
      const oldStyle = '''
---
project: Demo
status: idea
updated: 2026-09-28
---
# Demo

## Where it stands
Some prose.

## Tasks
- [ ] A thing
''';
      final dir = makeProject('demo', oldStyle);
      final findings = await checkProject(dir.path);
      expect(
        findings.map((f) => f.message),
        contains(contains('"## Where It Stands"')),
      );
    });
  });

  group('freshness — note behind the work, over budget', () {
    test('a note with a recent updated: and a quiet folder is fine', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      final findings = await checkProject(dir.path, now: DateTime(2026, 9, 28));
      expect(findings, isEmpty);
    });

    test('an on-hold project is never flagged behind or over budget', () async {
      writeSetup();
      writeFilledBoss();
      final stale = wellShapedNote
          .replaceFirst('status: in-progress', 'status: on-hold')
          .replaceFirst('updated: $_today', 'updated: 2020-01-01');
      final dir = makeProject('demo', stale);
      final findings = await checkProject(dir.path, now: DateTime(2026, 9, 28));
      expect(findings, isEmpty);
    });
  });

  group('sessions', () {
    test(
      'an open session updated over 2 hours ago is probably cut off',
      () async {
        writeSetup();
        writeFilledBoss();
        final dir = makeProject('demo', wellShapedNote);
        File(sep(dir.path, '.asa-session.md')).writeAsStringSync('''
---
status: open
updated: 2026-09-28T10:00:00
---
Doing: something
''');
        final findings = await checkProject(
          dir.path,
          now: DateTime(2026, 9, 28, 15),
        );
        expect(
          findings.map((f) => f.message),
          contains(contains('probably cut off')),
        );
      },
    );

    test('a closed session is never flagged', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      File(sep(dir.path, '.asa-session.md')).writeAsStringSync('''
---
status: closed
updated: 2026-09-28T10:00:00
---
Last done: something
''');
      final findings = await checkProject(
        dir.path,
        now: DateTime(2026, 9, 28, 15),
      );
      expect(findings, isEmpty);
    });
  });

  group('(waiting: Name, since YYYY-MM-DD) over 14 days', () {
    test('a wait over 14 days is a finding', () async {
      writeSetup();
      writeFilledBoss();
      final waiting =
          '''
---
project: Demo
status: idea
updated: $_today
---
# Demo

## Tasks
- [ ] Ask legal a question (waiting: Legal, since 2026-09-01)
''';
      final dir = makeProject('demo', waiting);
      final findings = await checkProject(dir.path, now: DateTime(2026, 9, 28));
      expect(
        findings.map((f) => f.message),
        contains(contains('waiting on Legal since 2026-09-01 — over 14 days')),
      );
    });

    test('a wait under 14 days is not a finding yet', () async {
      writeSetup();
      writeFilledBoss();
      final waiting =
          '''
---
project: Demo
status: idea
updated: $_today
---
# Demo

## Tasks
- [ ] Ask legal a question (waiting: Legal, since 2026-09-20)
''';
      final dir = makeProject('demo', waiting);
      final findings = await checkProject(dir.path, now: DateTime(2026, 9, 28));
      expect(findings, isEmpty);
    });
  });

  group('an unreadable project', () {
    test("says why, doesn't crash", () async {
      final findings = await checkProject(sep(root, 'nope'));
      expect(
        findings.map((f) => f.message),
        contains(contains('Could not read the project')),
      );
    });
  });

  group('bossFillPrompt — cp6\'s own "Fill with your AI" button', () {
    test('finds the real quoted prompt in the real templates/BOSS.md', () {
      final text = File('templates/BOSS.md').readAsStringSync();
      final prompt = bossFillPrompt(text);
      expect(prompt, isNotNull);
      expect(prompt, contains('Write my BOSS.md for Asa'));
      expect(prompt, isNot(contains('>')));
    });

    test('null when the quote shape is not there at all', () {
      expect(bossFillPrompt('# Nothing here'), isNull);
    });
  });

  group('changed without a note (ADR 0048) — real, not merely read-only', () {
    late Directory historyDir;

    setUp(() {
      historyDir = Directory.systemTemp.createTempSync(
        'asa-check-history-test-',
      );
    });

    tearDown(() => historyDir.deleteSync(recursive: true));

    test('nothing recorded yet (asa-brief never ran) reports OK, not a '
        'false finding', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);

      final findings = await checkProject(
        dir.path,
        now: DateTime(2026, 9, 28),
        historyRoot: historyDir.path,
      );
      expect(findings, isEmpty);
    });

    test('an unlogged CHARTER.md edit is a real finding, same as '
        "asa-brief --since's own", () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      final charterPath = sep(dir.path, 'CHARTER.md');
      File(charterPath).writeAsStringSync('## Objectives\n1. First.\n');

      // Baseline snapshot — same as asa-brief --all's own first look.
      await recordChanges(dir.path, root, historyRoot: historyDir.path);

      // The unlogged edit, with no matching .asa-log.md line at all.
      File(charterPath).writeAsStringSync('## Objectives\n1. Changed.\n');
      await recordChanges(dir.path, root, historyRoot: historyDir.path);

      final findings = await checkProject(
        dir.path,
        now: DateTime(2026, 9, 28),
        historyRoot: historyDir.path,
      );
      expect(
        findings.map((f) => f.message),
        contains(contains('CHARTER.md changed, not logged')),
      );
    });

    test('a same-day log line naming CHARTER.md clears the finding', () async {
      writeSetup();
      writeFilledBoss();
      final dir = makeProject('demo', wellShapedNote);
      final charterPath = sep(dir.path, 'CHARTER.md');
      File(charterPath).writeAsStringSync('## Objectives\n1. First.\n');
      await recordChanges(dir.path, root, historyRoot: historyDir.path);

      File(charterPath).writeAsStringSync('## Objectives\n1. Changed.\n');
      final today = DateTime.now();
      await recordChanges(
        dir.path,
        root,
        historyRoot: historyDir.path,
        now: today,
      );
      final logLine =
          '- ${today.toIso8601String().split("T").first} 10:00-10:05 · '
          'test · updated the objective · CHARTER.md\n';
      File(sep(dir.path, '.asa-log.md')).writeAsStringSync(logLine);

      final findings = await checkProject(
        dir.path,
        now: DateTime(2026, 9, 28),
        historyRoot: historyDir.path,
      );
      expect(
        findings.map((f) => f.message),
        isNot(contains(contains('CHARTER.md'))),
      );
    });
  });
}
