/// Product Hub — front page, Projects view.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the real Bars view, row layout
/// only" (that entry predates the 2026-09-09 rename — "Bars" is retired,
/// rule 12; the front-page toggle's second option is now "Projects
/// view"). Sketch: `asa-tasks-view.png`'s companion, `asa-front2.png` —
/// structure only; its exact example values (deadlines, staleness,
/// project counts) are that sketch's own old illustrative content, not
/// real data, per `APPROVED.md`'s note on it. Round 37 (`asa-one-look-v1`,
/// ADR 0029) moves this screen onto the shared `ui/` parts — one panel
/// with hairlines (already round 36 cp8's own fix), `Pill` by meaning
/// instead of an outlined status pill, `ProgressBar` instead of this
/// file's own bar-segment painting. The layout itself is unchanged.
///
/// **Deliberate simplification:** `asa-front2.png`'s own caption reads
/// "solid pill = measured, dashed pill = you set it." Every value this
/// round shows comes straight from typed frontmatter — nothing is
/// measured yet — so every pill would be dashed with no exception, and
/// Flutter has no built-in dashed border. Rather than add a package for a
/// visual distinction that has no second case to contrast against yet,
/// every pill here is a plain filled pill, by meaning. The solid/dashed
/// contrast is meaningful once the milestone-history round gives this
/// screen its first genuinely *measured* value — build that distinction
/// then.
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
/// a milestone. A project with no phase groupings shows no bar at all,
/// same absence rule as everything else on this row.
///
/// **2026-09-13, later still — "N parked".** `HANDOVER.md`'s "parked
/// items, and the rule of two". A small badge next to the status/priority
/// pills, shown only when a project has at least one parked task; more
/// than one gets a stronger, filled treatment rather than a bigger
/// number, so a pile-up reads as something to notice.
///
/// **2026-09-13, one more — an overdue signal.** `HANDOVER.md`, "an
/// overdue signal for `deadline`". The deadline text itself switches to
/// the "needs you" meaning once `isPastDeadline` says the month has
/// passed — no new pill, no new icon, no new line.
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
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
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
      return const EmptyLine('No projects here yet.');
    }

    final workCount = split.work.fold(
      0,
      (sum, root) => sum + _subtreeSize(root),
    );
    final otherCount = split.other == null ? 0 : _subtreeSize(split.other!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AsaSpace.md),
          child: Text(
            '${workCount + otherCount} projects · $workCount work · '
            '$otherCount not work',
            style: AsaText.meta,
          ),
        ),
        if (split.work.isNotEmpty)
          _rowPanel([for (final node in split.work) _row(node, depth: 0)]),
        if (split.other != null) ...[
          const SizedBox(height: AsaSpace.lg),
          _otherGroup(split.other!),
        ],
      ],
    );
  }

  /// 1 plus every descendant — the whole subtree [node] heads, for the
  /// summary line's work/not-work counts.
  int _subtreeSize(ProjectNode node) => 1 + countDescendants(node);

  Widget _otherGroup(ProjectNode other) {
    final count = countDescendants(other);
    return _rowPanel([
      InkWell(
        onTap: () => setState(() => _otherExpanded = !_otherExpanded),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AsaSpace.md,
            vertical: AsaSpace.sm,
          ),
          decoration: _otherExpanded ? _rowHairline : null,
          child: Row(
            children: [
              Icon(
                _otherExpanded ? Icons.expand_more : Icons.chevron_right,
                color: AsaColors.ink2,
              ),
              const SizedBox(width: AsaSpace.xs),
              Text(other.project.name, style: AsaText.rowName),
              const SizedBox(width: AsaSpace.sm),
              Text('$count · not work', style: AsaText.meta),
            ],
          ),
        ),
      ),
      if (_otherExpanded)
        for (final child in other.children) _row(child, depth: 1),
    ]);
  }

  /// `asa-front2` — one bordered panel, hairlines between rows, not a
  /// separate shadowed card each. [children] is flattened (each `_row`
  /// may itself hand back more than one row, recursively, for a child or
  /// grandchild project) so every hairline lands between real rows, not
  /// around a nested `Column` that drew several.
  Widget _rowPanel(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AsaColors.panel,
        border: Border.all(color: AsaColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static const _rowHairline = BoxDecoration(
    border: Border(bottom: BorderSide(color: AsaColors.soft)),
  );

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
    final meaning = meaningForStatus(project.status);
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
      padding: EdgeInsets.only(left: depth * AsaSpace.xl),
      child: DragTarget<Task>(
        onAcceptWithDetails: (details) =>
            widget.onAssignTask(details.data, node),
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: hovering ? AsaMeaning.moving.bg : null,
              border: Border(
                bottom: const BorderSide(color: AsaColors.soft),
                left: hovering
                    ? const BorderSide(color: AsaColors.blue, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: InkWell(
              onTap: () => widget.onOpenProject(openTarget(node.folder)),
              child: Padding(
                // Round 35/G — `asa-front2` draws a compact row, not a tall
                // card with a lot of empty space around its own content.
                padding: const EdgeInsets.symmetric(
                  horizontal: AsaSpace.md,
                  vertical: AsaSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: AsaText.rowName),
                        if (jira != null) ...[
                          const SizedBox(width: AsaSpace.sm),
                          LinkChip(
                            '$jira ↗',
                            onTap: () => openUrl(project.jira!),
                          ),
                        ],
                        const Spacer(),
                        _freshnessLabel(freshness, overdue),
                        const SizedBox(width: AsaSpace.xs),
                        StartMenu(
                          projectName: project.name,
                          projectFolder: node.folder,
                          repoPath: project.repoPath,
                        ),
                      ],
                    ),
                    // `asa-front2` draws the pills directly under the name,
                    // not with a visible gap between them.
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Pill(project.status, meaning: meaning),
                        if (project.priority != null) ...[
                          const SizedBox(width: AsaSpace.xs),
                          Pill(project.priority!, meaning: AsaMeaning.quiet),
                        ],
                        if (parkedCount > 0) ...[
                          const SizedBox(width: AsaSpace.xs),
                          _parkedBadge(parkedCount),
                        ],
                        const SizedBox(width: AsaSpace.sm),
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
                                fontSize: 14,
                                color: AsaColors.ink2,
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
                      const SizedBox(height: AsaSpace.sm),
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
                      const SizedBox(height: AsaSpace.sm),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.xs,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: ruleOfTwo ? AsaColors.amber : AsaColors.amberBg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark,
              size: 11,
              color: ruleOfTwo ? AsaColors.panel : AsaColors.amber,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: ruleOfTwo ? FontWeight.bold : FontWeight.normal,
                color: ruleOfTwo ? AsaColors.panel : AsaColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Round 32/A — the deadline when there is one, in the "needs you"
  /// meaning once it is overdue (`HANDOVER.md`, 2026-09-13, "an overdue
  /// signal for `deadline`"), otherwise the age since the project was
  /// last actually touched.
  Widget _freshnessLabel(String? freshness, bool overdue) {
    final text = Text(
      freshness ?? '—',
      style: TextStyle(
        fontSize: 12,
        color: overdue ? AsaMeaning.needsYou.fg : AsaColors.ink3,
        fontWeight: overdue ? FontWeight.bold : null,
      ),
    );
    return overdue ? Tooltip(message: 'Past its deadline', child: text) : text;
  }
}

/// Round 36 §2 f, `asa-areas-everywhere-v1` §1 — one bar segment per
/// area, in place of [PhaseBar]'s per-phase segments once a project has
/// any `plan\*.md` page. Keyed to [Area.doneCount]/[Area.totalCount]
/// rather than a roadmap [Phase] — the two segment kinds mean different
/// things (ADR 0024) and [PhaseBar] stays the unchanged fallback for a
/// project with no areas. The visual bar itself is [ProgressBar]; the
/// name/fraction labels underneath are this file's own, tappable rows.
class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.areas, required this.onTapArea});

  final List<Area> areas;

  /// Round-36 §3, L2 — a segment or its own label opens that one area.
  final void Function(Area area) onTapArea;

  double _fractionOf(Area area) =>
      area.totalCount == 0 ? 0.0 : area.doneCount / area.totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(
          segments: [for (final area in areas) _fractionOf(area)],
          height: 8,
        ),
        const SizedBox(height: AsaSpace.xs),
        Row(
          children: [
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: InkWell(
                  onTap: () => onTapArea(areas[i]),
                  child: Tooltip(
                    message:
                        '${areas[i].name}: ${areas[i].doneCount} of '
                        '${areas[i].totalCount} tasks done',
                    child: Text(
                      // "Marketing 3/7" — asa-areas-everywhere-v1 §1's own
                      // label, name and fraction together under one
                      // segment.
                      '${areas[i].name} ${areas[i].doneCount}/${areas[i].totalCount}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AsaColors.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
