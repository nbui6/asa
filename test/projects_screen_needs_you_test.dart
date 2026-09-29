// Round 38 §E — the overview's own Needs you panel and per-row markers,
// wired end to end through the real ProjectsScreen. Real disk, real
// fixture, same reasoning as plan_area_ticking_test.dart: only a real
// scan proves _load()'s own new gathering step (readAllDecisions +
// readRoundApprovals + lastLogVisit + readProjectNews, per project)
// actually reaches the screen.

import 'dart:io';

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _homeNote = '''
---
project: Demo
status: in-progress
updated: 2026-09-20
---

# Demo

## Tasks
- [ ] Do the thing
''';

const _decisionText = '''
# ADR 0001 — A proposed call

**Date:** 2026-09-15 · **Status:** proposed

## Decision
Something proposed.

## Why
Because.

## What would change this
Nothing.
''';

void main() {
  late Directory tempDir;
  late String projectsRoot;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-needs-you-test-');
    projectsRoot = '${tempDir.path}${Platform.pathSeparator}projects';
    final projectFolder = '$projectsRoot${Platform.pathSeparator}demo';
    Directory(projectFolder).createSync(recursive: true);
    File('$projectFolder${Platform.pathSeparator}demo.md')
        .writeAsStringSync(_homeNote);
    final decisionsDir = Directory(
      '$projectFolder${Platform.pathSeparator}decisions',
    )..createSync();
    File('${decisionsDir.path}${Platform.pathSeparator}0001-a-call.md')
        .writeAsStringSync(_decisionText);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<void> pumpAndSettleReal(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    await tester.runAsync(() async {
      await action();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a real proposed decision shows in the Needs you panel, oldest '
      '(only) item, 1 of 1', (tester) async {
    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';

    await pumpAndSettleReal(
      tester,
      () => tester.pumpWidget(
        MaterialApp(home: ProjectsScreen(settingsPath: settingsPath)),
      ),
    );

    await tester.enterText(find.byType(TextField), projectsRoot);
    await pumpAndSettleReal(
      tester,
      () => tester.tap(find.text('Use this folder')),
    );

    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('A proposed call'), findsOneWidget);
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('next ›'), findsNothing);
  });
}
