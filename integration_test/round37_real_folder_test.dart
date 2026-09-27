// Round 37 cp4 — Gate 2: the real folder, once, counts only. No real
// project name or content is asserted here, only that every one of them
// opens on Plan with no error text, and one screenshot per project lands
// outside git for persona-check to look at. Thrown away right after its
// one use, same reason as round37_screenshots_test.dart's own header.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:asa/core/projects_scan.dart';
import 'package:asa/hubs/product/project_screen.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _realRoot = r'C:\Users\nico.bui\workspace\projects';
const _outDir =
    r'C:\Users\nico.bui\workspace\projects\asa\screenshots\round-37-real';

final _boundaryKey = GlobalKey();

Future<void> _capture(String name) async {
  final renderObject = _boundaryKey.currentContext!.findRenderObject();
  final boundary = renderObject! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir${Platform.pathSeparator}$name.png')
      .writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A real disk read is a genuine async gap with no animation in between —
  // pumpAndSettle() alone has already been found to return before that
  // kind of gap actually closes (click_through_test.dart's own `waitFor`).
  // Polling for the expected result is the fix that already held up
  // there.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for $finder');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'every real project opens on Plan, no error text, one look each',
    (tester) async {
      final scan = await scanProjects(_realRoot);
      // A count only — real names never appear in this file's own source.
      expect(scan.projects, isNotEmpty);

      for (var i = 0; i < scan.projects.length; i++) {
        final project = scan.projects[i];

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            RepaintBoundary(
              key: _boundaryKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                // A distinct Key per project — otherwise Flutter reuses
                // the same ProjectScreen State across pumpWidget calls
                // (same runtimeType, no distinguishing Key), so initState
                // never re-runs and every capture after the first is a
                // stale repeat of project #1. Found against these very
                // screenshots.
                home: ProjectScreen(
                  key: ValueKey(project.folder),
                  folder: project.folder,
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await waitFor(tester, find.text('Plan'));

        // Plan is always the tab a project opens on (round-36 §9 point
        // 1) — checked by colour, not weight (round-37 §D2: every tab
        // label keeps the same weight, active or not).
        final planLabel = tester.widget<Text>(find.text('Plan'));
        expect(
          planLabel.style?.color,
          AsaColors.ink,
          reason:
              'project #${i + 1} of ${scan.projects.length} — Plan '
              'is not the active tab',
        );

        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('Error'), findsNothing);

        await _capture('project-${i + 1}');
      }

      // The count itself is the assertion round-36 cp8 already
      // established this same way — every real project opens, none
      // silently skipped.
      expect(scan.skipped, isEmpty);
    },
  );
}
