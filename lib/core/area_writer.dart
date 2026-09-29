/// Round 38 §B — `+ Add area`: the one new thing Asa may write into a
/// project's `plan\` folder on its own, alongside the narrow existing
/// amendment for `rounds\APPROVED.md`/`CHANGES.md` (ADR 0021/0026, both
/// amended 2026-09-28 for this same round). **Asa never edits or removes
/// an existing area page** — this writer only ever creates a brand new
/// one, and refuses outright if the name is already taken. Pure Dart, no
/// Flutter import.
library;

import 'dart:io';

import 'package:asa/core/skills_catalog.dart' show asaRepoPathFrom;
import 'package:asa/core/write_log.dart';

/// What creating an area actually did — [sourceFile] on success, a plain
/// [error] a person could read when it didn't happen at all (no file
/// touched either way).
class AreaCreateResult {
  const AreaCreateResult({this.sourceFile, this.error});

  final String? sourceFile;
  final String? error;

  bool get isSuccess => error == null;
}

final RegExp _notSlugChar = RegExp('[^a-z0-9]+');
final RegExp _edgeDashes = RegExp(r'^-+|-+$');

/// Lowercase, dashes, nothing else — `Finance` → `finance`, `Q4 Ops &
/// Runway` → `q4-ops-runway`. A name that reduces to nothing (all
/// punctuation, or empty) slugs to `''`, which [createArea] refuses
/// rather than write a file with no real name in it.
String slugifyAreaName(String name) {
  final lower = name.trim().toLowerCase().replaceAll(_notSlugChar, '-');
  return lower.replaceAll(_edgeDashes, '');
}

/// Writes `plan\<slug>.md` from `templates\area.md`, with the typed
/// [name] as its own title. [templatePath] and [writeLogPath] exist only
/// for tests — production code never passes either.
Future<AreaCreateResult> createArea(
  String projectFolder,
  String name, {
  String? templatePath,
  String? writeLogPath,
}) async {
  final trimmedName = name.trim();
  final slug = slugifyAreaName(trimmedName);
  if (slug.isEmpty) {
    return const AreaCreateResult(
      error: 'That name has no letters or numbers in it.',
    );
  }

  final sep = Platform.pathSeparator;
  final planDir = Directory(
    '$projectFolder$sep'
    'plan',
  );
  final targetPath = '${planDir.path}$sep$slug.md';
  final target = File(targetPath);

  if (target.existsSync()) {
    return AreaCreateResult(
      error: 'An area named "$slug" already exists — plan$sep$slug.md.',
    );
  }

  final resolvedTemplatePath =
      templatePath ??
      _defaultTemplatePath(projectsRoot: Directory(projectFolder).parent.path);
  if (resolvedTemplatePath == null) {
    return const AreaCreateResult(
      error:
          "Could not find the asa repo (rule 17's workspace shape) to "
          r'read templates\area.md from.',
    );
  }
  final template = File(resolvedTemplatePath);
  if (!template.existsSync()) {
    return AreaCreateResult(
      error: 'The area template is missing: $resolvedTemplatePath.',
    );
  }

  final templateText = await template.readAsString();
  final content = templateText.replaceFirst('# Name', '# $trimmedName');

  await planDir.create(recursive: true);
  await target.writeAsString(content);

  await appendWriteLogEntry(
    path: targetPath,
    field: 'area-created',
    from: '',
    to: trimmedName,
    logPath: writeLogPath,
  );

  return AreaCreateResult(sourceFile: targetPath);
}

/// `asa\templates\area.md` — same rule-17 fixed-sibling assumption
/// `skills_catalog.dart`'s own `asaRepoPathFrom` already makes (the asa
/// repo sits next to `projects\`, not derived from the running
/// executable, which is not reliable in a Flutter desktop build). Null
/// when the asa repo itself can't be found, same honest absence
/// `asaRepoPathFrom` already returns.
String? _defaultTemplatePath({required String projectsRoot}) {
  final asaRepoPath = asaRepoPathFrom(projectsRoot);
  if (asaRepoPath == null) return null;
  final sep = Platform.pathSeparator;
  return '$asaRepoPath$sep'
      'templates$sep'
      'area.md';
}
