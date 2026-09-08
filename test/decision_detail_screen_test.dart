// Real disk, real widget — the guarantee this file exists to prove is
// specifically about a double-tap race in the actual widget tree, which
// a unit test on the writer alone cannot reproduce.

import 'dart:io';

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
    // rebuild has a chance to disable the button via _saving. runAsync
    // plus a real delay is required here for the same reason
    // projects_screen_test.dart needs it: pumpAndSettle alone does not
    // reliably wait for a real dart:io Future to finish.
    await tester.runAsync(() async {
      await tester.tap(find.text('Accept'));
      await tester.tap(find.text('Accept'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    final contents = File(path).readAsStringSync();
    expect(RegExp('## Your call').allMatches(contents).length, 1);
  });
}
