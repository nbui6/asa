/// Product Hub — front page, Projects view.
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
///
/// **2026-09-13 — each row is now a drop target.** Round 8's inbox
/// (`HANDOVER.md`, "quick capture") drags an unfiled task from
/// `InboxPanel` onto whichever row it belongs to; the row highlights while
/// something is hovering over it. The write itself (`moveTask`) lives in
/// `ProjectsScreen` — this view only reports which task landed on which
/// node.
///
/// **2026-09-13, later — the segmented bar, per project, when there is
/// one.** `PLAN.md`'s "Open A" (2026-09-13) settled what a segment is: a
/// **phase** — a `###` heading inside `## Roadmap` — never a Round, never
/// a milestone. `PhaseBar` draws it, fed by `groupPhases(project.roadmap)`
/// right here; a project with no phase groupings shows no bar at all,
/// same absence rule as everything else on this row.
///
/// **2026-09-13, later still — "N parked".** `HANDOVER.md`'s "parked
/// items, and the rule of two". A small badge next to the status/priority
/// pills, shown only when a project has at least one parked task; more
/// than one gets a stronger, filled treatment rather than a bigger
/// number, so a pile-up reads as something to notice.
///
/// **2026-09-13, one more — an overdue signal.** `HANDOVER.md`, "an
/// overdue signal for `deadline`". The deadline text itself switches to a
/// warning colour once `isPastDeadline` says the month has passed — no
/// new pill, no new icon, no new line.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/phase_bar.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    required this.forest,
    required this.onOpenProject,
    required this.onAssignTask,
    super.key,
  });

  final List<ProjectNode> forest;

  /// Opens the project's own detail screen — same destination the old
  /// flat list's row tap already used.
  final void Function(String folder) onOpenProject;

  /// A row accepted an inbox task dropped on it — the write half of "drag
  /// it onto a project" lives one level up, in `ProjectsScreen`. This view
  /// only reports which task landed on which node.
  final Future<void> Function(Task task, ProjectNode node) onAssignTask;

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
    final phases = groupPhases(project.roadmap);
    final parkedCount = countParked(project.tasks);
    final overdue = isPastDeadline(
      project.deadline,
      project.status,
      DateTime.now(),
    );

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 8),
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) =>
            widget.onAssignTask(details.data, node),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          return Card(
            margin: EdgeInsets.zero,
            color: hovering ? Colors.indigo.shade50 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: hovering
                  ? BorderSide(color: Colors.indigo.shade300, width: 2)
                  : BorderSide.none,
            ),
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
                        _deadlineText(deadline, overdue),
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
                        if (parkedCount > 0) ...[
                          const SizedBox(width: 6),
                          _parkedBadge(parkedCount),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stripCodeSpanMarkers(
                              stripEmphasisMarkers(project.nextStep),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                    if (phases.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      PhaseBar(phases: phases),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
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

  /// "N parked" — `PLAN.md` v0.3. One parked task is a plain, quiet badge;
  /// more than one is the "rule of two" — a stronger, filled treatment so
  /// the pile-up reads as something to notice, not something to miss at a
  /// glance. Deciding that two parked items are really the same subject,
  /// and acting on it, stays Nico's own judgement — this only makes the
  /// count impossible to overlook.
  Widget _parkedBadge(int count) {
    final message = count == 1 ? '1 task parked' : '$count tasks parked';
    final ruleOfTwo = count > 1;

    return Tooltip(
      message: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: ruleOfTwo ? Colors.amber.shade700 : Colors.amber.shade50,
          border: ruleOfTwo ? null : Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark,
              size: 11,
              color: ruleOfTwo ? Colors.white : Colors.amber.shade800,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: ruleOfTwo ? FontWeight.bold : FontWeight.normal,
                color: ruleOfTwo ? Colors.white : Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The deadline, in a warning colour once it is overdue — `HANDOVER.md`,
  /// "an overdue signal for `deadline`". No new pill, no new icon; just
  /// this text's own colour changes. [ColorScheme.error] rather than a
  /// literal red, so it reads correctly in both a light and dark Windows
  /// theme, same requirement the phase bar and the parked badge already
  /// met.
  Widget _deadlineText(String? deadline, bool overdue) {
    final text = Text(
      deadline ?? '—',
      style: TextStyle(
        color: overdue
            ? Theme.of(context).colorScheme.error
            : Colors.grey.shade600,
        fontWeight: overdue ? FontWeight.bold : null,
      ),
    );
    return overdue ? Tooltip(message: 'Past its deadline', child: text) : text;
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
