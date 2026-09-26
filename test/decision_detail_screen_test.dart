// Real disk, real widget — the guarantee this file exists to prove is
// specifically about a double-tap race in the actual widget tree, which
// a unit test on the writer alone cannot reproduce.

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-detail-test-');
    path = '${tempDir.path}${Platform.pathSeparator}0001-example.md';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  testWidgets('two Accept taps recognised before the first rebuild write the '
      'verdict once, not twice — the real bug found on ADR 0012: five '
      'duplicate ## Your call blocks from a single real click', (tester) async {
    const original =
        '# ADR 0001 - Example\n\n'
        '**Date:** 2026-09-07 · **Status:** proposed\n\n'
        '## Decision\n\nSomething.\n';
    File(path).writeAsStringSync(original);

    final result = parseDecision(original, path);

    await tester.pumpWidget(
      MaterialApp(home: DecisionDetailScreen(decision: result.decision!)),
    );
    await tester.pumpAndSettle();

    // No pump between the two taps — both are recognised before any
    // rebuild has a chance to disable the button via _saving. runAsync is
    // required here for the same reason projects_screen_test.dart needs
    // it: pumpAndSettle alone does not reliably wait for a real dart:io
    // Future to finish.
    //
    // Poll for the write landing rather than sleeping a fixed duration —
    // 2026-09-09: a constant 500ms delay here flaked under the full
    // suite's load (a real write taking longer than 500ms when the
    // machine is busy, so the read below caught the file's original,
    // pre-write content: 0 matches, not 1). Polling is deterministic
    // given enough wall-clock time instead of a guess that has to be
    // guessed larger every time the machine gets busier.
    await tester.runAsync(() async {
      await tester.tap(find.text('Accept'));
      await tester.tap(find.text('Accept'));

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        final contents = File(path).readAsStringSync();
        if (RegExp('## Your call').hasMatch(contents)) break;
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pumpAndSettle();

    final contents = File(path).readAsStringSync();
    expect(RegExp('## Your call').allMatches(contents).length, 1);
  });

  group("round-36 §3, L17 — an area chip on the decision's own detail "
      'screen', () {
    const decision = Decision(
      title: 'A real decision',
      why: 'w',
      decision: 'd',
      whatWouldChangeThis: 'c',
      sourceFile: 'decisions/0009.md',
      number: '0009',
    );

    const area = Area(
      name: 'Sales',
      sourceFile: 'plan/sales.md',
      tasks: [],
      results: [],
      decisionNumbers: ['0009'],
      objectiveNumbers: [],
    );

    testWidgets('shows one chip per naming area; tapping pops, then '
        'calls onOpenArea', (tester) async {
      Area? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DecisionDetailScreen(
                      decision: decision,
                      areasNaming: const [area],
                      onOpenArea: (a) => opened = a,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      await tester.tap(find.text('Sales'));
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(opened, same(area));
    });

    testWidgets('no naming areas at all shows no chip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DecisionDetailScreen(decision: decision)),
      );

      expect(find.text('Sales'), findsNothing);
    });
  });
}
