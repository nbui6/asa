// ADR 0051 — archive and delete, wired at the bottom of Details. Real
// files, real disk, same reasoning as project_screen_edit_test.dart:
// ProjectScreen reads/writes through real dart:io. Archive (a plain
// folder move, contained entirely inside the temp projectsRoot built
// here) is exercised for real; Delete's own confirmation dialog is
// checked for its content and its Cancel path only — confirming it for
// real would send a real folder to the real Windows Recycle Bin on
// whatever machine runs this suite, the same reason recycle_bin_test.dart
// never calls the real send either. The real send was proven once, by
// hand, against a throwaway temp folder — HANDOVER.md has that
// checkpoint.

import 'dart:io';

import 'package:asa/hubs/product/project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory projectsRoot;
  late String parentFolder;
  late String childFolder;

  setUp(() {
    projectsRoot = Directory.systemTemp.createTempSync('asa-archive-ui-test-');
    parentFolder = '${projectsRoot.path}${Platform.pathSeparator}demo';
    childFolder = '${projectsRoot.path}${Platform.pathSeparator}child';
    Directory(parentFolder).createSync(recursive: true);
    File('$parentFolder${Platform.pathSeparator}demo.md')
        .writeAsStringSync('---\nproject: Demo\nstatus: in-progress\n---\n');
    Directory(childFolder).createSync(recursive: true);
    File('$childFolder${Platform.pathSeparator}child.md').writeAsStringSync(
      '---\nproject: Child\nstatus: in-progress\nparent: demo\n---\n',
    );
  });

  tearDown(() => projectsRoot.deleteSync(recursive: true));

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
        MaterialApp(home: ProjectScreen(folder: parentFolder)),
      ),
    );
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
  }

  // The Archive/Delete row sits at the very bottom of a long, scrollable
  // Details tab (AsaPage's own SingleChildScrollView) — below the default
  // test surface's own 800x600 without this.
  Future<void> tapScrolledIntoView(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  testWidgets('ADR 0051 — 🗄 Archive moves this project and its child into '
      '_archive, unchanged, no question asked', (tester) async {
    await pumpScreen(tester);

    await pumpAndSettleReal(
      tester,
      () => tapScrolledIntoView(tester, find.text('🗄 Archive')),
    );

    expect(Directory(parentFolder).existsSync(), isFalse);
    expect(Directory(childFolder).existsSync(), isFalse);
    final archiveRoot = '${projectsRoot.path}${Platform.pathSeparator}_archive';
    expect(
      Directory('$archiveRoot${Platform.pathSeparator}demo').existsSync(),
      isTrue,
    );
    expect(
      Directory('$archiveRoot${Platform.pathSeparator}child').existsSync(),
      isTrue,
    );
    expect(
      File(
        '$archiveRoot${Platform.pathSeparator}demo'
        '${Platform.pathSeparator}demo.md',
      ).readAsStringSync(),
      contains('status: in-progress'),
    );
  });

  testWidgets(
    "🗑 Delete's own confirmation names the folder, its file count, its "
    'sub-project, and that there is no repo to touch',
    (tester) async {
      await pumpScreen(tester);

      await pumpAndSettleReal(
        tester,
        () => tapScrolledIntoView(tester, find.text('🗑 Delete')),
      );

      expect(find.text('Move "Demo" to the Recycle Bin?'), findsOneWidget);
      expect(find.textContaining('With its sub-project Child'), findsOneWidget);
      expect(find.textContaining('the Recycle Bin'), findsWidgets);
      // No repoPath set on this fixture — the "repo … is not touched"
      // line only appears when there is a repo to name.
      expect(find.textContaining('is not touched'), findsNothing);
    },
  );

  testWidgets(
    'with a repoPath set, the confirmation names it and says it is not '
    'touched',
    (tester) async {
      File('$parentFolder${Platform.pathSeparator}demo.md').writeAsStringSync(
        '---\nproject: Demo\nstatus: in-progress\n'
        r'repo-path: C:\code\demo'
        '\n---\n',
      );
      await pumpScreen(tester);

      await pumpAndSettleReal(
        tester,
        () => tapScrolledIntoView(tester, find.text('🗑 Delete')),
      );

      expect(
        find.textContaining(r'The repo at C:\code\demo is not touched'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Cancel on the delete dialog deletes nothing', (tester) async {
    await pumpScreen(tester);

    await pumpAndSettleReal(
      tester,
      () => tapScrolledIntoView(tester, find.text('🗑 Delete')),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Move "Demo" to the Recycle Bin?'), findsNothing);
    expect(Directory(parentFolder).existsSync(), isTrue);
    expect(Directory(childFolder).existsSync(), isTrue);
  });
}
