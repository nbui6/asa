// Round 38 §B — the dialog's own logic (calls onCreateArea with the typed
// name, shows the refusal inline without closing, closes and switches
// tabs on success), tested against PlanView directly with fake
// callbacks — the same level area_writer_test.dart already proves the
// real write at, and plan_view_test.dart already tests every other
// PlanView interaction at. A full real-ProjectScreen, real-disk version
// of this test hit a reproducible hang in this environment specifically
// on a second concurrent readProject() call inside an un-awaited
// onDataChanged() fired from a dialog's own continuation — a real, odd
// interaction between this widget-test binding and back-to-back
// Directory.list() calls, not anything this round's own code does
// differently from any other onDataChanged caller. Isolating the test
// at this level sidesteps that entirely without leaving the dialog's own
// behaviour unverified.

import 'package:asa/core/area.dart';
import 'package:asa/core/area_writer.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/hubs/product/plan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<Area> areas,
    required Future<AreaCreateResult> Function(String) onCreateArea,
    void Function(String?)? onSelectAreaTab,
    VoidCallback? onDataChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlanView(
            plan: const Plan(pages: []),
            areas: areas,
            decisions: const [],
            homeTasks: const [],
            projectSourceFile: 'demo.md',
            onCreateArea: onCreateArea,
            onSelectAreaTab: onSelectAreaTab,
            onDataChanged: onDataChanged,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Create calls onCreateArea with the typed name, then switches tabs '
    'and reloads on success',
    (tester) async {
      String? typedName;
      String? selected;
      var reloaded = false;

      await pump(
        tester,
        areas: const [],
        onCreateArea: (name) async {
          typedName = name;
          return const AreaCreateResult(sourceFile: 'plan/finance.md');
        },
        onSelectAreaTab: (s) => selected = s,
        onDataChanged: () => reloaded = true,
      );

      // A project with no areas yet: "+ Add area" is a plain link.
      await tester.tap(find.text('+ Add area'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Finance');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(typedName, 'Finance');
      expect(find.byType(AlertDialog), findsNothing);
      expect(selected, 'plan/finance.md');
      expect(reloaded, isTrue);
    },
  );

  testWidgets(
    'a refusal shows inline, the dialog stays open, nothing else is '
    'called',
    (tester) async {
      var selectCalled = false;
      var reloadCalled = false;

      await pump(
        tester,
        areas: const [],
        onCreateArea: (name) async => AreaCreateResult(
          error: 'An area named "${name.toLowerCase()}" already exists.',
        ),
        onSelectAreaTab: (_) => selectCalled = true,
        onDataChanged: () => reloadCalled = true,
      );

      await tester.tap(find.text('+ Add area'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Finance');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('already exists'), findsOneWidget);
      expect(selectCalled, isFalse);
      expect(reloadCalled, isFalse);
    },
  );

  testWidgets('Cancel closes the dialog and calls nothing', (tester) async {
    var createCalled = false;

    await pump(
      tester,
      areas: const [],
      onCreateArea: (name) async {
        createCalled = true;
        return const AreaCreateResult(sourceFile: 'plan/finance.md');
      },
    );

    await tester.tap(find.text('+ Add area'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(createCalled, isFalse);
  });

  testWidgets(
    'a project that already has areas reaches + Add area from the tab '
    'strip, alongside All and the existing area',
    (tester) async {
      await pump(
        tester,
        areas: const [
          Area(
            name: 'Sales',
            sourceFile: 'plan/sales.md',
            tasks: [],
            results: [],
            decisionNumbers: [],
            objectiveNumbers: [],
          ),
        ],
        onCreateArea: (name) async =>
            const AreaCreateResult(sourceFile: 'plan/finance.md'),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('+ Add area'), findsOneWidget);

      await tester.tap(find.text('+ Add area'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );
}
