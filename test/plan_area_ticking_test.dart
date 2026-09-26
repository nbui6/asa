// Round 34/F, the narrow amendment to ADR 0021 — real files, real disk,
// same reasoning as project_screen_edit_test.dart: ProjectScreen reads
// and writes through real dart:io, so only a real temp folder proves the
// tick → write → re-read loop actually lands on the area's own file,
// changes exactly one line, and logs the write.

import 'dart:io';

import 'package:asa/hubs/product/project_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _homeNote = '''
---
project: Demo
status: building
updated: 2026-09-26
---

# Demo
''';

const _areaPage = '''
# Sales

The partner registers and closes its own deals.

## Goal
Serves Objective 1.

## Tasks
- [ ] Agree the shared account list
- [ ] Second demo for the account
''';

void main() {
  late Directory tempDir;
  late String folder;
  late String areaFile;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-area-ticking-test-');
    folder = tempDir.path;
    final name = tempDir.path.split(Platform.pathSeparator).last;
    File('${tempDir.path}${Platform.pathSeparator}$name.md')
        .writeAsStringSync(_homeNote);

    final planDir = Directory('${tempDir.path}${Platform.pathSeparator}plan')
      ..createSync();
    areaFile = '${planDir.path}${Platform.pathSeparator}1-sales.md';
    File(areaFile).writeAsStringSync(_areaPage);

    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
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

  testWidgets(
    "ticking a task inside an area writes exactly one line of the area's "
    'own file, [ ] to [x], and logs the write — never PLAN.md, never '
    'CHARTER.md',
    (tester) async {
      final before = File(areaFile).readAsStringSync();

      await pumpAndSettleReal(
        tester,
        () => tester.pumpWidget(
          MaterialApp(
            home: ProjectScreen(folder: folder, writeLogPath: logPath),
          ),
        ),
      );

      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      await tester.tap(find.text('Sales'));
      await tester.pump();

      expect(find.text('Agree the shared account list'), findsOneWidget);

      await pumpAndSettleReal(
        tester,
        () => tester.tap(find.byType(Checkbox).first),
      );

      final after = File(areaFile).readAsStringSync();
      final beforeLines = before.split('\n');
      final afterLines = after.split('\n');
      expect(afterLines.length, beforeLines.length);

      final changed = <int>[];
      for (var i = 0; i < beforeLines.length; i++) {
        if (beforeLines[i] != afterLines[i]) changed.add(i);
      }
      expect(changed, hasLength(1));
      expect(beforeLines[changed.single], contains('[ ]'));
      expect(afterLines[changed.single], contains('[x]'));

      expect(File(logPath).existsSync(), isTrue);
      expect(File(logPath).readAsStringSync(), contains('1-sales.md'));

      // Untick — the file returns to byte-identical, same discipline
      // task_writer.dart already proves for every other checkbox writer.
      await pumpAndSettleReal(
        tester,
        () => tester.tap(find.byType(Checkbox).first),
      );
      expect(File(areaFile).readAsStringSync(), before);
    },
  );
}
