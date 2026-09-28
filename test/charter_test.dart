// Round 16 — reading CHARTER.md's four fixed sections into a Strategy.

import 'dart:io';

import 'package:asa/core/charter.dart';
import 'package:asa/core/plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _realShaped = '''
# Charter — Demo

## Origin

**Points at §1, never restates it.** Full account: §1 below.

## Who it's for

The user, alone.

## Pain points

1. Decisions get lost.
2. Side projects die quietly.

## Objectives

1. **Start working again in under a minute.** *(`PERSONA.md`)*
   Would show: he opens Asa unprompted after a gap. **Unknown.**
   Served by Round 0, Round 1, and Round 6.

2. **Know what was decided.** *(`PERSONA.md`, 2026-09-01)*
   Would show: a decision gets recovered from Asa. **Holding.**
   Served by Round 5 and Round 26.

Not decided here, on purpose: whether a Round may serve more than one
objective — see ADR 0024.
''';

void main() {
  group('readCharter — the four sections', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('asa-charter-test-');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('a real-shaped CHARTER.md reads all four sections', () async {
      File('${tempDir.path}${Platform.pathSeparator}CHARTER.md')
          .writeAsStringSync(_realShaped);

      final strategy = await readCharter(tempDir.path);

      expect(strategy.isEmpty, isFalse);
      expect(strategy.origin, contains('Points at §1'));
      expect(strategy.whoItsFor, 'The user, alone.');
      expect(strategy.painPoints, contains('Decisions get lost.'));
      expect(strategy.objectives, hasLength(2));
    });

    test('an objective carries its title, its evidence line, and its own '
        'raw paragraph for deriveLinks', () async {
      File('${tempDir.path}${Platform.pathSeparator}CHARTER.md')
          .writeAsStringSync(_realShaped);

      final strategy = await readCharter(tempDir.path);
      final first = strategy.objectives.first;

      expect(first.title, 'Start working again in under a minute.');
      expect(
        first.evidence,
        'he opens Asa unprompted after a gap. **Unknown.**',
      );

      final rounds = deriveLinks(first.sentence)
          .where((l) => l.kind == PlanLinkKind.round)
          .map((l) => l.target);
      expect(rounds, containsAll(['0', '1', '6']));
    });

    test(
      'the trailing paragraph after the last objective (mentioning '
      "ADR 0024) does not leak into that objective's own Round links",
      () async {
        File('${tempDir.path}${Platform.pathSeparator}CHARTER.md')
            .writeAsStringSync(_realShaped);

        final strategy = await readCharter(tempDir.path);
        final second = strategy.objectives.last;

        final adrLinks = deriveLinks(second.sentence)
            .where((l) => l.kind == PlanLinkKind.adr);
        expect(adrLinks, isEmpty);
      },
    );

    test('missing any one of the four sections makes the whole Strategy '
        'empty — no partial screen', () async {
      const missingObjectives = '''
# Charter — Demo

## Origin

Something.

## Who it's for

The user.

## Pain points

1. A pain.
''';
      File('${tempDir.path}${Platform.pathSeparator}CHARTER.md')
          .writeAsStringSync(missingObjectives);

      final strategy = await readCharter(tempDir.path);
      expect(strategy.isEmpty, isTrue);
    });

    test('no CHARTER.md at all reads as empty, not an error', () async {
      final strategy = await readCharter(tempDir.path);
      expect(strategy.isEmpty, isTrue);
      expect(strategy.origin, isNull);
      expect(strategy.objectives, isEmpty);
    });

    test('pain points drops a preamble before the list — real shape, '
        "CHARTER.md's own section carries an editorial paragraph about "
        'when it was moved, before the three real pain points start', () async {
      const withPreamble = '''
# Charter — Demo

## Origin

Something.

## Who it's for

The user.

## Pain points

**Added 2026-09-14, moved here and renamed** after a sketch loop — this
sentence is commentary about the section, not a pain point.

1. Decisions get lost.
2. Side projects die quietly.

## Objectives

1. **A title.** *(source)*
   Would show: something. **Holding.**
   Served by Round 1.
''';
      File('${tempDir.path}${Platform.pathSeparator}CHARTER.md')
          .writeAsStringSync(withPreamble);

      final strategy = await readCharter(tempDir.path);

      expect(strategy.painPoints, isNot(contains('commentary')));
      expect(strategy.painPoints, startsWith('1. Decisions get lost.'));
    });
  });

  group("the real fixture — Asa's own CHARTER.md", () {
    test('reads as a non-empty Strategy with 3-5 objectives', () async {
      final projectFolder =
          '${Directory.current.path}${Platform.pathSeparator}..'
          '${Platform.pathSeparator}projects${Platform.pathSeparator}asa';
      if (!Directory(projectFolder).existsSync()) {
        return; // Gate 2: only runs where projects\asa exists locally.
      }

      final strategy = await readCharter(projectFolder);

      expect(strategy.isEmpty, isFalse);
      expect(strategy.objectives.length, inInclusiveRange(3, 5));
      for (final objective in strategy.objectives) {
        expect(objective.title, isNotEmpty);
      }
    });
  });
}
