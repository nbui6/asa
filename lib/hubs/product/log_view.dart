/// Product Hub — the Log tab (Round 38 §E, ADR 0034), replacing Decisions
/// in the same place. Two views: *What happened* (a merged, derived
/// timeline — nothing written for the Log itself, `log_entries.dart`'s
/// own job) and *Decisions in force* (the same current-decisions set
/// `asa-brief` gives an AI). One *Needs your yes* card sits above both,
/// cycling through whatever is waiting — a proposed decision or a round
/// — one at a time; **this replaces §C's own flat "Needs your yes" list
/// and "Yes to selected."** The round's own *Your call* screen
/// (`round_call_screen.dart`) stays, reached from the card's title or a
/// timeline row.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/log_entries.dart';
import 'package:asa/core/log_visit.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_state.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/round_call_screen.dart';
import 'package:asa/hubs/product/ui/area_chip.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/escape_to_cancel.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

enum LogSubView { whatHappened, decisionsInForce }

class LogView extends StatefulWidget {
  const LogView({
    required this.projectFolder,
    required this.homeSourceFile,
    required this.entries,
    required this.decisions,
    required this.roadmap,
    required this.approvals,
    required this.loadRoundText,
    required this.onApproveRound,
    required this.onRequestRoundChanges,
    this.areas = const [],
    this.onOpenArea,
    this.onDataChanged,
    this.lastVisitPath,
    this.onWriteResult,
    this.onCreateDecision,
    this.onRecordDecisionYes,
    super.key,
  });

  final String projectFolder;

  /// The project's own home note — round-43.md §C's own "＋ Result"
  /// writes here whenever "Not in an area" stays selected. Passed in
  /// rather than re-derived from [projectFolder]: `findHomeNote`'s own
  /// "first note with frontmatter" fallback is a real disk read this
  /// widget has no way to redo, and the caller already has the answer.
  final String homeSourceFile;
  final List<LogEntry> entries;
  final List<DecisionReadResult> decisions;
  final List<Milestone> roadmap;
  final RoundApprovals approvals;
  final List<Area> areas;
  final void Function(Area area)? onOpenArea;
  final VoidCallback? onDataChanged;

  /// Reads a round's own file text (`readRoundFileText`, real disk, in
  /// production) — injected rather than called directly, the same
  /// reason `round_call_screen.dart`'s own header names: a widget test
  /// driving this through real `dart:io` hit a reproducible hang in
  /// this environment (a second real async disk call, triggered from a
  /// button's own `onPressed`), a `runAsync`/`FakeAsync` interaction
  /// specific to this test binding, not a production risk.
  final Future<String?> Function(String roundNumber) loadRoundText;

  /// Writes a round's Yes (`approveRound`, real disk, in production) —
  /// the needs-your-yes card's own **Yes** button calls this with no
  /// `feedback` (its quick-yes shortcut, round-38.md §E's own "Yes ·
  /// Changes… · 1 of N"); `RoundCallScreen`, pushed from a timeline row
  /// or the card's own title, can supply real typed feedback. Same
  /// injection reasoning as [loadRoundText].
  final Future<void> Function(
    String roundNumber, {
    required String roundTitle,
    String? feedback,
  })
  onApproveRound;

  /// Writes a round's own Needs changes (`requestRoundChanges`, real
  /// disk, in production) — used when pushing `RoundCallScreen` from a
  /// timeline row or the card's own title, same injection reasoning as
  /// [loadRoundText].
  final Future<void> Function(String roundNumber, {required String what})
  onRequestRoundChanges;

  /// Overrides where "since you were last here" is recorded — production
  /// never sets this.
  final String? lastVisitPath;

  /// Round 43 §C — the Log's own "＋ Result" button. Null area is "Not in
  /// an area" (the project's own home note); no task, since nothing was
  /// ticked to get here.
  final Future<void> Function({
    required String path,
    required String text,
    String? taskText,
    ResultLink? link,
  })?
  onWriteResult;

  /// Same button's own "＋ Decision" sibling.
  final Future<void> Function({
    required String projectFolder,
    required String decisionText,
    String? why,
    String? area,
    List<String> objectives,
    ResultLink? link,
  })?
  onCreateDecision;

