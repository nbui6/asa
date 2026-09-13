// Widget-level check for the overdue-deadline signal — HANDOVER.md, "an
// overdue signal for deadline". Invented dates throughout; the point is
// the colour logic, not any real project's actual deadline.

import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget pumpRow(Project project) {
    return MaterialApp(
      home: Scaffold(
        body: ProjectsView(
          forest: [ProjectNode(project: project, folder: project.sourceFile)],
          onOpenProject: (_) {},
          onAssignTask: (_, _) async {},
        ),
      ),
    );
  }

  const overdueProject = Project(
    name: 'Overdue Demo',
    status: 'building',
    milestone: '',
    nextStep: '',
    repoPath: '',
    updated: '2026-09-13',
    sourceFile: 'demo/demo.md',
    deadline: '2020-01',
  );

  testWidgets("an overdue deadline renders in the theme's error colour", (
    tester,
  ) async {
    await tester.pumpWidget(pumpRow(overdueProject));

    final text = tester.widget<Text>(find.text('Jan 2020'));
    final context = tester.element(find.text('Jan 2020'));
    expect(text.style?.color, Theme.of(context).colorScheme.error);
  });

  testWidgets('shipped suppresses the signal even with the same overdue '
      'date', (tester) async {
    const shipped = Project(
      name: 'Shipped Demo',
      status: 'shipped',
      milestone: '',
      nextStep: '',
      repoPath: '',
      updated: '2026-09-13',
      sourceFile: 'demo/shipped.md',
      deadline: '2020-01',
    );
    await tester.pumpWidget(pumpRow(shipped));

    final text = tester.widget<Text>(find.text('Jan 2020'));
    expect(text.style?.color, Colors.grey.shade600);
  });

  testWidgets('a future deadline is not overdue and stays the plain '
      'colour', (tester) async {
    const future = Project(
      name: 'Future Demo',
      status: 'building',
      milestone: '',
      nextStep: '',
      repoPath: '',
      updated: '2026-09-13',
      sourceFile: 'demo/future.md',
      deadline: '2099-01',
    );
    await tester.pumpWidget(pumpRow(future));

    final text = tester.widget<Text>(find.text('Jan 2099'));
    expect(text.style?.color, Colors.grey.shade600);
  });
}
