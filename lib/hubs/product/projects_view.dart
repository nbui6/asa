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

import 'package:asa/core/area.dart';
import 'package:asa/core/freshness.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/phase_bar.dart';
import 'package:asa/hubs/product/start_menu.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    required this.forest,
    required this.onOpenProject,
    required this.onAssignTask,
    super.key,
  });

  final List<ProjectNode> forest;

  /// Opens the project's own detail screen — round-36 §3, L1/L2/L3/L4: a
  /// plain row tap builds a bare [ProjectOpenTarget] (lands wherever the
  /// project screen opens by default); an area's bar segment or the row's
  /// own next-step text name where inside the project to land instead.
  final void Function(ProjectOpenTarget target) onOpenProject;

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

    final workCount = split.work.fold(
      0,
      (sum, root) => sum + _subtreeSize(root),
    );
    final otherCount = split.other == null ? 0 : _subtreeSize(split.other!);

    // Round 35/G — `asa-front2`'s biggest drift: no summary line, and rows
    // stretched full width instead of a readable column. Centred at a
    // fixed max width, same fix a long line of prose would get, applied to
    // a long line of pills and a Start button instead.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${workCount + otherCount} projects · $workCount work · '
                '$otherCount not work',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            for (final node in split.work) _row(node, depth: 0),
            if (split.other != null) _otherGroup(split.other!),
          ],
        ),
      ),
    );
  }

  /// 1 plus every descendant — the whole subtree [node] heads, for the
  /// summary line's work/not-work counts.
  int _subtreeSize(ProjectNode node) => 1 + countDescendants(node);

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
    // Round 33/E — a child or grandchild wasn't drawn at all before this:
    // `_row` only ever rendered its own node, and the one caller that
    // walked `node.children` (`_otherGroup`) only went one level deep.
    // Recursing here, once, makes every depth show up everywhere a forest
    // is walked — the work bucket's own children included, which never
    // had a caller for them before.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(node, depth: depth),
        for (final child in node.children) _row(child, depth: depth + 1),
      ],
    );
  }

  Widget _card(ProjectNode node, {required int depth}) {
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
    final freshness = freshnessText(
      humanizedDeadline: deadline,
      lastTouched: node.lastTouched,
      now: DateTime.now(),
    );
    final nextStepResult = effectiveNextStepWithArea(
      project.tasks,
      project.nextStep,
      areas: node.areas,
    );
    final nextStep = nextStepResult.text;

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
              onTap: () => widget.onOpenProject(openTarget(node.folder)),
              child: Padding(
                // Round 35/G — `asa-front2` draws a compact row, not a tall
                // card with a lot of empty space around its own content.
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                        _freshnessLabel(freshness, overdue),
                        const SizedBox(width: 4),
                        StartMenu(
                          projectName: project.name,
                          projectFolder: node.folder,
                          repoPath: project.repoPath,
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
                        if (parkedCount > 0) ...[
                          const SizedBox(width: 6),
                          _parkedBadge(parkedCount),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            // L3 — only tappable when a real task backs the
                            // text; the typed field or honest absence has
                            // nowhere more specific to land than the row's
                            // own tap already goes.
                            onTap: nextStepResult.task == null
                                ? null
                                : () => widget.onOpenProject(
                                    openTarget(
                                      node.folder,
                                      areaSourceFile:
                                          nextStepResult.area?.sourceFile,
                                      openHome: nextStepResult.area == null,
                                      highlightRawLine:
                                          nextStepResult.task!.rawLine,
                                    ),
                                  ),
                            child: Text(
                              nextStep ?? 'no next step',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontStyle: nextStep == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (node.areas.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _AreaBar(
                        areas: node.areas,
                        // L2 — a segment or its label opens that one area.
                        onTapArea: (area) => widget.onOpenProject(
                          openTarget(
                            node.folder,
                            areaSourceFile: area.sourceFile,
                          ),
                        ),
                      ),
                    ] else if (phases.isNotEmpty) ...[
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

  /// Round 32/A — the deadline when there is one, in a warning colour
  /// once it is overdue (`HANDOVER.md`, 2026-09-13, "an overdue signal for
  /// `deadline`"), otherwise the age since the project was last actually
  /// touched. Same widget either way; only the source of the text and
  /// whether the overdue styling can ever apply changes upstream, in
  /// `freshnessText`/`isPastDeadline`. `ColorScheme.error` rather than a
  /// literal red, so it reads correctly in both a light and dark Windows
  /// theme, same requirement the phase bar and the parked badge already
  /// met.
  Widget _freshnessLabel(String? freshness, bool overdue) {
    final text = Text(
      freshness ?? '—',
      style: TextStyle(
        color: overdue
            ? Theme.of(context).colorScheme.error
            : Colors.grey.shade600,
        fontWeight: overdue ? FontWeight.bold : null,
      ),
    );
    return overdue ? Tooltip(message: 'Past its deadline', child: text) : text;
  }

  /// Round 32/C — a status can be any of ADR 0017's seven words, but one
  /// real note had a whole paragraph as its value until this round. A
  /// pill with no width limit would widen or wrap the row for that; this
  /// one clips to a single line with an ellipsis instead, however long
  /// the real value is — shown as written, never rewritten or hidden.
  Widget _pill(String text, StatusEmphasis emphasis) {
    final color = emphasis == StatusEmphasis.active
        ? Colors.blue.shade700
        : Colors.grey.shade700;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
    );
  }
}

/// Round 36 §2 f, `asa-areas-everywhere-v1` §1 — one bar segment per
/// area, in place of [PhaseBar]'s per-phase segments once a project has
/// any `plan\*.md` page. Same shape as [PhaseBar] (a labelled, filled
/// segment per entry) but keyed to [Area.doneCount]/[Area.totalCount]
/// rather than a roadmap [Phase] — duplicated rather than shared, since
/// the two segment kinds mean different things (ADR 0024) and
/// [PhaseBar] stays the unchanged fallback for a project with no areas.
class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.areas, required this.onTapArea});

  final List<Area> areas;

  /// Round-36 §3, L2 — a segment or its own label opens that one area.
  final void Function(Area area) onTapArea;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: InkWell(
                  onTap: () => onTapArea(areas[i]),
                  child: _segment(areas[i], colors),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: InkWell(
                  onTap: () => onTapArea(areas[i]),
                  child: Text(
                    // "Marketing 3/7" — asa-areas-everywhere-v1 §1's own
                    // label, name and fraction together under one segment.
                    '${areas[i].name} ${areas[i].doneCount}/${areas[i].totalCount}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, color: colors.outline),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _segment(Area area, ColorScheme colors) {
    final total = area.totalCount;
    final fraction = total == 0 ? 0.0 : area.doneCount / total;

    return Tooltip(
      message: '${area.name}: ${area.doneCount} of $total tasks done',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(color: colors.surfaceContainerHighest),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
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
