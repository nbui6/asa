/// Round 39 cp4 — `asa-check`, the command line. Thin on purpose: every
/// real rule lives in `lib\core\check.dart`, pure Dart with no Flutter
/// import. Run via `dart run bin/check.dart "<project>"`, or
/// `asa-check.cmd` once `asa\bin` is on PATH — see `bin/README.md`.
library;

// `avoid_print` is off for this file only — a command whose entire job is
// printing to stdout is not the mistake that rule exists to catch.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:asa/core/check.dart';
import 'package:asa/core/settings.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('asa-check "<project>"');
    exitCode = 64;
    return;
  }

  final settings = await readSettings();
  final root = settings.projectsFolder;
  if (root == null) {
    stderr.writeln(
      'No projects folder set yet — open Asa once and choose one, or set '
      r"it by hand in %APPDATA%\Asa\settings.json's projectsFolder.",
    );
    exitCode = 1;
    return;
  }

  final folder = '$root${Platform.pathSeparator}${args.first}';
  final findings = await checkProject(folder);

  if (findings.isEmpty) {
    print('OK');
    return;
  }

  for (final finding in findings) {
    print(finding.message);
  }
  exitCode = 1;
}
