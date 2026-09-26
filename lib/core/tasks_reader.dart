/// Builds the Tasks view's groups from a project scan.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the front-page Tasks view."
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart' show slugOf;
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';

/// Round 34/E — one area's own tasks, grouped by the area's name, inside
/// its project's own [TaskGroup]. Only areas with at least one task get a
/// group — the same "nothing to show, no row" rule [TaskGroup] itself
/// already follows.
class AreaTaskGroup {
  const AreaTaskGroup({
    required this.name,
    required this.sourceFile,
    required this.tasks,
  });

  final String name;
  final String sourceFile;
  final List<Task> tasks;
}

/// One project's tasks, plus the children whose own `parent:` names it —
/// but only children that have tasks of their own to show.
class TaskGroup {
  const TaskGroup({
    required this.project,
    required this.tasks,
    this.children = const [],
    this.areaGroups = const [],
  });

  final Project project;
  final List<Task> tasks;
  final List<TaskGroup> children;

  /// Round 34/E — after the project's own home-note tasks, one group per
  /// area that has any, in area order.
  final List<AreaTaskGroup> areaGroups;
}

/// One group per project with a non-empty `## Tasks` section, nested under
/// its parent **only when the parent also has one**. A parent with no
/// `## Tasks` of its own — `other`, a folder rather than a project, see
/// `other.md` — contributes no row at all, at any depth; a project under
/// it becomes a root instead of vanishing. Confirmed real chain: `other`
/// (no tasks, never shows) → `asa` (has tasks, top level) →
/// `vibe-coding-kit` (`parent: asa`, no `## Tasks` yet — nothing to nest).
///
/// This is the one parent-chain read the Projects view's own grouping
/// reuses rather than re-implementing — see the spec note above.
Future<List<TaskGroup>> buildTaskGroups(
  List<ProjectSummary> projects,
  FileAccess files,
) async {
  final tasksBySlug = <String, List<Task>>{};
  final areaGroupsBySlug = <String, List<AreaTaskGroup>>{};
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

    final areas = await readAreasVia(summary.folder, files);
    areaGroupsBySlug[slug] = [
      for (final area in areas)
        if (area.tasks.isNotEmpty)
          AreaTaskGroup(
            name: area.name,
            sourceFile: area.sourceFile,
            tasks: area.tasks,
          ),
    ];
  }

  bool hasTasks(String? slug) =>
      slug != null &&
      ((tasksBySlug[slug]?.isNotEmpty ?? false) ||
          (areaGroupsBySlug[slug]?.isNotEmpty ?? false));

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
    areaGroups: areaGroupsBySlug[slug] ?? const [],
    children: (childSlugsOf[slug] ?? const <String>[]).map(build).toList(),
  );

  return rootSlugs.map(build).toList();
}
