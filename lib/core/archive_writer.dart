/// ADR 0051 — archive and delete a project. Plain folder moves (archive,
/// restore) and a Recycle-Bin send (delete, `recycle_bin.dart`), never a
/// Flutter plugin — `open_url.dart`'s own header already names why
/// nothing on this machine builds with one (`pubspec.yaml`'s "NO
/// PLUGINS" note). Pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/project_tree.dart';
import 'package:asa/core/recycle_bin.dart';

/// [node]'s own folder, plus every descendant's — any depth, the same
/// subtree `ProjectNode.children` already resolves via each project's own
/// `parent:` field. ADR 0051 point 3: "a parent takes its sub-projects
/// along," for both archive and delete, since a sub-project is never
/// nested inside its parent's own folder on disk — only its own `parent:`
/// field says so — so moving one directory tree would leave every child
/// behind.
List<String> subtreeFolders(ProjectNode node) {
  return [
    node.folder,
    for (final child in node.children) ...subtreeFolders(child),
  ];
}

/// Moves [node] and its whole subtree from `projectsRoot\<slug>` to
/// `projectsRoot\_archive\<slug>`, unchanged — no file inside any of them
/// is read or rewritten, so an old status stays exactly what it was for
/// [restoreProject] to bring back. `_archive\` is created if this is the
/// first archive on this laptop; `scanProjects` already skips any folder
/// starting with `_`, so nothing further is needed to keep it, and
/// `asa-brief`, out of the overview, Tasks and the checks.
///
/// Refuses, moving nothing, if any destination already exists — a name
/// collision is a real finding to surface, not a guess to resolve by
/// overwriting.
Future<void> archiveProject(String projectsRoot, ProjectNode node) async {
  final sep = Platform.pathSeparator;
  final archiveRoot =
      '$projectsRoot$sep'
      '_archive';
  final folders = subtreeFolders(node);

  for (final folder in folders) {
    final dest = '$archiveRoot$sep${slugOf(folder)}';
    if (Directory(dest).existsSync()) {
      throw StateError('$dest already exists — refusing to archive over it.');
    }
  }

  await Directory(archiveRoot).create(recursive: true);
  for (final folder in folders) {
    await Directory(folder).rename('$archiveRoot$sep${slugOf(folder)}');
  }
}

/// The reverse of [archiveProject] — moves [archivedNode] (built from a
/// scan of `projectsRoot\_archive\` itself, the same `buildProjectForest`
/// the real `projects\` scan uses) and its own subtree back into
/// `projectsRoot`, old status and all. Same collision refusal as
/// [archiveProject].
Future<void> restoreProject(
  String projectsRoot,
  ProjectNode archivedNode,
) async {
  final sep = Platform.pathSeparator;
  final folders = subtreeFolders(archivedNode);

  for (final folder in folders) {
    final dest = '$projectsRoot$sep${slugOf(folder)}';
    if (Directory(dest).existsSync()) {
      throw StateError('$dest already exists — refusing to restore over it.');
    }
  }

  for (final folder in folders) {
    await Directory(folder).rename('$projectsRoot$sep${slugOf(folder)}');
  }
}

/// Sends [node] and its whole subtree to the Windows Recycle Bin (ADR
/// 0051 point 2/3) — one [sendToRecycleBin] call per folder, since a
/// sub-project is its own top-level folder, never nested inside this
/// one's. Stops at the first folder that fails rather than leaving the
/// subtree half gone with no record of where it stopped.
Future<void> deleteProject(ProjectNode node) async {
  for (final folder in subtreeFolders(node)) {
    await sendToRecycleBin(folder);
  }
}

/// When [folder] itself — not any file inside it — was last touched.
/// Archive and restore are both a plain rename, which changes the
/// folder's own modified time even though nothing inside is read or
/// rewritten — the closest honest answer to "when was this archived"
/// without inventing a stored field ADR 0051 never asked for (point 6:
/// no "Archived" status word). Null on any read error, same as a stat
/// call failing anywhere else in this app.
DateTime? folderTouchedAt(String folder) {
  try {
    return Directory(folder).statSync().modified;
  } on Object {
    return null;
  }
}

/// The real file/folder count a delete confirmation names — every file
/// anywhere under [folder], recursively; a `SkippedFolder`-style read
/// error is not this function's job, since by the time a project is on
/// screen it was already read once successfully.
Future<int> countFiles(String folder) async {
  var count = 0;
  await for (final entity in Directory(
    folder,
  ).list(recursive: true, followLinks: false)) {
    if (entity is File) count++;
  }
  return count;
}
