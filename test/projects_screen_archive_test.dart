// ADR 0051 point 4 — the overview's own folded-list row actions (🗄/🗑)
// and the Archived group's own ↩, wired end to end through the real
// ProjectsScreen. Real disk, real fixture, same reasoning as
// projects_screen_needs_you_test.dart: only a real scan proves _load()'s
// own re-scan of both projects\ and projects\_archive\ actually reaches
// the screen. Delete's own confirmation is checked for content and
// Cancel only, never confirmed for real — see project_screen_archive_
// test.dart's own header for why.

import 'dart:io';

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectsRoot;
  late String pausedFolder;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-overview-archive-');
    projectsRoot = '${tempDir.path}${Platform.pathSeparator}projects';
    final demoFolder = '$projectsRoot${Platform.pathSeparator}demo';
    Directory(demoFolder).createSync(recursive: true);
    File('$demoFolder${Platform.pathSeparator}demo.md')
        .writeAsStringSync('---\nproject: Demo\nstatus: in-progress\n---\n');

    pausedFolder = '$projectsRoot${Platform.pathSeparator}paused';
    Directory(pausedFolder).createSync(recursive: true);
    File('$pausedFolder${Platform.pathSeparator}paused.md')
        .writeAsStringSync('---\nproject: Paused\nstatus: on-hold\n---\n');
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

  Future<void> pumpScreen(WidgetTester tester) async {
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
    await tester.tap(find.textContaining('show ›'));
    await tester.pumpAndSettle();
  }

  testWidgets(r'🗄 on a hidden row moves it into _archive\ and the overview '
      'reflects it — Archived 1, no longer among the hidden', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Paused'), findsOneWidget);

    await pumpAndSettleReal(tester, () => tester.tap(find.text('🗄')));

    expect(
      Directory(pausedFolder).existsSync(),
      isFalse,
      reason: r'moved out of projects\',
    );
    expect(find.textContaining('Archived 1'), findsOneWidget);
    // Paused now appears exactly once — as the archived row, with its
    // own "was On hold" label — not a second time as a still-hidden
    // on-hold row too.
    expect(find.text('Paused'), findsOneWidget);
    expect(find.textContaining('archived today · was On hold'), findsOneWidget);
  });

  testWidgets('↩ on an archived row moves it back, old status and all', (
    tester,
  ) async {
    await pumpScreen(tester);
    await pumpAndSettleReal(tester, () => tester.tap(find.text('🗄')));

    await pumpAndSettleReal(tester, () => tester.tap(find.text('↩')));

    expect(Directory(pausedFolder).existsSync(), isTrue);
    expect(find.textContaining('On hold 1'), findsOneWidget);
    expect(find.textContaining('Archived'), findsNothing);
  });

  testWidgets('🗑 on a hidden row opens the same confirmation Details shows; '
      'Cancel deletes nothing', (tester) async {
    await pumpScreen(tester);

    await pumpAndSettleReal(tester, () => tester.tap(find.text('🗑')));

    expect(find.text('Move "Paused" to the Recycle Bin?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(Directory(pausedFolder).existsSync(), isTrue);
  });
}
