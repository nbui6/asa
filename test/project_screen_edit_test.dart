// Real files, real disk — same reasoning as inbox_flow_test.dart:
// ProjectScreen reads through readProject (real dart:io), so only a real
// temp folder proves the edit → save → re-read loop actually works.

import 'dart:io';

import 'package:asa/hubs/product/project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _realShapedBody = '''
---
project: Demo
status: building
parent: other
priority: high
deadline: 2026-09
jira: https://example.atlassian.net/browse/DEMO-1
milestone: Some milestone
next-step: Some next step
updated: 2026-09-13
---

# Demo

A paragraph of body text.
''';

void main() {
  late Directory tempDir;
  late String folder;
  late String projectFile;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-project-edit-test-');
    folder = tempDir.path;
    projectFile =
        '${tempDir.path}${Platform.pathSeparator}'
        '${tempDir.path.split(Platform.pathSeparator).last}.md';
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
    File(projectFile).writeAsStringSync(_realShapedBody);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  // A real dart:io read/write does not, by itself, end pumpAndSettle's
  // wait — only the setState() after it does. The call that *kicks off*
  // the real Future has to happen inside runAsync() too, not just the
  // wait afterward — a Future started in the fake-async zone stays there
  // no matter how long a later runAsync() waits. Same pattern
  // projects_screen_test.dart already established (see its own comment
  // on this, 2026-09-04).
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
    await pumpAndSettleReal(
      tester,
      () => tester.pumpWidget(
        MaterialApp(
          home: ProjectScreen(folder: folder, writeLogPath: logPath),
        ),
      ),
    );
    // The screen defaults to the Decisions tab — every field this round
    // touches lives on Details.
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
  }

  Future<void> editAndSave(
    WidgetTester tester,
    String label,
    String newValue,
  ) async {
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first,
        matching: find.byIcon(Icons.edit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), newValue);
    await pumpAndSettleReal(tester, () => tester.tap(find.byIcon(Icons.check)));
  }

  group('Round 20 — editing a whitelisted field, one at a time', () {
    testWidgets('Parent: edit, save, the new value shows and survives a '
        'reload', (tester) async {
      await pumpScreen(tester);
      expect(find.text('other'), findsOneWidget);

      await editAndSave(tester, 'Parent', 'a-different-parent');

      expect(find.text('a-different-parent'), findsOneWidget);
      expect(find.text('other'), findsNothing);
      // Survives a re-read from disk, not just the in-memory value.
      expect(
        File(projectFile).readAsStringSync(),
        contains('parent: a-different-parent'),
      );
    });

    testWidgets('Priority: edit, save, the new value shows', (tester) async {
      await pumpScreen(tester);

      await editAndSave(tester, 'Priority', 'low');

      expect(find.text('low'), findsOneWidget);
    });

    testWidgets('Deadline: edit, save, the new value shows', (tester) async {
      await pumpScreen(tester);

      await editAndSave(tester, 'Deadline', '2027-01');

      // Round 37 §D6 — humanised ("Jan 2027"), not the raw "2027-01".
      expect(find.text('Jan 2027'), findsOneWidget);
    });

    testWidgets('Jira: edit, save, the new value shows', (tester) async {
      await pumpScreen(tester);

      await editAndSave(
        tester,
        'Jira',
        'https://example.atlassian.net/browse/DEMO-9',
      );

      // Round 37 §D6 — a chip naming the ticket ("DEMO-9 ↗"), not the
      // raw full URL.
      expect(find.text('DEMO-9 ↗'), findsOneWidget);
    });

    testWidgets(
      'Status: a picker, not free text — selecting a value saves it, in '
      'the new ADR 0041 word even though the file started on the old one',
      (tester) async {
        await pumpScreen(tester);
        // The fixture's own `status: building` — an old word — reads and
        // shows as its new label, "In progress".
        expect(find.text('In progress'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find
                .ancestor(of: find.text('Status'), matching: find.byType(Row))
                .first,
            matching: find.byIcon(Icons.edit),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('On hold').last);
        await tester.pumpAndSettle();

        await pumpAndSettleReal(
          tester,
          () => tester.tap(find.byIcon(Icons.check)),
        );

        expect(find.text('On hold'), findsOneWidget);
        expect(
          File(projectFile).readAsStringSync(),
          contains('status: on-hold'),
        );
      },
    );

    testWidgets('a value cleared by editing to nothing shows "not set"', (
      tester,
    ) async {
      await pumpScreen(tester);

      await editAndSave(tester, 'Priority', '');

      // Round 37 §D6 — "not set" in grey, not the literal "(not set)".
      expect(find.text('not set'), findsOneWidget);
    });

    testWidgets('nothing else on the row changes shape — Milestone and '
        'Next step stay plain, read-only text with no edit icon', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Milestone'), findsOneWidget);
      expect(find.text('Next step'), findsOneWidget);
      // Five editable fields (Status/Parent/Priority/Deadline/Jira) means
      // five edit icons — not one for every row on the tab.
      expect(find.byIcon(Icons.edit), findsNWidgets(5));
    });

    testWidgets('a drift — the file changed on disk since it was read — '
        'shows the real reason, not a silent failure', (tester) async {
      await pumpScreen(tester);

      await tester.tap(
        find.descendant(
          of: find
              .ancestor(of: find.text('Priority'), matching: find.byType(Row))
              .first,
          matching: find.byIcon(Icons.edit),
        ),
      );
      await tester.pumpAndSettle();

      // His editor, in the real scenario — the file changes underneath.
      File(projectFile).writeAsStringSync(
        _realShapedBody.replaceFirst('status: building', 'status: paused'),
      );

      await tester.enterText(find.byType(TextField), 'low');
      await pumpAndSettleReal(
        tester,
        () => tester.tap(find.byIcon(Icons.check)),
      );

      expect(find.textContaining('Could not save'), findsOneWidget);
      // Refused, not silently applied — the file still says what the
      // "external edit" put there, not the low priority just typed.
      expect(
        File(projectFile).readAsStringSync(),
        isNot(contains('priority: low')),
      );
    });
  });
}
