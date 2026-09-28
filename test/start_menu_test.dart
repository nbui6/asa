// Round 32/D — the Start menu. "Open code in VS Code" must never be an
// action a tap can reach when there is nowhere for it to go; whether the
// real `code` binary is on this machine's PATH is not something a test
// suite should depend on to stay green, so that half is a code-reading
// guarantee (the try/catch around Process.run in start_menu.dart), not a
// live-process test here.

import 'package:asa/hubs/product/start_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String repoPath) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StartMenu(
          projectName: 'Demo',
          projectFolder: r'C:\demo',
          repoPath: repoPath,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Round 35/F — the rocket icon has a real tooltip, not just an icon',
    (tester) async {
      await _pump(tester, r'C:\demo\repo');

      final button = tester.widget<PopupMenuButton<dynamic>>(
        find.byWidgetPredicate((w) => w is PopupMenuButton<dynamic>),
      );
      expect(button.tooltip, 'Start working on this project');
    },
  );

  testWidgets('shows all four actions', (tester) async {
    await _pump(tester, r'C:\demo\repo');
    await tester.tap(find.byIcon(Icons.rocket_launch_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Copy opener'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Open folder'), findsOneWidget);
    expect(find.text('Open code in VS Code'), findsOneWidget);
  });

  testWidgets(
    'Round 39 cp7 — Resume copies asa-brief on this project, by name',
    (tester) async {
      // Same reasoning as links_test.dart's own L10 test — this machine's
      // test environment has no working default clipboard mock, so a real
      // Clipboard.setData call hangs rather than resolving.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      await _pump(tester, r'C:\demo\repo');
      await tester.tap(find.byIcon(Icons.rocket_launch_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(copied, contains('asa-brief "Demo"'));
      expect(copied, contains(r'projects\AGENTS.md'));
    },
  );

  testWidgets('Open code in VS Code is disabled when repo-path is empty '
      '— never a dead tap', (tester) async {
    await _pump(tester, '');
    await tester.tap(find.byIcon(Icons.rocket_launch_outlined));
    await tester.pumpAndSettle();

    final item = tester.widget<PopupMenuItem<dynamic>>(
      find.ancestor(
        of: find.text('Open code in VS Code'),
        matching: find.byWidgetPredicate((w) => w is PopupMenuItem<dynamic>),
      ),
    );
    expect(item.enabled, isFalse);
  });

  testWidgets('Open code in VS Code is enabled when repo-path is set', (
    tester,
  ) async {
    await _pump(tester, r'C:\demo\repo');
    await tester.tap(find.byIcon(Icons.rocket_launch_outlined));
    await tester.pumpAndSettle();

    final item = tester.widget<PopupMenuItem<dynamic>>(
      find.ancestor(
        of: find.text('Open code in VS Code'),
        matching: find.byWidgetPredicate((w) => w is PopupMenuItem<dynamic>),
      ),
    );
    expect(item.enabled, isTrue);
  });
}