  /// Delivery v2 A1 — asa-log-v2: "Yes or Changes right there, then the
  /// next." Records the verdict with "No reason given." for whichever
  /// shape [Decision.sourceFile] is, both now supported
  /// (`appendVerdictAnyShape`). Null falls back to opening the detail
  /// screen instead, this card's own older behaviour, for a caller (or
  /// test) not wired for it.
  final Future<void> Function(Decision decision)? onRecordDecisionYes;

  @override
  State<LogView> createState() => _LogViewState();
}

final RegExp _roundNumberInTitle = RegExp(
  r'Round\s*(\d+)',
  caseSensitive: false,
);

class _LogViewState extends State<LogView> {
  LogSubView _view = LogSubView.whatHappened;
  DateTime? _lastVisit;
  bool _olderShown = false;
  int _needsYouIndex = 0;
  final Set<String> _expanded = {};
  bool _showReplaced = false;

  /// Round 43 §C — null when neither "＋ Result" nor "＋ Decision" is
  /// open; at most one at a time, same as the Tasks view's own tick
  /// prompt.
  bool _addingResult = false;
  bool _addingDecision = false;
  final _addTextController = TextEditingController();
  final _addWhyController = TextEditingController();
  bool _addLinkFieldOpen = false;
  final _addLinkController = TextEditingController();

  /// Null is "Not in an area" — the project's own home note. Round-43.md
  /// §C's own default ("the one the user came from") has no meaning on
  /// this screen (nothing was ticked to arrive from); "Not in an area"
  /// is the same fallback the round names for that same case elsewhere.
  Area? _addSelectedArea;

  @override
  void dispose() {
    _addTextController.dispose();
    _addWhyController.dispose();
    _addLinkController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLastVisit();
  }

  Future<void> _loadLastVisit() async {
    final visit = await lastLogVisit(
      widget.projectFolder,
      path: widget.lastVisitPath,
    );
    // "The since-line moves after opening" — read once, before
    // recording this visit, so the line still shows what was new *this*
    // time; the freshly recorded timestamp only takes effect next time.
    if (mounted) setState(() => _lastVisit = visit);
    await recordLogVisit(widget.projectFolder, path: widget.lastVisitPath);
  }

