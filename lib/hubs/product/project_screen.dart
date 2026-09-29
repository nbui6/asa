/// Product Hub — one project's state, in detail.
///
/// Built 2026-09-04 to match the approved sketch, `asa-v01b.png`: a quiet
/// typographic list — no Material AppBar, no cards, no uppercase tabs. The
/// provenance block stays, collapsed behind one line — it is the best
/// thing in this codebase, not deleted, not moved. The one-line
/// description under the project name landed the same day, once
/// `project_reader.dart` could expose it.
///
/// **2026-09-13 — Round 20, the five whitelisted fields become editable.**
/// Found while building this: the spec said all five (`parent`, `status`,
/// `priority`, `deadline`, `jira`) were "already shown" here — only
/// `status` was; the other four render on `ProjectsView`'s row instead,
/// and `parent` was not displayed anywhere at all. Asked the user directly
/// rather than guess; his answer: add the missing four as plain rows
/// here too, then make all five editable in this one place. `status`
/// gets a picker over ADR 0017's own six-value enum (hardcoded here —
/// nothing in code defined it yet either) rather than free text, so a
/// typo can't create a new, invisible status; the other four are a plain
/// text field. Saving goes through `project_writer.dart`'s
/// `setProjectField`, then re-reads the whole project from disk — the
/// file is the source of truth, never the in-memory typed value.
///
/// **Round 37 (ADR 0029)** moves this screen onto `AsaPage` and the
/// shared `ui/` parts. Two behaviour changes went with it, both named in
/// the round's own §D2/§D6, not incidental: every project now always
/// shows all four tabs (an empty one explains why and what to do,
/// instead of hiding), and the Details tab's five fields display as the
/// same chip/pill/formatted-date styles the rest of the app already uses
/// for the same data, not their own raw text.
library;

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/area_writer.dart';
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/log_entries.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_reader.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_writer.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_call_writer.dart';
import 'package:asa/core/round_file.dart';
import 'package:asa/core/round_state.dart';
import 'package:asa/core/status_words.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/task_writer.dart';
import 'package:asa/hubs/product/log_view.dart';
import 'package:asa/hubs/product/plan_view.dart';
import 'package:asa/hubs/product/start_menu.dart';
import 'package:asa/hubs/product/strategy_view.dart';
import 'package:asa/hubs/product/ui/area_chip.dart';
import 'package:asa/hubs/product/ui/asa_page.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/source_line.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Round 16 ordered this `Strategy · Plan · Decisions · Details`; round-36
/// §2 a reorders it again, this time to `Plan · Strategy · Decisions ·
/// Details`, and a project now opens on Plan — `asa-project-page-v1`,
/// approved 2026-09-26. Round 37 §D2 — every one of these four always
/// shows, in this order, on every project; an empty one says why and what
/// to do instead of disappearing.
enum _Tab { plan, strategy, log, details }

/// ADR 0041's own seven values, in the order the ADR states them — the
/// field writer writes only these; an old word (`building`, `paused`,
/// `shipped`, `dropped`) is never written again once a project's status
/// is next saved through this picker.
final _statusValues = [for (final word in statusWords) word.stored];

