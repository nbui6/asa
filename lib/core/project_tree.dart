/// The parent-chain forest every grouped view derives its own grouping
/// from — the Tasks view's nesting, and now the Projects view's work/other
/// split.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entries for both rounds.
library;

import 'package:asa/core/project.dart';
import 'package:asa/core/projects_scan.dart';

/// The folder name a project is known by — what a `[[double bracket]]`
/// reference and a `parent:` field both point at. One shared definition;
/// every parent-chain read in this app resolves identity through this,
/// not a copy of its own.
String slugOf(String folder) => folder.split(RegExp(r'[\\/]')).last;

/// One project, plus the children whose `parent:` field names it —
/// possibly several levels deep. See [buildProjectForest].
class ProjectNode {
  const ProjectNode({
    required this.project,
    required this.folder,
    this.children = const [],
  });

  final Project project;
  final String folder;
  final List<ProjectNode> children;
}

/// The full parent-chain forest of every scanned project. A project
/// becomes a root when it has no `parent:` field, or when that field
/// names a project not present in this scan; everything else nests under
/// the project its `parent:` field names — real chain checked against
/// disk: `other` (no parent, a root) → `asa` (`parent: other`) →
/// `vibe-coding-kit` (`parent: asa`).
List<ProjectNode> buildProjectForest(List<ProjectSummary> projects) {
  final bySlug = <String, ProjectSummary>{
    for (final summary in projects) slugOf(summary.folder): summary,
  };

  final childSlugsOf = <String, List<String>>{};
  final rootSlugs = <String>[];

  for (final summary in projects) {
    final slug = slugOf(summary.folder);
    final parent = summary.project.parent;
    if (parent != null && bySlug.containsKey(parent)) {
      childSlugsOf.putIfAbsent(parent, () => []).add(slug);
    } else {
      rootSlugs.add(slug);
    }
  }

  ProjectNode build(String slug) {
    final summary = bySlug[slug]!;
    return ProjectNode(
      project: summary.project,
      folder: summary.folder,
      children: (childSlugsOf[slug] ?? const <String>[]).map(build).toList(),
    );
  }

  return rootSlugs.map(build).toList();
}
