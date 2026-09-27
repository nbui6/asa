/// Product Hub — the Plan tab. Round 27 built it against `asa-plan-v3`;
/// Round 34 (ADR 0024) adds areas — `plan\<area>.md`, one page per area,
/// goal → plan → tasks → results → decisions — and rebuilds this screen
/// around them, sketch `asa-plan-v5.html`. **A project with no `plan\`
/// folder (`asa` today) keeps exactly the Round 27 screen** — regression,
/// checked explicitly, not assumed.
///
/// Sketch history: `asa-plan-v2.html` was drawn straight from Round 26's
/// data and Nico found it overwhelming — *"the sections in Plan + derived
/// links parts are just very overwhelmed for me."* v3 fixed it by
/// collapsing everything by default and showing only what a real heading
/// says, never a paraphrase of it.
///
/// **Read-only, all of it — ADR 0021 point 4 — except one narrow amendment
/// (2026-09-26): Asa may change checkbox state only, `[ ]` ↔ `[x]`, in a
/// `plan\*.md` page's own `## Tasks` (Round 34 F, now approved).** No
/// prose, no new lines, no reordering, and still never `PLAN.md` or
/// `CHARTER.md`. Everything else here opens the real file with
/// `open_url.dart` instead of writing anything.
library;

import 'dart:async';

import 'package:asa/core/area.dart';
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/project_row.dart' show effectiveNextStepWithArea;
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/start_menu.dart';
import 'package:flutter/material.dart';

class PlanView extends StatefulWidget {
  const PlanView({
    required this.plan,
    required this.areas,
    required this.decisions,
    required this.projectSourceFile,
    required this.homeTasks,
    this.strategy,
    this.onOpenStrategy,
    this.onOpenObjective,
    this.onOpenArea,
    this.onToggleTask,
    this.onDataChanged,
    this.areaToOpen,
    this.openHomeOnStart = false,
    this.highlightTaskRawLine,
    this.typedNextStep = '',
    this.projectName = '',
    this.projectFolder = '',
    this.repoPath = '',
    super.key,
  });

  final Plan plan;

  /// Every `plan\<area>.md` page, already parsed — Round 34/A. Empty for a
  /// project with no `plan\` folder, which keeps today's Round 27 screen.
  final List<Area> areas;

  /// Already loaded by `ProjectScreen` for the Decisions tab — reused here
  /// so a "what changed" ADR chip can open the real decision file instead
  /// of `PLAN.md`, without this widget reading the file system itself.
  final List<DecisionReadResult> decisions;

  /// A Round has no file of its own — the project's own note is where its
  /// `## Roadmap` entry actually lives, so a Round chip opens this rather
  /// than `PLAN.md` too. Same fallback when an ADR chip's number cannot be
  /// found in [decisions]. Also "Not in an area"'s own file, and where its
  /// checkbox ticks land.
  final String projectSourceFile;

  /// The project's own home-note tasks — Round 34/B's "Not in an area"
  /// row, the last one in the area list, same tasks `TasksView` already
  /// shows, read once by `ProjectScreen` rather than re-read here.
  final List<Task> homeTasks;

  /// Null when the project has no `CHARTER.md` — "What this project is
  /// for" only shows once there is a real strategy to point at.
  final Strategy? strategy;

  /// Switches `ProjectScreen`'s own tab to Strategy — null in a test that
  /// does not need it.
  final VoidCallback? onOpenStrategy;

  /// Round-36 §3, L12 — switches `ProjectScreen`'s own tab to Strategy and
  /// asks it to open one specific objective, named by its 1-based number
  /// (`"1"` from `Objective 1` in a `## Goal` section). Null in a test
  /// that does not need it, or when an area names no objective at all.
  final void Function(String objectiveNumber)? onOpenObjective;

  /// Round-36 §3, L17 — handed straight through to a `DecisionDetailScreen`
  /// this widget pushes (an area's own ADR chip, L13), so an area chip
  /// shown there lands back here with that area open. Null keeps that
  /// chip inert, for a caller not wired for it yet.
  final void Function(Area area)? onOpenArea;

