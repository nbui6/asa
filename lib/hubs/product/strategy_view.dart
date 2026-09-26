/// Product Hub — the Strategy tab. Round 16, built against
/// `sketches\asa-strategy-v3.html`, after Nico rejected two Plan-tab
/// drafts on the same grounds — *"how is this helping me understand the
/// plan? Which part of the plan is done, I dont have the big picture."*
/// ADR 0025 (the strategy layer) and ADR 0026 (a round has a state, not a
/// checkbox) are the data model; ADR 0024 (areas) does not apply — Asa has
/// none, so an objective claims a Round directly, in its own text.
///
/// **Read-only, all of it — same rule as the Plan tab.** Tapping a Round
/// opens the project's own note (`open_url.dart`, already built); tapping
/// an ADR chip opens that decision when it is already loaded, or the same
/// note otherwise. Nothing here writes a byte anywhere.
library;

import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_state.dart';
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
    super.key,
  });

  final Strategy strategy;
  final List<Milestone> roadmap;
  final RoundApprovals approvals;
  final List<DecisionReadResult> decisions;
  final String charterSourceFile;
  final String personaSourceFile;
  final String projectSourceFile;

  @override
  State<StrategyView> createState() => _StrategyViewState();
}

class _StrategyViewState extends State<StrategyView> {
  // Every objective starts collapsed, same as the Plan tab — persona-check
  // ran on this exact screen shape twice this week (v2, v4) and both
  // failed on density; nothing here is expanded until asked for.
  final Set<int> _expanded = {};

