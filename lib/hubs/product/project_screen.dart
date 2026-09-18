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
/// and `parent` was not displayed anywhere at all. Asked Nico directly
/// rather than guess; his answer: add the missing four as plain rows
/// here too, then make all five editable in this one place. `status`
/// gets a picker over ADR 0017's own six-value enum (hardcoded here —
/// nothing in code defined it yet either) rather than free text, so a
/// typo can't create a new, invisible status; the other four are a plain
/// text field. Saving goes through `project_writer.dart`'s
/// `setProjectField`, then re-reads the whole project from disk — the
/// file is the source of truth, never the in-memory typed value.
library;

import 'dart:io';

import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_reader.dart';
import 'package:asa/core/project_writer.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/plan_view.dart';
import 'package:asa/hubs/product/strategy_view.dart';
import 'package:flutter/material.dart';

/// Round 16's tab reorder: `Strategy · Plan · Decisions · Details`,
/// matching `asa-strategy-v3.html`'s own row for every tab that actually
/// exists (Roadmap and the six-tab row's other gaps are not built).
/// `strategy` and `plan` are each absent-not-empty; `decisions` and
/// `details` never move and never disappear.
enum _Tab { strategy, plan, decisions, details }

/// ADR 0017's own six values, in the order the ADR states them. No code
/// defined this list before this round — the picker needs it to exist
/// somewhere, and this screen is the only place that reads it today.
const _statusValues = [
  'idea',
  'discovery-done',
  'building',
  'shipped',
  'ongoing',
  'paused',
  'dropped',
];

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({
    required this.folder,
    this.writeLogPath,
    this.onOpenTasks,
    super.key,
  });

  final String folder;

  /// Overrides where a field edit's write is logged. Production never
  /// sets this — it exists so a test can save through the real
  /// `setProjectField` without touching `%APPDATA%\Asa\write-log.jsonl`.
  final String? writeLogPath;

  /// Round 27's navigation fix — Nico: *"we should still be able to
  /// navigate there, with the tasks of this project on top for easy
  /// work."* Null in a test that does not need it. In the real app this
  /// pops back to `ProjectsScreen` and switches it to the Tasks view with
  /// this project's name — the only host `TasksView` has, traced rather
  /// than assumed.
  final void Function(String projectName)? onOpenTasks;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectReadResult? _read;
  GitState? _git;
  List<DecisionReadResult>? _decisions;
  Plan? _plan;
  Strategy? _strategy;
  RoundApprovals _approvals = const RoundApprovals({});
  bool _loading = true;
  _Tab _activeTab = _Tab.strategy;
  bool _provenanceExpanded = false;

  // Editing one of the five whitelisted fields — Round 20. Only one field
  // is ever mid-edit at a time; starting a new one silently drops any
  // other in-progress edit, since nothing unsaved is lost by that (the
  // file itself is untouched until Save).
  String? _editingField;
  final _editController = TextEditingController();
  String? _editError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEdit(String field, String currentValue) {
    setState(() {
      _editingField = field;
      _editController.text = currentValue;
      _editError = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingField = null;
      _editError = null;
    });
  }

  Future<void> _saveEdit(String field) async {
    final read = _read;
    if (read == null || !read.isSuccess) return;

    setState(() {
      _saving = true;
      _editError = null;
    });

    try {
      await setProjectField(
        read.project!.sourceFile,
        field: field,
        value: _editController.text.trim(),
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
    final strategy = await readCharter(widget.folder);
    final approvals = await readRoundApprovals(
      widget.folder,
      const DiskFileAccess(),
    );

    if (!mounted) return;
    setState(() {
      _read = read;
      _git = git;
      _decisions = decisions;
      _plan = plan;
      _strategy = strategy;
      _approvals = approvals;
      _loading = false;
      // A tab that just disappeared (a reload after its section turned
      // empty) should not leave the screen on a body with no label above
      // it — fall back to the first tab that is still actually there.
      final visible = _visibleTabs();
      if (!visible.contains(_activeTab)) _activeTab = visible.first;
    });
  }

  /// `Strategy` first, per the sketch's own row order — `Decisions` and
  /// `Details` never move and never disappear.
  List<_Tab> _visibleTabs() {
    final strategy = _strategy;
    final plan = _plan;
    return [
      if (strategy != null && !strategy.isEmpty) _Tab.strategy,
      if (plan != null && !plan.isEmpty) _Tab.plan,
      _Tab.decisions,
      _Tab.details,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final read = _read;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerRow(),
            const SizedBox(height: 16),
            if (_loading) const Text('Loading…'),
            if (!_loading && read != null) ...[
              Text(
                read.isSuccess ? read.project!.name : 'Project',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (read.isSuccess && read.project!.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  read.project!.description!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
              _tabRow(),
              const SizedBox(height: 4),
              const Divider(height: 1),
              const SizedBox(height: 4),
              _tabBody(read),
              const SizedBox(height: 24),
              _provenanceSection(read),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    final read = _read;
    final canOpenTasks =
        widget.onOpenTasks != null && read != null && read.isSuccess;

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 20),
          color: Colors.grey.shade700,
          visualDensity: VisualDensity.compact,
          tooltip: 'Back',
        ),
        const Spacer(),
        // Round 27: "one button, not a fourth real tab" — styled
        // distinctly (the sketch's small ↗ glyph) so it reads as leaving
        // this screen, which it does: it pops back to the front page.
        if (canOpenTasks)
          TextButton.icon(
            onPressed: () => widget.onOpenTasks!(read.project!.name),
            icon: const Icon(Icons.north_east, size: 14),
            label: const Text('Tasks'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              visualDensity: VisualDensity.compact,
            ),
          ),
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh, size: 20),
          color: Colors.grey.shade700,
          visualDensity: VisualDensity.compact,
          tooltip: 'Reload',
        ),
      ],
    );
  }

  /// Plain text, a 2px underline on the active one — row 3 of the drift
  /// table. Not a Material `TabBar`: no uppercase, no full-width band.
  ///
  /// Round 16 reorders this to `Strategy · Plan · Decisions · Details`,
  /// matching the sketch's own row for every tab that actually exists.
  /// `Strategy` and `Plan` show only once there is one — the same
  /// absent-not-empty rule every conditional tab here already follows.
  Widget _tabRow() {
    final labels = {
      _Tab.strategy: 'Strategy',
      _Tab.plan: 'Plan',
      _Tab.decisions: 'Decisions',
      _Tab.details: 'Details',
    };
    final visible = _visibleTabs();
    return Row(
      children: [
        for (final tab in visible) ...[
          if (tab != visible.first) const SizedBox(width: 24),
          _tabLabel(labels[tab]!, tab),
        ],
      ],
    );
  }

  Widget _tabBody(ProjectReadResult read) {
    switch (_activeTab) {
      case _Tab.strategy:
        final strategy = _strategy;
        if (strategy == null || strategy.isEmpty) return _decisionsTab(read);
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
        );
      case _Tab.plan:
        final plan = _plan;
        if (plan == null || plan.isEmpty) return _decisionsTab(read);
        return PlanView(
          plan: plan,
          decisions: _decisions ?? const [],
          projectSourceFile: read.isSuccess
              ? read.project!.sourceFile
              : widget.folder,
        );
      case _Tab.decisions:
        return _decisionsTab(read);
      case _Tab.details:
        return _detailsTab(read);
    }
  }

  Widget _tabLabel(String label, _Tab tab) {
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? Colors.black87 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// 2026-09-07 trial (`asa-decisions-v2.png`): split into "Needs a look"
  /// and "Settled" when there is anything to put in the first group. A
  /// healthy project — nothing proposed — falls back to exactly the flat
  /// list, so a group header is never shown empty.
  Widget _decisionsTab(ProjectReadResult read) {
    final decisions = _decisions ?? [];

    if (decisions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Nothing decided yet.'),
      );
    }

    final groups = groupForReview(decisions);
    if (groups.needsALook.isEmpty) {
      return Column(
        children: [for (final result in decisions) _decisionRow(result)],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Needs a look', groups.needsALook.length),
        for (final result in groups.needsALook) _decisionRow(result),
        const SizedBox(height: 16),
        _groupLabel('Settled', groups.settled.length),
        for (final result in groups.settled) _decisionRow(result),
      ],
    );
  }

  Widget _groupLabel(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '${label.toUpperCase()} · $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  static const _hairline = BoxDecoration(
    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
  );

  /// A flat list, one row per decision, a hairline between — row 4 of the
  /// drift table. Not a `Card`: no shadow, no per-row container.
  Widget _decisionRow(DecisionReadResult result) {
    if (!result.isSuccess) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: _hairline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unreadable — ${result.sourceFile}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(result.error ?? 'Unknown problem'),
            const SizedBox(height: 8),
            _RawBlock(title: 'Raw text', body: result.rawText),
          ],
        ),
      );
    }

    final decision = result.decision!;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DecisionDetailScreen(decision: decision),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: _hairline,
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    decision.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (decision.status != null) _statusPill(decision),
                  // The pill alone would drop "names what replaced it" —
                  // still required (HANDOVER.md §5b), so it stays as a
                  // small note next to the pill rather than inside it.
                  if (decision.supersededBy != null)
                    Text(
                      '→ replaced by ${decision.supersededBy}',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _humanDate(decision.date),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Row 5 of the drift table — green accepted, blue proposed, grey
  /// superseded. The pill shows a short canonical word, not the raw parsed
  /// status text (which can run to a whole sentence, e.g. asa/0007's
  /// "proposed - needs Nico's decision") — the full text is one tap away,
  /// on the detail screen. Uses `displayStatus`, not the raw header field —
  /// ADR 0011: a recorded verdict overrides a stale `proposed` header.
  Widget _statusPill(Decision decision) {
    final status = decision.displayStatus;
    final lower = status.toLowerCase();
    final Color background;
    final Color foreground;
    final String label;

    if (lower.contains('superseded')) {
      background = const Color(0xFFEEEEEE);
      foreground = const Color(0xFF616161);
      label = 'superseded';
    } else if (decision.isProposed) {
      // The same check `groupForReview` uses for "Needs a look" — one
      // canonical place this is decided, not two.
      background = const Color(0xFFE3F2FD);
      foreground = const Color(0xFF1565C0);
      label = 'proposed';
    } else if (lower.contains('accepted')) {
      background = const Color(0xFFE8F5E9);
      foreground = const Color(0xFF2E7D32);
      label = 'accepted';
    } else {
      background = const Color(0xFFEEEEEE);
      foreground = const Color(0xFF616161);
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Row 6 of the drift table — `today`, `1 Sep`, `22 Aug`. Kept local to
  /// this file rather than `lib/core/`, even though it is the kind of
  /// logic-with-a-rule ARCHITECTURE.md says belongs in `core/` — this
  /// round is scoped to `project_screen.dart` and nothing else. Worth
  /// moving to `decisions_reader.dart` alongside `sortDecisionsNewestFirst`
  /// in a round that is allowed to touch it.
  String _humanDate(String? date) {
    if (date == null) return '';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    final now = DateTime.now();
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return 'today';
    }

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
    return '${parsed.day} ${months[parsed.month - 1]}';
  }

  Widget _detailsTab(ProjectReadResult read) {
    if (!read.isSuccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not read the project',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(read.error ?? 'Unknown problem'),
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
        ),
        _editableField('Parent', 'parent', project.parent),
        _editableField('Priority', 'priority', project.priority),
        _editableField('Deadline', 'deadline', project.deadline),
        _editableField('Jira', 'jira', project.jira),
        _Field(
          'Milestone',
          effectiveMilestone(project.roadmap, project.milestone),
        ),
        _Field('Next step', project.nextStep),
        _Field('Note updated by hand', project.updated),
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
  /// `rawValue` is the real, possibly-null value (never the "(not set)"
  /// placeholder) — the editor starts from an empty box for an unset
  /// field, not from placeholder text someone would have to clear first.
  Widget _editableField(
    String label,
    String field,
    String? rawValue, {
    List<String>? picker,
  }) {
    return _EditableField(
      label: label,
      displayValue: (rawValue == null || rawValue.isEmpty)
          ? '(not set)'
          : rawValue,
      editing: _editingField == field,
      controller: _editController,
      error: _editingField == field ? _editError : null,
      saving: _saving,
      picker: picker,
      onStartEdit: () => _startEdit(field, rawValue ?? ''),
      onPickerChanged: (value) => setState(() => _editController.text = value),
      onSave: () => _saveEdit(field),
      onCancel: _cancelEdit,
    );
  }

  String _lastMovedText(GitState? git) {
    if (git == null) return '(not checked)';
    if (git.error != null) return 'unknown — see below';

    final days = git.daysSinceLastCommit(DateTime.now());
    if (days == null) return 'unknown';
    if (days == 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  /// Row 8 of the drift table — collapsed behind one line that expands.
  /// The sketch does not show this block at all, because the sketch is
  /// about the list, not because the block should go: rule 5, and
  /// HANDOVER.md is explicit that this stays.
  Widget _provenanceSection(ProjectReadResult read) {
    if (!read.isSuccess) return const SizedBox.shrink();

    final sourceFile = read.project!.sourceFile;
    final fileName = sourceFile.split(RegExp(r'[\\/]')).last;

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
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Read from: $fileName',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        if (_provenanceExpanded) ...[
          const SizedBox(height: 8),
          _RawBlock(title: 'Read from: $sourceFile', body: read.rawFrontmatter),
          const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: SelectableText(value)),
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
    required this.displayValue,
    required this.editing,
    required this.controller,
    required this.error,
    required this.saving,
    required this.onStartEdit,
    required this.onPickerChanged,
    required this.onSave,
    required this.onCancel,
    this.picker,
  });

  final String label;
  final String displayValue;
  final bool editing;
  final TextEditingController controller;
  final String? error;
  final bool saving;
  final VoidCallback onStartEdit;
  final ValueChanged<String> onPickerChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  /// Non-null only for `status` — ADR 0017's six values. A picker rather
  /// than free text, so a typo can't create a new, invisible status.
  final List<String>? picker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 200,
                child: Text(label, style: const TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: editing ? _editor() : SelectableText(displayValue),
              ),
              const SizedBox(width: 8),
              _controls(),
            ],
          ),
          if (editing && error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 200),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _editor() {
    if (picker != null) {
      final current = controller.text;
      return DropdownButton<String>(
        value: picker!.contains(current) ? current : null,
        hint: Text(current.isEmpty ? '(not set)' : current),
        isExpanded: true,
        isDense: true,
        items: [
          for (final option in picker!)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: saving
            ? null
            : (value) {
                if (value != null) onPickerChanged(value);
              },
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
        padding: EdgeInsets.all(8),
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
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF2F2F2),
          child: SelectableText(
            body.isEmpty ? '(nothing)' : body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