  /// Round 34/F — ticks one task, in [Area.sourceFile] or
  /// [projectSourceFile] (for "Not in an area"). Null keeps every checkbox
  /// here read-only, for a caller not ready to wire the write path yet.
  final Future<void> Function(String sourceFile, Task task)? onToggleTask;

  /// Round 36 cp6 — called after an ADR chip's own pushed
  /// `DecisionDetailScreen` reports a verdict was actually recorded there,
  /// so the caller can reload its own cached `decisions`/`areas` rather
  /// than show what was true before that Accept/Reject. Null in a test
  /// that never records a verdict from here.
  final VoidCallback? onDataChanged;

  /// Round 34/D, L13/L17 — an area's own `sourceFile`, set by a caller
  /// (an ADR chip elsewhere) that wants this one area open the next time
  /// this tab is shown. Read once, on the change that sets it — see
  /// `_PlanViewState.didUpdateWidget`.
  final String? areaToOpen;

  /// Round-36 §3, L3 — a caller that wants "Not in an area" open the next
  /// time this tab is shown, the same way [areaToOpen] opens one area.
  /// False in a test that does not need it.
  final bool openHomeOnStart;

  /// Round-36 §3, L3/L9 — the exact [Task.rawLine] to briefly highlight
  /// the next time this tab is shown, wherever that task actually renders
  /// (an area's own tasks, or "Not in an area"). Null shows no highlight
  /// at all — the ordinary case for every existing caller.
  final String? highlightTaskRawLine;

  /// The project's own typed `next-step:` field — round-36 §2 b's "Next"
  /// line falls back to this only when no home or area task is open,
  /// same chain [effectiveNextStepWithArea] already implements. Empty
  /// keeps that chain's own honest-absence behaviour.
  final String typedNextStep;

  /// Round-36 §2 b's Next line needs these three, unchanged, to draw its
  /// own [StartMenu] — the same Start button already on every project row
  /// and the header, now repeated here so starting work never requires
  /// leaving the Plan tab. Empty defaults keep every existing test, which
  /// does not exercise Start from this widget, working unchanged.
  final String projectName;
  final String projectFolder;
  final String repoPath;

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  // Every group starts collapsed — this round's own scope line, not an
  // oversight, and deliberately not persisted across a reload or a tab
  // switch: a fresh `PlanView` always starts from the same, predictable
  // "nothing open yet" state.
  // Membership means "expanded" — an empty set, the starting state, means
  // every group is collapsed by default without having to know every
  // group's id in advance.
  final Set<int> _expanded = {};

  /// Areas keyed by [Area.sourceFile], not `identityHashCode` — see
  /// `_areaRow`'s own comment: ticking a task reloads the project and
  /// re-parses a brand new `Area`, and identity would not survive that.
  final Set<String> _expandedAreas = {};
  bool _olderChangesShown = false;
  bool _moreGroupsShown = false;
  bool _overviewExpanded = false;
  bool _notInAnAreaExpanded = false;

  /// Round-36 §3, L3/L9 — the task row currently drawn highlighted, or
  /// null for none. Cleared automatically about 2 s after it is set —
  /// [_armHighlightTimer] — never left showing.
  String? _highlightedRawLine;

  // Persona-check, re-run against this real screen: showing all ~24 of a
  // real project's top-level groups at once — even one line each,
  // collapsed — reproduces the row-count version of the overwhelm that
  // blocked `asa-plan-v2.html`, not just the per-row density it already
  // fixed. `asa-plan-v3.html` draws 4 before its own "+N more, collapsed"
  // line; 6 keeps that same shape with a little more room before the
  // fold — a bounded number, picked and named, same discipline this
  // project already asks of any other bounded list.
  static const _topLevelGroupCap = 6;

  @override
  void initState() {
    super.initState();
    final target = widget.areaToOpen;
    if (target != null) _expandedAreas.add(target);
    // Round 36 cp8, §9 point 1 — a project with no plan pages at all shows
    // "Not in an area" as its only row; open by default, same reasoning
    // openHomeOnStart already uses for a caller that asked for it.
    final soleRow = widget.areas.isEmpty && widget.plan.isEmpty;
    if (widget.openHomeOnStart || soleRow) _notInAnAreaExpanded = true;
    _highlightedRawLine = widget.highlightTaskRawLine;
    if (_highlightedRawLine != null) _armHighlightTimer();
  }

