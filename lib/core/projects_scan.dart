/// Scans a folder of project folders and reads the state of each one.
///
/// Round 2. Note what this did **not** need: no change to `project.dart`,
/// `project_reader.dart` or `git_state.dart`. It only adds. That is the layer
/// boundary from ARCHITECTURE.md doing its job.
library;

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/freshness.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_reader.dart';

/// One row in the projects list.
class ProjectSummary {
  const ProjectSummary({
    required this.project,
    required this.git,
    required this.folder,
    this.lastTouched,
    this.areas = const [],
  });

  final Project project;
  final GitState git;

  /// The folder this project was read from.
  final String folder;

  /// Round 36 §2 f — every `plan\<area>.md` page, read once at scan time
  /// so the overview's own bar segments and next-step text can read areas
  /// too, the same chain `ProjectScreen` already uses. Empty for a project
  /// with no `plan\` folder, same as everywhere else areas are read.
  final List<Area> areas;

  /// Round 32/A — git's last commit when readable, otherwise the newest
  /// file modification time inside [folder]. See `freshness.dart`'s
  /// `lastTouchedOf`, computed once here at scan time rather than per
  /// row, since it is the same real disk read either way.
  final DateTime? lastTouched;

  /// Whole days since the last commit, or null when git could not say.
  int? daysStale(DateTime now) => git.daysSinceLastCommit(now);
}

/// A folder that looked like a project but could not be read, and why.
///
/// Kept and shown rather than skipped silently. A folder that vanishes from a
/// list is indistinguishable from a folder that does not exist.
class SkippedFolder {
  const SkippedFolder(this.folder, this.reason);

  final String folder;
  final String reason;
}

class ScanResult {
  const ScanResult({
    this.projects = const [],
    this.skipped = const [],
    this.error,
  });

  final List<ProjectSummary> projects;
  final List<SkippedFolder> skipped;
  final String? error;
}

/// Reads every immediate subfolder of [projectsRoot] as a project.
///
/// Hidden folders and anything named `_to_delete` are ignored without comment —
/// they are not projects and never were.
Future<ScanResult> scanProjects(String projectsRoot) async {
  final root = Directory(projectsRoot);

  if (!root.existsSync()) {
    return ScanResult(error: 'No folder at: $projectsRoot');
  }

  final found = <ProjectSummary>[];
  final skipped = <SkippedFolder>[];

  await for (final entry in root.list(followLinks: false)) {
    if (entry is! Directory) continue;

    final name = entry.path.split(Platform.pathSeparator).last;
    if (name.startsWith('.') || name.startsWith('_')) continue;

    final read = await readProject(entry.path);

    if (!read.isSuccess) {
      skipped.add(SkippedFolder(name, read.error ?? 'unknown problem'));
      continue;
    }

    final git = await readGitState(read.project!.repoPath);
    final touched = await lastTouchedOf(entry.path, git);
    final areas = await readAreas(entry.path);
    found.add(
      ProjectSummary(
        project: read.project!,
        git: git,
        folder: entry.path,
        lastTouched: touched,
        areas: areas,
      ),
    );
  }

  return ScanResult(projects: found, skipped: skipped);
}

/// Most stale first. Projects whose git state is unknown go last.
///
/// Unknown is deliberately not treated as "fresh" or as "very stale" — it is a
/// different thing, and sorting it into the middle of real numbers would make
/// the list lie. It goes at the end, visibly labelled.
List<ProjectSummary> sortByStaleness(
  List<ProjectSummary> projects,
  DateTime now,
) {
  final known = <ProjectSummary>[];
  final unknown = <ProjectSummary>[];

  for (final summary in projects) {
    if (summary.daysStale(now) == null) {
      unknown.add(summary);
    } else {
      known.add(summary);
    }
  }

  known.sort((a, b) => b.daysStale(now)!.compareTo(a.daysStale(now)!));
  unknown.sort((a, b) => a.project.name.compareTo(b.project.name));

  return [...known, ...unknown];
}

/// "today", "1 day ago", "12 days ago", or "unknown".
String stalenessLabel(ProjectSummary summary, DateTime now) {
  final days = summary.daysStale(now);
  if (days == null) return 'unknown';
  if (days == 0) return 'today';
  if (days == 1) return '1 day ago';
  return '$days days ago';
}
