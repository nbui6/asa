/// Product Hub — the Plan tab. Round 27 built it against `asa-plan-v3`;
/// Round 34 (ADR 0024) adds areas — `plan\<area>.md`, one page per area,
/// goal → plan → tasks → results → decisions — and rebuilds this screen
/// around them, sketch `asa-plan-v5.html`. **A project with no `plan\`
/// folder (`asa` today) keeps exactly the Round 27 screen** — regression,
/// checked explicitly, not assumed. Round 37 (ADR 0029) moves this screen
/// onto the shared `ui/` parts — its own layout is unchanged.
///
/// Sketch history: `asa-plan-v2.html` was drawn straight from Round 26's
/// data and the user found it overwhelming — *"the sections in Plan + derived
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
import 'package:asa/core/area_writer.dart' show AreaCreateResult;
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/task.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/escape_to_cancel.dart';
import 'package:asa/hubs/product/ui/hover_pencil.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/task_row.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/gestures.dart';
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
    this.selectedAreaTab,
    this.onSelectAreaTab,
    this.onCreateArea,
    this.onSetAreaSection,
    this.onClearAreaSection,
    this.onEditResultText,
    this.onRemoveResultText,
    this.openHomeOnStart = false,
    this.highlightTaskRawLine,
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

  /// Round 38 §B — a strip of area tabs replaces the old expand-in-place
  /// row: `null` means "All"; an area's own [Area.sourceFile] otherwise.
  /// Owned by `ProjectScreen`, not this widget — "the selected area is
  /// remembered per project while the app runs," which only holds if it
  /// survives this widget being torn down and rebuilt on every switch
  /// away from and back to the Plan tab (see round-38.md §B).
  final String? selectedAreaTab;

  /// Tapping an area row in "All", or an area chip anywhere else in this
  /// screen's tree (Round 34/D, L13/L17). Null in a test that does not
  /// need it.
  final void Function(String? sourceFile)? onSelectAreaTab;

  /// Round 38 §B's own `+ Add area` — writes a brand new, empty area page
  /// and reports what happened; this widget shows the dialog and the
  /// refusal, never writes a file itself (`area_writer.dart` does, ADR
  /// 0021/0026's narrow amendment). Null keeps `+ Add area` out of a test
  /// that does not need it.
  final Future<AreaCreateResult> Function(String name)? onCreateArea;

  /// Round 43 §D — fills an area's empty `## Goal`/`## Plan` with what the
  /// user typed (＋), or rewrites it from ✎ on existing text. `oldValue` is
  /// what this screen was showing before the edit — `''` for the ＋ path,
  /// the previous text for ✎ — so the real writer's own drift check has
  /// something to compare against; passing the wrong "what it was" would
  /// make every ✎ edit of non-empty text fail that check. Null keeps the
  /// old "No goal yet" line, for a caller (or test) not wired for it.
  final Future<void> Function(
    String sourceFile,
    String heading,
    String oldValue,
    String newText,
  )?
  onSetAreaSection;

  /// Round 43 §D — 🗑 in a filled Goal/Plan's own edit mode: clears it back
  /// to empty (the heading and ＋ show again). Null keeps 🗑 off the edit
  /// row entirely, for a caller (or test) not wired for it.
  final Future<void> Function(String sourceFile, String heading)?
  onClearAreaSection;

  /// Round 43 §D — the human's own ✎ on an existing result's own text.
  /// Null keeps every result read-only, for a caller (or test) not wired
  /// for it. The whole `AreaResult` is passed, not just its text — the
  /// writer needs its own `rawLine` (to find it) and its date/task/link
  /// (to rebuild the line unchanged apart from the text).
  final Future<void> Function(
    String sourceFile,
    AreaResult result,
    String newText,
  )?
  onEditResultText;

  /// Round 43 §D — 🗑 in a result's own edit mode: removes that one line
  /// outright. Null keeps 🗑 off the result edit row, same gating as
  /// [onEditResultText] — a result with no [onEditResultText] never reaches
  /// edit mode in the first place, so this is never called for one.
  final Future<void> Function(String sourceFile, AreaResult result)?
  onRemoveResultText;

  /// Round-36 §3, L3 — a caller that wants "Not in an area" open the next
  /// time this tab is shown. False in a test that does not need it.
  final bool openHomeOnStart;

  /// Round-36 §3, L3/L9 — the exact [Task.rawLine] to briefly highlight
  /// the next time this tab is shown, wherever that task actually renders
  /// (an area's own tasks, or "Not in an area"). Null shows no highlight
  /// at all — the ordinary case for every existing caller.
  final String? highlightTaskRawLine;

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
  bool _olderChangesShown = false;
  bool _moreGroupsShown = false;
  bool _overviewExpanded = false;
  bool _notInAnAreaExpanded = false;

  /// Round 38 §F (ADR 0036) — "the same rule inside a project: done tasks
  /// ... fold into one line." Keyed by the same `sourceFile` a task row
  /// already carries (the project's own home note, or one area's page),
  /// so the home task list and every area's own list fold independently.
  final Set<String> _doneTasksShown = {};

  /// Round 38 §F — results fold the same way, "newest two, then N older
  /// ›." Keyed by the area's own `sourceFile` — results are area-only.
  final Set<String> _olderResultsShown = {};

  /// Round 43 §D — the one empty place currently open for typing, keyed
  /// `'$sourceFile\u0000$heading'`; null when none is.
  String? _addingSectionKey;
  final _sectionController = TextEditingController();

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  /// Round-36 §3, L3/L9 — the task row currently drawn highlighted, or
  /// null for none. Cleared automatically about 2 s after it is set —
  /// [_armHighlightTimer]. Never left showing.
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
    // Round 38 §A — the header's own Next line can now point at a home
    // task (no area) while this PlanView is already mounted (the tab was
    // already Plan, so it never remounts); without this,
    // `_notInAnAreaExpanded` only ever got set once, in `initState`.
    if (widget.openHomeOnStart && !oldWidget.openHomeOnStart) {
      setState(() => _notInAnAreaExpanded = true);
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
      // with a real `PLAN.md` keeps its own legacy screen unchanged, just
      // with the Next line above it; a project with neither gets the Next
      // line, "what this project is for" if there's a real Strategy, its
      // home tasks under "Not in an area" (the only row, so open by
      // default — see initState), and one quiet pointer to how it would
      // grow areas at all. Round 38 §B — either way, "a project without
      // areas shows only All … and + Add area": both bodies gain that one
      // entry point, nothing else about them changes.
      final body = widget.plan.isEmpty ? _noPlanBody() : _legacyBody();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onCreateArea != null) ...[
            _addAreaEntry(),
            const SizedBox(height: AsaSpace.sm),
          ],
          body,
        ],
      );
    }

    // Round 38 §B — a strip of area tabs replaces the old expand-in-place
    // row: All · one per area · + Add area.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _areaTabStrip(),
        const SizedBox(height: AsaSpace.sm),
        const Divider(height: 1, color: AsaColors.soft),
        const SizedBox(height: AsaSpace.sm),
        _areaTabBody(),
      ],
    );
  }

  /// `null` (or a `sourceFile` no longer among [Area]s — the file was
  /// renamed or removed by hand, ADR 0021 point 4's own boundary, never
  /// this app) both mean "All".
  Area? _selectedArea() {
    final selected = widget.selectedAreaTab;
    if (selected == null) return null;
    for (final area in widget.areas) {
      if (area.sourceFile == selected) return area;
    }
    return null;
  }

  Widget _areaTabStrip() {
    final selected = _selectedArea();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AsaSpace.lg,
      runSpacing: AsaSpace.xs,
      children: [
        _areaTabLabel(
          'All',
          selected: selected == null,
          onTap: () => widget.onSelectAreaTab?.call(null),
        ),
        for (final area in widget.areas)
          _areaTabLabel(
            area.name,
            selected: selected?.sourceFile == area.sourceFile,
            onTap: () => widget.onSelectAreaTab?.call(area.sourceFile),
          ),
        if (widget.onCreateArea != null)
          _areaTabLabel(
            '+ Add area',
            selected: false,
            onTap: _showAddAreaDialog,
          ),
      ],
    );
  }

  /// A smaller, secondary strip — the four main tabs (Strategy/Plan/
  /// Decisions/Details) already own `AsaText.rowName`'s weight and the
  /// underline; this one reads as a sub-navigation, `AsaText.meta`-sized,
  /// a light fill instead of an underline when selected.
  Widget _areaTabLabel(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AsaColors.ground : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: AsaText.meta.copyWith(
            color: selected ? AsaColors.ink : AsaColors.ink2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _areaTabBody() {
    final selected = _selectedArea();
    if (selected != null) return _areaDetail(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.strategy != null && !widget.strategy!.isEmpty) ...[
          _whatThisProjectIsFor(widget.strategy!),
          const SizedBox(height: AsaSpace.xs),
        ],
        for (final area in widget.areas) _areaSummaryRow(area),
        _notInAnAreaRow(),
        const SizedBox(height: AsaSpace.lg),
        _overviewRow(),
      ],
    );
  }

  Widget _addAreaEntry() => LinkChip('+ Add area', onTap: _showAddAreaDialog);

  Future<void> _showAddAreaDialog() async {
    final controller = TextEditingController();
    String? error;

    final created = await showDialog<AreaCreateResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add area'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Name'),
                    onSubmitted: (_) async {
                      final result = await widget.onCreateArea!(
                        controller.text,
                      );
                      if (result.isSuccess) {
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(result);
                        }
                      } else {
                        setDialogState(() => error = result.error);
                      }
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AsaSpace.xs),
                    Text(
                      error!,
                      style: AsaText.meta.copyWith(
                        color: AsaMeaning.needsYou.fg,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await widget.onCreateArea!(controller.text);
                    if (result.isSuccess) {
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(result);
                      }
                    } else {
                      setDialogState(() => error = result.error);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != null && created.isSuccess) {
      widget.onSelectAreaTab?.call(created.sourceFile);
      widget.onDataChanged?.call();
    }
  }

  /// Round 27's own screen, unchanged — a project with a `PLAN.md` but no
  /// `plan\` folder never sees anything Round 34 added. Asa itself no
  /// longer takes this path (it gained a real `plan\` folder alongside
  /// its own `PLAN.md`, round-38.md §D's own "done by the deciding
  /// session" note) — this stays as the general fallback for any other
  /// project still in that shape.
  Widget _legacyBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('What changed'),
        const SizedBox(height: AsaSpace.xs),
        _whatChanged(),
        const SizedBox(height: AsaSpace.xl),
        const SectionLabel('The plan'),
        const SizedBox(height: AsaSpace.xs),
        ..._outline(),
        const SizedBox(height: AsaSpace.lg),
        _strategyPointer(),
      ],
    );
  }

  /// Round 36 cp8, §9 point 1 — a project with neither `PLAN.md` nor
  /// `plan\`: no areas, no legacy roadmap, nothing invented to fill the
  /// gap. Why the project exists if that's known (the Next line above it
  /// is now the header's own, Round 38 §A), its own home tasks (the only
  /// row here, open by default), and one honest pointer to how it would
  /// grow areas at all — never a button that writes anything itself,
  /// matching ADR 0021's own read-only rule.
  Widget _noPlanBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.strategy != null && !widget.strategy!.isEmpty) ...[
          _whatThisProjectIsFor(widget.strategy!),
          const SizedBox(height: AsaSpace.xs),
        ],
        _notInAnAreaRow(),
        const SizedBox(height: AsaSpace.md),
        const EmptyLine(
          'No areas yet. To split this project into areas: Start → Copy '
          'opener, and ask the AI.',
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
        padding: const EdgeInsets.symmetric(
          vertical: AsaSpace.sm,
          horizontal: AsaSpace.md,
        ),
        decoration: const BoxDecoration(
          color: AsaColors.ground,
          border: Border(
            bottom: BorderSide(color: AsaColors.soft),
            left: BorderSide(color: AsaColors.ink3, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AsaText.body.copyWith(color: AsaColors.ink2),
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
            const SizedBox(width: AsaSpace.sm),
            LinkChip('Strategy →', onTap: widget.onOpenStrategy),
          ],
        ),
      ),
    );
  }

  // --- One area's row, in "All" ------------------------------------------

  /// Round 38 §B — "All is the list … one row per area … a row opens its
  /// area's tab": a plain summary row, no expand/collapse of its own any
  /// more (that whole page is now the area's own tab, [_areaDetail]).
  Widget _areaSummaryRow(Area area) {
    return InkWell(
      onTap: () => widget.onSelectAreaTab?.call(area.sourceFile),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AsaSpace.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AsaColors.soft)),
        ),
        // One row, per both approved sketches (asa-plan-v5,
        // asa-project-page-v1) — round-35/G's own persona-check worry
        // (density) is about a row's *height*, not about spreading one
        // row's own fields across several lines.
        child: Row(
          children: [
            Text(area.name, style: AsaText.rowName),
            const SizedBox(width: AsaSpace.sm),
            Expanded(
              child: Text(
                _areaNextTaskLabel(area),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: AsaText.meta.copyWith(
                  color: _areaHasOpenTask(area)
                      ? AsaColors.ink2
                      : AsaColors.ink3,
                  fontStyle: _areaHasOpenTask(area)
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: AsaSpace.sm),
            Text(_resultLabel(area), style: AsaText.meta),
            const SizedBox(width: AsaSpace.sm),
            SizedBox(
              width: 90,
              child: ProgressBar(segments: [_areaFraction(area)]),
            ),
            const SizedBox(width: AsaSpace.sm),
            SizedBox(
              width: 32,
              child: Text(
                '${area.doneCount} / ${area.totalCount}',
                textAlign: TextAlign.right,
                style: AsaText.meta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _areaFraction(Area area) =>
      area.totalCount == 0 ? 0.0 : area.doneCount / area.totalCount;

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

  /// Round 38 §B — a brand new area (nothing in any of its five parts)
  /// shows one honest line instead of five separate "No X yet"s: *"Empty
  /// so far. To fill it: Start → Copy opener, and tell the AI what this
  /// area is for."* Not only for the moment right after creation — any
  /// area this empty gets the same message, since it is a fact about the
  /// file, not a one-time flag this widget would have to remember.
  bool _isAreaEmpty(Area area) =>
      (area.goal == null || area.goal!.isEmpty) &&
      (area.planText == null || area.planText!.isEmpty) &&
      area.tasks.isEmpty &&
      area.results.isEmpty &&
      area.decisionNumbers.isEmpty;

  Widget _areaDetail(Area area) {
    if (_isAreaEmpty(area)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmptyLine(
            'Empty so far. To fill it: Start → Copy opener, and tell the '
            'AI what this area is for.',
          ),
          const SizedBox(height: AsaSpace.xs),
          LinkChip('open the page ↗', onTap: () => openUrl(area.sourceFile)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _goalField(area),
        _textField('Plan', area.planText, empty: 'No plan yet', area: area),
        _tasksField(area.tasks, sourceFile: area.sourceFile),
        _resultsField(area.results, sourceFile: area.sourceFile),
        _decisionsField(area.decisionNumbers),
        const SizedBox(height: AsaSpace.xs),
        LinkChip('open the page ↗', onTap: () => openUrl(area.sourceFile)),
      ],
    );
  }

  Widget _textField(
    String label,
    String? value, {
    required String empty,
    Area? area,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 2),
          _sectionField(
            area,
            label,
            value,
            empty,
            (text) => Text(text, style: AsaText.body),
          ),
        ],
      ),
    );
  }

  /// Round 43 §D — one area section (`## Goal`/`## Plan`), in whichever of
  /// its three states applies: empty (heading and ＋ only), read (filled,
  /// ✎ revealed on hover once a writer is wired in), or being typed
  /// (either the ＋ just opened it, or ✎ did, pre-filled with the current
  /// text). [renderFilled] draws the read state's own text — [_goalField]
  /// passes one that turns "Objective N" into its own link, [_textField]
  /// passes plain text.
  Widget _sectionField(
    Area? area,
    String heading,
    String? rawValue,
    String emptyText,
    Widget Function(String displayText) renderFilled,
  ) {
    final write = widget.onSetAreaSection;
    final key = area == null ? null : '${area.sourceFile}\u0000$heading';
    final hasValue = rawValue != null && rawValue.isNotEmpty;

    if (area != null && write != null && _addingSectionKey == key) {
      Future<void> submit() async {
        final text = _sectionController.text.trim();
        setState(() => _addingSectionKey = null);
        if (text.isEmpty || text == rawValue) return;
        await write(area.sourceFile, heading, rawValue ?? '', text);
        widget.onDataChanged?.call();
      }

      final clear = widget.onClearAreaSection;
      final field = EscapeToCancel(
        onEscape: () => setState(() => _addingSectionKey = null),
        child: TextField(
          controller: _sectionController,
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => submit(),
        ),
      );
      // Round 43 §D — 🗑 only once there is something to remove: the ＋
      // path opens this same editing branch from empty, and clearing
      // something that was never there would write nothing meaningful.
      if (!hasValue || clear == null) return field;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field),
          Tooltip(
            message: 'remove',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                setState(() => _addingSectionKey = null);
                await clear(area.sourceFile, heading);
                widget.onDataChanged?.call();
              },
            ),
          ),
        ],
      );
    }

    if (!hasValue) {
      if (area == null || write == null) return EmptyLine(emptyText);
      return Tooltip(
        message: 'add',
        child: InkWell(
          onTap: () => setState(() {
            _addingSectionKey = key;
            _sectionController.clear();
          }),
          child: Text('＋', style: AsaText.body.copyWith(color: AsaColors.blue)),
        ),
      );
    }

    final displayText = stripCodeSpanMarkers(stripEmphasisMarkers(rawValue));
    final content = renderFilled(displayText);
    if (area == null || write == null) return content;

    return HoverPencil(
      onEdit: () => setState(() {
        _addingSectionKey = key;
        _sectionController.text = rawValue;
      }),
      child: content,
    );
  }

  /// Round-36 §3, L12 — same shape as [_textField]; tapping the objective
  /// switches to Strategy with that objective expanded.
  ///
  /// Round-37 §D4, answered by the deciding session 2026-09-27 19:36 (the
  /// question this file itself had flagged): the objective shows once —
  /// the words "Objective N" inside the Goal sentence become the link
  /// itself (blue text, ADR 0029's "you can click it"), never a separate
  /// chip repeating the same words below it. "Serves Objective 1." reads
  /// as one sentence with one link; nothing is removed and nothing shows
  /// twice.
  Widget _goalField(Area area) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Goal'),
          const SizedBox(height: 2),
          _sectionField(
            area,
            'Goal',
            area.goal,
            'No goal yet',
            (text) => _goalText(text, area.objectiveNumbers),
          ),
        ],
      ),
    );
  }

  static final RegExp _objectiveMention = RegExp(
    r'Objective\s*(\d+)',
    caseSensitive: false,
  );

  /// The Goal sentence, with every "Objective N" mention inside it turned
  /// into the link itself — round-37 §D4 — but only when [objectiveNumbers]
  /// (parsed by `area.dart`'s own scoping rule) actually names that number;
  /// a textual coincidence that isn't a real, recognised objective mention
  /// stays plain text, same as before this round. Plain text throughout
  /// when nothing matches.
  Widget _goalText(String text, List<String> objectiveNumbers) {
    final matches = _objectiveMention.allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: AsaText.body);

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final number = match.group(1)!;
      if (objectiveNumbers.contains(number)) {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: const TextStyle(color: AsaColors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () => widget.onOpenObjective?.call(number),
          ),
        );
      } else {
        spans.add(TextSpan(text: match.group(0)));
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: AsaText.body, children: spans));
  }

  Widget _tasksField(List<Task> tasks, {required String sourceFile}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Tasks'),
          const SizedBox(height: 2),
          _taskListBody(tasks, sourceFile: sourceFile),
        ],
      ),
    );
  }

  /// The task rows themselves, with no section heading of their own — so
  /// [_notInAnAreaRow] can drop them straight under its own header without
  /// a second, redundant "Tasks" label. Round 38 §F — done tasks fold into
  /// "✓ N done · show ›", same shape `tasks_view.dart`'s own "Show
  /// completed" already uses on the front page.
  Widget _taskListBody(List<Task> tasks, {required String sourceFile}) {
    if (tasks.isEmpty) return const EmptyLine('Nothing yet');

    // Round 37 cp6, §D6 item 5 — the same first-open-unparked-task rule
    // `_areaNextTaskLabel` already uses for the closed row's own summary;
    // an opened area's task list gets the same "next" pill the sketch
    // draws, not just that closed-row text.
    final nextEligible = tasks.where((t) => !t.done && !t.parked);
    final nextTask = nextEligible.isEmpty ? null : nextEligible.first.rawLine;
    final doneCount = tasks.where((t) => t.done).length;
    final expanded = _doneTasksShown.contains(sourceFile);
    // Original file order either way — folding removes rows, it never
    // reorders them, so a task's own position never jumps out from under
    // whichever row was just tapped.
    final visibleTasks = expanded
        ? tasks
        : tasks.where((t) => !t.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in visibleTasks)
          _taskRow(
            task,
            sourceFile: sourceFile,
            isNext: task.rawLine == nextTask,
          ),
        if (doneCount > 0)
          _foldLink(
            expanded: expanded,
            collapsedLabel: '✓ $doneCount done',
            onTap: () => setState(() {
              if (expanded) {
                _doneTasksShown.remove(sourceFile);
              } else {
                _doneTasksShown.add(sourceFile);
              }
            }),
          ),
      ],
    );
  }

  Widget _taskRow(
    Task task, {
    required String sourceFile,
    bool isNext = false,
  }) {
    final canToggle = widget.onToggleTask != null;
    return TaskRow(
      text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
      done: task.done,
      isNext: isNext,
      highlighted: _highlightedRawLine == task.rawLine,
      onToggle: canToggle
          ? (_) {
              // Round 38 §F — a task ticked just now must not vanish out
              // from under the tap that ticked it; auto-reveal this list's
              // own fold rather than let the newly-done row fold away
              // before the reload even lands.
              setState(() => _doneTasksShown.add(sourceFile));
              widget.onToggleTask!(sourceFile, task);
            }
          : null,
    );
  }

  /// Round 38 §F — "show ›" once folded, "Hide" once expanded, same wording
  /// `tasks_view.dart`'s own "Show completed"/"Hide completed" already
  /// uses for the identical done-tasks fold on the front page.
  Widget _foldLink({
    required bool expanded,
    required String collapsedLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Text.rich(
          TextSpan(
            children: [
              if (!expanded)
                TextSpan(text: '$collapsedLabel  ', style: AsaText.meta),
              TextSpan(
                text: expanded ? 'Hide' : 'show ›',
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

  Widget _resultsField(List<AreaResult> results, {required String sourceFile}) {
    final expanded = _olderResultsShown.contains(sourceFile);
    final visible = expanded ? results : results.take(2).toList();
    final olderCount = results.length - 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Results'),
          const SizedBox(height: 2),
          if (results.isEmpty)
            const EmptyLine('Nothing yet')
          else ...[
            for (final result in visible)
              _resultRow(result, sourceFile: sourceFile),
            if (olderCount > 0)
              _foldLink(
                expanded: expanded,
                collapsedLabel: '$olderCount older',
                onTap: () => setState(() {
                  if (expanded) {
                    _olderResultsShown.remove(sourceFile);
                  } else {
                    _olderResultsShown.add(sourceFile);
                  }
                }),
              ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(AreaResult result, {required String sourceFile}) {
    final write = widget.onEditResultText;
    // Undated (a verbatim pre-this-app line) has no key: editResultText
    // always writes a dated line, and there is no way to ask it to leave
    // a result undated — editing one would silently stamp today's date
    // onto a line that never had one. Left read-only rather than that.
    final key = (result.rawLine == null || result.date == null)
        ? null
        : '$sourceFile\u0000result\u0000${result.rawLine}';
    final editing = key != null && _addingSectionKey == key;

    Widget dateLabel() => result.date == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(right: AsaSpace.xs),
            child: SizedBox(
              width: 60,
              child: Text(
                _humanDate(result.date!),
                style: AsaText.meta.copyWith(
                  fontFamily: 'monospace',
                  color: AsaColors.ink2,
                ),
              ),
            ),
          );

    if (editing) {
      Future<void> submit() async {
        final text = _sectionController.text.trim();
        setState(() => _addingSectionKey = null);
        if (text.isEmpty || text == result.text) return;
        await write!(sourceFile, result, text);
        widget.onDataChanged?.call();
      }

      final remove = widget.onRemoveResultText;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dateLabel(),
            Expanded(
              child: EscapeToCancel(
                onEscape: () => setState(() => _addingSectionKey = null),
                child: TextField(
                  controller: _sectionController,
                  autofocus: true,
                  decoration: const InputDecoration(isDense: true),
                  onSubmitted: (_) => submit(),
                ),
              ),
            ),
            if (remove != null)
              Tooltip(
                message: 'remove',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    setState(() => _addingSectionKey = null);
                    await remove(sourceFile, result);
                    widget.onDataChanged?.call();
                  },
                ),
              ),
          ],
        ),
      );
    }

    final content = Text(result.text, style: AsaText.body);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dateLabel(),
          Expanded(
            child: (write == null || key == null)
                ? content
                : HoverPencil(
                    onEdit: () => setState(() {
                      _addingSectionKey = key;
                      _sectionController.text = result.text;
                    }),
                    child: content,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _decisionsField(List<String> decisionNumbers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Decisions'),
          const SizedBox(height: 2),
          if (decisionNumbers.isEmpty)
            const EmptyLine('None yet')
          else
            Wrap(
              spacing: AsaSpace.sm,
              runSpacing: AsaSpace.xs,
              children: [
                for (final number in decisionNumbers) _adrChip(number),
              ],
            ),
        ],
      ),
    );
  }

  /// Round-37 §D3 — "both show both": the number with the (loaded)
  /// decision's own title, shortened; the bare "ADR N" when it is not
  /// loaded, same fallback `_openDecision` itself uses.
  Widget _adrChip(String number) {
    final decision = _decisionFor(number);
    final label = decision == null
        ? 'ADR $number'
        : decisionChipLabel(decision.number, decision.title);
    return LinkChip(label, onTap: () => _openDecision(number));
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
            areasNaming: areasNamingDecision(decision, widget.areas),
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

  String _decisionSourceFor(String number) {
    for (final result in widget.decisions) {
      if (result.decision?.number == number) return result.decision!.sourceFile;
    }
    return widget.projectSourceFile;
  }

  // --- Not in an area ----------------------------------------------------

  Widget _notInAnAreaRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AsaSpace.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AsaColors.soft)),
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
                  color: AsaColors.ink3,
                ),
                const SizedBox(width: AsaSpace.xs),
                const Text('Not in an area', style: AsaText.rowName),
                const SizedBox(width: AsaSpace.sm),
                Text(
                  '${widget.homeTasks.where((t) => !t.done).length} open',
                  style: AsaText.meta,
                ),
              ],
            ),
          ),
          if (_notInAnAreaExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: AsaSpace.xs),
              child: _taskListBody(
                widget.homeTasks,
                sourceFile: widget.projectSourceFile,
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
                color: AsaColors.ink3,
              ),
              const SizedBox(width: AsaSpace.xs),
              const Text('Overview', style: AsaText.rowName),
              const SizedBox(width: AsaSpace.sm),
              Text(summary, style: AsaText.meta),
            ],
          ),
        ),
        if (_overviewExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: AsaSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('What changed'),
                const SizedBox(height: AsaSpace.xs),
                _whatChanged(),
                const SizedBox(height: AsaSpace.lg),
                const SectionLabel('The plan'),
                const SizedBox(height: AsaSpace.xs),
                ..._outline(),
              ],
            ),
          ),
      ],
    );
  }

  // --- What changed --------------------------------------------------

  Widget _whatChanged() {
    final entries = _changeEntries(widget.plan);
    if (entries.isEmpty) {
      return const EmptyLine('Nothing dated yet.');
    }

    final shown = _olderChangesShown ? entries : entries.take(3).toList();
    final olderCount = entries.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in shown) _changeRow(entry),
        if (olderCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AsaSpace.xs),
            child: LinkChip(
              'older ($olderCount) ↓',
              onTap: () => setState(() => _olderChangesShown = true),
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
        padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs + 3),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AsaColors.soft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                _humanDate(entry.date),
                style: AsaText.meta.copyWith(
                  fontFamily: 'monospace',
                  color: AsaColors.ink2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry.text.isEmpty ? '(untitled)' : entry.text,
                style: AsaText.body,
              ),
            ),
            const SizedBox(width: AsaSpace.sm),
            Wrap(
              spacing: AsaSpace.xs,
              runSpacing: AsaSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Round 37 cp6 — the deciding session's own cp4 finding:
                // consecutive Round chips read as one run-on phrase with
                // only a bare space between them. The same visible " · "
                // separator the ADR chips already carry inside their own
                // label, between chips here instead.
                for (var i = 0; i < shownLinks.length; i++) ...[
                  if (i > 0) const Text('·', style: AsaText.meta),
                  _linkChip(shownLinks[i]),
                ],
                if (hiddenCount > 0)
                  Tooltip(
                    message: links
                        .skip(_maxChipsShown)
                        .map((l) => l.sentence)
                        .join('\n'),
                    child: Text('+$hiddenCount', style: AsaText.meta),
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
    final label = _linkChipLabel(link);
    return Tooltip(
      message: link.sentence,
      child: LinkChip(label, onTap: () => openUrl(_targetFor(link))),
    );
  }

  /// Round-37 §D3 — both show both: the loaded decision's own title with
  /// its number, not just "ADR N"; a bare "ADR N" fallback when it is not
  /// loaded, same as [_adrChip].
  String _linkChipLabel(PlanLink link) {
    if (link.kind != PlanLinkKind.adr) return 'Round ${link.target}';
    final decision = _decisionFor(link.target);
    return decision == null
        ? 'ADR ${link.target}'
        : decisionChipLabel(decision.number, decision.title);
  }

  /// The real decision file for an ADR chip, when one is already loaded;
  /// the project's own note (never `PLAN.md`) for a Round chip, or for an
  /// ADR number that does not match anything in [PlanView.decisions] —
  /// still a real, more specific file than the plan, never a dead tap.
  String _targetFor(PlanLink link) {
    if (link.kind == PlanLinkKind.adr) {
      final decision = _decisionFor(link.target);
      if (decision != null) return decision.sourceFile;
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
        padding: const EdgeInsets.only(top: AsaSpace.xs),
        child: LinkChip(
          '+ $more more, collapsed ↓',
          onTap: () => setState(() => _moreGroupsShown = true),
        ),
      ),
    );
    return shown;
  }

  Widget _pageGroup(PlanPage page, List<_SectionNode> roots) {
    final id = identityHashCode(page);
    final collapsed = !_expanded.contains(id);
    return _toggleGroup(
      label: titleCaseFirst(page.aspect!),
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
                          color: AsaColors.ink3,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(label, style: AsaText.body),
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
      padding: const EdgeInsets.symmetric(vertical: AsaSpace.sm),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AsaColors.soft)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'The two non-negotiable gates live one tab over',
              style: AsaText.meta,
            ),
          ),
          LinkChip('Strategy →', onTap: widget.onOpenStrategy),
        ],
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