  @override
  void didUpdateWidget(PlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only react to a genuinely new request — the same sourceFile arriving
    // again (e.g. a reload after a tick) must not reopen a row the person
    // already collapsed by hand.
    final target = widget.areaToOpen;
    if (target != null && target != oldWidget.areaToOpen) {
      _expandedAreas.add(target);
    }
    final line = widget.highlightTaskRawLine;
    if (line != null && line != oldWidget.highlightTaskRawLine) {
      setState(() => _highlightedRawLine = line);
      _armHighlightTimer();
    }
  }

  /// Round-36 §3, L3/L9 — clears [_highlightedRawLine] about 2 s after it
  /// is set. `Future.delayed` rather than an `AnimationController`: the
  /// highlight is "on, then off", never something to scrub or reverse.
  void _armHighlightTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedRawLine = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.areas.isEmpty) {
      // Round 36 cp8, §9 point 1 — found against the real folder: 12 of 13
      // real projects have neither `PLAN.md` nor `plan\`, and used to land
      // on the Decisions tab entirely (this widget never even built) —
      // contradicting §2 a's own "every project opens on Plan." A project
      // with a real `PLAN.md` (asa, today) keeps its own legacy screen
      // unchanged, just with the Next line above it; a project with
      // neither gets the Next line, "what this project is for" if there's
      // a real Strategy, its home tasks under "Not in an area" (the only
      // row, so open by default — see initState), and one quiet pointer
      // to how it would grow areas at all.
      if (widget.plan.isEmpty) return _noPlanBody();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_nextLineRow(), const SizedBox(height: 4), _legacyBody()],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.strategy != null && !widget.strategy!.isEmpty) ...[
          _whatThisProjectIsFor(widget.strategy!),
          const SizedBox(height: 4),
        ],
        _nextLineRow(),
        const SizedBox(height: 4),
        for (final area in widget.areas) _areaRow(area),
        _notInAnAreaRow(),
        const SizedBox(height: 16),
        _overviewRow(),
      ],
    );
  }

  /// Round 27's own screen, unchanged — a project with no `plan\` folder
  /// (`asa` today) never sees anything Round 34 added.
  Widget _legacyBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What changed'),
        _whatChanged(),
        const SizedBox(height: 20),
        _label('The plan'),
        ..._outline(),
        const SizedBox(height: 16),
        _strategyPointer(),
        const SizedBox(height: 12),
        _readOnlyNote(),
      ],
    );
  }

  /// Round 36 cp8, §9 point 1 — a project with neither `PLAN.md` nor
  /// `plan\`: no areas, no legacy roadmap, nothing invented to fill the
  /// gap. Just the Next line, why the project exists if that's known, its
  /// own home tasks (the only row here, open by default), and one honest
  /// pointer to how it would grow areas at all — never a button that
  /// writes anything itself, matching ADR 0021's own read-only rule.
  Widget _noPlanBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.strategy != null && !widget.strategy!.isEmpty) ...[
          _whatThisProjectIsFor(widget.strategy!),
          const SizedBox(height: 4),
        ],
        _nextLineRow(),
        const SizedBox(height: 4),
        _notInAnAreaRow(),
        const SizedBox(height: 12),
        Text(
          'No areas yet. To split this project into areas: Start → Copy '
          'opener, and ask the AI.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // --- What this project is for ---------------------------------------

  Widget _whatThisProjectIsFor(Strategy strategy) {
    final line = strategy.objectives.isNotEmpty
        ? stripCodeSpanMarkers(
            stripEmphasisMarkers(strategy.objectives.first.title),
          )
        : stripCodeSpanMarkers(stripEmphasisMarkers(strategy.origin ?? ''));

    return InkWell(
      onTap: widget.onOpenStrategy,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border(
            bottom: const BorderSide(color: Color(0xFFE0E0E0)),
            left: BorderSide(color: Colors.grey.shade400, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  children: [
                    const TextSpan(
                      text: 'What this project is for',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' — $line'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Strategy →',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- The Next line — round-36 §2 b ------------------------------------

  /// The project's single next step, wherever it actually comes from —
  /// same chain [effectiveNextStepWithArea] already implements for the
  /// overview — with the area it belongs to as a small chip, and the real
  /// Start menu on the right so starting work never needs a second tab.
  Widget _nextLineRow() {
    final result = effectiveNextStepWithArea(
      widget.homeTasks,
      widget.typedNextStep,
      areas: widget.areas,
    );
    final text = result.text;

    // A bounded card, not just a bottom-bordered row — asa-project-page-v1's
    // own drawing of this line sets it apart from the area list below it,
    // the same way `_readOnlyNote` already sets its own box apart.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FC),
        border: Border.all(color: const Color(0xFFDCD6EF)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: text == null
                  ? null
                  : () => _openNextTask(result.area, result.task),
              child: Row(
                children: [
                  Text(
                    'NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text ?? 'No next step',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: text == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: text == null
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (result.area != null) ...[
                    const SizedBox(width: 8),
                    _areaNameChip(result.area!.name),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          StartMenu(
            projectName: widget.projectName,
            projectFolder: widget.projectFolder,
            repoPath: widget.repoPath,
            // L10 — only a real task names itself and its area page; the
            // typed field or honest absence has no task to point at.
            nextTaskText: result.task != null ? text : null,
            areaSourceFile: result.area?.sourceFile,
          ),
        ],
      ),
    );
  }

  /// L9 — tapping the Next line's task opens the area holding it (or
  /// "Not in an area" for a home task) and briefly highlights the task
  /// row itself, same mechanism L3 (the overview's own next-step text)
  /// uses to land here.
  void _openNextTask(Area? area, Task? task) {
    setState(() {
      if (area == null) {
        _notInAnAreaExpanded = true;
      } else {
        _expandedAreas.add(area.sourceFile);
      }
      if (task != null) _highlightedRawLine = task.rawLine;
    });
    if (task != null) _armHighlightTimer();
  }

  Widget _areaNameChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEF1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // --- One area's row ---------------------------------------------------

  Widget _areaRow(Area area) {
    // Keyed by sourceFile, not identityHashCode — ticking a task inside
    // an area reloads the whole project, which re-parses a brand new
    // Area object from disk. identityHashCode would change on every
    // reload and silently collapse the row that was just ticked open;
    // the file path is the one thing that stays the same.
    final expanded = _expandedAreas.contains(area.sourceFile);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expandedAreas.remove(area.sourceFile);
              } else {
                _expandedAreas.add(area.sourceFile);
              }
            }),
            // One row, per both approved sketches (asa-plan-v5,
            // asa-project-page-v1) — round-35/G's own persona-check
            // worry (density) is about a row's *height*, not about
            // spreading one row's own fields across several lines.
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  area.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _areaNextTaskLabel(area),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: _areaHasOpenTask(area)
                          ? Colors.grey.shade700
                          : Colors.grey.shade500,
                      fontSize: 12.5,
                      fontStyle: _areaHasOpenTask(area)
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _resultLabel(area),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 90, child: _progressBar(area)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${area.doneCount} / ${area.totalCount}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 8),
              child: _areaDetail(area),
            ),
        ],
      ),
    );
  }

  Widget _progressBar(Area area) {
    final total = area.totalCount;
    final fraction = total == 0 ? 0.0 : area.doneCount / total;
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : fraction,
          backgroundColor: const Color(0xFFEDEEF1),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF2A7355)),
        ),
      ),
    );
  }

  String _resultLabel(Area area) {
    for (final result in area.results) {
      if (result.date != null) return 'result ${_humanDate(result.date!)}';
    }
    return 'no result yet';
  }

  /// Round-36 §2 c — a closed area row shows its next open task instead
  /// of its goal or summary; the goal itself only shows once expanded, in
  /// [_areaDetail]. Zero tasks and every-task-done both read as "all
  /// done" — there is nothing open either way.
  String _areaNextTaskLabel(Area area) {
    for (final task in area.tasks) {
      if (!task.done && !task.parked) {
        return 'next ${stripCodeSpanMarkers(stripEmphasisMarkers(task.text))}';
      }
    }
    return 'nothing open — all done';
  }

  bool _areaHasOpenTask(Area area) =>
      area.tasks.any((t) => !t.done && !t.parked);

  Widget _areaDetail(Area area) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _goalField(area),
        _textField('Plan', area.planText, empty: 'No plan yet'),
        _tasksField(area.tasks, sourceFile: area.sourceFile),
        _resultsField(area.results),
        _decisionsField(area.decisionNumbers),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => openUrl(area.sourceFile),
          child: Text(
            'open the page ↗',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(String label, String? value, {required String empty}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          Text(
            value == null || value.isEmpty
                ? empty
                : stripCodeSpanMarkers(stripEmphasisMarkers(value)),
            style: TextStyle(
              color: value == null || value.isEmpty
                  ? Colors.grey.shade500
                  : Colors.black87,
              fontStyle: value == null || value.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Round-36 §3, L12 — same shape as [_textField], plus one chip per
  /// number in [Area.objectiveNumbers] (only ever parsed from this same
  /// Goal section — `area.dart`'s own scoping rule). Tapping one switches
  /// to Strategy with that objective expanded.
  Widget _goalField(Area area) {
    final goal = area.goal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Goal'),
          Text(
            goal == null || goal.isEmpty
                ? 'No goal yet'
                : stripCodeSpanMarkers(stripEmphasisMarkers(goal)),
            style: TextStyle(
              color: goal == null || goal.isEmpty
                  ? Colors.grey.shade500
                  : Colors.black87,
              fontStyle: goal == null || goal.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          if (area.objectiveNumbers.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final number in area.objectiveNumbers)
                  _objectiveChip(number),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _objectiveChip(String number) {
    return InkWell(
      onTap: () => widget.onOpenObjective?.call(number),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE4F0EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Objective $number',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A7355),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _tasksField(List<Task> tasks, {required String sourceFile}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Tasks'),
          if (tasks.isEmpty)
            Text(
              'Nothing yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final task in tasks) _taskRow(task, sourceFile: sourceFile),
        ],
      ),
    );
  }

  Widget _taskRow(Task task, {required String sourceFile}) {
    final canToggle = widget.onToggleTask != null;
    final highlighted = _highlightedRawLine == task.rawLine;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: highlighted ? const Color(0xFFFFF3CD) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: task.done,
              onChanged: canToggle
                  ? (_) => widget.onToggleTask!(sourceFile, task)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
              style: TextStyle(
                fontSize: 13,
                color: task.done ? Colors.grey.shade500 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsField(List<AreaResult> results) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Results'),
          if (results.isEmpty)
            Text(
              'Nothing yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final result in results) _resultRow(result),
        ],
      ),
    );
  }

  Widget _resultRow(AreaResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.date != null) ...[
            SizedBox(
              width: 60,
              child: Text(
                _humanDate(result.date!),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(result.text, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _decisionsField(List<String> decisionNumbers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Decisions'),
          if (decisionNumbers.isEmpty)
            Text(
              'None yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final number in decisionNumbers) _adrChip(number),
              ],
            ),
        ],
      ),
    );
  }

  Widget _adrChip(String number) {
    return InkWell(
      onTap: () => _openDecision(number),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE6ECF7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'ADR $number',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F5FA6),
          ),
        ),
      ),
    );
  }

  /// Round-36 §3, L13 — the decision detail screen when [number] is
  /// already loaded (real in-app navigation, so popping back returns to
  /// this same Plan tab with this same area still open); the raw file
  /// otherwise, same fallback as before this round, for a number this
  /// screen never loaded a decision for.
  Future<void> _openDecision(String number) async {
    final decision = _decisionFor(number);
    if (decision != null) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => DecisionDetailScreen(
            decision: decision,
            areasNaming: _areasNaming(number),
            onOpenArea: widget.onOpenArea,
          ),
        ),
      );
      if (changed ?? false) widget.onDataChanged?.call();
      return;
    }
    unawaited(openUrl(_decisionSourceFor(number)));
  }

  Decision? _decisionFor(String number) {
    for (final result in widget.decisions) {
      if (result.decision?.number == number) return result.decision;
    }
    return null;
  }

  /// Round-36 §3, L17 — every area whose own `decisionNumbers` names
  /// [number], same rule `ProjectScreen._areasNaming` already uses for
  /// the decision row itself.
  List<Area> _areasNaming(String number) => [
    for (final area in widget.areas)
      if (area.decisionNumbers.contains(number)) area,
  ];

  String _decisionSourceFor(String number) {
    for (final result in widget.decisions) {
      if (result.decision?.number == number) return result.decision!.sourceFile;
    }
    return widget.projectSourceFile;
  }

  // --- Not in an area ----------------------------------------------------

  Widget _notInAnAreaRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _notInAnAreaExpanded = !_notInAnAreaExpanded),
            child: Row(
              children: [
                Icon(
                  _notInAnAreaExpanded
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Not in an area',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.homeTasks.where((t) => !t.done).length} open',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_notInAnAreaExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 6),
              child: widget.homeTasks.isEmpty
                  ? Text(
                      'Nothing yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final task in widget.homeTasks)
                          _taskRow(task, sourceFile: widget.projectSourceFile),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  // --- Overview — What changed and the outline, folded one level down --

  Widget _overviewRow() {
    if (!widget.plan.pages.any((p) => p.aspect == null)) {
      return const SizedBox.shrink();
    }

    final entries = _changeEntries(widget.plan);
    final summary = entries.isEmpty
        ? 'nothing dated yet'
        : 'last changed ${_humanDate(entries.first.date)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _overviewExpanded = !_overviewExpanded),
          child: Row(
            children: [
              Icon(
                _overviewExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              const Text(
                'Overview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                summary,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_overviewExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('What changed'),
                _whatChanged(),
                const SizedBox(height: 16),
                _label('The plan'),
                ..._outline(),
                const SizedBox(height: 12),
                _readOnlyNote(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // --- What changed --------------------------------------------------

  Widget _whatChanged() {
    final entries = _changeEntries(widget.plan);
    if (entries.isEmpty) {
      return Text(
        'Nothing dated yet.',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    final shown = _olderChangesShown ? entries : entries.take(3).toList();
    final olderCount = entries.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in shown) _changeRow(entry),
        if (olderCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => setState(() => _olderChangesShown = true),
              child: Text(
                'older ($olderCount) ↓',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  /// Round 35/C — the chip `Wrap` used to have no width limit in this
  /// `Row`, so once a real entry accumulated enough Round/ADR links it
  /// claimed all the width it wanted first, and the sibling `Expanded`
  /// text — the actual sentence this whole panel exists to show — was
  /// squeezed to a few pixels and wrapped one letter per line. Capping the
  /// chip *count* rather than a pixel width fixes it at the source: with
  /// at most 4 small chip-shaped things ever in this row, the text always
  /// gets the room it needs.
  static const _maxChipsShown = 3;

  Widget _changeRow(_ChangeEntry entry) {
    final links = _dedupeLinks(entry.links);
    final shownLinks = links.take(_maxChipsShown).toList();
    final hiddenCount = links.length - shownLinks.length;

    return InkWell(
      onTap: () => openUrl(entry.sourceFile),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                _humanDate(entry.date),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(entry.text.isEmpty ? '(untitled)' : entry.text),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final link in shownLinks) _linkChip(link),
                if (hiddenCount > 0)
                  Tooltip(
                    message: links
                        .skip(_maxChipsShown)
                        .map((l) => l.sentence)
                        .join('\n'),
                    child: Text(
                      '+$hiddenCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ADR 0021's revision #2: "a derived link is rendered as the sentence
  /// it came from — never as a bare 'related' row." The chip itself stays
  /// a two-word tag — persona-check, re-run against this real screen,
  /// found the sketch's own bare chips read fine collapsed but say
  /// nothing on their own once you look for the sentence the whole point
  /// of Round 26 was to keep. A tooltip costs nothing until asked for, so
  /// both are true at once: compact by default, the real sentence one
  /// hover away, never paraphrased.
  Widget _linkChip(PlanLink link) {
    final isAdr = link.kind == PlanLinkKind.adr;
    return Tooltip(
      message: link.sentence,
      child: InkWell(
        onTap: () => openUrl(_targetFor(link)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isAdr ? const Color(0xFFE6ECF7) : const Color(0xFFFAF0DA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isAdr ? 'ADR ${link.target}' : 'Round ${link.target}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isAdr ? const Color(0xFF2F5FA6) : const Color(0xFF8A5A12),
            ),
          ),
        ),
      ),
    );
  }

  /// The real decision file for an ADR chip, when one is already loaded;
  /// the project's own note (never `PLAN.md`) for a Round chip, or for an
  /// ADR number that does not match anything in [PlanView.decisions] —
  /// still a real, more specific file than the plan, never a dead tap.
  String _targetFor(PlanLink link) {
    if (link.kind == PlanLinkKind.adr) {
      for (final result in widget.decisions) {
        if (result.decision?.number == link.target) {
          return result.decision!.sourceFile;
        }
      }
    }
    return widget.projectSourceFile;
  }

  // --- The outline -----------------------------------------------------

  /// The front page's own `##` sections sit directly at the top level —
  /// today's only real shape, and what `asa-plan-v3.html` draws. Any
  /// `plan\*.md` page (none exist on any real project yet) gets its own
  /// top-level group first, named by its aspect, so a real second page
  /// does not dump its sections in flat alongside the front page's own.
  ///
  /// Capped at [_topLevelGroupCap], same "older, collapsed" shape as
  /// "what changed" — every group is one line while collapsed, but a
  /// real project has enough of them that showing all of them at once is
  /// its own kind of overwhelm, independent of any one row's density.
  List<Widget> _outline() {
    final all = <Widget>[];
    for (final page in widget.plan.pages) {
      // Round 34 — every `plan\*.md` page is now an area, already drawn by
      // its own row above; the Overview's outline only ever repeats the
      // front page's own sections, never an area a second time.
      if (page.aspect != null && widget.areas.isNotEmpty) continue;

      final roots = _sectionTree(page.sections);
      if (page.aspect == null) {
        for (final node in roots) {
          all.add(_sectionGroup(node, depth: 0, sourceFile: page.sourceFile));
        }
      } else {
        all.add(_pageGroup(page, roots));
      }
    }

    if (_moreGroupsShown || all.length <= _topLevelGroupCap) return all;

    final shown = all.take(_topLevelGroupCap).toList();
    final more = all.length - shown.length;
    shown.add(
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: InkWell(
          onTap: () => setState(() => _moreGroupsShown = true),
          child: Text(
            '+ $more more, collapsed ↓',
            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          ),
        ),
      ),
    );
    return shown;
  }

  Widget _pageGroup(PlanPage page, List<_SectionNode> roots) {
    final id = identityHashCode(page);
    final collapsed = !_expanded.contains(id);
    return _toggleGroup(
      label: _titleCase(page.aspect!),
      hasChildren: true, // a page is always worth opening, even with 0 sections
      collapsed: collapsed,
      onToggleCollapse: () => _flip(id),
      onOpen: () => openUrl(page.sourceFile),
      depth: 0,
      children: collapsed
          ? const []
          : [
              for (final node in roots)
                _sectionGroup(node, depth: 1, sourceFile: page.sourceFile),
            ],
    );
  }

  Widget _sectionGroup(
    _SectionNode node, {
    required int depth,
    required String sourceFile,
  }) {
    final id = identityHashCode(node.section);
    final collapsed = !_expanded.contains(id);
    final hasChildren = node.children.isNotEmpty;

    return _toggleGroup(
      label: node.section.heading,
      hasChildren: hasChildren,
      collapsed: collapsed,
      onToggleCollapse: () => _flip(id),
      onOpen: () => openUrl(sourceFile),
      depth: depth,
      children: (!hasChildren || collapsed)
          ? const []
          : [
              for (final child in node.children)
                _sectionGroup(child, depth: depth + 1, sourceFile: sourceFile),
            ],
    );
  }

  void _flip(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Widget _toggleGroup({
    required String label,
    required bool hasChildren,
    required bool collapsed,
    required VoidCallback onToggleCollapse,
    required VoidCallback onOpen,
    required int depth,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                child: hasChildren
                    ? InkWell(
                        onTap: onToggleCollapse,
                        child: Icon(
                          collapsed ? Icons.chevron_right : Icons.expand_more,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(label),
                  ),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  // --- Strategy pointer and the read-only note ------------------------

  Widget _strategyPointer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'The two non-negotiable gates live one tab over',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ),
          Text(
            'Strategy →',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCDFE4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Read-only. Tapping anything opens the real file. Nothing here '
        'edits PLAN.md.',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
      ),
    );
  }
}

// --- Pure helpers, tested directly ------------------------------------

class _ChangeEntry {
  _ChangeEntry({
    required this.date,
    required this.text,
    required this.sourceFile,
    required this.links,
    required this.sequence,
  });

  final DateTime date;
  final String text;
  final String sourceFile;
  final List<PlanLink> links;

  /// Encounter order across every page, in file order — the tie-break
  /// for two entries dated the same day. `PLAN.md`'s own convention is
  /// append-at-the-end, so a later position in the file is a later entry.
  final int sequence;
}

final RegExp _isoDateHeading = RegExp(r'^(\d{4}-\d{2}-\d{2})\b\s*(.*)$');

/// Every dated heading across every page of [plan], newest first — same
/// date sorts by file position, later wins. Round 27's own instruction:
/// "newest means the latest date, and among equal dates the one that
/// appears later in the file."
List<_ChangeEntry> _changeEntries(Plan plan) {
  final entries = <_ChangeEntry>[];
  var sequence = 0;

  for (final page in plan.pages) {
    for (final section in page.sections) {
      final match = _isoDateHeading.firstMatch(section.heading);
      if (match == null) continue;
      final date = DateTime.tryParse(match.group(1)!);
      if (date == null) continue;

      entries.add(
        _ChangeEntry(
          date: date,
          text: match.group(2)!.replaceFirst(RegExp(r'^[\s—-]+'), '').trim(),
          sourceFile: page.sourceFile,
          // Round 34/A added PlanLinkKind.objective — "What changed" only
          // ever showed Round/ADR chips, and _linkChip below has no shape
          // for a third kind (it would mislabel one "Round N"), so this
          // panel keeps excluding it, same as it already excludes wikilink.
          links: deriveLinks(section.body)
              .where(
                (l) =>
                    l.kind != PlanLinkKind.wikilink &&
                    l.kind != PlanLinkKind.objective,
              )
              .toList(),
          sequence: sequence++,
        ),
      );
    }
  }

  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.sequence.compareTo(a.sequence);
  });
  return entries;
}

/// One mention deduplicated to one chip — a section that names "Round 26"
/// three times shows one "Round 26" chip, not three.
List<PlanLink> _dedupeLinks(List<PlanLink> links) {
  final seen = <String>{};
  final result = <PlanLink>[];
  for (final link in links) {
    final key = '${link.kind}:${link.target}';
    if (seen.add(key)) result.add(link);
  }
  return result;
}

/// One heading and its own nested headings — `###` under the `##` it
/// physically follows, and so on. [Section] itself is a flat, file-order
/// list; this is the one place that turns it into the tree the outline
/// actually renders, built from the same [Section]s Round 26 already
/// parsed rather than re-reading anything.
class _SectionNode {
  _SectionNode(this.section, this.children);

  final Section section;
  final List<_SectionNode> children;
}

/// [sections] filtered to level 2+ (a page's own `#` title is not a
/// section a human toggles) and nested by heading level.
List<_SectionNode> _sectionTree(List<Section> sections) {
  final roots = <_SectionNode>[];
  final stack = <_SectionNode>[];

  for (final section in sections) {
    if (section.level < 2) continue;
    final node = _SectionNode(section, []);
    while (stack.isNotEmpty && stack.last.section.level >= section.level) {
      stack.removeLast();
    }
    if (stack.isEmpty) {
      roots.add(node);
    } else {
      stack.last.children.add(node);
    }
    stack.add(node);
  }
  return roots;
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

/// `today` / `yesterday` / `14 Sep` — the same convention
/// `project_screen.dart`'s own `_humanDate` already uses for a decision's
/// date, duplicated rather than shared: that one is private to a
/// different file and this round is scoped to the Plan tab, not a
/// refactor of it.
String _humanDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
