// Round 34/D — an area chip on a decision row, real files: a decision
// that an area names, opened through the real ProjectScreen, not an
// in-memory fixture.

import 'dart:io';

import 'package:asa/hubs/product/project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _homeNote = '''
---
project: Demo
status: building
updated: 2026-09-26
---

# Demo
''';

const _areaPage = '''
# Sales

## Decisions
ADR 0003 — deals go through the partner portal.
''';

// Round 34's own self-test list names this exact case: "one decision
// named by two areas."
const _secondAreaPage = '''
# Finance

## Decisions
Also governed by ADR 0003, for the revenue recognition side.
''';

const _decisionFile = '''
# ADR 0003 - Deals go through the partner portal

**Date:** 2026-09-01 · **Status:** accepted

## Decision

Every deal is routed through the partner portal.
''';

void main() {
  late Directory tempDir;
  late String folder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'asa-area-decision-chip-test-',
    );
    folder = tempDir.path;
    final name = tempDir.path.split(Platform.pathSeparator).last;
    File(
      '${tempDir.path}${Platform.pathSeparator}$name.md',
    ).writeAsStringSync(_homeNote);

    final planDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}plan',
    )..createSync();
    File(
      '${planDir.path}${Platform.pathSeparator}sales.md',
    ).writeAsStringSync(_areaPage);
    File(
      '${planDir.path}${Platform.pathSeparator}finance.md',
    ).writeAsStringSync(_secondAreaPage);

    final decisionsDir = Directory(
      '${tempDir.path}${Platform.pathSeparator}decisions',
    )..createSync();
    File(
      '${decisionsDir.path}${Platform.pathSeparator}0003-partner-portal.md',
    ).writeAsStringSync(_decisionFile);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  testWidgets(
    'the area chip on a decision row switches to Plan, with that area '
    'already open',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ProjectScreen(folder: folder)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decisions'));
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      await tester.tap(find.text('Sales'));
      await tester.pumpAndSettle();

      // Landed on Plan, and the area is already open — its Goal/Tasks
      // detail is visible without a further tap.
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('DECISIONS'), findsOneWidget);
      expect(find.text('ADR 0003'), findsOneWidget);
    },
  );

  testWidgets(
    'one decision named by two areas gets two chips, one per area, '
    'neither merged nor dropped',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: ProjectScreen(folder: folder)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Decisions'));
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
    },
  );
}
