// Round 16 — the Strategy tab. Pure widget tests: a Strategy and a
// roadmap are built by hand in memory, so these only check what this
// screen does with data it is handed.

import 'package:asa/core/charter.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/strategy_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Milestone _round(String number, {required bool done, String extra = ''}) {
  return Milestone(
    title: 'Round $number — a real round',
    done: done,
    bodyLines: extra.isEmpty ? const [] : [extra],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Strategy strategy,
  List<Milestone> roadmap = const [],
  RoundApprovals approvals = const RoundApprovals({}),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StrategyView(
          strategy: strategy,
          roadmap: roadmap,
          approvals: approvals,
          decisions: const [],
          charterSourceFile: 'CHARTER.md',
          personaSourceFile: 'PERSONA.md',
          projectSourceFile: 'demo.md',
        ),
      ),
    ),
  );
}

void main() {
  group('objective expand/collapse — collapsed by default', () {
    testWidgets('a round is not shown until the objective is expanded', (
      tester,
    ) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence: 'Ship the thing. Served by Round 1.',
          ),
        ],
      );

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
      );

      expect(find.text('Ship the thing'), findsOneWidget);
      expect(find.text('Round 1 — a real round'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Round 1 — a real round'), findsOneWidget);
    });

    testWidgets('the progress sentence and segment bar show even '
        'collapsed', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence: 'Ship the thing. Served by Round 1 and Round 2.',
          ),
        ],
      );

      // Round 1 is done but has no row in the (default empty) ledger, so
      // it reads as waiting for approval, not completed — 0 of 2.
      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true), _round('2', done: false)],
      );

      expect(find.text('0 of 2 completed'), findsOneWidget);
    });
  });

  group('the empty-ledger case', () {
    testWidgets('a done round with no approval row waits for approval, '
        'shown once expanded', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence: 'Ship the thing. Served by Round 1.',
          ),
        ],
      );

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Two matches, deliberately: the round's own state pill, and the
      // legend's always-visible label for the same colour/word.
      expect(find.text('waiting for your approval'), findsNWidgets(2));
      expect(find.text('1 waiting for you'), findsOneWidget);
    });

    testWidgets('a matching row in the ledger makes the round completed, '
        'and the waiting pill disappears', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence: 'Ship the thing. Served by Round 1.',
          ),
        ],
      );
      const approvals = RoundApprovals({
        '1': (date: '2026-09-15', words: 'yes', result: 'shipped'),
      });

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
        approvals: approvals,
      );

      expect(find.text('1 waiting for you'), findsNothing);
      expect(find.text('1 of 1 completed'), findsOneWidget);
    });
  });

  group('persona-check fixes, re-run against the real screen', () {
    testWidgets(
      'markdown markers in real prose are stripped for display — found '
      "on Who it's for, Pain points and an objective's evidence",
      (tester) async {
        const strategy = Strategy(
          origin: 'o',
          whoItsFor: '**Nico**, alone — see `PERSONA.md`.',
          painPoints: '1. A **bold** pain, with `code` in it.',
          objectives: [
            Objective(
              title: 'Ship the **thing**',
              evidence: 'a `file` changes. **Holding.**',
              sentence: 'Ship the thing. Served by Round 1.',
            ),
          ],
        );

        await _pump(
          tester,
          strategy: strategy,
          roadmap: [_round('1', done: true)],
        );
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();

        expect(find.textContaining('**'), findsNothing);
        expect(find.textContaining('`'), findsNothing);
        expect(find.text('Nico, alone — see PERSONA.md.'), findsOneWidget);
        expect(find.text('1. A bold pain, with code in it.'), findsOneWidget);
        expect(find.text('Ship the thing'), findsOneWidget);
      },
    );

    testWidgets('the evidence sentence stays hidden until expanded, but '
        'its word-only chip is visible collapsed — rule 7, colour is '
        'never the only signal', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'a decision gets recovered. **Failing.**',
            sentence: 'Ship the thing. Served by Round 1.',
          ),
        ],
      );

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
      );

      expect(find.text('failing'), findsOneWidget);
      expect(find.textContaining('Would show:'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.textContaining('Would show:'), findsOneWidget);
    });
  });

  group('the legend', () {
    testWidgets('a round no objective claims is counted, not dropped', (
      tester,
    ) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'Nico',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence: 'Ship the thing. Served by Round 1.',
          ),
        ],
      );

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true), _round('2', done: false)],
      );

      expect(find.text('1 round serves no objective yet'), findsOneWidget);
    });
  });
}