/// ADR 0041's *Means* column, keyed by the stored word — the picker's own
/// grey hint, so *In progress* and *Ongoing* can't be mixed up.
final _statusMeans = {for (final word in statusWords) word.stored: word.means};

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({
    required this.folder,
    this.writeLogPath,
    this.onOpenTasks,
    this.initialAreaToOpen,
    this.initialOpenHome = false,
    this.initialHighlightRawLine,
    this.initialOpenLog = false,
    super.key,
  });

  final String folder;

  /// Overrides where a field edit's write is logged. Production never
  /// sets this — it exists so a test can save through the real
  /// `setProjectField` without touching `%APPDATA%\Asa\write-log.jsonl`.
  final String? writeLogPath;

  /// Round 27's navigation fix — the user: *"we should still be able to
  /// navigate there, with the tasks of this project on top for easy
  /// work."* Null in a test that does not need it. In the real app this
  /// pops back to `ProjectsScreen` and switches it to the Tasks view with
  /// this project's name — the only host `TasksView` has, traced rather
  /// than assumed.
  final void Function(String projectName)? onOpenTasks;

  /// Round-36 §3, L2/L6 — a caller (the overview, the Tasks view) that
  /// wants this one area open the moment this screen's Plan tab first
  /// shows, from `ProjectOpenTarget.areaSourceFile`. Null for a plain
  /// open, landing wherever Plan already opens by default.
  final String? initialAreaToOpen;

  /// Round-36 §3, L3 — same as [initialAreaToOpen], for "Not in an area"
  /// instead, from `ProjectOpenTarget.openHome`.
  final bool initialOpenHome;

  /// Round 38 §E — the overview's own *Needs you* card and per-row
  /// markers land here, from `ProjectOpenTarget.openLog`, so tapping one
  /// opens straight onto the Log tab rather than wherever the project
  /// screen opens by default.
  final bool initialOpenLog;

  /// Round-36 §3, L3/L9 — the exact task row to briefly highlight once
  /// the Plan tab first shows, from `ProjectOpenTarget.highlightRawLine`.
  final String? initialHighlightRawLine;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectReadResult? _read;
  GitState? _git;
  List<DecisionReadResult>? _decisions;
  Plan? _plan;
  List<Area> _areas = const [];
  List<LogEntry> _logEntries = const [];

  /// Round 34/D — an area chip on a decision row sets this, then switches
  /// to the Plan tab. Round 38 §B — this is now the area *tab* strip's own
  /// selection ("the selected area is remembered per project while the
  /// app runs"), owned here rather than inside `PlanView` because that
  /// widget is torn down and rebuilt on every switch away from and back
  /// to the Plan tab. `null` means "All".
  String? _selectedAreaTab;

  /// Round-36 §3, L12 — an area's Objective chip on the Plan tab sets
  /// this, then switches to the Strategy tab; `StrategyView` opens that
  /// one objective on the next build. Sticky, same reasoning as
  /// `_selectedAreaTab`.
  String? _objectiveToOpen;
  Strategy? _strategy;
  RoundApprovals _approvals = const RoundApprovals({});
  bool _loading = true;
  _Tab _activeTab = _Tab.plan;
  bool _provenanceExpanded = false;

  /// Round 38 §A — the header's own Next line hoists `PlanView`'s old
  /// `_nextLineRow`, so it shows above every tab, not only Plan. Tapping
  /// it still has to land on the right area (or "Not in an area") and
  /// highlight the right task, the same as before the hoist — these two
  /// carry that into a freshly built `PlanView` exactly like
  /// `_selectedAreaTab` already does for the decision-row-area-chip case.
  bool _openHomeNow = false;
  String? _highlightRawLine;

  // Editing one of the five whitelisted fields — Round 20. Only one field
  // is ever mid-edit at a time; starting a new one silently drops any
  // other in-progress edit, since nothing unsaved is lost by that (the
  // file itself is untouched until Save).
  String? _editingField;
  final _editController = TextEditingController();

  /// Round 38 §G — `deadline` alone edits as *from* and *to* months
  /// (`asa-tasks-v3` §1); every other field still uses `_editController`
  /// on its own, and this stays blank for them.
  final _editControllerTo = TextEditingController();
  String? _editError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedAreaTab = widget.initialAreaToOpen;
    if (widget.initialOpenLog) _activeTab = _Tab.log;
    _load();
  }

  @override
  void dispose() {
    _editController.dispose();
    _editControllerTo.dispose();
    super.dispose();
  }

  void _startEdit(String field, String currentValue) {
    setState(() {
      _editingField = field;
      if (field == 'deadline') {
        final parts = currentValue.split('/');
        _editController.text = parts.isNotEmpty ? parts[0] : '';
        _editControllerTo.text = parts.length > 1 ? parts[1] : '';
      } else {
        _editController.text = currentValue;
        _editControllerTo.text = '';
      }
      _editError = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingField = null;
      _editError = null;
    });
  }

  /// Round 38 §G — the *from* and *to* months, joined into the one raw
  /// shape `project_writer.dart` already knows how to write: `YYYY-MM`
  /// alone when *to* is blank, `YYYY-MM/YYYY-MM` when both are given.
  String _composedDeadline() {
    final from = _editController.text.trim();
    final to = _editControllerTo.text.trim();
    if (from.isEmpty) return '';
    return to.isEmpty ? from : '$from/$to';
  }

  Future<void> _saveEdit(String field) async {
    final read = _read;
    if (read == null || !read.isSuccess) return;

    final value = field == 'deadline'
        ? _composedDeadline()
        : _editController.text.trim();

    setState(() {
      _saving = true;
      _editError = null;
    });

    try {
      await setProjectField(
        read.project!.sourceFile,
        field: field,
        value: value,
        expectedFrontmatter: read.rawFrontmatter,
        writeLogPath: widget.writeLogPath,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editError = 'Could not save: $e';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _editingField = null;
      _saving = false;
    });
    await _load();
  }

  /// Round 34/F, the narrow amendment to ADR 0021 (2026-09-26): Asa may
  /// change checkbox state only, `[ ]` ↔ `[x]`, in a `plan\*.md` page's own
  /// `## Tasks` — reusing `task_writer.dart`'s existing `setTaskDone`
  /// unchanged, the same writer and the same write log every other
  /// checkbox in this app already goes through. [sourceFile] is either an
  /// area's own file or the project's home note ("Not in an area") —
  /// `setTaskDone` does not care which, it matches the exact line either
  /// way.
  Future<void> _toggleAreaOrHomeTask(String sourceFile, Task task) async {
    await setTaskDone(
      sourceFile,
      rawLine: task.rawLine,
      done: !task.done,
      writeLogPath: widget.writeLogPath,
    );
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final read = await readProject(widget.folder);
    GitState? git;
    if (read.isSuccess) {
      git = await readGitState(read.project!.repoPath);
    }
    final decisions = sortDecisionsNewestFirst(
      await readAllDecisions(widget.folder, const DiskFileAccess()),
    );
    final plan = await readPlan(widget.folder);
    final areas = await readAreas(widget.folder);
    final strategy = await readCharter(widget.folder);
    final approvals = await readRoundApprovals(
      widget.folder,
      const DiskFileAccess(),
    );
    final logEntries = await readLogEntries(
      widget.folder,
      const DiskFileAccess(),
    );

    if (!mounted) return;
    setState(() {
      _read = read;
      _git = git;
      _decisions = decisions;
      _plan = plan;
      _areas = areas;
      _strategy = strategy;
      _approvals = approvals;
      _logEntries = logEntries;
      _loading = false;
    });
  }

  /// Round 37 §D2 — always all four; Round 38 §A reorders them
  /// `Strategy · Plan · Decisions · Details` (the user, testing Round
  /// 36/37: *"Strategy should come before Plan"*), but a project still
  /// **opens** on Plan (`asa-project-page-v1`'s rule: you land on the
  /// work — see `_activeTab`'s own initial value). A tab with nothing to
  /// show yet still shows, explaining why and what to do, rather than
  /// disappearing (`_tabBody`'s own empty-state bodies).
  static const _tabs = [_Tab.strategy, _Tab.plan, _Tab.log, _Tab.details];

  @override
  Widget build(BuildContext context) {
    final read = _read;

    return AsaPage(
      name: read != null && read.isSuccess ? read.project!.name : 'Project',
      onBack: () => Navigator.of(context).maybePop(),
      actions: _pageActions(read),
      // Round 36 cp6 — found by the click-through test: gating this whole
      // block on `!_loading` unmounted PlanView (and every other tab
      // body) on *every* reload, including the one
      // `_toggleAreaOrHomeTask` triggers after a plain checkbox tick —
      // undoing, at this level, the exact thing `_areaRow`'s own
      // sourceFile-keying was built to prevent. `read` alone is the
      // right gate: it holds the previous read until the new one lands,
      // so the body stays mounted and in place through a reload; only
      // the very first load, before any `read` exists yet, shows
      // "Loading…".
      body: read == null
          ? const Text('Loading…', style: AsaText.body)
          : _body(read),
    );
  }

  List<Widget> _pageActions(ProjectReadResult? read) {
    final canOpenTasks =
        widget.onOpenTasks != null && read != null && read.isSuccess;
    return [
      if (read != null && read.isSuccess)
        StartMenu(
          projectName: read.project!.name,
          projectFolder: widget.folder,
          repoPath: read.project!.repoPath,
        ),
      // Round 27: "one button, not a fourth real tab" — styled distinctly
      // (the sketch's small ↗ glyph) so it reads as leaving this screen,
      // which it does: it pops back to the front page.
      if (canOpenTasks)
        TextButton.icon(
          onPressed: () => widget.onOpenTasks!(read.project!.name),
          icon: const Icon(Icons.north_east, size: 14),
          label: const Text('Tasks'),
          style: TextButton.styleFrom(
            foregroundColor: AsaColors.ink2,
            visualDensity: VisualDensity.compact,
          ),
        ),
      IconButton(
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh, size: 20),
        color: AsaColors.ink2,
        visualDensity: VisualDensity.compact,
        tooltip: 'Reload',
      ),
    ];
  }

  Widget _body(ProjectReadResult read) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (read.isSuccess && read.project!.description != null) ...[
          Text(
            stripCodeSpanMarkers(
              stripEmphasisMarkers(read.project!.description!),
            ),
            style: AsaText.body.copyWith(color: AsaColors.ink2),
          ),
          const SizedBox(height: AsaSpace.md),
        ],
        if (read.isSuccess) ...[
          _headerNextLine(read),
          const SizedBox(height: AsaSpace.md),
        ],
        _tabRow(),
        const SizedBox(height: AsaSpace.xs),
        const Divider(height: 1, color: AsaColors.soft),
        const SizedBox(height: AsaSpace.sm),
        _tabBody(read),
        const SizedBox(height: AsaSpace.xl),
        _provenanceSection(read),
      ],
    );
  }

  /// Plain text, a 2 px underline on the active one — no uppercase, no
  /// full-width band. Every label uses the same, always-bold weight
  /// ([AsaText.rowName]) regardless of which is active, so becoming
  /// active never widens a label and shifts its neighbours — round-37
  /// §D2's "reserve width"; only the colour and the underline change.
  /// Round 38 §E — "the tab shows a dot, not a count, when something
  /// needs [the user]" (§A's own amber count goes once this exists): a
  /// proposed decision, or a round waiting for approval — the same two
  /// sources `LogView`'s own *Needs your yes* panel cycles through.
  bool get _logNeedsYou {
    final hasProposedDecision = (_decisions ?? const []).any(
      (r) => r.decision?.isProposed ?? false,
    );
    if (hasProposedDecision) return true;
    final roadmap = (_read?.isSuccess ?? false)
        ? _read!.project!.roadmap
        : const <Milestone>[];
    return roadmap.any(
      (m) => roundStateOf(m, _approvals) == RoundState.waitingForApproval,
    );
  }

  Widget _tabRow() {
    const labels = {
      _Tab.plan: 'Plan',
      _Tab.strategy: 'Strategy',
      _Tab.log: 'Log',
      _Tab.details: 'Details',
    };
    return Row(
      children: [
        for (final tab in _tabs) ...[
          if (tab != _tabs.first) const SizedBox(width: AsaSpace.xl),
          _tabLabel(
            labels[tab]!,
            tab,
            showDot: tab == _Tab.log && _logNeedsYou,
          ),
        ],
      ],
    );
  }

  Widget _tabLabel(String label, _Tab tab, {bool showDot = false}) {
    final active = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.only(bottom: AsaSpace.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AsaColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AsaText.rowName.copyWith(
                color: active ? AsaColors.ink : AsaColors.ink3,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: AsaSpace.xs),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AsaColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Round 38 §A — the Next line, hoisted out of `PlanView` into the
  /// header so it shows above every tab, not only Plan. Same visual
  /// shape and same `effectiveNextStepWithArea` chain `PlanView`'s old
  /// `_nextLineRow` used; tapping it switches to Plan and tells the next
  /// `PlanView` which area (or "Not in an area") and task to open.
  Widget _headerNextLine(ProjectReadResult read) {
    final result = effectiveNextStepWithArea(
      read.project!.tasks,
      read.project!.nextStep,
      areas: _areas,
    );
    final text = result.text;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AsaSpace.md,
        vertical: AsaSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AsaColors.panel,
        border: Border.all(color: AsaColors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: text == null
                  ? null
                  : () => _openNextFromHeader(result.area, result.task),
              child: Row(
                children: [
                  const SectionLabel('Next'),
                  const SizedBox(width: AsaSpace.sm),
                  Expanded(
                    child: Text(
                      text ?? 'No next step',
                      style: AsaText.rowName.copyWith(
                        fontStyle: text == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: text == null ? AsaColors.ink3 : AsaColors.ink,
                      ),
                    ),
                  ),
                  if (result.area != null) ...[
                    const SizedBox(width: AsaSpace.sm),
                    AreaChip(result.area!.name),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AsaSpace.md),
          StartMenu(
            projectName: read.project!.name,
            projectFolder: widget.folder,
            repoPath: read.project!.repoPath,
            nextTaskText: result.task != null ? text : null,
            areaSourceFile: result.area?.sourceFile,
          ),
        ],
      ),
    );
  }

  void _openNextFromHeader(Area? area, Task? task) {
    setState(() {
      _activeTab = _Tab.plan;
      if (area == null) {
        _openHomeNow = true;
        // Round 38 §B — "Not in an area" only lives inside "All"; a home
        // task's own Next line must not leave some other area's tab
        // selected, or that row would be invisible.
        _selectedAreaTab = null;
      } else {
        _selectedAreaTab = area.sourceFile;
      }
      _highlightRawLine = task?.rawLine;
    });
  }

  Widget _tabBody(ProjectReadResult read) {
    switch (_activeTab) {
      case _Tab.strategy:
        final strategy = _strategy;
        // Round 37 §D2 — an empty tab explains why and what to do,
        // rather than falling back to a different tab's own body.
        if (strategy == null || strategy.isEmpty) {
          return const EmptyLine(
            'No strategy yet. Start → Copy opener, and ask the AI to '
            'write CHARTER.md.',
          );
        }
        return StrategyView(
          strategy: strategy,
          roadmap: read.isSuccess ? read.project!.roadmap : const [],
          approvals: _approvals,
          decisions: _decisions ?? const [],
          charterSourceFile:
              '${widget.folder}${Platform.pathSeparator}CHARTER.md',
          personaSourceFile:
              '${widget.folder}${Platform.pathSeparator}PERSONA.md',
          projectSourceFile: read.isSuccess
              ? read.project!.sourceFile
              : widget.folder,
          objectiveToOpen: _objectiveToOpen,
          areas: _areas,
          onOpenArea: _openArea,
          onDataChanged: _load,
        );
      case _Tab.plan:
        // Round 36 cp8, §9 point 1 — always PlanView, never a fallback to
        // Decisions: PlanView itself now has a real, honest body for a
        // project with no plan pages at all (`_noPlanBody`).
        return PlanView(
          plan: _plan ?? const Plan(pages: []),
          areas: _areas,
          decisions: _decisions ?? const [],
          homeTasks: read.isSuccess ? read.project!.tasks : const [],
          strategy: _strategy,
          onOpenStrategy: () => setState(() => _activeTab = _Tab.strategy),
          onOpenObjective: (number) => setState(() {
            _activeTab = _Tab.strategy;
            _objectiveToOpen = number;
          }),
          onOpenArea: _openArea,
          onDataChanged: _load,
          onToggleTask: _toggleAreaOrHomeTask,
          selectedAreaTab: _selectedAreaTab,
          onSelectAreaTab: (sourceFile) =>
              setState(() => _selectedAreaTab = sourceFile),
          onCreateArea: (name) => createArea(
            widget.folder,
            name,
            writeLogPath: widget.writeLogPath,
          ),
          openHomeOnStart: widget.initialOpenHome || _openHomeNow,
          highlightTaskRawLine:
              _highlightRawLine ?? widget.initialHighlightRawLine,
          projectSourceFile: read.isSuccess
              ? read.project!.sourceFile
              : widget.folder,
        );
      case _Tab.log:
        return _logTab(read);
      case _Tab.details:
        return _detailsTab(read);
    }
  }

  /// Round 38 §E (ADR 0034) — the Log tab, replacing the old flat
  /// Decisions list in the same place. `LogView` owns its own rendering;
  /// this just wires it to real data and real writers.
  Widget _logTab(ProjectReadResult read) {
    return LogView(
      projectFolder: widget.folder,
      entries: _logEntries,
      decisions: _decisions ?? const [],
      roadmap: read.isSuccess ? read.project!.roadmap : const [],
      approvals: _approvals,
      areas: _areas,
      onOpenArea: _openArea,
      onDataChanged: _load,
      loadRoundText: (roundNumber) => readRoundFileText(
        widget.folder,
        roundNumber,
        const DiskFileAccess(),
      ),
      onApproveRound: (roundNumber, {required roundTitle, feedback}) =>
          approveRound(
            widget.folder,
            roundNumber,
            roundTitle: roundTitle,
            feedback: feedback,
            writeLogPath: widget.writeLogPath,
          ),
      onRequestRoundChanges: (roundNumber, {required what}) =>
          requestRoundChanges(
            widget.folder,
            roundNumber,
            what: what,
            writeLogPath: widget.writeLogPath,
          ),
    );
  }

  /// Round-36 §3, L17 — also handed to `DecisionDetailScreen`, `PlanView`
  /// and `StrategyView` as `onOpenArea`, so an area chip anywhere in this
  /// screen's tree lands the same way: Plan tab, that area open.
  void _openArea(Area area) => setState(() {
    _activeTab = _Tab.plan;
    _selectedAreaTab = area.sourceFile;
  });

  Widget _detailsTab(ProjectReadResult read) {
    if (!read.isSuccess) {
      return Container(
        padding: const EdgeInsets.all(AsaSpace.lg),
        decoration: BoxDecoration(
          border: Border.all(color: AsaMeaning.needsYou.fg),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not read the project',
              style: AsaText.rowName.copyWith(color: AsaMeaning.needsYou.fg),
            ),
            const SizedBox(height: AsaSpace.sm),
            Text(read.error ?? 'Unknown problem', style: AsaText.body),
          ],
        ),
      );
    }

    final project = read.project!;
    final git = _git;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editableField(
          'Status',
          'status',
          project.status,
          picker: _statusValues,
          valueBuilder: (value) =>
              Pill(statusLabel(value), meaning: meaningForStatus(value)),
        ),
        _editableField('Parent', 'parent', project.parent),
        _editableField('Priority', 'priority', project.priority),
        _editableField(
          'Deadline',
          'deadline',
          project.deadline,
          periodEditor: true,
          valueBuilder: (value) =>
              Text(humanizeDeadline(value) ?? value, style: AsaText.body),
        ),
        _editableField(
          'Jira',
          'jira',
          project.jira,
          valueBuilder: (value) => LinkChip(
            '${jiraLabel(value) ?? value} ↗',
            onTap: () => openUrl(value),
          ),
        ),
        _Field(
          'Milestone',
          effectiveMilestone(project.roadmap, project.milestone),
        ),
        _Field(
          'Next step',
          effectiveNextStep(project.tasks, project.nextStep, areas: _areas) ??
              'no next step',
        ),
        _Field(
          'Note updated by hand',
          asaDetailDate(project.updated) ?? project.updated,
        ),
        _Field('Last moved (from git)', _lastMovedText(git)),
        _Field(
          'Repo',
          project.repoPath.isEmpty ? '(no code yet)' : project.repoPath,
        ),
      ],
    );
  }

  /// One of the five ADR 0007-whitelisted fields — `field` is the exact
  /// frontmatter key, matching `project_writer.dart`'s own whitelist.
  /// `rawValue` is the real, possibly-null value (never a placeholder) —
  /// the editor starts from an empty box for an unset field, not from
  /// placeholder text someone would have to clear first.
  ///
  /// `valueBuilder`, when given, renders a non-empty value as the same
  /// chip/pill/formatted style the rest of the app already uses for that
  /// data (round-37 §D6) — never used for an unset value, which always
  /// reads "not set" regardless.
  Widget _editableField(
    String label,
    String field,
    String? rawValue, {
    List<String>? picker,
    Widget Function(String value)? valueBuilder,
    bool periodEditor = false,
  }) {
    return _EditableField(
      label: label,
      rawValue: rawValue,
      valueBuilder: valueBuilder,
      editing: _editingField == field,
      controller: _editController,
      controllerTo: _editControllerTo,
      periodEditor: periodEditor,
      error: _editingField == field ? _editError : null,
      saving: _saving,
      picker: picker,
      onStartEdit: () => _startEdit(field, rawValue ?? ''),
      onPickerChanged: (value) => setState(() => _editController.text = value),
      onSave: () => _saveEdit(field),
      onCancel: _cancelEdit,
    );
  }

  /// Round 37 §D6 — drops the old "— see below" phrase: the provenance
  /// section it pointed at is either right there once expanded, or the
  /// person has not expanded it yet, and either way "— see below" told
  /// them nothing that "unknown" alone doesn't.
  String _lastMovedText(GitState? git) {
    if (git == null) return '(not checked)';
    if (git.error != null) return 'unknown';

    final days = git.daysSinceLastCommit(DateTime.now());
    if (days == null) return 'unknown';
    if (days == 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  /// Collapsed behind one line that expands. The sketch does not show
  /// this block at all, because the sketch is about the list, not because
  /// the block should go: rule 5, and HANDOVER.md is explicit that this
  /// stays.
  Widget _provenanceSection(ProjectReadResult read) {
    if (!read.isSuccess) return const SizedBox.shrink();

    final sourceFile = read.project!.sourceFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _provenanceExpanded = !_provenanceExpanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _provenanceExpanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: AsaColors.ink3,
              ),
              const SizedBox(width: AsaSpace.xs),
              SourceLine(sourceFile),
            ],
          ),
        ),
        if (_provenanceExpanded) ...[
          const SizedBox(height: AsaSpace.sm),
          _RawBlock(title: 'Read from: $sourceFile', body: read.rawFrontmatter),
          const SizedBox(height: AsaSpace.lg),
          if (_git != null)
            _RawBlock(
              title: _git!.command,
              body: _git!.error == null
                  ? _git!.rawOutput
                  : '${_git!.error}\n\n${_git!.rawOutput}',
            ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  /// Round 37 cp6, §D6 item 9 — every one of this screen's own "there is
  /// nothing here" conventions (`(not set)`, `(no code yet)`, `(not
  /// checked)`, `no next step`, `unknown`) read as one style, not each
  /// its own bracket-or-not wording. The word stays whatever `core/`
  /// already derives — this only unifies how it looks.
  static const _emptyValues = {
    '(not set)',
    '(no code yet)',
    '(not checked)',
    'no next step',
    'unknown',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label, style: const TextStyle(color: AsaColors.ink3)),
          ),
          Expanded(
            child: _emptyValues.contains(value)
                ? EmptyLine(value)
                : SelectableText(value, style: AsaText.body),
          ),
        ],
      ),
    );
  }
}

