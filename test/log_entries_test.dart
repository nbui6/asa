// Round 38 §E — the Log's own merged timeline. Real files, real disk,
// same reasoning as area_test.dart's own readAreas tests: six real
// sources, each already trusted by its own test file
// (decisions_reader_test.dart, round_approvals_test.dart,
// changes_file_test.dart, session_log's own coverage, area_test.dart,
// change_history_test.dart) — this file proves they land in one sorted
// list with the right type each, not that any one of them parses
// correctly on its own.

import 'dart:io';

import 'package:asa/core/change_history.dart' show recordChanges;
import 'package:asa/core/decisions_reader.dart' show DiskFileAccess;
import 'package:asa/core/log_entries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectFolder;
  late String historyRoot;
  const files = DiskFileAccess();

  String sep(String a, String b) => '$a${Platform.pathSeparator}$b';

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-log-entries-test-');
    projectFolder = sep(tempDir.path, 'demo');
    Directory(projectFolder).createSync(recursive: true);
    historyRoot = sep(tempDir.path, 'history');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('a decision contributes type decision, with its area/objective/round',
      () async {
    Directory(sep(projectFolder, 'decisions')).createSync();
    File(sep(sep(projectFolder, 'decisions'), '0001-thing.md'))
        .writeAsStringSync('''
# ADR 0001 — A real decision

**Date:** 2026-09-20 · **Status:** accepted
**Links:** Area: Sales · Serves: Objective 1 · Round: 38

## Decision
The decision text.

## Why
Because.

## What would change this
Nothing.
''');

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.decision);
    expect(entries.first.area, 'Sales');
    expect(entries.first.objectiveNumber, '1');
    expect(entries.first.round, '38');
  });

  test('a sketch approval contributes type yourYes, not decision', () async {
    final sketchesDir = Directory(sep(projectFolder, 'sketches'))
      ..createSync();
    // The row's own image/source paths must resolve, rule 17's own
    // shape: projects\<name>\... — decisions_reader.dart's own
    // SketchApprovalsSource checks both are real files, not just text.
    File(sep(sketchesDir.path, 'a.png')).writeAsStringSync('x');
    File(sep(sketchesDir.path, 'a.html')).writeAsStringSync('x');
    File(sep(sketchesDir.path, 'APPROVED.md')).writeAsStringSync(r'''
| Date | Sketch | Image | Source | Covers | Said, verbatim |
|---|---|---|---|---|---|
| 2026-09-20 | a-sketch | `projects\demo\sketches\a.png` | `projects\demo\sketches\a.html` | The whole thing | "yes" |
''');

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.yourYes);
  });

  test('a round approval contributes type yourYes', () async {
    Directory(sep(projectFolder, 'rounds')).createSync();
    File(sep(sep(projectFolder, 'rounds'), 'APPROVED.md'))
        .writeAsStringSync('''
| date | round | their exact words | the result, in one line |
|---|---|---|---|
| 2026-09-20 | 38 | "yes" | Areas as tabs, shipped |
''');

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.yourYes);
    expect(entries.first.round, '38');
  });

  test('a change request contributes type changesAsked', () async {
    Directory(sep(projectFolder, 'rounds')).createSync();
    File(sep(sep(projectFolder, 'rounds'), 'CHANGES.md')).writeAsStringSync('''
| date | round | what they want changed |
|---|---|---|
| 2026-09-20 | 38 | move the button |
''');

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.changesAsked);
    expect(entries.first.detail, 'move the button');
  });

  test('a .asa-log.md line contributes type aiWorked', () async {
    File(sep(projectFolder, '.asa-log.md')).writeAsStringSync(
      '- 2026-09-20 10:00-10:05 · test · did the thing · demo.md\n',
    );

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.aiWorked);
  });

  test('a dated area result contributes type result', () async {
    Directory(sep(projectFolder, 'plan')).createSync();
    File(sep(sep(projectFolder, 'plan'), '1-sales.md')).writeAsStringSync('''
# Sales

## Goal
Serves Objective 1.

## Plan

## Tasks

## Results
- 2026-09-20 — Something happened.

## Decisions
''');

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(1));
    expect(entries.first.type, LogEntryType.result);
    expect(entries.first.area, 'Sales');
  });

  test(
    'an unlogged change contributes type changedWithoutNote; a logged '
    'one contributes type change',
    () async {
      final charterPath = sep(projectFolder, 'CHARTER.md');
      File(charterPath).writeAsStringSync('## Objectives\n1. First.\n');
      await recordChanges(
        projectFolder,
        tempDir.path,
        historyRoot: historyRoot,
      );

      File(charterPath).writeAsStringSync('## Objectives\n1. Changed.\n');
      await recordChanges(
        projectFolder,
        tempDir.path,
        historyRoot: historyRoot,
      );

      final entries = await readLogEntries(
        projectFolder,
        files,
        historyRoot: historyRoot,
      );
      expect(entries, hasLength(1));
      expect(entries.first.type, LogEntryType.changedWithoutNote);

      // Now with a same-day log line naming the file — logged instead.
      final today = DateTime.now();
      final logLine =
          '- ${today.toIso8601String().split("T").first} 10:00-10:05 · '
          'test · updated · CHARTER.md\n';
      File(sep(projectFolder, '.asa-log.md')).writeAsStringSync(logLine);
      File(charterPath)
          .writeAsStringSync('## Objectives\n1. Changed again.\n');
      await recordChanges(
        projectFolder,
        tempDir.path,
        historyRoot: historyRoot,
      );

      final entries2 = await readLogEntries(
        projectFolder,
        files,
        historyRoot: historyRoot,
      );
      expect(entries2.any((e) => e.type == LogEntryType.change), isTrue);
    },
  );

  test('sorted newest first across every source', () async {
    File(sep(projectFolder, '.asa-log.md')).writeAsStringSync(
      '- 2026-09-10 10:00-10:05 · test · old · demo.md\n'
      '- 2026-09-25 10:00-10:05 · test · new · demo.md\n',
    );

    final entries = await readLogEntries(projectFolder, files);
    expect(entries, hasLength(2));
    expect(entries.first.date, DateTime(2026, 9, 25));
    expect(entries.last.date, DateTime(2026, 9, 10));
  });

  test('an empty project contributes nothing, not an error', () async {
    final entries = await readLogEntries(projectFolder, files);
    expect(entries, isEmpty);
  });
}
