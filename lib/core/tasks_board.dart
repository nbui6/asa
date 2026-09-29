/// Round 42 — the data the new Tasks screen needs: a left rail (Next up,
/// Inbox, every visible project with its own open count) and, for
/// whichever project is open, its own tasks — home first, then each area,
/// same order the Plan tab already uses. One pass per project, real disk.
///
/// Deliberately not `buildTaskGroups`/`TaskGroup` (`tasks_reader.dart`,
/// the old flat "every project, all at once" Tasks view this round
/// replaces): that reader only ever includes a project that already has a
/// task somewhere, and nests parent/child projects — neither fits here.
/// The left rail names every *visible* project (ADR 0036) so a project
/// with zero tasks today can still get its first one; the right pane
/// shows one project at a time, never a nested tree.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/project.dart';
import 'package:asa/core/project_row.dart' show effectiveNextStepWithArea;
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';

/// One project's own tasks, home note and every area, read once. [areas]
/// includes an area with zero tasks of its own — "+ Add a task" still
/// needs somewhere to add the first one.
class ProjectTasksSnapshot {
  const ProjectTasksSnapshot({
    required this.project,
    required this.folder,
    required this.homeTasks,
    required this.areas,
  });

  final Project project;
  final String folder;
  final List<Task> homeTasks;
  final List<Area> areas;

  int get openCount =>
      homeTasks.where((t) => !t.done).length +
      areas.fold<int>(
        0,
        (sum, area) => sum + area.tasks.where((t) => !t.done).length,
      );
}

/// One snapshot per project in [visibleProjects] — already filtered to
/// ADR 0036's own visible set by the caller (`ProjectsScreen._load()`
/// already builds this list for the overview and the old Tasks view;
/// this reuses it rather than filtering a second time).
Future<List<ProjectTasksSnapshot>> buildProjectTasksSnapshots(
  List<ProjectSummary> visibleProjects,
  FileAccess files,
) async {
  final result = <ProjectTasksSnapshot>[];
  for (final summary in visibleProjects) {
    final contents = await files.readFile(summary.project.sourceFile);
    final homeTasks = parseTasks(contents);
    final areas = await readAreasVia(summary.folder, files);
    result.add(
      ProjectTasksSnapshot(
        project: summary.project,
        folder: summary.folder,
        homeTasks: homeTasks,
        areas: areas,
      ),
    );
  }
  return result;
}

/// Round 42 §A — "one line per project in the left list, its first open
/// task." Same chain [effectiveNextStepWithArea] already uses everywhere
/// else this app shows a project's own next step (home task first, then
/// the first area with one, in area order) — one source, not a second
/// "what's next" rule invented for this one screen. A project with no
/// real open task anywhere (every task done, or none at all) contributes
/// no row — there is nothing to tick.
class NextUpItem {
  const NextUpItem({
    required this.projectName,
    required this.projectFolder,
    required this.text,
    required this.task,
    this.area,
  });

  final String projectName;
  final String projectFolder;
  final String text;
  final Task task;
  final Area? area;
}

List<NextUpItem> buildNextUp(List<ProjectTasksSnapshot> snapshots) {
  final items = <NextUpItem>[];
  for (final snapshot in snapshots) {
    final result = effectiveNextStepWithArea(
      snapshot.homeTasks,
      snapshot.project.nextStep,
      areas: snapshot.areas,
    );
    if (result.task == null) continue;
    items.add(
      NextUpItem(
        projectName: snapshot.project.name,
        projectFolder: snapshot.folder,
        text: result.text!,
        task: result.task!,
        area: result.area,
      ),
    );
  }
  return items;
}