  List<_NeedsYourYesItem> get _waiting {
    final items = <_NeedsYourYesItem>[];
    for (final result in widget.decisions) {
      if (result.decision?.isProposed ?? false) {
        items.add(_NeedsYourYesDecision(result));
      }
    }
    for (final milestone in widget.roadmap) {
      if (roundStateOf(milestone, widget.approvals) !=
          RoundState.waitingForApproval) {
        continue;
      }
      final number = _roundNumberInTitle.firstMatch(milestone.title)?.group(1);
      if (number == null) continue;
      items.add(_NeedsYourYesRound(number, milestone.title));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waiting.isNotEmpty) ...[
          _needsYouPanel(waiting),
          const SizedBox(height: AsaSpace.lg),
        ],
        _viewSwitch(),
        const SizedBox(height: AsaSpace.md),
        _addButtons(),
        if (_addingResult || _addingDecision) _addForm(),
        const SizedBox(height: AsaSpace.md),
        if (_view == LogSubView.whatHappened)
          _whatHappened()
        else
          _decisionsInForce(),
      ],
    );
  }

  // --- Round 43 §C — the Log's own "＋ Result"/"＋ Decision" ------------

  Widget _addButtons() {
    return Row(
      children: [
        _addButton('＋ Result', _addingResult, _startAddingResult),
        const SizedBox(width: AsaSpace.sm),
        _addButton('＋ Decision', _addingDecision, _startAddingDecision),
      ],
    );
  }

  Widget _addButton(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.sm,
          vertical: AsaSpace.xs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AsaColors.line),
          borderRadius: BorderRadius.circular(4),
          color: selected ? AsaColors.soft : null,
        ),
        child: Text(
          label,
          style: AsaText.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _startAddingResult() {
    setState(() {
      _addingResult = true;
      _addingDecision = false;
      _addTextController.clear();
      _addWhyController.clear();
      _addLinkFieldOpen = false;
      _addLinkController.clear();
    });
  }

  void _startAddingDecision() {
    setState(() {
      _addingDecision = true;
      _addingResult = false;
      _addTextController.clear();
      _addWhyController.clear();
      _addLinkFieldOpen = false;
      _addLinkController.clear();
    });
  }

  void _cancelAdd() => setState(() {
    _addingResult = false;
    _addingDecision = false;
  });

  Widget _addForm() {
    final isDecision = _addingDecision;
    return Padding(
      padding: const EdgeInsets.only(top: AsaSpace.sm),
      child: EscapeToCancel(
        onEscape: _cancelAdd,
        child: Container(
          padding: const EdgeInsets.all(AsaSpace.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AsaColors.line),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isDecision ? 'Decision' : 'Result',
                    style: AsaText.meta.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: AsaSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: _addTextController,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: isDecision
                            ? 'What was decided'
                            : 'What came out of it',
                      ),
                      onSubmitted: (_) => _submitAdd(),
                    ),
                  ),
                  const SizedBox(width: AsaSpace.xs),
                  Tooltip(
                    message: 'Link a file, folder or web page',
                    child: InkWell(
                      onTap: () => setState(() => _addLinkFieldOpen = true),
                      child: const Text('📎'),
                    ),
                  ),
                  const SizedBox(width: AsaSpace.xs),
                  _areaPicker(),
                ],
              ),
              if (isDecision) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('Why', style: AsaText.meta),
                    const SizedBox(width: AsaSpace.sm),
                    Expanded(
                      child: TextField(
                        controller: _addWhyController,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '(optional)',
                        ),
                        onSubmitted: (_) => _submitAdd(),
                      ),
                    ),
                  ],
                ),
              ],
              if (_addLinkFieldOpen)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TextField(
                    controller: _addLinkController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Paste a path or a link',
                    ),
                    onSubmitted: (_) => _submitAdd(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "The area is the one the user came from (else Not in an area); tap
  /// to pick another; its objective follows the area." Nothing was
  /// ticked to arrive from on this screen, so it always starts at "Not
  /// in an area" — the picker is how the round's own "tap to pick
  /// another" is reached.
  Widget _areaPicker() {
    return PopupMenuButton<Area?>(
      tooltip: 'Change the area',
      onSelected: (area) => setState(() => _addSelectedArea = area),
      itemBuilder: (context) => [
        const PopupMenuItem<Area?>(child: Text('Not in an area')),
        for (final area in widget.areas)
          PopupMenuItem<Area?>(value: area, child: Text(area.name)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AsaColors.violetBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _addSelectedArea?.name ?? 'Not in an area',
          style: AsaText.meta.copyWith(color: AsaColors.violet),
        ),
      ),
    );
  }

  Future<void> _submitAdd() async {
    final text = _addTextController.text.trim();
    if (text.isEmpty) return;
    final isDecision = _addingDecision;
    final area = _addSelectedArea;
    final link = _deriveLink(_addLinkController.text.trim());
    setState(() {
      _addingResult = false;
      _addingDecision = false;
    });

    if (isDecision) {
      await widget.onCreateDecision?.call(
        projectFolder: widget.projectFolder,
        decisionText: text,
        why: _addWhyController.text.trim().isEmpty
            ? null
            : _addWhyController.text.trim(),
        area: area?.name,
        objectives: area?.objectiveNumbers ?? const [],
        link: link,
      );
    } else {
      await widget.onWriteResult?.call(
        path: area?.sourceFile ?? widget.homeSourceFile,
        text: text,
        link: link,
      );
    }
    widget.onDataChanged?.call();
  }

  /// Same derivation as the Tasks view's own tick prompt — kept as its
  /// own copy rather than a shared helper: the two screens' own 📎 fields
  /// happen to want the same rule today, but nothing here depends on
  /// that staying true, and a screen-crossing import for four lines of
  /// pure string logic is the wrong price for avoiding one duplicate.
  ResultLink? _deriveLink(String typed) {
    if (typed.isEmpty) return null;
    final isUrl = RegExp('^https?://', caseSensitive: false).hasMatch(typed);
    if (isUrl) {
      final shortened = typed.replaceFirst(
        RegExp('^https?://', caseSensitive: false),
        '',
      );
      final label = shortened.length > 40
          ? '${shortened.substring(0, 40)}…'
          : shortened;
      return ResultLink(label: label, target: typed);
    }
    final segments = typed
        .split(RegExp(r'[\\/]'))
        .where((s) => s.isNotEmpty)
        .toList();
    final label = segments.isEmpty ? typed : segments.last;
    return ResultLink(label: label, target: typed);
  }

  Widget _viewSwitch() {
    return Row(
      children: [
        _viewLabel('What happened', LogSubView.whatHappened),
        const SizedBox(width: AsaSpace.lg),
        _viewLabel('Decisions in force', LogSubView.decisionsInForce),
      ],
    );
  }

  Widget _viewLabel(String label, LogSubView view) {
    final selected = _view == view;
    return InkWell(
      onTap: () => setState(() => _view = view),
      child: Container(
        padding: const EdgeInsets.only(bottom: AsaSpace.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AsaColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AsaText.rowName.copyWith(
            color: selected ? AsaColors.ink : AsaColors.ink3,
          ),
        ),
      ),
    );
  }

  // --- Needs your yes ----------------------------------------------------

  Widget _needsYouPanel(List<_NeedsYourYesItem> waiting) {
    final index = _needsYouIndex % waiting.length;
    final item = waiting[index];
    return Container(
      padding: const EdgeInsets.all(AsaSpace.md),
      decoration: BoxDecoration(
        color: AsaMeaning.needsYou.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Needs your yes'),
          const SizedBox(height: AsaSpace.xs),
          InkWell(
            onTap: () => _openItem(item),
            child: Text(item.title, style: AsaText.rowName),
          ),
          const SizedBox(height: AsaSpace.sm),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AsaColors.green),
                onPressed: () => _recordYesFor(item),
                child: const Text('Yes'),
              ),
              const SizedBox(width: AsaSpace.sm),
              OutlinedButton(
                onPressed: () => _openItem(item),
                child: const Text('Changes…'),
              ),
              const Spacer(),
              Text('${index + 1} of ${waiting.length}', style: AsaText.meta),
              if (waiting.length > 1)
                TextButton(
                  onPressed: () => setState(() => _needsYouIndex++),
                  child: const Text('next ›'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _recordYesFor(_NeedsYourYesItem item) async {
    if (item is _NeedsYourYesRound) {
      await widget.onApproveRound(item.roundNumber, roundTitle: item.title);
      widget.onDataChanged?.call();
      return;
    }
    final onRecordDecisionYes = widget.onRecordDecisionYes;
    final decision = (item as _NeedsYourYesDecision).result.decision!;
    if (onRecordDecisionYes == null) {
      // Not wired — the older behaviour, opening the detail screen rather
      // than guessing an accept with no reason recorded.
      await _openItem(item);
      return;
    }
    await onRecordDecisionYes(decision);
    // Delivery v2 A1 — "then the next": once this item is no longer
    // proposed, `_waiting` itself is one shorter and whatever was next
    // shifts into this same index — no manual advance needed, the same
    // way a round's own Yes above already works.
    widget.onDataChanged?.call();
  }

  Future<void> _openItem(_NeedsYourYesItem item) async {
    if (item is _NeedsYourYesDecision) {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => DecisionDetailScreen(
            decision: item.result.decision!,
            areasNaming: _areasNaming(item.result.decision!),
            onOpenArea: widget.onOpenArea,
          ),
        ),
      );
      if (changed ?? false) widget.onDataChanged?.call();
      return;
    }
    final round = item as _NeedsYourYesRound;
    await openRoundCall(
      context,
      roundNumber: round.roundNumber,
      roundTitle: round.title,
      loadRoundText: widget.loadRoundText,
      onApproveRound: widget.onApproveRound,
      onRequestRoundChanges: widget.onRequestRoundChanges,
      onDataChanged: widget.onDataChanged,
    );
  }

  List<Area> _areasNaming(Decision decision) {
    return areasNamingDecision(decision, widget.areas);
  }

  // --- What happened -------------------------------------------------

  Widget _whatHappened() {
    if (widget.entries.isEmpty) {
      return const EmptyLine('Nothing happened here yet.');
    }

    final lastVisit = _lastVisit;
    final newer = lastVisit == null
        ? widget.entries
        : widget.entries.where((e) => e.date.isAfter(lastVisit)).toList();
    final older = lastVisit == null
        ? const <LogEntry>[]
        : widget.entries.where((e) => !e.date.isAfter(lastVisit)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in newer) _logRow(entry),
        if (lastVisit != null && newer.isNotEmpty && older.isNotEmpty) ...[
          const SizedBox(height: AsaSpace.sm),
          const Divider(height: 1, color: AsaColors.soft),
          const SizedBox(height: AsaSpace.sm),
        ],
        if (older.isNotEmpty) ..._foldedByWeek(older),
      ],
    );
  }

  List<Widget> _foldedByWeek(List<LogEntry> older) {
    if (_olderShown) {
      return [for (final entry in older) _logRow(entry)];
    }
    final weeks = <String>{};
    for (final entry in older) {
      weeks.add(_weekOf(entry.date));
    }
    return [
      for (final week in weeks)
        InkWell(
          onTap: () => setState(() => _olderShown = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
            child: Text('Week of $week · show ›', style: AsaText.meta),
          ),
        ),
    ];
  }

  String _weekOf(DateTime date) {
    final mondayOffset = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: mondayOffset));
    return _dayOf(monday);
  }

  Widget _logRow(LogEntry entry) {
    final key = '${entry.type}-${entry.date.toIso8601String()}-${entry.title}';
    final expanded = _expanded.contains(key);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AsaColors.soft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expanded.remove(key);
              } else {
                _expanded.add(key);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      _timeOrDayOf(entry.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AsaText.meta,
                    ),
                  ),
                  const SizedBox(width: AsaSpace.sm),
                  Pill(
                    _typeLabel(entry.type),
                    meaning: _typeMeaning(entry.type),
                  ),
                  const SizedBox(width: AsaSpace.sm),
                  Expanded(
                    child: Text(
                      entry.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AsaText.body,
                    ),
                  ),
                  if (entry.hint != null) ...[
                    const SizedBox(width: AsaSpace.sm),
                    Text(entry.hint!, style: AsaText.meta),
                  ],
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 44 + AsaSpace.sm,
                bottom: AsaSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.detail, style: AsaText.body),
                  const SizedBox(height: AsaSpace.xs),
                  Wrap(
                    spacing: AsaSpace.xs,
                    children: [
                      // Round 38 §E, L27 — the same area lookup
                      // `_areaSectionLabel` already uses: a real chip's
                      // own `onTap` when this area is actually loaded,
                      // inert otherwise rather than a chip that looks
                      // tappable and does nothing.
                      if (entry.area != null)
                        AreaChip(
                          entry.area!,
                          onTap: _openAreaByName(entry.area!),
                        ),
                      if (entry.round != null) Text('Round ${entry.round}'),
                      if (entry.file != null)
                        Text(entry.file!, style: AsaText.meta),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The deciding session, 2026-10-05 15:20: today's own entries show the
  /// time; older ones show the day, never a bare `00:00` — a source that
  /// only ever carries a day (`.asa-log.md`'s own date, with no time)
  /// parses as exact midnight, so "no time recorded" and "today, midnight
  /// sharp" are indistinguishable on purpose, and both read as the day.
  String _timeOrDayOf(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final hasTime = date.hour != 0 || date.minute != 0;
    if (isToday && hasTime) return _timeOf(date);
    return _dayOf(date);
  }

  String _timeOf(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _dayOf(DateTime date) {
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

  String _typeLabel(LogEntryType type) => switch (type) {
    LogEntryType.decision => 'decision',
    LogEntryType.yourYes => 'your yes',
    LogEntryType.changesAsked => 'changes asked',
    LogEntryType.aiWorked => 'AI worked',
    LogEntryType.change => 'change',
    LogEntryType.changedWithoutNote => 'changed without a note',
    LogEntryType.result => 'result',
  };

  AsaMeaning _typeMeaning(LogEntryType type) => switch (type) {
    LogEntryType.changedWithoutNote => AsaMeaning.needsYou,
    LogEntryType.yourYes => AsaMeaning.done,
    _ => AsaMeaning.quiet,
  };

  // --- Decisions in force --------------------------------------------

  Widget _decisionsInForce() {
    final current = widget.decisions
        .where((r) => r.isSuccess)
        .where((r) => (r.decision!.supersededBy ?? '').isEmpty)
        .toList();
    final everywhere = current.where((r) => r.decision!.links.scopeAlways);
    // Grouped by every area that names it — its own `**Links:**` line, or
    // an area page's own `## Decisions` naming the number back
    // (`areasNamingDecision`, the same either-direction match the old
    // flat list's own chips used) — never just one area picked
    // arbitrarily, since a real decision can be named by more than one
    // (Round 34's own self-test case).
    final byArea = <String, List<DecisionReadResult>>{};
    final unscoped = <DecisionReadResult>[];
    for (final result in current) {
      if (result.decision!.links.scopeAlways) continue;
      final areas = areasNamingDecision(result.decision, widget.areas);
      if (areas.isEmpty) {
        unscoped.add(result);
      } else {
        for (final area in areas) {
          byArea.putIfAbsent(area.name, () => []).add(result);
        }
      }
    }
    final replaced = widget.decisions
        .where((r) => r.isSuccess)
        .where((r) => (r.decision!.supersededBy ?? '').isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (everywhere.isNotEmpty) ...[
          const SectionLabel('Everywhere'),
          const SizedBox(height: AsaSpace.xs),
          for (final r in everywhere) _decisionInForceRow(r),
          const SizedBox(height: AsaSpace.md),
        ],
        for (final area in byArea.keys) ...[
          _areaSectionLabel(area),
          const SizedBox(height: AsaSpace.xs),
          for (final r in byArea[area]!) _decisionInForceRow(r),
          const SizedBox(height: AsaSpace.md),
        ],
        if (unscoped.isNotEmpty) ...[
          const SectionLabel('Not linked to an area'),
          const SizedBox(height: AsaSpace.xs),
          for (final r in unscoped) _decisionInForceRow(r),
          const SizedBox(height: AsaSpace.md),
        ],
        if (current.isEmpty && replaced.isEmpty)
          const EmptyLine('Nothing decided yet.'),
        if (replaced.isNotEmpty) ...[
          if (!_showReplaced)
            TextButton(
              onPressed: () => setState(() => _showReplaced = true),
              child: const Text('show replaced'),
            )
          else ...[
            const SectionLabel('Replaced'),
            const SizedBox(height: AsaSpace.xs),
            for (final r in replaced) _decisionInForceRow(r),
          ],
        ],
      ],
    );
  }

  /// Grouped by area already (round-38.md §E's own shape), so there's no
  /// per-row chip the way the old flat list had one — this area heading
  /// is the equivalent tap target instead, same `onOpenArea` navigation.
  Widget _areaSectionLabel(String areaName) {
    final match = widget.areas
        .where((a) => a.name.toLowerCase() == areaName.toLowerCase())
        .firstOrNull;
    if (match == null || widget.onOpenArea == null) {
      return SectionLabel(areaName);
    }
    return InkWell(
      onTap: () => widget.onOpenArea!(match),
      child: SectionLabel(areaName),
    );
  }

  /// Round 38 §E, L27 — "What happened"'s own expanded-row area chip,
  /// same lookup as [_areaSectionLabel]; null when this area name
  /// doesn't resolve to a real, loaded [Area], leaving the chip inert.
  VoidCallback? _openAreaByName(String areaName) {
    final match = widget.areas
        .where((a) => a.name.toLowerCase() == areaName.toLowerCase())
        .firstOrNull;
    if (match == null || widget.onOpenArea == null) return null;
    return () => widget.onOpenArea!(match);
  }

  Widget _decisionInForceRow(DecisionReadResult result) {
    final decision = result.decision!;
    return InkWell(
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => DecisionDetailScreen(
              decision: decision,
              areasNaming: _areasNaming(decision),
              onOpenArea: widget.onOpenArea,
            ),
          ),
        );
        if (changed ?? false) widget.onDataChanged?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
        child: Text(decision.title, style: AsaText.body),
      ),
    );
  }
}

sealed class _NeedsYourYesItem {
  String get title;
}

class _NeedsYourYesDecision extends _NeedsYourYesItem {
  _NeedsYourYesDecision(this.result);
  final DecisionReadResult result;

  @override
  String get title => result.decision!.title;
}

class _NeedsYourYesRound extends _NeedsYourYesItem {
  _NeedsYourYesRound(this.roundNumber, this.title);
  final String roundNumber;

  @override
  final String title;
}
