// Round 32/C — the status pill can't break the row (ADR 0017). One real
// note had a whole paragraph as its status; this proves the pill clips
// instead of widening or wrapping the card.

import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Project _project({required String status}) {
  return Project(
    name: 'Demo',
    status: status,
    milestone: '',
    nextStep: '',
    repoPath: '',
    updated: '2026-09-25',
    sourceFile: 'demo/demo.md',
  );
}

Future<void> _pump(WidgetTester tester, List<ProjectNode> forest) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectsView(
          forest: forest,
          onOpenProject: (_) {},
          onAssignTask: (_, _) async {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a whole-paragraph status clips to one line, never wraps or overflows',
    (tester) async {
      const longStatus =
          'This is a whole paragraph masquerading as a status value, the '
          'exact real shape found in one project note before this round, '
          'long enough that an unbounded pill would widen or wrap the '
          'entire row rather than stay a small pill next to the others.';
      final node = ProjectNode(
        project: _project(status: longStatus),
        folder: 'demo',
      );

      await _pump(tester, [node]);

      expect(tester.takeException(), isNull);

      final pillText = tester.widget<Text>(find.text(longStatus));
      expect(pillText.maxLines, 1);
      expect(pillText.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets('an unrecognized status word still renders, neutral emphasis', (
    tester,
  ) async {
    final node = ProjectNode(
      project: _project(status: 'archived'),
      folder: 'demo',
    );

    await _pump(tester, [node]);

    expect(tester.takeException(), isNull);
    expect(find.text('archived'), findsOneWidget);
  });

  testWidgets('every ADR 0017 word renders without throwing', (tester) async {
    for (final status in [
      'idea',
      'discovery-done',
      'building',
      'shipped',
      'ongoing',
      'paused',
      'dropped',
    ]) {
      final node = ProjectNode(
        project: _project(status: status),
        folder: 'demo',
      );
      await _pump(tester, [node]);
      expect(tester.takeException(), isNull, reason: status);
      expect(find.text(status), findsOneWidget);
    }
  });
}
