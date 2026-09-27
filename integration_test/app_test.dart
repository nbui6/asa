// The feature test HANDOVER.md asks for: launch, choose a folder, open a
// project, see a decision, see one marked superseded. It works for a
// person, not just for a parser.
//
// Builds ProjectsScreen directly, with settingsPath pointed at a temp file,
// rather than going through AsaApp — the real Asa always reads and writes
// `%APPDATA%\Asa\settings.json`, and a test must never overwrite whatever
// folder a person actually has chosen there.

import 'dart:io';

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'launch, choose a folder, open a project, see a decision, see one '
    'marked superseded',
    (tester) async {
      // No addTearDown deleting tempDir: the folder picker writes
      // settings.json in the background after the tap that starts it, and
      // deleting the folder out from under a still-in-flight write raced
      // and threw "path not found" in projects_screen_test.dart on
      // 2026-09-03 — same shape here. The OS cleans up
      // Directory.systemTemp on its own.
      final tempDir = Directory.systemTemp.createTempSync('asa-feature-test-');

      final sep = Platform.pathSeparator;
      final project = Directory('${tempDir.path}${sep}sample-project')
        ..createSync();
      File('${project.path}${sep}sample-project.md').writeAsStringSync('''
---
project: Sample project
status: building
milestone: v0.1
next-step: Ship it
repo-path:
updated: 2026-09-01
---

# Sample project
''');

      final decisions = Directory('${project.path}${sep}decisions')
        ..createSync();
      File('${decisions.path}${sep}0001-first.md').writeAsStringSync('''
# ADR 0001 - The first decision

**Date:** 2026-09-01 · **Status:** superseded by 0002

## Decision

The first approach.
''');
      File('${decisions.path}${sep}0002-second.md').writeAsStringSync('''
# ADR 0002 - The second decision

**Date:** 2026-09-02 · **Status:** accepted (supersedes 0001)

## Decision

The second, better approach.
''');

      final settingsPath = '${tempDir.path}${sep}test-settings.json';

      // No injected dialog: this is exactly what a person gets. There is
      // no folder dialog in this build (no plugins - see pubspec.yaml), so
      // the route is paste a path and press the button, and the button is
      // labelled for what it actually does.
      await tester.pumpWidget(
        MaterialApp(home: ProjectsScreen(settingsPath: settingsPath)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Use this folder'), findsOneWidget);

      await tester.enterText(find.byType(TextField), tempDir.path);
      await tester.tap(find.text('Use this folder'));
      await tester.pumpAndSettle();

      expect(find.text('Sample project'), findsOneWidget);

      await tester.tap(find.text('Sample project'));
      await tester.pumpAndSettle();

      // Round 36 cp8 — every project opens on Plan now, with or without
      // plan pages of its own; this fixture has neither, so Decisions
      // needs an explicit tap to see what this test is actually about.
      await tester.tap(find.text('Decisions'));
      await tester.pumpAndSettle();

      expect(find.text('The first decision'), findsOneWidget);
      expect(find.text('The second decision'), findsOneWidget);
      expect(find.textContaining('replaced by 0002'), findsOneWidget);
    },
  );
}
