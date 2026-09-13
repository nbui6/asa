// The inbox, end to end through the real screen — Round 8, 2026-09-13.
// Capture with no project open, then the drag that assigns it to one.
// Real files, real disk, same reasoning as projects_screen_test.dart: only
// dart:io proves what a real write and a real re-read actually do.

import 'dart:io';

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory workspaceDir;
  late Directory projectsDir;
  late String settingsPath;
  late String homePath;

  setUp(() {
    // workspaceDir stands in for `%USERPROFILE%\workspace\` — HOME.md sits
    // at its root, `projects\` one level under it, same shape as rule 17.
    workspaceDir = Directory.systemTemp.createTempSync('asa-inbox-test-');
    projectsDir = Directory(
      '${workspaceDir.path}${Platform.pathSeparator}projects',
    )..createSync();
    settingsPath = '${workspaceDir.path}${Platform.pathSeparator}settings.json';
    homePath = '${workspaceDir.path}${Platform.pathSeparator}HOME.md';

    final demoDir = Directory(
      '${projectsDir.path}${Platform.pathSeparator}demo',
    )..createSync();
    File('${demoDir.path}${Platform.pathSeparator}demo.md').writeAsStringSync(
      '---\nproject: Demo\nstatus: building\n---\n\n# Demo\n',
    );
  });

  tearDown(() => workspaceDir.deleteSync(recursive: true));

  Future<void> pumpAndChooseFolder(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProjectsScreen(settingsPath: settingsPath)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('projectsFolderField')),
      projectsDir.path,
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Use this folder'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'typing with no project open, and no HOME.md yet, lands it in the '
    'inbox',
    (tester) async {
      expect(File(homePath).existsSync(), isFalse);
      await pumpAndChooseFolder(tester);

      // Visible even at zero — the whole panel used to vanish here, which
      // is exactly what made it look missing in a real screenshot.
      expect(find.textContaining('Inbox empty'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('inboxCaptureField')),
        'Call the dentist',
      );
      await tester.runAsync(() async {
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('1 unfiled'), findsOneWidget);
      expect(find.text('Call the dentist'), findsOneWidget);
      expect(
        File(homePath).readAsStringSync(),
        contains('- [ ] Call the dentist'),
      );
    },
  );

  testWidgets(
    'dragging an inbox item onto a project moves it into that project — '
    'and out of the inbox',
    (tester) async {
      File(homePath).writeAsStringSync('## Tasks\n\n- [ ] Call the dentist\n');
      await pumpAndChooseFolder(tester);

      expect(find.textContaining('1 unfiled'), findsOneWidget);
      await tester.tap(find.textContaining('1 unfiled'));
      await tester.pumpAndSettle();
      expect(find.text('Call the dentist'), findsOneWidget);

      final dragSource = find.byIcon(Icons.drag_indicator);
      final dropTarget = find.text('Demo');
      expect(dragSource, findsOneWidget);
      expect(dropTarget, findsOneWidget);

      await tester.runAsync(() async {
        final gesture = await tester.startGesture(tester.getCenter(dragSource));
        await gesture.moveTo(tester.getCenter(dropTarget));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(
        File(homePath).readAsStringSync(),
        isNot(contains('Call the dentist')),
      );
      final demoNotePath =
          '${projectsDir.path}${Platform.pathSeparator}demo'
          '${Platform.pathSeparator}demo.md';
      expect(
        File(demoNotePath).readAsStringSync(),
        contains('- [ ] Call the dentist'),
      );
      expect(find.textContaining('Inbox empty'), findsOneWidget);
    },
  );
}
