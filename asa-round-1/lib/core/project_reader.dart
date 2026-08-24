/// Finds a project home note on disk and reads it.
///
/// Separate from `project.dart` so that the parsing can be tested without
/// touching the file system.
library;

import 'dart:io';

import 'project.dart';

/// Reads the project home note inside [projectFolder].
///
/// The convention: a folder contains exactly one note whose name matches the
/// folder — `projects/asa/asa.md`. If that is missing, the first `.md` file
/// with frontmatter is used instead.
Future<ProjectReadResult> readProject(String projectFolder) async {
  final folder = Directory(projectFolder);

  if (!await folder.exists()) {
    return ProjectReadResult(error: 'No folder at: $projectFolder');
  }

  final noteFile = await findHomeNote(folder);
  if (noteFile == null) {
    return ProjectReadResult(
      error: 'No markdown file with frontmatter found in: $projectFolder',
    );
  }

  final contents = await noteFile.readAsString();
  final raw = extractRawFrontmatter(contents);

  if (raw.isEmpty) {
    return ProjectReadResult(
      error: 'Found ${noteFile.path} but it has no frontmatter block',
    );
  }

  final fields = parseFrontmatter(contents);
  return ProjectReadResult(
    project: projectFromFields(fields, noteFile.path),
    rawFrontmatter: raw,
  );
}

/// Prefers a note named after the folder; otherwise the first note that has
/// frontmatter. Returns null if there is neither.
Future<File?> findHomeNote(Directory folder) async {
  final folderName = folder.path.split(Platform.pathSeparator).last;

  final markdownFiles = <File>[];
  await for (final entry in folder.list(followLinks: false)) {
    if (entry is File && entry.path.toLowerCase().endsWith('.md')) {
      markdownFiles.add(entry);
    }
  }

  for (final file in markdownFiles) {
    final name = file.path.split(Platform.pathSeparator).last;
    if (name.toLowerCase() == '$folderName.md'.toLowerCase()) {
      return file;
    }
  }

  for (final file in markdownFiles) {
    final contents = await file.readAsString();
    if (extractRawFrontmatter(contents).isNotEmpty) {
      return file;
    }
  }

  return null;
}
