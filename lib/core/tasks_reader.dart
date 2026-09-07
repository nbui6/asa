/// Builds the Tasks view's groups from a project scan.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the front-page Tasks view."
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/project.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';

/// One project's tasks, plus the children whose own `parent:` names it —
/// but only children that have tasks of their own to show.
class TaskGroup {
  const TaskGroup({
    required this.project,
    required this.tasks,
    this.children = const [],
  });

  final Project project;
  final List<Task> tasks;
  final List<TaskGroup> children;
}

/// One group per project with a non-empty `## Tasks` section, nested under
/// its parent **only when the parent also has one**. A parent with no
/// `## Tasks` of its own — `other`, a folder rather than a project, see
/// `other.md` — contributes no row at all, at any depth; a project under
/// it becomes a root instead of vanishing. Confirmed real chain: `other`
/// (no tasks, never shows) → `asa` (has tasks, top level) →
/// `vibe-coding-kit` (`parent: asa`, no `## Tasks` yet — nothing to nest).
///
/// This is the one parent-chain read a later Bars-view grouping should
/// reuse rather than re-implement — see the spec note above.
Future<List<TaskGroup>> buildTaskGroups(
  List<ProjectSummary> projects,
  FileAccess files,
) async {
  final tasksBySlug = <String, List<Task>>{};
  final projectBySlug = <String, Project>{};
  final parentBySlug = <String, String?>{};
  final orderedSlugs = <String>[];

  for (final summary in projects) {
    final slug = slugOf(summary.folder);
    final contents = await files.readFile(summary.project.sourceFile);
    orderedSlugs.add(slug);
    projectBySlug[slug] = summary.project;
    parentBySlug[slug] = summary.project.parent;
    tasksBySlug[slug] = parseTasks(contents);
  }

  bool hasTasks(String? slug) =>
      slug != null && (tasksBySlug[slug]?.isNotEmpty ?? false);

  final childSlugsOf = <String, List<String>>{};
  final rootSlugs = <String>[];

  for (final slug in orderedSlugs) {
    if (!hasTasks(slug)) continue;
    final parent = parentBySlug[slug];
    if (hasTasks(parent)) {
      childSlugsOf.putIfAbsent(parent!, () => []).add(slug);
    } else {
      rootSlugs.add(slug);
    }
  }

  TaskGroup build(String slug) => TaskGroup(
    project: projectBySlug[slug]!,
    tasks: tasksBySlug[slug]!,
    children: (childSlugsOf[slug] ?? const <String>[]).map(build).toList(),
  );

  return rootSlugs.map(build).toList();
}

/// The folder name a project is known by — what `[[double bracket]]`
/// references and a `parent:` field both point at. Works with either path
/// separator so a test fixture path (`/`) and a real Windows scan
/// (`\`) resolve the same way.
String slugOf(String folder) => folder.split(RegExp(r'[\\/]')).last;
