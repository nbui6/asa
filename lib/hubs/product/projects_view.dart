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
import 'package:asa/core/open_url.dart';
import 'package:asa/core/project_create_writer.dart';
import 'package:asa/core/project_news.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart' show ProjectSummary;
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/status_words.dart' show canonicalStatus, statusLabel;
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/start_menu.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/escape_to_cancel.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/phase_bar.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class ProjectsView extends StatefulWidget {
  const ProjectsView({
    required this.forest,
    required this.onOpenProject,
    required this.onAssignTask,
    required this.onCreateProject,
    this.news = const {},
    this.hidden = const [],
    super.key,
  });

  final List<ProjectNode> forest;

  /// Round 38 §F, ADR 0036 — every project whose status is `on-hold`,
  /// `done` or `canceled`; already excluded from [forest] by the caller,
  /// so this view only has to fold them into the one quiet line below the
  /// list and, once that line is opened, one group per status.
  final List<ProjectSummary> hidden;

  /// Round 38 §E — one project's own news (a blue *N new*, an amber
  /// *changed without a note*), keyed by its folder. Empty for a node
  /// whose project this map has nothing for — no marker at all, the same
  /// honest absence as everywhere else.
  final Map<String, ProjectNews> news;

  /// Opens the project's own detail screen — round-36 §3, L1/L2/L3/L4: a
  /// plain row tap builds a bare [ProjectOpenTarget] (lands wherever the
  /// project screen opens by default); an area's bar segment or the row's
  /// own next-step text name where inside the project to land instead.
  final void Function(ProjectOpenTarget target) onOpenProject;

  /// A row accepted an inbox task dropped on it — the write half of "drag
  /// it onto a project" lives one level up, in `ProjectsScreen`. This view
  /// only reports which task landed on which node.
  final Future<void> Function(Task task, ProjectNode node) onAssignTask;

  /// Round 43 §E — the ＋ row at the bottom of the project list. The write
  /// itself (`createProject`) lives in `ProjectsScreen`, same split as
  /// every other writer this screen owns; this view only shows the field,
  /// its refusal on the line, and — on success — opens the new project via
  /// [onOpenProject].
  final Future<ProjectCreateResult> Function(String name) onCreateProject;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  bool _otherExpanded = false;
  bool _hiddenExpanded = false;

  /// Round 38 §F — the order the ADR's own words, and the sketch, list
  /// the three statuses in: on-hold, then done, then canceled.
  static const _hiddenOrder = ['on-hold', 'done', 'canceled'];

  // --- Round 43 §E — "＋ New project" ------------------------------------

  bool _addingProject = false;
  TextEditingController? _newProjectController;
  String? _newProjectError;
  bool _savingProject = false;

  @override
  void dispose() {
    _newProjectController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final split = splitByBucket(widget.forest);

    if (split.work.isEmpty && split.other == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmptyLine('No projects here yet.'),
          const SizedBox(height: AsaSpace.md),
          _rowPanel([_newProjectRow()]),
        ],
      );
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
        _rowPanel([
          for (final node in split.work) _row(node, depth: 0),
          _newProjectRow(),
        ]),
        if (split.other != null) ...[
          const SizedBox(height: AsaSpace.lg),
          _otherGroup(split.other!),
        ],
        if (widget.hidden.isNotEmpty) ...[
          const SizedBox(height: AsaSpace.lg),
          _hiddenSection(),
          if (_hiddenExpanded) ...[
            const SizedBox(height: AsaSpace.sm),
            _hiddenGroups(),
          ],
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

  /// Round 38 §F, ADR 0036 — the one quiet line below the list: "On hold
  /// N · Done N · Canceled N · show ›". Folded by default, same shape as
  /// [_otherGroup]; opened, it groups every hidden project by its own
  /// status instead of showing one combined row list.
  Widget _hiddenSection() {
    final counts = <String, int>{};
    for (final summary in widget.hidden) {
      final canonical = canonicalStatus(summary.project.status);
      counts[canonical] = (counts[canonical] ?? 0) + 1;
    }
    final parts = [
      for (final word in _hiddenOrder)
        if (counts[word] != null) '${statusLabel(word)} ${counts[word]}',
    ];

    return InkWell(
      onTap: () => setState(() => _hiddenExpanded = !_hiddenExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${parts.join(' · ')}  ', style: AsaText.meta),
              TextSpan(
                text: _hiddenExpanded ? 'hide' : 'show ›',
                style: const TextStyle(
                  color: AsaColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The per-status groups themselves, shown below [_hiddenSection]'s own
  /// line once it's tapped open — one group per status that actually has
  /// a project, newest first by `updated:`. A row opens the whole project
  /// as usual; there is no "Bring back" button — changing the status
  /// field back is the only way back, per the round's own wording.
  Widget _hiddenGroups() {
    final byStatus = <String, List<ProjectSummary>>{};
    for (final summary in widget.hidden) {
      final canonical = canonicalStatus(summary.project.status);
      (byStatus[canonical] ??= []).add(summary);
    }
    for (final group in byStatus.values) {
      group.sort((a, b) => b.project.updated.compareTo(a.project.updated));
    }

    return _rowPanel([
      for (final word in _hiddenOrder)
        if (byStatus[word] != null) ...[
          _hiddenGroupHeader(word),
          for (final summary in byStatus[word]!) _hiddenRow(summary),
        ],
    ]);
  }

  Widget _hiddenGroupHeader(String canonicalStatusWord) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AsaSpace.md,
        vertical: AsaSpace.sm,
      ),
      child: Pill(
        statusLabel(canonicalStatusWord),
        meaning: meaningForStatus(canonicalStatusWord),
      ),
    );
  }

  Widget _hiddenRow(ProjectSummary summary) {
    final lastResult = _newestResultOf(summary);
    return InkWell(
      onTap: () => widget.onOpenProject(openTarget(summary.folder)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.md,
          vertical: AsaSpace.sm,
        ),
        decoration: _rowHairline,
        child: Row(
          children: [
            Text(summary.project.name, style: AsaText.rowName),
            const SizedBox(width: AsaSpace.sm),
            Expanded(
              child: Text(
                [
                  if (asaListDate(summary.project.updated) != null)
                    asaListDate(summary.project.updated)!,
                  if (lastResult != null) 'last: "$lastResult"',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AsaText.meta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The single newest dated result across every one of [summary]'s own
  /// areas — `AreaResult.results` is already sorted newest-first per
  /// area (`area.dart`'s own `_parseResults`), so only each area's own
  /// first dated entry is a candidate; null when no area has one, same
  /// honest absence as everywhere else on this row.
  String? _newestResultOf(ProjectSummary summary) {
    AreaResult? newest;
    for (final area in summary.areas) {
      final firstDated = area.results.where((r) => r.date != null).firstOrNull;
      if (firstDated == null) continue;
      if (newest == null || firstDated.date!.isAfter(newest.date!)) {
        newest = firstDated;
      }
    }
    return newest?.text;
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
                      // Round 37 cp6, §D6 item 7 — the rocket used to sit
                      // in the name's own row, whose height it set (a
                      // Material icon button's own tap target is taller
                      // than a line of text), leaving a visible gap above
                      // the pills below it. Centred (the Row's own
                      // default) against the whole name-and-pills block
                      // instead, `asa-front2`'s own drawing.
                      children: [
                        Expanded(
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
                                  ..._newsMarker(
                                    widget.news[node.folder],
                                    node.folder,
                                  ),
                                ],
                              ),
                              // Round 38 §G — priority and the status pill
                              // leave this inner row: priority stays in
                              // Details only, and the status pill moves to
                              // the row's own right end, after the
                              // deadline. `asa-front2`'s own gap-free pill
                              // spacing no longer applies here.
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (parkedCount > 0) ...[
                                    _parkedBadge(parkedCount),
                                    const SizedBox(width: AsaSpace.sm),
                                  ],
                                  Expanded(
                                    child: InkWell(
                                      // L3 — only tappable when a real task
                                      // backs the text; the typed field or
                                      // honest absence has nowhere more
                                      // specific to land than the row's own
                                      // tap already goes.
                                      onTap: nextStepResult.task == null
                                          ? null
                                          : () => widget.onOpenProject(
                                              openTarget(
                                                node.folder,
                                                areaSourceFile: nextStepResult
                                                    .area
                                                    ?.sourceFile,
                                                openHome:
                                                    nextStepResult.area == null,
                                                highlightRawLine: nextStepResult
                                                    .task!
                                                    .rawLine,
                                              ),
                                            ),
                                      child: Text(
                                        nextStep ?? 'no next step',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AsaText.body.copyWith(
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
                            ],
                          ),
                        ),
                        const SizedBox(width: AsaSpace.sm),
                        if (deadline != null) ...[
                          _deadlineLabel(deadline, overdue),
                          const SizedBox(width: AsaSpace.xs),
                        ],
                        Pill(project.status, meaning: meaning),
                        const SizedBox(width: AsaSpace.xs),
                        StartMenu(
                          projectName: project.name,
                          projectFolder: node.folder,
                          repoPath: project.repoPath,
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
  /// and acting on it, stays the user's own judgement — this only makes the
  /// count impossible to overlook.
  /// Round 38 §E — "only if something happened since [the user] last
  /// opened that project's Log: a blue N new marker, or amber changed
  /// without a note if any change has no log line." The amber signal
  /// wins when both apply — it names a real gap, not just activity.
  List<Widget> _newsMarker(ProjectNews? news, String folder) {
    if (news == null || !news.hasAnything) return const [];
    // Round 38 §E, L25 — "Clicking it opens the project on its Log." Its
    // own `InkWell`, nested inside the row's — the more specific gesture
    // wins the tap, the same pattern the Start-menu icon already relies
    // on at the other end of this same row.
    void onTap() => widget.onOpenProject(openTarget(folder, openLog: true));
    if (news.hasUnloggedChange) {
      return [
        const SizedBox(width: AsaSpace.sm),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AsaSpace.xs,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: AsaColors.amberBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'changed without a note',
              style: AsaText.meta.copyWith(color: AsaColors.amber),
            ),
          ),
        ),
      ];
    }
    return [
      const SizedBox(width: AsaSpace.sm),
      InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AsaSpace.xs,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: AsaColors.blueBg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${news.newCount} new',
            style: AsaText.meta.copyWith(color: AsaColors.blue),
          ),
        ),
      ),
    ];
  }

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
              style: AsaText.meta.copyWith(
                fontWeight: ruleOfTwo ? FontWeight.bold : FontWeight.normal,
                color: ruleOfTwo ? AsaColors.panel : AsaColors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Round 38 §G — the deadline, shown only when `project.deadline` is
  /// set (the caller checks that); no fallback to a staleness age
  /// anymore, that signal left the row. In the "needs you" meaning once
  /// it is overdue (`HANDOVER.md`, 2026-09-13, "an overdue signal for
  /// `deadline`") — a single month or a period, [isPastDeadline] already
  /// decides which.
  Widget _deadlineLabel(String deadline, bool overdue) {
    final text = Text(
      deadline,
      style: AsaText.meta.copyWith(
        color: overdue ? AsaMeaning.needsYou.fg : AsaColors.ink3,
        fontWeight: overdue ? FontWeight.bold : null,
      ),
    );
    return overdue ? Tooltip(message: 'Past its deadline', child: text) : text;
  }

  // --- Round 43 §E — "＋ New project" ------------------------------------

  /// The sketch's own §6 line, same row shape as every other project row
  /// in this panel (hairline, name padding) so it reads as one more row,
  /// not a separate control bolted on below the list.
  Widget _newProjectRow() {
    if (!_addingProject) {
      return InkWell(
        onTap: () => setState(() {
          _addingProject = true;
          _newProjectController = TextEditingController();
          _newProjectError = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AsaSpace.md,
            vertical: AsaSpace.sm,
          ),
          child: Text(
            '＋ New project',
            style: AsaText.body.copyWith(color: AsaColors.blue),
          ),
        ),
      );
    }

    final controller = _newProjectController!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AsaSpace.md,
        vertical: AsaSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EscapeToCancel(
            onEscape: _closeNewProjectField,
            child: SizedBox(
              height: 26,
              child: TextField(
                controller: controller,
                autofocus: true,
                enabled: !_savingProject,
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  hintText: 'Project name',
                ),
                onSubmitted: (_) => _submitNewProject(controller),
              ),
            ),
          ),
          if (_newProjectError != null)
            Padding(
              padding: const EdgeInsets.only(top: AsaSpace.xs),
              child: Text(
                _newProjectError!,
                style: AsaText.meta.copyWith(color: AsaMeaning.needsYou.fg),
              ),
            ),
        ],
      ),
    );
  }

  void _closeNewProjectField() {
    setState(() {
      _newProjectController?.dispose();
      _newProjectController = null;
      _addingProject = false;
      _newProjectError = null;
    });
  }

  Future<void> _submitNewProject(TextEditingController controller) async {
    if (_savingProject) return;
    final name = controller.text.trim();
    if (name.isEmpty) {
      _closeNewProjectField();
      return;
    }

    setState(() {
      _savingProject = true;
      _newProjectError = null;
    });
    final result = await widget.onCreateProject(name);
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _savingProject = false;
        _newProjectError = result.error;
      });
      return;
    }

    _newProjectController?.dispose();
    _newProjectController = null;
    setState(() {
      _addingProject = false;
      _savingProject = false;
      _newProjectError = null;
    });
    widget.onOpenProject(openTarget(result.folder!, openStrategy: true));
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
                      style: AsaText.sectionLabel.copyWith(
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
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
