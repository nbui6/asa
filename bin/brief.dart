/// Round 39 cp3 — `asa-brief`, the command line. Thin on purpose: every
/// real rule lives in `lib\core\brief.dart`, pure Dart with no Flutter
/// import, so this file only parses arguments and prints what that
/// returns. Run via `dart run bin/brief.dart ...`, or `asa-brief.cmd`
/// once `asa\bin` is on PATH — see `bin/README.md`.
library;

// `avoid_print` is off for this file only — a command whose entire job is
// printing to stdout is not the mistake that rule exists to catch.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:asa/core/brief.dart';
import 'package:asa/core/settings.dart';

const _usage = '''
asa-brief --all
asa-brief --since <date>
asa-brief "<project>" [--area <name>] [--round <N>]
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  String? project;
  String? area;
  String? round;
  String? since;
  var all = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '--all':
        all = true;
      case '--area':
        i++;
        area = i < args.length ? args[i] : null;
      case '--round':
        i++;
        round = i < args.length ? args[i] : null;
      case '--since':
        i++;
        since = i < args.length ? args[i] : null;
      default:
        project ??= arg;
    }
  }

  if (all) {
    final root = await _projectsRootOrFail();
    if (root == null) return;
    print(await briefAll(root, recordHistory: true));
    return;
  }

  if (since != null) {
    final root = await _projectsRootOrFail();
    if (root == null) return;
    final date = DateTime.tryParse(since);
    if (date == null) {
      stderr.writeln('--since needs a real date, e.g. --since 2026-09-25');
      exitCode = 64;
      return;
    }
    print(await briefSince(root, date));
    return;
  }

  if (project == null) {
    stderr.write(_usage);
    exitCode = 64;
    return;
  }

  final root = await _projectsRootOrFail();
  if (root == null) return;
  final folder = '$root${Platform.pathSeparator}$project';
  print(
    await briefProject(folder, area: area, round: round, recordHistory: true),
  );
}

/// The projects folder Asa itself is pointed at — read the same way the
/// app does, from `%APPDATA%\Asa\settings.json`, so `asa-brief` never
/// drifts from what the running app would show for the same project.
Future<String?> _projectsRootOrFail() async {
  final settings = await readSettings();
  final root = settings.projectsFolder;
  if (root == null) {
    stderr.writeln(
      'No projects folder set yet — open Asa once and choose one, or set '
      r"it by hand in %APPDATA%\Asa\settings.json's projectsFolder.",
    );
    exitCode = 1;
    return null;
  }
  return root;
}
