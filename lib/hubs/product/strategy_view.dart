/// Product Hub — the Strategy tab. Round 16, built against
/// `sketches\asa-strategy-v3.html`, after the user rejected two Plan-tab
/// drafts on the same grounds — *"how is this helping me understand the
/// plan? Which part of the plan is done, I dont have the big picture."*
/// ADR 0025 (the strategy layer) and ADR 0026 (a round has a state, not a
/// checkbox) are the data model; ADR 0024 (areas) does not apply — Asa has
/// none, so an objective claims a Round directly, in its own text.
/// Round 37 (ADR 0029) moves this screen onto the shared `ui/` parts —
/// its own layout is unchanged, exactly `asa-strategy-v3`.
///
/// **Read-only, all of it — same rule as the Plan tab.** Tapping a Round
/// opens the project's own note (`open_url.dart`, already built); tapping
/// an ADR chip opens that decision when it is already loaded, or the same
/// note otherwise. Nothing here writes a byte anywhere.
library;

import 'dart:async';

import 'package:asa/core/area.dart';
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_state.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class StrategyView extends StatefulWidget {
  const StrategyView({
    required this.strategy,
    required this.roadmap,
    required this.approvals,
    required this.decisions,
    required this.charterSourceFile,
    required this.personaSourceFile,
    required this.projectSourceFile,
    this.objectiveToOpen,
    this.areas = const [],
    this.onOpenArea,
    this.onDataChanged,
    super.key,
  });

  final Strategy strategy;
  final List<Milestone> roadmap;
  final RoundApprovals approvals;
  final List<DecisionReadResult> decisions;
  final String charterSourceFile;
  final String personaSourceFile;
  final String projectSourceFile;

  /// Round-36 §3, L12 — an area's "Objective N" chip on the Plan tab sets
  /// this to `"N"` (1-based, matching `CHARTER.md`'s own numbered list)
  /// and switches to this tab; that one objective opens on the next build.
  /// Read once, on the change that sets it — see `_StrategyViewState`'s
  /// own `didUpdateWidget`, same pattern `PlanView.areaToOpen` uses.
  final String? objectiveToOpen;

  /// Round-36 §3, L17 — every project area, so an ADR chip's own decision
  /// detail screen (L15) can show which ones name it. Empty for a test
  /// that does not need it — `Decisions` tab or `PlanView` already loads
  /// the real list either way.
  final List<Area> areas;

  /// Handed straight through to a `DecisionDetailScreen` this widget
  /// pushes, so an area chip shown there lands on the Plan tab with that
  /// area open. Null keeps that chip inert.
  final void Function(Area area)? onOpenArea;

  /// Round 36 cp6 — same as `PlanView.onDataChanged`: called when an ADR
  /// chip's own pushed `DecisionDetailScreen` reports a verdict was
  /// actually recorded, so the caller can reload its own cached
  /// `decisions` rather than show what was true before that Accept/Reject.
  final VoidCallback? onDataChanged;

  @override
  State<StrategyView> createState() => _StrategyViewState();
}

class _StrategyViewState extends State<StrategyView> {
  // Every objective starts collapsed, same as the Plan tab — persona-check
  // ran on this exact screen shape twice this week (v2, v4) and both
  // failed on density; nothing here is expanded until asked for.
  //
  // Keyed by the objective's own 0-based position in `strategy.objectives`
  // — not `identityHashCode`, per round-36 §3 L12: a fresh `Strategy` is
  // read on every `ProjectScreen._load()`, and identity would not survive
  // that reload, the exact bug `PlanView._expandedAreas` already found and
  // fixed the same way for areas.
  final Set<int> _expanded = {};

  final RegExp _roundNumberInTitle = RegExp(
    r'^Round\s*(\d+)\b',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    final index = _objectiveIndex(widget.objectiveToOpen);
    if (index != null) _expanded.add(index);
  }