  final RegExp _roundNumberInTitle = RegExp(
    r'^Round\s*(\d+)\b',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final strategy = widget.strategy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Who it's for"),
        _whoItsFor(_plain(strategy.whoItsFor!)),
        const SizedBox(height: 20),
        _label('Pain points'),
        Text(_plain(strategy.painPoints!)),
        const SizedBox(height: 20),
        _label('Objectives'),
        for (final objective in strategy.objectives) _objectiveTile(objective),
        const SizedBox(height: 12),
        _legend(),
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

  Widget _whoItsFor(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(text)),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => openUrl(widget.personaSourceFile),
          child: Text(
            'PERSONA.md ↗',
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

  // --- Objectives --------------------------------------------------

  Map<String, Milestone> _roadmapByNumber() {
    final byNumber = <String, Milestone>{};
    for (final milestone in widget.roadmap) {
      final number = _roundNumberInTitle.firstMatch(milestone.title)?.group(1);
      if (number != null) byNumber[number] = milestone;
    }
    return byNumber;
  }

  Widget _objectiveTile(Objective objective) {
    final id = identityHashCode(objective);
    final expanded = _expanded.contains(id);
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expanded.remove(id);
              } else {
                _expanded.add(id);
              }
            }),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _plain(objective.title),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (waiting > 0) ...[
                  _waitingPill(waiting),
                  const SizedBox(width: 8),
                ],
                Text(
                  '$completed of ${rounds.length} completed',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          // Round 35/G — `asa-strategy-v3`'s own approved drawing puts the
          // state chip and the "Would show: …" sentence under the title,
          // visible while collapsed — this had moved the chip into the
          // header row and hidden the sentence behind the expand arrow, on
          // an earlier persona-check's own overwhelm worry. Nico's call
          // when he approved the sketch, not the builder's: visible.
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_evidenceWord(objective.evidence) case final word?) ...[
                  _evidenceChip(word),
                  const SizedBox(width: 6),
                ],
                Expanded(child: _evidenceRow(objective.evidence)),
              ],
            ),
          ),
          if (rounds.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: ConstrainedBox(
                // Round 35/G — the sketch's bars run about the width of the
                // title column, not the full stretch of the window.
                constraints: const BoxConstraints(maxWidth: 480),
                child: _segmentBar(rounds.map((r) => r.state).toList()),
              ),
            ),
          ],
          if (expanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final round in rounds)
                    _roundRow(round.milestone, round.state),
                  if (adrLinks.isNotEmpty) _adrRow(adrLinks),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _waitingPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E9CD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count waiting for you',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7D4F08),
        ),
      ),
    );
  }

  Widget _segmentBar(List<RoundState> states) {
    return SizedBox(
      height: 8,
      child: Row(
        children: [
          for (final state in states) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _segmentColor(state),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (state != states.last) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }

  Color _segmentColor(RoundState state) {
    switch (state) {
      case RoundState.completed:
      case RoundState.noApprovalNeeded:
        return const Color(0xFF2A7355);
      case RoundState.waitingForApproval:
        return const Color(0xFFE0A63A);
      case RoundState.inProgress:
        return const Color(0xFF6F8FC4);
      case RoundState.planned:
        return const Color(0xFFEDEEF1);
    }
  }

  // The word-only chip already sits in the collapsed header row (rule 7:
  // colour is a hint, never the only signal, so the word has to be
  // visible even collapsed) — this expanded-only row is the sentence
  // behind it, never repeated as a second chip.
  Widget _evidenceRow(String evidence) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Would show: ${_plain(evidence)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
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

  Widget _evidenceChip(String word) {
    final Color background;
    final Color foreground;
    switch (word) {
      case 'holding':
        background = const Color(0xFFE4F0EA);
        foreground = const Color(0xFF2A7355);
      case 'failing':
        background = const Color(0xFFF6E4E4);
        foreground = const Color(0xFF9C3F3F);
      default:
        background = const Color(0xFFECEFF3);
        foreground = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        word,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _roundRow(Milestone milestone, RoundState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => openUrl(widget.projectSourceFile),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _plain(milestone.title),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
            _statePill(state),
          ],
        ),
      ),
    );
  }

  Widget _statePill(RoundState state) {
    final String label;
    final Color background;
    final Color foreground;
    switch (state) {
      case RoundState.completed:
        label = 'completed';
        background = const Color(0xFFE4F0EA);
        foreground = const Color(0xFF2A7355);
      case RoundState.waitingForApproval:
        label = 'waiting for your approval';
        background = const Color(0xFFF7E9CD);
        foreground = const Color(0xFF7D4F08);
      case RoundState.inProgress:
        label = 'in progress';
        background = const Color(0xFFE6ECF7);
        foreground = const Color(0xFF2F5FA6);
      case RoundState.planned:
        label = 'planned';
        background = const Color(0xFFEDEEF1);
        foreground = Colors.grey.shade600;
      case RoundState.noApprovalNeeded:
        label = 'no approval needed';
        background = const Color(0xFFE4F0EA);
        foreground = const Color(0xFF2A7355);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _adrRow(List<PlanLink> adrLinks) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [for (final link in adrLinks) _adrChip(link)],
            ),
          ),
          InkWell(
            onTap: () => openUrl(widget.charterSourceFile),
            child: Text(
              'open the text ↗',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adrChip(PlanLink link) {
    return Tooltip(
      message: link.sentence,
      child: InkWell(
        onTap: () => openUrl(_adrTarget(link)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE6ECF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'ADR ${link.target}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F5FA6),
            ),
          ),
        ),
      ),
    );
  }

  String _adrTarget(PlanLink link) {
    for (final result in widget.decisions) {
      if (result.decision?.number == link.target) {
        return result.decision!.sourceFile;
      }
    }
    return widget.charterSourceFile;
  }

  // --- Legend --------------------------------------------------------

  Widget _legend() {
    final unclaimed = _unclaimedCount();
    return Container(
      padding: const EdgeInsets.only(top: 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _legendDot(const Color(0xFF2A7355), 'completed'),
          _legendDot(const Color(0xFFE0A63A), 'waiting for your approval'),
          _legendDot(const Color(0xFF6F8FC4), 'in progress'),
          _legendDot(const Color(0xFFEDEEF1), 'planned'),
          if (unclaimed > 0)
            Text(
              unclaimed == 1
                  ? '1 round serves no objective yet'
                  : '$unclaimed rounds serve no objective yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
        ),
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
