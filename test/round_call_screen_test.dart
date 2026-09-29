// Round 38 §C — the round's own "Your call" screen, tested with fake
// injected callbacks — see round_call_screen.dart's own header for why:
// a version driving this through the real dart:io-backed functions hit a
// reproducible hang in this environment, the same class of issue found
// and worked around the same way for plan_view.dart's + Add area dialog.
// The real functions (readRoundFileText, approveRound,
// requestRoundChanges) have their own coverage in round_file_test.dart
// and round_call_writer_test.dart.

import 'package:asa/core/changes_file.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/round_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _roundText = '''
# Round 38 — Strategy first, areas as tabs

**Area:** App

## The finish line

1. First line.
2. Second line.

## How it's tested

1. Open Asa.
2. Say yes.
''';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? roundText = _roundText,
    Future<void> Function({required String? feedback})? onApprove,
    Future<void> Function({required String what})? onRequestChanges,
    VoidCallback? onOpenRoundFile,
    RoundApproval? existingApproval,
    ChangeRequest? existingChangeRequest,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoundCallScreen(
          roundNumber: '38',
          loadRoundText: () async => roundText,
          onApprove: onApprove ?? ({required feedback}) async {},
          onRequestChanges: onRequestChanges ?? ({required what}) async {},
          onOpenRoundFile: onOpenRoundFile ?? () {},
          existingApproval: existingApproval,
          existingChangeRequest: existingChangeRequest,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the title, the finish line and the test, cut to five lines '
    'each, and "waiting for your yes"',
    (tester) async {
      await pump(tester);

      expect(
        find.text('Round 38 — Strategy first, areas as tabs'),
        findsOneWidget,
      );
      expect(find.text('waiting for your yes'), findsOneWidget);
      expect(find.textContaining('First line.'), findsOneWidget);
      expect(find.textContaining('Open Asa.'), findsOneWidget);
    },
  );

  testWidgets('Yes calls onApprove with null feedback when the box is '
      'empty, then shows "Your call. Yes — <date>"', (tester) async {
    String? feedbackPassed = 'not called';
    var called = false;
    await pump(
      tester,
      onApprove: ({required feedback}) async {
        called = true;
        feedbackPassed = feedback;
      },
    );

    await tester.tap(find.text("Yes, it's right"));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(feedbackPassed, isNull);
    expect(find.text('Your call. '), findsOneWidget);
    expect(find.textContaining('Yes —'), findsOneWidget);
  });

  testWidgets('typed feedback is passed through to onApprove', (
    tester,
  ) async {
    String? feedbackPassed;
    await pump(
      tester,
      onApprove: ({required feedback}) async => feedbackPassed = feedback,
    );

    await tester.enterText(find.byType(TextField), 'looks right');
    await tester.tap(find.text("Yes, it's right"));
    await tester.pumpAndSettle();

    expect(feedbackPassed, 'looks right');
  });

  testWidgets(
    'Needs changes requires the box filled in before calling anything',
    (tester) async {
      var called = false;
      await pump(
        tester,
        onRequestChanges: ({required what}) async => called = true,
      );

      await tester.tap(find.text('Needs changes'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.textContaining('Say what needs to change'), findsOneWidget);
    },
  );

  testWidgets(
    'Needs changes with real text calls onRequestChanges, then shows '
    '"Your call. Needs changes — …"',
    (tester) async {
      String? whatPassed;
      await pump(
        tester,
        onRequestChanges: ({required what}) async => whatPassed = what,
      );

      await tester.enterText(find.byType(TextField), 'move the button');
      await tester.tap(find.text('Needs changes'));
      await tester.pumpAndSettle();

      expect(whatPassed, 'move the button');
      expect(find.text('Your call. '), findsOneWidget);
      expect(find.textContaining('Needs changes —'), findsOneWidget);
    },
  );

  testWidgets('an already-recorded round shows settled, not the buttons', (
    tester,
  ) async {
    await pump(
      tester,
      existingApproval: (
        date: '2026-09-20',
        words: 'in Asa',
        result: 'Round 38',
      ),
    );

    expect(find.text('settled'), findsOneWidget);
    expect(find.text('Your call. '), findsOneWidget);
    expect(find.textContaining('Yes — 2026-09-20'), findsOneWidget);
    expect(find.text("Yes, it's right"), findsNothing);
  });

  testWidgets('no round file at all is an honest absence, not a crash', (
    tester,
  ) async {
    await pump(tester, roundText: null);

    expect(find.text('No round file found for this number.'), findsOneWidget);
  });

  testWidgets('open the round file calls the injected callback', (
    tester,
  ) async {
    var opened = false;
    await pump(tester, onOpenRoundFile: () => opened = true);

    await tester.tap(find.text('open the round file ↗'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });
}
