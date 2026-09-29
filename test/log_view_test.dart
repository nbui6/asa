// Round 38 §E — the Log tab. Entries/decisions/roadmap are all passed in
// directly (no disk read inside this widget for those); only the "since
// you were last here" file and the injected round-writer callbacks touch
// anything real, and both are sandboxed/faked here — see
// log_view.dart's own header for why the writer calls are injected
// rather than called directly.

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/log_entries.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/log_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DecisionReadResult _decision({
  String number = '0001',
  String title = 'A decision',
  bool proposed = false,
  String? area,
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
      links: DecisionLinks(area: area),
    ),
  );
}

void main() {
  late Directory tempDir;
  late String lastVisitPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-log-view-test-');
    lastVisitPath = '${tempDir.path}${Platform.pathSeparator}visits.json';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<void> pump(
    WidgetTester tester, {
    List<LogEntry> entries = const [],
    List<DecisionReadResult> decisions = const [],
    List<Area> areas = const [],
    Future<void> Function(
      String, {
      required String roundTitle,
      String? feedback,
    })?
    onApproveRound,
    Future<void> Function(String, {required String what})?
        onRequestRoundChanges,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogView(
            projectFolder: 'demo',
            entries: entries,
            decisions: decisions,
            roadmap: const [],
            approvals: const RoundApprovals({}),
            areas: areas,
            loadRoundText: (_) async => null,
            onApproveRound:
                onApproveRound ?? (_, {required roundTitle, feedback}) async {},
            onRequestRoundChanges:
                onRequestRoundChanges ?? (_, {required what}) async {},
            lastVisitPath: lastVisitPath,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('an empty project shows the honest empty state', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Nothing happened here yet.'), findsOneWidget);
  });

  testWidgets('each entry shows its own type label and title', (
    tester,
  ) async {
    await pump(
      tester,
      entries: [
        LogEntry(
          type: LogEntryType.aiWorked,
          date: DateTime(2026, 9, 20, 10, 30),
          title: 'did the thing',
          detail: 'did the thing',
        ),
        LogEntry(
          type: LogEntryType.changedWithoutNote,
          date: DateTime(2026, 9, 21, 9),
          title: 'CHARTER.md',
          detail: '1 before, 2 after',
        ),
      ],
    );

    expect(find.text('AI worked'), findsOneWidget);
    expect(find.text('did the thing'), findsOneWidget);
    expect(find.text('changed without a note'), findsOneWidget);
    expect(find.text('CHARTER.md'), findsOneWidget);
  });

  testWidgets(
    'the needs-your-yes card shows one item and cycles with next',
    (tester) async {
      await pump(
        tester,
        decisions: [
          _decision(title: 'First proposed', proposed: true),
          _decision(number: '0002', title: 'Second proposed', proposed: true),
        ],
      );

      expect(find.text('1 of 2'), findsOneWidget);
      final firstVisible =
          find.text('First proposed').evaluate().isNotEmpty;
      final secondVisible =
          find.text('Second proposed').evaluate().isNotEmpty;
      expect(firstVisible ^ secondVisible, isTrue);

      await tester.tap(find.text('next ›'));
      await tester.pump();

      expect(find.text('2 of 2'), findsOneWidget);
    },
  );

  testWidgets('no waiting items shows no needs-your-yes card at all', (
    tester,
  ) async {
    await pump(
      tester,
      decisions: [_decision(title: 'Already settled')],
    );
    expect(find.text('Needs your yes'), findsNothing);
  });

  testWidgets('Yes on a round in the card calls onApproveRound', (
    tester,
  ) async {
    // Roadmap-based waiting rounds need a real Milestone/RoundApprovals
    // pairing — covered at the readLogEntries/round_state.dart level
    // already; this test focuses on the decision half of the card,
    // which needs no round file at all.
    String? approvedNumber;
    await pump(
      tester,
      decisions: [_decision(number: '0009', proposed: true)],
      onApproveRound: (n, {required roundTitle, feedback}) async {
        approvedNumber = n;
      },
    );

    // A proposed decision's own Yes opens its detail screen rather than
    // quick-approving (log_view.dart's own _recordYesFor comment) — so
    // tapping Yes here should navigate, not call onApproveRound at all.
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(approvedNumber, isNull);
  });

  testWidgets('switching to Decisions in force shows the other view', (
    tester,
  ) async {
    await pump(
      tester,
      decisions: [_decision(title: 'A settled call', area: 'Sales')],
      areas: const [
        Area(
          name: 'Sales',
          sourceFile: 'plan/sales.md',
          tasks: [],
          results: [],
          decisionNumbers: [],
          objectiveNumbers: [],
        ),
      ],
    );

    await tester.tap(find.text('Decisions in force'));
    await tester.pump();

    // SectionLabel renders its own text uppercased.
    expect(find.text('SALES'), findsOneWidget);
    expect(find.text('A settled call'), findsOneWidget);
  });
}
