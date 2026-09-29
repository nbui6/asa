// Round 39 cp6 — the Instruction for AI screen. Real disk, a small
// invented workspace (a sibling "asa" folder + a "projects" folder),
// never the real repo or the real projects folder.

import 'dart:convert';
import 'dart:io';

import 'package:asa/hubs/product/instruction_for_ai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory workspace;
  late String settingsPath;

  String join(List<String> parts) => parts.join(Platform.pathSeparator);

  setUp(() {
    workspace = Directory.systemTemp.createTempSync(
      'asa-instruction-screen-test-',
    );
    final asaRepo = join([workspace.path, 'asa']);
    final projectsRoot = join([workspace.path, 'projects']);
    Directory(asaRepo).createSync(recursive: true);
    Directory(projectsRoot).createSync(recursive: true);

    Directory(join([asaRepo, 'templates'])).createSync(recursive: true);
    File(join([asaRepo, 'templates', 'AGENTS.md']))
        .writeAsStringSync('## 0. Your job\n\nKeep things moving.\n');

    Directory(join([asaRepo, 'kit', 'skills', 'demo-skill']))
        .createSync(recursive: true);
    File(join([asaRepo, 'kit', 'skills', 'demo-skill', 'SKILL.md']))
        .writeAsStringSync(
          '---\nname: demo-skill\ndescription: A demo skill.\n---\n',
        );
    Directory(join([asaRepo, '.claude', 'skills', 'demo-skill']))
        .createSync(recursive: true);
    File(join([asaRepo, '.claude', 'skills', 'demo-skill', 'SKILL.md']))
        .writeAsStringSync(
          '---\nname: demo-skill\ndescription: A demo skill.\n---\n',
        );

    Directory(join([asaRepo, 'kit', 'agents'])).createSync(recursive: true);
    File(join([asaRepo, 'kit', 'agents', 'demo-agent.md'])).writeAsStringSync(
      '---\nname: demo-agent\ndescription: A demo agent.\n---\n',
    );

    File(join([projectsRoot, 'AGENTS.md']))
        .writeAsStringSync('## 0. Your job\n\nKeep things moving.\n');
    File(join([projectsRoot, 'BOSS.md'])).writeAsStringSync('''
# BOSS.md — Jamie

## Read this first — the short version
1. **How I like to get information:** One thing at a time.

## Your rules — the second half of the list
1. 2026-09-01 — An invented rule for this test.
''');

    final demo = join([projectsRoot, 'demo']);
    Directory(demo).createSync(recursive: true);
    File(join([demo, 'demo.md'])).writeAsStringSync('''
---
project: Demo
status: idea
updated: 2026-09-28
---
# Demo

## Tasks
- [ ] A task
''');
    File(join([projectsRoot, '.asa-setup.md']))
        .writeAsStringSync('set-up: 2026-09-28\n');

    settingsPath = join([workspace.path, 'settings.json']);
    File(settingsPath)
        .writeAsStringSync(jsonEncode({'projectsFolder': projectsRoot}));
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  // Real dart:io reads and a real `git` subprocess run inside _load() —
  // Flutter's fake test zone never advances those on its own, so the
  // widget's own loading spinner (an indefinitely-animating
  // CircularProgressIndicator) would make a bare pumpAndSettle() time
  // out forever. runAsync() lets the real Future actually finish first,
  // same pattern project_screen_edit_test.dart's own pumpAndSettleReal
  // already established.
  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstructionForAiScreen(settingsPath: settingsPath),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('shows all five parts, starting on How it works', (tester) async {
    await pump(tester);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Instructions'), findsOneWidget);
    expect(find.text('Skills & agents'), findsOneWidget);
    expect(find.text('Working with you'), findsOneWidget);
    expect(find.textContaining('Checks ('), findsOneWidget);
    // SectionLabel renders its own text upper-cased.
    expect(find.textContaining('THE LOOP, EVERY SESSION'), findsOneWidget);
  });

  testWidgets('Instructions shows the installed copy matches ✓', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Instructions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('matches'), findsOneWidget);
    expect(find.text('Copy for any AI'), findsOneWidget);
  });

  testWidgets('Skills & agents finds the real demo skill and agent', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Skills & agents'));
    await tester.pumpAndSettle();
    expect(find.text('demo-skill'), findsOneWidget);
    expect(find.textContaining('in the repo ✓'), findsOneWidget);
    expect(find.text('demo-agent'), findsOneWidget);
  });

  testWidgets('Working with you shows the filled-in BOSS.md sections', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Working with you'));
    await tester.pumpAndSettle();
    expect(find.textContaining('One thing at a time'), findsOneWidget);
    expect(
      find.textContaining('An invented rule for this test'),
      findsOneWidget,
    );
  });

  testWidgets("Checks shows asa-check's own findings — the fixture project is "
      'well-shaped, so OK', (tester) async {
    await pump(tester);
    await tester.tap(find.textContaining('Checks ('));
    await tester.pumpAndSettle();
    expect(find.textContaining('OK'), findsOneWidget);
  });

  testWidgets(
    'Round 38 §F, ADR 0036 — an on-hold project never reaches the '
    'aggregate Checks, even though it would otherwise be a real finding',
    (tester) async {
      // A second, real project — deliberately missing "## Tasks" (a real
      // asa-check finding on its own) and set on-hold, so this proves
      // exclusion rather than a fixture that was clean anyway.
      final projectsRoot = join([workspace.path, 'projects']);
      final paused = '$projectsRoot${Platform.pathSeparator}paused';
      Directory(paused).createSync(recursive: true);
      File('$paused${Platform.pathSeparator}paused.md').writeAsStringSync('''
---
project: Paused Project
status: on-hold
updated: 2026-09-28
---
# Paused Project
''');

      await pump(tester);
      await tester.tap(find.textContaining('Checks ('));
      await tester.pumpAndSettle();

      expect(find.textContaining('OK'), findsOneWidget);
      expect(find.textContaining('Paused Project'), findsNothing);
    },
  );
}
