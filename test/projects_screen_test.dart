// The folder picker, pinned.
//
// On 2026-09-03 the button labelled "Choose folder..." opened nothing and,
// with the text box empty, did nothing at all - no dialog, no message, no
// error. It read as broken hardware. Hard rule 6 says show every failure
// with its reason; a silent no-op is a failure with no reason.
//
// These tests are the gate on that never returning.
//
// Two shapes are covered, because two exist. On THIS machine there is no
// folder dialog at all - Windows will not build a Flutter plugin without
// Developer Mode, which is not available here - so the button uses the
// text box and is labelled "Use this folder". Anyone whose machine can
// build a plugin passes a `pickFolder` function and gets a real dialog;
// those tests inject one, because no test can click a native window.

import 'dart:io';

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String settingsPath;

  // No tearDown deleting tempDir: `_useFolder` writes settings.json in the
  // background after the tap that starts it, and nothing here reads it
  // back — deleting the folder out from under that still-in-flight write
  // is what caused "path not found" 2026-09-03. The OS cleans up
  // Directory.systemTemp on its own; a stray folder per test run costs
  // nothing.
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-picker-test-');
    settingsPath = '${tempDir.path}${Platform.pathSeparator}settings.json';
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Future<String?> Function()? picker,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectsScreen(settingsPath: settingsPath, pickFolder: picker),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('no dialog available — what ships on this machine', () {
    testWidgets('the button does not promise a dialog it does not have', (
      tester,
    ) async {
      await pumpScreen(tester, null);

      expect(find.text('Use this folder'), findsOneWidget);
      expect(find.text('Choose folder…'), findsNothing);
    });

    testWidgets('pressing it with an empty box explains itself', (
      tester,
    ) async {
      await pumpScreen(tester, null);

      await tester.tap(find.text('Use this folder'));
      await tester.pumpAndSettle();

      expect(find.textContaining('That box is empty'), findsOneWidget);
    });

    testWidgets('a pasted path is accepted by the button', (tester) async {
      await pumpScreen(tester, null);

      await tester.enterText(find.byType(TextField), tempDir.path);

      // Verified empirically 2026-09-04: removing tearDown alone does not
      // fix this — plain tap()+pumpAndSettle() still leaves the button on
      // "Loading…", because pumpAndSettle settles on "no frame scheduled
      // right now" and a real dart:io Future finishing does not by itself
      // cause that; only the setState() after it does. `runAsync` plus a
      // real delay gives the write and the scan definite wall-clock time
      // to actually finish first.
      await tester.runAsync(() async {
        await tester.tap(find.text('Use this folder'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      // Round 35/B — once a folder is accepted, the field/button collapse
      // to the one-line summary rather than staying open relabelled "Load".
      expect(find.text('Load'), findsNothing);
      expect(find.textContaining('Projects: '), findsOneWidget);
    });
  });

  group('a dialog was supplied — a fork with admin rights', () {
    testWidgets('cancelling with an empty box says so, and does not sit '
        'silent', (tester) async {
      await pumpScreen(tester, () async => null);

      await tester.tap(find.text('Choose folder…'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('No folder chosen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a chosen folder is put in the box, not just remembered', (
      tester,
    ) async {
      await pumpScreen(tester, () async => tempDir.path);

      await tester.tap(find.text('Choose folder…'));
      await tester.pumpAndSettle();

      expect(find.text(tempDir.path), findsOneWidget);
    });

    testWidgets('cancelling falls back to a path already typed', (
      tester,
    ) async {
      await pumpScreen(tester, () async => null);

      await tester.enterText(find.byType(TextField), tempDir.path);
      await tester.tap(find.text('Choose folder…'));
      await tester.pumpAndSettle();

      // No complaint: there was a path to use.
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  testWidgets('Enter on an empty box explains itself', (tester) async {
    await pumpScreen(tester, null);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('That box is empty'), findsOneWidget);
  });

  group('Round 35/B — the folder box collapses once a folder is set', () {
    testWidgets('first run (nothing saved yet) is unchanged — the full box, '
        'not the one-line summary', (tester) async {
      await pumpScreen(tester, null);

      expect(find.text('Projects folder'), findsOneWidget);
      expect(find.byKey(const Key('projectsFolderField')), findsOneWidget);
      expect(find.textContaining('Projects: '), findsNothing);
    });

    testWidgets('after accepting a folder, the box is one line, not the '
        'field and button', (tester) async {
      await pumpScreen(tester, null);
      await tester.enterText(find.byType(TextField), tempDir.path);
      await tester.runAsync(() async {
        await tester.tap(find.text('Use this folder'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(find.text('Projects folder'), findsNothing);
      expect(find.byKey(const Key('projectsFolderField')), findsNothing);
      expect(find.textContaining('Projects: ${tempDir.path}'), findsOneWidget);
    });

    testWidgets('"change" reopens the field, and loading again collapses '
        'it back', (tester) async {
      await pumpScreen(tester, null);
      await tester.enterText(find.byType(TextField), tempDir.path);
      await tester.runAsync(() async {
        await tester.tap(find.text('Use this folder'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Projects: '));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectsFolderField')), findsOneWidget);
      expect(find.text('Load'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Load'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectsFolderField')), findsNothing);
      expect(find.textContaining('Projects: ${tempDir.path}'), findsOneWidget);
    });
  });
}
