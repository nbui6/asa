/// Round 43 §E, ADR 0042 — "＋ New project": creates `projects\<slug>\`,
/// its home note from `templates\project-note.md` (the name, `status:
/// idea`, empty `## Tasks`), and the project's own `HOW-ASA-WORKS.md`
/// pointer. Same template-copying shape as `area_writer.dart`'s
/// `createArea`; pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/skills_catalog.dart' show asaRepoPathFrom;
import 'package:asa/core/slug.dart';
import 'package:asa/core/write_log.dart';

/// What creating a project actually did — [folder]/[sourceFile] on
/// success, a plain [error] a person could read when it didn't happen at
/// all (no file touched either way).
class ProjectCreateResult {
  const ProjectCreateResult({this.folder, this.sourceFile, this.error});

  final String? folder;
  final String? sourceFile;
  final String? error;

  bool get isSuccess => error == null;
}

/// The characters Windows itself refuses in a file or folder name —
/// round-43.md §E's own list, verbatim.
final RegExp _forbiddenChars = RegExp(r'[\\/:*?"<>|]');

/// Windows' own reserved device names — refused regardless of case, with
/// or without an extension, same as the real filesystem already refuses
/// them.
const _reservedNames = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
};

/// Writes `projects\<slug>\<slug>.md` from `templates\project-note.md`
/// (the typed [name] filled in, `status: idea`, `updated:` today) plus a
/// copy of `templates\HOW-ASA-WORKS.md`, under [projectsRoot].
/// [projectNoteTemplatePath]/[howAsaWorksTemplatePath]/[writeLogPath]
/// exist only for tests — production code never passes any of them.
///
/// **Refuses on the line, writing nothing:** the typed name reduces to
/// nothing once trimmed; it contains one of Windows' own forbidden path
/// characters (`\ / : * ? " < > |`); its slug is a Windows reserved
/// device name (`CON`, `NUL`, …); or a folder with that slug already
/// exists.
Future<ProjectCreateResult> createProject(
  String projectsRoot,
  String name, {
  String? projectNoteTemplatePath,
  String? howAsaWorksTemplatePath,
  String? writeLogPath,
}) async {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return const ProjectCreateResult(error: 'A project needs a name.');
  }

  final forbidden = _forbiddenChars
      .allMatches(trimmedName)
      .map((m) => m.group(0)!)
      .toSet();
  if (forbidden.isNotEmpty) {
    return ProjectCreateResult(
      error:
          'That name has a character Windows itself refuses in a path: '
          '${forbidden.join(' ')}',
    );
  }

  final slug = slugify(trimmedName);
  if (slug.isEmpty) {
    return const ProjectCreateResult(
      error: 'That name has no letters or numbers in it.',
    );
  }
  if (_reservedNames.contains(slug.toUpperCase())) {
    return ProjectCreateResult(
      error: '"$slug" is a name Windows itself reserves — pick another.',
    );
  }

  final sep = Platform.pathSeparator;
  final folder = '$projectsRoot$sep$slug';
  if (Directory(folder).existsSync()) {
    return ProjectCreateResult(
      error: 'A project named "$slug" already exists.',
    );
  }

  final resolvedProjectNoteTemplatePath =
      projectNoteTemplatePath ??
      _templatePath(projectsRoot: projectsRoot, name: 'project-note.md');
  final resolvedHowAsaWorksTemplatePath =
      howAsaWorksTemplatePath ??
      _templatePath(projectsRoot: projectsRoot, name: 'HOW-ASA-WORKS.md');
  if (resolvedProjectNoteTemplatePath == null ||
      resolvedHowAsaWorksTemplatePath == null) {
    return const ProjectCreateResult(
      error:
          "Could not find the asa repo (rule 17's workspace shape) to "
          'read its templates from.',
    );
  }

  final noteTemplate = File(resolvedProjectNoteTemplatePath);
  final howAsaWorksTemplate = File(resolvedHowAsaWorksTemplatePath);
  if (!noteTemplate.existsSync()) {
    return ProjectCreateResult(
      error:
          'The project-note template is missing: '
          '$resolvedProjectNoteTemplatePath.',
    );
  }
  if (!howAsaWorksTemplate.existsSync()) {
    return ProjectCreateResult(
      error:
          'The HOW-ASA-WORKS template is missing: '
          '$resolvedHowAsaWorksTemplatePath.',
    );
  }

  final today = _isoDate(DateTime.now());
  final noteContent = (await noteTemplate.readAsString())
      .replaceFirst('project: ', 'project: $trimmedName')
      .replaceFirst('\n# \n', '\n# $trimmedName\n')
      .replaceFirst('updated: ', 'updated: $today');

  await Directory(folder).create(recursive: true);
  final sourceFile = '$folder$sep$slug.md';
  await File(sourceFile).writeAsString(noteContent);
  await howAsaWorksTemplate.copy('$folder${sep}HOW-ASA-WORKS.md');

  await appendWriteLogEntry(
    path: sourceFile,
    field: 'project-created',
    from: '',
    to: trimmedName,
    logPath: writeLogPath,
  );

  return ProjectCreateResult(folder: folder, sourceFile: sourceFile);
}

/// `asa\templates\<name>` — same fixed-sibling assumption
/// `area_writer.dart`'s own `_defaultTemplatePath` already makes.
String? _templatePath({required String projectsRoot, required String name}) {
  final asaRepoPath = asaRepoPathFrom(projectsRoot);
  if (asaRepoPath == null) return null;
  final sep = Platform.pathSeparator;
  return '$asaRepoPath${sep}templates$sep$name';
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
