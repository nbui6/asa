// Round 36 cp5 — round-36.md §5's own match-the-sketch loop. Real engine,
// real fonts (an integration test, not a plain widget test — the same
// reason `app_test.dart` already runs this way), the invented fixture at
// `test\fixtures\round-36\` (never `projects\`, Gate 2). Screenshots land
// in `projects\asa\screenshots\round-36\` (outside git) for a real,
// side-by-side comparison against the approved sketches — never compared
// from memory.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _outDir =
    r'C:\Users\nico.bui\workspace\projects\asa\screenshots\round-36';

const _fixtureRoot = r'C:\Users\nico.bui\workspace\asa\test\fixtures\round-36';

final _boundaryKey = GlobalKey();

Future<void> _capture(WidgetTester tester, String name) async {
  final renderObject = _boundaryKey.currentContext!.findRenderObject();
  final boundary = renderObject! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir${Platform.pathSeparator}$name.png')
      .writeAsBytesSync(bytes.buffer.asUint8List());
}

Future<void> _pumpAt(
  WidgetTester tester,
  Widget home,
  double width,
  double height,
) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [(1920.0, 1080.0), (1280.0, 800.0)]) {
    final tag = '${size.$1.toInt()}x${size.$2.toInt()}';

    testWidgets('overview — $tag', (tester) async {
      // A fresh temp dir every run — a fixed name here means the second
      // run of this file finds settings.json already pointed at the
      // fixture from the first run, so the folder box starts collapsed
      // and "Use this folder" is never there to tap.
      final tempDir = Directory.systemTemp.createTempSync('asa-r36-shot-');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final settingsPath = '${tempDir.path}${Platform.pathSeparator}s.json';
      await _pumpAt(
        tester,
        ProjectsScreen(settingsPath: settingsPath),
        size.$1,
        size.$2,
      );
      await tester.enterText(find.byType(TextField), _fixtureRoot);
      await tester.tap(find.text('Use this folder'));
      await tester.pumpAndSettle();
      await _capture(tester, 'overview-$tag');

      await tester.tap(find.byIcon(Icons.checklist));
      await tester.pumpAndSettle();
      await _capture(tester, 'tasks-view-$tag');

      await tester.tap(find.byIcon(Icons.view_agenda_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Northwind partnership'));
      await tester.pumpAndSettle();
      await _capture(tester, 'project-plan-tab-$tag');

      await tester.tap(find.text('Sales'));
      await tester.pumpAndSettle();
      await _capture(tester, 'project-plan-tab-sales-open-$tag');

      await tester.tap(find.text('Strategy'));
      await tester.pumpAndSettle();
      await _capture(tester, 'project-strategy-tab-$tag');

      await tester.tap(find.text('Decisions'));
      await tester.pumpAndSettle();
      await _capture(tester, 'project-decisions-tab-$tag');

      await tester.tap(find.text('Run the webinar before any paid ads'));
      await tester.pumpAndSettle();
      await _capture(tester, 'decision-detail-$tag');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      await _capture(tester, 'project-details-tab-$tag');
    });
  }
}
