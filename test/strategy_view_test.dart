// Round 16 — the Strategy tab. Pure widget tests: a Strategy and a
// roadmap are built by hand in memory, so these only check what this
// screen does with data it is handed.

import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/strategy_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<void> Function(String heading, String oldValue, String newText)?
  onSetCharterSection,
  Future<void> Function(String heading)? onClearCharterSection,
  Future<void> Function()? onCreateCharterFile,
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
          onSetCharterSection: onSetCharterSection,
          onClearCharterSection: onClearCharterSection,
          onCreateCharterFile: onCreateCharterFile,
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
        fileExists: true,
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
        fileExists: true,
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
        fileExists: true,
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
        fileExists: true,
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
        fileExists: true,
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
          fileExists: true,
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
          fileExists: true,
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
        fileExists: true,
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
      fileExists: true,
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
      fileExists: true,
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

  group('ADR 0050 — no CHARTER.md at all', () {
    const noFile = Strategy(
      fileExists: false,
      origin: null,
      whoItsFor: null,
      painPoints: null,
      objectives: [],
    );

    testWidgets('shows the one line and the one ＋; tapping it calls '
        'onCreateCharterFile', (tester) async {
      var created = false;
      await _pump(
        tester,
        strategy: noFile,
        onCreateCharterFile: () async => created = true,
      );

      expect(find.text('No strategy yet.'), findsOneWidget);
      expect(find.text('＋'), findsOneWidget);

      await tester.tap(find.text('＋'));
      await tester.pump();

      expect(created, isTrue);
    });

    testWidgets('with no onCreateCharterFile wired, falls back to the older '
        '"ask the AI" line and no ＋ at all', (tester) async {
      await _pump(tester, strategy: noFile);

      expect(
        find.textContaining('ask the AI to write CHARTER.md'),
        findsOneWidget,
      );
      expect(find.text('＋'), findsNothing);
    });
  });

  group("ADR 0050 — Who it's for / Pain points / Objectives, each its own "
      'empty place', () {
    const partial = Strategy(
      fileExists: true,
      origin: 'o',
      whoItsFor: null,
      painPoints: null,
      objectives: [],
    );

    testWidgets(
      'a CHARTER.md with none of the three sections filled shows three '
      'headings, each with its own ＋ — never the old all-or-nothing '
      '"No strategy yet" line',
      (tester) async {
        await _pump(
          tester,
          strategy: partial,
          onSetCharterSection: (heading, oldValue, text) async {},
        );

        expect(find.text('No strategy yet.'), findsNothing);
        // SectionLabel renders its own text upper-cased.
        expect(find.text("WHO IT'S FOR"), findsOneWidget);
        expect(find.text('PAIN POINTS'), findsOneWidget);
        expect(find.text('OBJECTIVES'), findsOneWidget);
        expect(find.text('＋'), findsNWidgets(3));
      },
    );

    testWidgets(
      'with no writer wired at all, an empty section falls back to its '
      'own plain line instead of a silent, inert ＋',
      (tester) async {
        await _pump(tester, strategy: partial);

        expect(find.text('＋'), findsNothing);
        expect(find.text("No who it's for yet."), findsOneWidget);
        expect(find.text('No pain points yet.'), findsOneWidget);
      },
    );

    testWidgets(
      "tapping Who it's for's ＋ opens an inline field; Enter writes via "
      "onSetCharterSection with heading \"Who it's for\" and oldValue ''",
      (tester) async {
        String? writtenHeading;
        String? writtenOldValue;
        String? writtenText;
        await _pump(
          tester,
          strategy: partial,
          onSetCharterSection: (heading, oldValue, text) async {
            writtenHeading = heading;
            writtenOldValue = oldValue;
            writtenText = text;
          },
        );

        await tester.tap(find.text('＋').first);
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Solo builders.');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(writtenHeading, "Who it's for");
        expect(writtenOldValue, '');
        expect(writtenText, 'Solo builders.');
      },
    );

    testWidgets('Esc closes the empty-place field without writing', (
      tester,
    ) async {
      var written = false;
      await _pump(
        tester,
        strategy: partial,
        onSetCharterSection: (heading, oldValue, text) async {
          written = true;
        },
      );

      await tester.tap(find.text('＋').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ignored');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('＋'), findsNWidgets(3));
      expect(written, isFalse);
    });

    testWidgets(
      "✎ on hover of a filled Who it's for edits it in place, pre-filled; "
      'Enter writes the new text with the old one as oldValue',
      (tester) async {
        const filled = Strategy(
          fileExists: true,
          origin: 'o',
          whoItsFor: 'Solo builders, alone.',
          painPoints: null,
          objectives: [],
        );
        String? writtenOldValue;
        String? writtenText;
        await _pump(
          tester,
          strategy: filled,
          onSetCharterSection: (heading, oldValue, text) async {
            writtenOldValue = oldValue;
            writtenText = text;
          },
        );

        expect(find.byIcon(Icons.edit), findsNothing);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(find.text('Solo builders, alone.')),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit), findsOneWidget);
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pump();

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.controller!.text, 'Solo builders, alone.');

        await tester.enterText(find.byType(TextField), 'Solo builders.');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(writtenOldValue, 'Solo builders, alone.');
        expect(writtenText, 'Solo builders.');
      },
    );

    testWidgets("🗑 in a filled Who it's for's own edit mode calls "
        'onClearCharterSection, never onSetCharterSection', (tester) async {
      const filled = Strategy(
        fileExists: true,
        origin: 'o',
        whoItsFor: 'Solo builders, alone.',
        painPoints: null,
        objectives: [],
      );
      String? clearedHeading;
      await _pump(
        tester,
        strategy: filled,
        onSetCharterSection: (heading, oldValue, text) async {},
        onClearCharterSection: (heading) async {
          clearedHeading = heading;
        },
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(find.text('Solo builders, alone.')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(clearedHeading, "Who it's for");
    });

    testWidgets(
      'an empty Objectives section writes the minimal structural wrapper '
      'a real objective needs to parse — "1. **<typed text>**" — never '
      'invented prose',
      (tester) async {
        String? writtenHeading;
        String? writtenOldValue;
        String? writtenText;
        await _pump(
          tester,
          strategy: partial,
          onSetCharterSection: (heading, oldValue, text) async {
            writtenHeading = heading;
            writtenOldValue = oldValue;
            writtenText = text;
          },
        );

        await tester.tap(find.text('＋').last);
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Ship the thing');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(writtenHeading, 'Objectives');
        expect(writtenOldValue, '');
        expect(writtenText, '1. **Ship the thing**\n');
      },
    );
  });
}
