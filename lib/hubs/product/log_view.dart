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
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

enum LogSubView { whatHappened, decisionsInForce }

class LogView extends StatefulWidget {
  const LogView({
    required this.projectFolder,
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
    super.key,
  });

  final String projectFolder;
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
        if (_view == LogSubView.whatHappened)
          _whatHappened()
        else
          _decisionsInForce(),
      ],
    );
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
                style: FilledButton.styleFrom(
                  backgroundColor: AsaColors.green,
                ),
                onPressed: () => _recordYesFor(item),
                child: const Text('Yes'),
              ),
              const SizedBox(width: AsaSpace.sm),
              OutlinedButton(
                onPressed: () => _openItem(item),
                child: const Text('Changes…'),
              ),
              const Spacer(),
              Text(
                '${index + 1} of ${waiting.length}',
                style: AsaText.meta,
              ),
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
    // A proposed decision's own Yes belongs on its detail screen, where
    // the reason box lives — opening it is the honest action here, not
    // guessing an accept with no reason recorded.
    await _openItem(item);
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monday.day} ${months[monday.month - 1]}';
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
                    width: 44,
                    child: Text(_timeOf(entry.date), style: AsaText.meta),
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

  String _timeOf(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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