  @override
  void didUpdateWidget(StrategyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only react to a genuinely new request — see `PlanView`'s own
    // `didUpdateWidget` for why this guard matters.
    if (widget.objectiveToOpen != null &&
        widget.objectiveToOpen != oldWidget.objectiveToOpen) {
      final index = _objectiveIndex(widget.objectiveToOpen);
      if (index != null) _expanded.add(index);
    }
  }

  /// `"1"` → `0` — an objective's own 1-based number, as `CHARTER.md`'s
  /// numbered list and `area.dart`'s `objectiveNumbers` both write it,
  /// converted to this list's 0-based position. Null for anything that
  /// does not parse, or that names an objective past the end of the list.
  int? _objectiveIndex(String? number) {
    if (number == null) return null;
    final n = int.tryParse(number);
    if (n == null || n < 1 || n > widget.strategy.objectives.length) {
      return null;
    }
    return n - 1;
  }

  @override
  Widget build(BuildContext context) {
    final strategy = widget.strategy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Who it's for"),
        const SizedBox(height: AsaSpace.xs),
        _whoItsFor(_plain(strategy.whoItsFor!)),
        const SizedBox(height: AsaSpace.lg),
        const SectionLabel('Pain points'),
        const SizedBox(height: AsaSpace.xs),
        Text(_plain(strategy.painPoints!), style: AsaText.body),
        const SizedBox(height: AsaSpace.lg),
        const SectionLabel('Objectives'),
        for (var i = 0; i < strategy.objectives.length; i++)
          _objectiveTile(strategy.objectives[i], i),
        const SizedBox(height: AsaSpace.md),
        _legend(),
      ],
    );
  }

  Widget _whoItsFor(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(text, style: AsaText.body)),
        const SizedBox(width: AsaSpace.sm),
        LinkChip(
          'PERSONA.md ↗',
          onTap: () => openUrl(widget.personaSourceFile),
        ),
      ],
    );
  }

  // --- Objectives --------------------------------------------------

  Map<String, Milestone> _roadmapByNumber() {
    final byNumber = <String, Milestone>{};
    for (final milestone in widget.roadmap) {
      final number = _roundNumberInTitle.firstMatch(milestone.title)?.group(1);
      if (number != null) byNumber[number] = milestone;
    }
    return byNumber;
  }

  Widget _objectiveTile(Objective objective, int index) {
    final expanded = _expanded.contains(index);
    final byNumber = _roadmapByNumber();

    final roundLinks = _dedupeByTarget(
      deriveLinks(objective.sentence)
          .where((l) => l.kind == PlanLinkKind.round),
    );
    final rounds = [
      for (final link in roundLinks)
        if (byNumber[link.target] case final milestone?)
          (
            milestone: milestone,
            state: roundStateOf(milestone, widget.approvals),
          ),
    ];
    final adrLinks = _dedupeByTarget(
      deriveLinks(objective.sentence).where((l) => l.kind == PlanLinkKind.adr),
    );

    final completed = rounds
        .where(
          (r) =>
              r.state == RoundState.completed ||
              r.state == RoundState.noApprovalNeeded,
        )
        .length;
    final waiting = rounds
        .where((r) => r.state == RoundState.waitingForApproval)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AsaSpace.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AsaColors.soft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expanded.remove(index);
              } else {
                _expanded.add(index);
              }
            }),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: AsaColors.ink3,
                ),
                const SizedBox(width: AsaSpace.xs),
                Expanded(
                  child: Text(_plain(objective.title), style: AsaText.rowName),
                ),
                if (waiting > 0) ...[
                  Pill(
                    '$waiting waiting for you',
                    meaning: AsaMeaning.needsYou,
                  ),
                  const SizedBox(width: AsaSpace.sm),
                ],
                // Round 37 §D5 — a zero count isn't shown: "0 of 0
                // completed" said nothing a person could act on.
                if (rounds.isNotEmpty)
                  Text(
                    '$completed of ${rounds.length} completed',
                    style: AsaText.meta,
                  ),
              ],
            ),
          ),
          // Round 35/G — `asa-strategy-v3`'s own approved drawing puts the
          // state chip and the "Would show: …" sentence under the title,
          // visible while collapsed — this had moved the chip into the
          // header row and hidden the sentence behind the expand arrow, on
          // an earlier persona-check's own overwhelm worry. The user's call
          // when he approved the sketch, not the builder's: visible.
          const SizedBox(height: AsaSpace.xs),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_evidenceMeaning(objective.evidence) case final m?) ...[
                  Pill(_evidenceWord(objective.evidence)!, meaning: m),
                  const SizedBox(width: AsaSpace.xs),
                ],
                Expanded(child: _evidenceRow(objective.evidence)),
              ],
            ),
          ),
          if (rounds.isNotEmpty) ...[
            const SizedBox(height: AsaSpace.xs),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: ConstrainedBox(
                // Round 35/G — the sketch's bars run about the width of the
                // title column, not the full stretch of the window.
                constraints: const BoxConstraints(maxWidth: 480),
                child: ProgressBar(
                  segments: [for (final r in rounds) _roundFraction(r.state)],
                  meanings: [for (final r in rounds) _roundMeaning(r.state)],
                ),
              ),
            ),
          ],
          if (expanded) ...[
            const SizedBox(height: AsaSpace.xs),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final round in rounds)
                    _roundRow(round.milestone, round.state),
                  if (adrLinks.isNotEmpty) _adrRow(adrLinks),
                  // Round 38 §D.1 — anything else CHARTER.md holds for
                  // this objective (most often "Served by Round N, …")
                  // shows only now, opened, never in the collapsed row.
                  if (objectiveWhy(objective) case final why?) ...[
                    const SizedBox(height: AsaSpace.sm),
                    const SectionLabel('Why'),
                    const SizedBox(height: 2),
                    Text(_plain(why), style: AsaText.body),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Round-37 §2 — a round is either done or not, never partly; "planned"
  // stays unfilled (0), matching the sketch's own light-grey planned
  // segment, which `ProgressBar`'s own soft background already draws.
  double _roundFraction(RoundState state) =>
      state == RoundState.planned ? 0 : 1;

  AsaMeaning _roundMeaning(RoundState state) => switch (state) {
    RoundState.completed || RoundState.noApprovalNeeded => AsaMeaning.done,
    RoundState.waitingForApproval => AsaMeaning.needsYou,
    RoundState.inProgress => AsaMeaning.moving,
    RoundState.planned => AsaMeaning.quiet,
  };

  // The word-only chip already sits in the collapsed header row (rule 7:
  // colour is a hint, never the only signal, so the word has to be
  // visible even collapsed) — this expanded-only row is the sentence
  // behind it, never repeated as a second chip.
  Widget _evidenceRow(String evidence) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text('Would show: ${_plain(evidence)}', style: AsaText.meta),
        ),
      ],
    );
  }

  final RegExp _boldWord = RegExp(r'\*\*(\w+)');

  String? _evidenceWord(String evidence) {
    final match = _boldWord.firstMatch(evidence);
    if (match == null) return null;
    final word = match.group(1)!.toLowerCase();
    return ['unknown', 'holding', 'failing'].contains(word) ? word : null;
  }

  /// ADR 0029 has no separate "error" meaning — "failing" is the most
  /// urgent of the three evidence words, so it takes "needs you" (amber),
  /// same reasoning the overdue-deadline signal already uses (round 37
  /// cp1). "Holding" is done/green; "unknown" is quiet/grey.
  AsaMeaning? _evidenceMeaning(String evidence) {
    switch (_evidenceWord(evidence)) {
      case 'holding':
        return AsaMeaning.done;
      case 'failing':
        return AsaMeaning.needsYou;
      case 'unknown':
        return AsaMeaning.quiet;
      default:
        return null;
    }
  }

  Widget _roundRow(Milestone milestone, RoundState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => openUrl(widget.projectSourceFile),
        child: Row(
          children: [
            Expanded(child: Text(_plain(milestone.title), style: AsaText.body)),
            Pill(_stateLabel(state), meaning: _roundMeaning(state)),
          ],
        ),
      ),
    );
  }

  String _stateLabel(RoundState state) => switch (state) {
    RoundState.completed => 'completed',
    RoundState.waitingForApproval => 'waiting for your approval',
    RoundState.inProgress => 'in progress',
    RoundState.planned => 'planned',
    RoundState.noApprovalNeeded => 'no approval needed',
  };

  Widget _adrRow(List<PlanLink> adrLinks) {
    return Padding(
      padding: const EdgeInsets.only(top: AsaSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: AsaSpace.xs,
              children: [for (final link in adrLinks) _adrChip(link)],
            ),
          ),
          LinkChip(
            'open the text ↗',
            onTap: () => openUrl(widget.charterSourceFile),
          ),
        ],
      ),
    );
  }

  /// Round-37 §D3 — "both show both": the number with the (shortened)
  /// title, when the decision is actually loaded; the bare number, same
  /// as before, when it is not (the raw-file fallback `_openAdr` also
  /// uses).
  Widget _adrChip(PlanLink link) {
    final decision = _decisionFor(link.target);
    final label = decision == null
        ? 'ADR ${link.target}'
        : decisionChipLabel(decision.number, decision.title);
    return Tooltip(
      message: link.sentence,
      child: LinkChip(label, onTap: () => _openAdr(link)),
    );
  }

  Decision? _decisionFor(String number) {
    for (final result in widget.decisions) {
      if (result.decision?.number == number) return result.decision;
    }
    return null;
  }

  /// Round-36 §3, L15 — a loaded decision opens the real in-app detail
  /// screen, same as `PlanView`'s own area ADR chip; popping back returns
  /// to this same Strategy tab with this same objective still expanded,
  /// since neither is touched by the push. The Round link stays on
  /// `openUrl` unchanged — "as built today", per L15's own wording.
  Future<void> _openAdr(PlanLink link) async {
    final decision = _decisionFor(link.target);
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
    unawaited(openUrl(widget.charterSourceFile));
  }

  // --- Legend --------------------------------------------------------

  Widget _legend() {
    final unclaimed = _unclaimedCount();
    // Round 37 §D5 — the legend only makes sense once a bar is actually
    // shown; a project with no rounds at all (or none claimed by any
    // objective) has nothing for it to explain.
    if (widget.roadmap.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(top: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AsaColors.soft)),
      ),
      child: Wrap(
        spacing: AsaSpace.lg,
        runSpacing: AsaSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _legendDot(AsaMeaning.done, 'completed'),
          _legendDot(AsaMeaning.needsYou, 'waiting for your approval'),
          _legendDot(AsaMeaning.moving, 'in progress'),
          _legendDot(AsaMeaning.quiet, 'planned'),
          if (unclaimed > 0)
            Text(
              unclaimed == 1
                  ? '1 round serves no objective yet'
                  : '$unclaimed rounds serve no objective yet',
              style: AsaText.meta,
            ),
        ],
      ),
    );
  }

  Widget _legendDot(AsaMeaning meaning, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: meaning.fg,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AsaText.meta),
      ],
    );
  }

  int _unclaimedCount() {
    final claimed = <String>{};
    for (final objective in widget.strategy.objectives) {
      for (final link in deriveLinks(objective.sentence)) {
        if (link.kind == PlanLinkKind.round) claimed.add(link.target);
      }
    }
    final byNumber = _roadmapByNumber();
    return byNumber.keys.where((n) => !claimed.contains(n)).length;
  }

  List<PlanLink> _dedupeByTarget(Iterable<PlanLink> links) {
    final seen = <String>{};
    final result = <PlanLink>[];
    for (final link in links) {
      if (seen.add(link.target)) result.add(link);
    }
    return result;
  }

  /// `CHARTER.md` is real prose, `**bold**` and `` `code` `` included —
  /// found the same way `tasks_view.dart` found it on real task text: a
  /// literal asterisk or backtick on screen is a rendering defect, not
  /// data worth preserving. Applied only at display time, same as there;
  /// [Objective.evidence] and [Objective.sentence] themselves stay raw
  /// for `deriveLinks` to read.
  String _plain(String text) =>
      stripCodeSpanMarkers(stripEmphasisMarkers(text));
}
