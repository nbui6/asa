/// Product Hub — front page, Projects view. Row layout only, per the
/// 2026-09-07 scope split: no segmented milestone-history bar yet, since
/// no project file has ever recorded more than its current `milestone:`
/// value — there is nothing real to segment.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the real Bars view, row layout
/// only" (that entry predates the 2026-09-09 rename — "Bars" is retired,
/// rule 12; the front-page toggle's second option is now "Projects
/// view"). Sketch: `asa-tasks-view.png`'s companion, `asa-front2.png` —
/// structure only; its exact example values (deadlines, staleness,
/// project counts) are that sketch's own old illustrative content, not
/// real data, per `APPROVED.md`'s note on it.
///
/// **Deliberate simplification:** `asa-front2.png`'s own caption reads
/// "solid pill = measured, dashed pill = you set it." Every value this
/// round shows comes straight from typed frontmatter — nothing is
/// measured yet — so every pill would be dashed with no exception, and
/// Flutter has no built-in dashed border. Rather than add a package for a
/// visual distinction that has no second case to contrast against yet,
/// every pill here is a plain outlined pill. The solid/dashed contrast is
/// meaningful once the milestone-history round gives this screen its
/// first genuinely *measured* value — build that distinction then.
library;

import 'package:asa/core/open_url.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    required this.forest,
    required this.onOpenProject,
    super.key,
  });

  final List<ProjectNode> forest;

  /// Opens the project's own detail screen — same destination the old
  /// flat list's row tap already used.
  final void Function(String folder) onOpenProject;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  bool _otherExpanded = false;

  @override
  Widget build(BuildContext context) {
    final split = splitByBucket(widget.forest);

    if (split.work.isEmpty && split.other == null) {
      return const _Panel(child: Text('No projects here yet.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final node in split.work) _row(node, depth: 0),
        if (split.other != null) _otherGroup(split.other!),
      ],
    );
  }

  Widget _otherGroup(ProjectNode other) {
    final count = countDescendants(other);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _otherExpanded = !_otherExpanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _otherExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    other.project.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count · not work',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          if (_otherExpanded)
            for (final child in other.children) _row(child, depth: 1),
        ],
      ),
    );
  }

  Widget _row(ProjectNode node, {required int depth}) {
    final project = node.project;
    final jira = jiraLabel(project.jira);
    final deadline = humanizeDeadline(project.deadline);
    final emphasis = statusEmphasis(project.status);

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => widget.onOpenProject(node.folder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (jira != null) ...[
                      const SizedBox(width: 8),
                      _jiraChip(jira, project.jira!),
                    ],
                    const Spacer(),
                    Text(
                      deadline ?? '—',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(project.status, emphasis),
                    if (project.priority != null) ...[
                      const SizedBox(width: 6),
                      _pill(project.priority!, StatusEmphasis.neutral),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.nextStep,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jiraChip(String label, String url) {
    return InkWell(
      onTap: () => openUrl(url),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.blue.shade800,
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, StatusEmphasis emphasis) {
    final color = emphasis == StatusEmphasis.active
        ? Colors.blue.shade700
        : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