/// One of the five ADR 0007-whitelisted fields, editable in place —
/// Round 20. Stateless: every bit of state (which field is mid-edit, the
/// typed value, an error, whether a save is in flight) lives in
/// `_ProjectScreenState`, same reason `_ProjectsScreenState` owns
/// `InboxPanel`'s capture logic rather than the panel itself.
class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.rawValue,
    required this.editing,
    required this.controller,
    required this.error,
    required this.saving,
    required this.onStartEdit,
    required this.onPickerChanged,
    required this.onSave,
    required this.onCancel,
    this.picker,
    this.valueBuilder,
    this.controllerTo,
    this.periodEditor = false,
  });

  final String label;
  final String? rawValue;
  final bool editing;
  final TextEditingController controller;

  /// Round 38 §G — the *to* month, only used when [periodEditor] is true.
  final TextEditingController? controllerTo;

  /// Round 38 §G — `deadline` alone: two small `YYYY-MM` boxes, *from*
  /// ([controller]) and *to* ([controllerTo]), instead of the one free-text
  /// box every other field uses.
  final bool periodEditor;
  final String? error;
  final bool saving;
  final VoidCallback onStartEdit;
  final ValueChanged<String> onPickerChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  /// Non-null only for `status` — ADR 0017's six values. A picker rather
  /// than free text, so a typo can't create a new, invisible status.
  final List<String>? picker;

  /// Round 37 §D6 — renders a non-empty value the same way the rest of
  /// the app already shows that same data (a status pill, a Jira chip, a
  /// humanised deadline). Never called for an unset value.
  final Widget Function(String value)? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: Text(
                  label,
                  style: const TextStyle(color: AsaColors.ink3),
                ),
              ),
              if (editing) Expanded(child: _editor()) else _valueDisplay(),
              const SizedBox(width: AsaSpace.sm),
              _controls(),
              if (!editing) const Spacer(),
            ],
          ),
          if (editing && error != null)
            Padding(
              padding: const EdgeInsets.only(top: AsaSpace.xs, left: 200),
              child: Text(
                error!,
                style: AsaText.meta.copyWith(color: AsaMeaning.needsYou.fg),
              ),
            ),
        ],
      ),
    );
  }

  Widget _valueDisplay() {
    final value = rawValue;
    if (value == null || value.isEmpty) return const EmptyLine('not set');
    final builder = valueBuilder;
    if (builder != null) return builder(value);
    return SelectableText(value, style: AsaText.body);
  }

  Widget _editor() {
    if (picker != null) {
      final current = controller.text;
      return DropdownButton<String>(
        value: picker!.contains(canonicalStatus(current))
            ? canonicalStatus(current)
            : null,
        hint: Text(current.isEmpty ? 'not set' : statusLabel(current)),
        isExpanded: true,
        isDense: true,
        items: [
          for (final option in picker!)
            DropdownMenuItem(
              value: option,
              child: Row(
                children: [
                  Text(statusLabel(option)),
                  const SizedBox(width: AsaSpace.sm),
                  Expanded(
                    child: Text(
                      _statusMeans[option] ?? '',
                      style: const TextStyle(color: AsaColors.ink3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: saving
            ? null
            : (value) {
                if (value != null) onPickerChanged(value);
              },
      );
    }

    if (periodEditor) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !saving,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'YYYY-MM',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AsaSpace.xs),
            child: Text('to', style: TextStyle(color: AsaColors.ink3)),
          ),
          Expanded(
            child: TextField(
              controller: controllerTo,
              enabled: !saving,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'YYYY-MM (optional)',
              ),
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: controller,
      enabled: !saving,
      autofocus: true,
      decoration: const InputDecoration(isDense: true, isCollapsed: true),
    );
  }

  Widget _controls() {
    if (!editing) {
      return IconButton(
        icon: const Icon(Icons.edit, size: 16),
        onPressed: onStartEdit,
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
      );
    }

    if (saving) {
      return const Padding(
        padding: EdgeInsets.all(AsaSpace.sm),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, size: 18),
          onPressed: onSave,
          tooltip: 'Save',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onCancel,
          tooltip: 'Cancel',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _RawBlock extends StatelessWidget {
  const _RawBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AsaText.meta),
        const SizedBox(height: AsaSpace.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AsaSpace.md),
          color: AsaColors.soft,
          child: SelectableText(
            body.isEmpty ? '(nothing)' : body,
            style: AsaText.meta.copyWith(
              fontFamily: 'monospace',
              color: AsaColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
