// Round 16 — the Strategy tab. Pure widget tests: a Strategy and a
// roadmap are built by hand in memory, so these only check what this
// screen does with data it is handed.

import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
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
  List<DecisionReadResult> decisions = const [],
  String? objectiveToOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StrategyView(
          strategy: strategy,
          roadmap: roadmap,
          approvals: approvals,
          decisions: decisions,
          charterSourceFile: 'CHARTER.md',
          personaSourceFile: 'PERSONA.md',
          projectSourceFile: 'demo.md',
          objectiveToOpen: objectiveToOpen,
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
        whoItsFor: 'the user',
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

    testWidgets('Round 38 §D.1 — anything CHARTER.md holds beyond the evidence '
        'line shows only once expanded, under Why', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'the user',
        painPoints: '1. a pain',
        objectives: [
          Objective(
            title: 'Ship the thing',
            evidence: 'it ships',
            sentence:
                'Ship the thing. Would show: it ships. Served by '
                'Round 1.',
          ),
        ],
      );

      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
      );

      expect(find.text('WHY'), findsNothing);
      expect(find.textContaining('Served by Round 1.'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('WHY'), findsOneWidget);
      expect(find.text('Served by Round 1.'), findsOneWidget);
    });

    testWidgets('the progress sentence and segment bar show even '
        'collapsed', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'the user',
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
        whoItsFor: 'the user',
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
      // Round 38 §C, L19 — the objective's own aggregate pill is a link
      // now, "N waiting for your yes →", not the bare count it used to be.
      expect(find.text('1 waiting for your yes →'), findsOneWidget);
    });

    testWidgets('a matching row in the ledger makes the round completed, '
        'and the waiting pill disappears', (tester) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'the user',
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

      expect(find.text('1 waiting for your yes →'), findsNothing);
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
          whoItsFor: '**the user**, alone — see `PERSONA.md`.',
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
        expect(find.text('the user, alone — see PERSONA.md.'), findsOneWidget);
        expect(find.text('1. A bold pain, with code in it.'), findsOneWidget);
        expect(find.text('Ship the thing'), findsOneWidget);
      },
    );

    testWidgets(
      'Round 35/G — the evidence sentence and its word-only chip are both '
      'visible collapsed, under the title, as asa-strategy-v3 draws them '
      "— reversing an earlier persona-check's own overwhelm worry, "
      "the user's call once he approved the sketch",
      (tester) async {
        const strategy = Strategy(
          origin: 'o',
          whoItsFor: 'the user',
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
        expect(find.textContaining('Would show:'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pump();

        // Still visible expanded too — never a second, duplicate copy.
        expect(find.textContaining('Would show:'), findsOneWidget);
      },
    );
  });

  group('the legend', () {
    testWidgets('a round no objective claims is counted, not dropped', (
      tester,
    ) async {
      const strategy = Strategy(
        origin: 'o',
        whoItsFor: 'the user',
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

  group('round-36 §3, L12 — objectiveToOpen expands one objective on '
      'arrival', () {
    const strategy = Strategy(
      origin: 'o',
      whoItsFor: 'the user',
      painPoints: '1. a pain',
      objectives: [
        Objective(
          title: 'First objective',
          evidence: 'e1',
          sentence: 'First objective. Served by Round 1.',
        ),
        Objective(
          title: 'Second objective',
          evidence: 'e2',
          sentence: 'Second objective. Served by Round 2.',
        ),
      ],
    );

    testWidgets('"2" expands the second objective, not the first', (
      tester,
    ) async {
      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true), _round('2', done: true)],
        objectiveToOpen: '2',
      );

      expect(find.text('Round 1 — a real round'), findsNothing);
      expect(find.text('Round 2 — a real round'), findsOneWidget);
    });

    testWidgets('a number past the end of the list expands nothing, '
        'rather than throwing', (tester) async {
      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true), _round('2', done: true)],
        objectiveToOpen: '9',
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Round 1 — a real round'), findsNothing);
      expect(find.text('Round 2 — a real round'), findsNothing);
    });
  });

  group("round-36 §3, L15 — an objective's ADR chip opens decision detail; "
      'Round stays as built today', () {
    const decision = Decision(
      title: 'A real decision',
      why: 'w',
      decision: 'd',
      whatWouldChangeThis: 'c',
      sourceFile: 'decisions/0009.md',
      number: '0009',
    );

    const strategy = Strategy(
      origin: 'o',
      whoItsFor: 'the user',
      painPoints: '1. a pain',
      objectives: [
        Objective(
          title: 'Ship the thing',
          evidence: 'it ships',
          sentence: 'Ship the thing. Served by Round 1, ADR 0009.',
        ),
      ],
    );

    testWidgets('a loaded decision opens the real in-app detail screen, '
        'back returns here with the objective still expanded', (tester) async {
      await _pump(
        tester,
        strategy: strategy,
        roadmap: [_round('1', done: true)],
        decisions: const [
          DecisionReadResult(
            sourceFile: 'decisions/0009.md',
            decision: decision,
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      // Round 37 §D3 — both show both: the chip names the loaded
      // decision's own title with its number, not just "ADR 0009".
      await tester.tap(find.text('0009 · A real decision'));
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsOneWidget);
      // Round 37 §D3 — both show both: the header names the number with
      // the title now.
      expect(find.text('0009 · A real decision'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(find.text('Round 1 — a real round'), findsOneWidget);
    });
  });
}
