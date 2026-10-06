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
import 'package:flutter/services.dart';
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
    Future<void> Function({
      required String path,
      required String text,
      String? taskText,
      ResultLink? link,
    })?
    onWriteResult,
    Future<void> Function({
      required String projectFolder,
      required String decisionText,
      String? why,
      String? area,
      List<String> objectives,
      ResultLink? link,
    })?
    onCreateDecision,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogView(
            projectFolder: 'demo',
            homeSourceFile: 'demo/demo.md',
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
            onWriteResult: onWriteResult,
            onCreateDecision: onCreateDecision,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('an empty project shows the honest empty state', (tester) async {
    await pump(tester);
    expect(find.text('Nothing happened here yet.'), findsOneWidget);
  });

  testWidgets('each entry shows its own type label and title', (tester) async {
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

  // The deciding session, 2026-10-05 15:20 — asa-log-v2: today's own
  // entries show the time, older ones show the day, and a day-only source
  // (no time recorded) never reads as midnight.
  group('the time column (asa-log-v2)', () {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String dayLabel(DateTime date) => '${date.day} ${months[date.month - 1]}';

    testWidgets("today's own entry with a real time shows the time", (
      tester,
    ) async {
      final now = DateTime.now();
      await pump(
        tester,
        entries: [
          LogEntry(
            type: LogEntryType.aiWorked,
            date: DateTime(now.year, now.month, now.day, 14, 26),
            title: 'did the thing',
            detail: 'did the thing',
          ),
        ],
      );
      expect(find.text('14:26'), findsOneWidget);
    });

    testWidgets('an older entry shows its day, never its time', (tester) async {
      await pump(
        tester,
        entries: [
          LogEntry(
            type: LogEntryType.aiWorked,
            date: DateTime(2026, 9, 27, 14, 5),
            title: 'did the thing',
            detail: 'did the thing',
          ),
        ],
      );
      expect(find.text('27 Sep'), findsOneWidget);
      expect(find.text('14:05'), findsNothing);
    });

    testWidgets('an entry with no recorded time shows its day, never 00:00', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await pump(
        tester,
        entries: [
          LogEntry(
            type: LogEntryType.aiWorked,
            date: today,
            title: 'did the thing',
            detail: 'did the thing',
          ),
        ],
      );
      expect(find.text('00:00'), findsNothing);
      expect(find.text(dayLabel(today)), findsOneWidget);
    });
  });

  testWidgets('the needs-your-yes card shows one item and cycles with next', (
    tester,
  ) async {
    await pump(
      tester,
      decisions: [
        _decision(title: 'First proposed', proposed: true),
        _decision(number: '0002', title: 'Second proposed', proposed: true),
      ],
    );

    expect(find.text('1 of 2'), findsOneWidget);
    final firstVisible = find.text('First proposed').evaluate().isNotEmpty;
    final secondVisible = find.text('Second proposed').evaluate().isNotEmpty;
    expect(firstVisible ^ secondVisible, isTrue);

    await tester.tap(find.text('next ›'));
    await tester.pump();

    expect(find.text('2 of 2'), findsOneWidget);
  });

  testWidgets('no waiting items shows no needs-your-yes card at all', (
    tester,
  ) async {
    await pump(tester, decisions: [_decision(title: 'Already settled')]);
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

  group('Round 43 §C — the Log\'s own "＋ Result"/"＋ Decision"', () {
    testWidgets('＋ Result opens a line; Enter writes via onWriteResult, '
        'defaulting to "Not in an area" — the home note', (tester) async {
      String? writtenPath;
      String? writtenText;
      await pump(
        tester,
        onWriteResult: ({required path, required text, taskText, link}) async {
          writtenPath = path;
          writtenText = text;
        },
      );

      await tester.tap(find.text('＋ Result'));
      await tester.pump();

      expect(find.text('Result'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'A plain result');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenPath, 'demo/demo.md');
      expect(writtenText, 'A plain result');
      expect(find.text('Result'), findsNothing);
    });

    testWidgets('picking an area writes there instead, and its own '
        'objective follows it', (tester) async {
      const sales = Area(
        name: 'Sales',
        sourceFile: 'demo/plan/sales.md',
        tasks: [],
        results: [],
        decisionNumbers: [],
        objectiveNumbers: ['2'],
      );
      String? writtenProjectFolder;
      String? writtenDecisionText;
      String? writtenArea;
      List<String>? writtenObjectives;
      await pump(
        tester,
        areas: const [sales],
        onCreateDecision:
            ({
              required projectFolder,
              required decisionText,
              why,
              area,
              objectives = const [],
              link,
            }) async {
              writtenProjectFolder = projectFolder;
              writtenDecisionText = decisionText;
              writtenArea = area;
              writtenObjectives = objectives;
            },
      );

      await tester.tap(find.text('＋ Decision'));
      await tester.pump();
      await tester.tap(find.text('Not in an area'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sales').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Flat fee it is');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(writtenProjectFolder, 'demo');
      expect(writtenDecisionText, 'Flat fee it is');
      expect(writtenArea, 'Sales');
      expect(writtenObjectives, ['2']);
    });

    testWidgets('Esc closes the form without writing', (tester) async {
      var written = false;
      await pump(
        tester,
        onWriteResult: ({required path, required text, taskText, link}) async {
          written = true;
        },
      );

      await tester.tap(find.text('＋ Result'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'Ignored');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('Result'), findsNothing);
      expect(written, isFalse);
    });
  });
}
