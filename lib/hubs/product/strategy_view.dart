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
/// **Read-only for the rounds and ADRs it links** — tapping a chip opens
/// that decision when it is already loaded, or the project's own note
/// otherwise (`open_url.dart`); nothing here writes a round or a
/// decision. **Writable for the strategy itself, ADR 0044/0050:**
/// *Who it's for*, *Pain points* and a first *Objective*, each an empty
/// place (heading + ＋) until the user types it, same `_sectionField`
/// shape `PlanView`'s own Goal/Plan already use — `onSetCharterSection`/
/// `onClearCharterSection` do the writing, `area_section_writer.dart`'s
/// own `setAreaSection`/`clearAreaSection` reused directly against
/// `CHARTER.md`. A project with no `CHARTER.md` at all gets the one
/// line and the one ＋ that creates it (`onCreateCharterFile`).
///
/// **Round 38 §C — a round's own row goes to its own *Your call* screen**
/// (`round_call_screen.dart`'s `openRoundCall`) once the three writer
/// callbacks are wired in, same as the Log tab's identical *Needs your
/// yes* card; the per-objective *"N waiting for your yes"* pill opens the
/// Log tab itself. Neither wired (the old default, and every test that
/// hasn't opted in) falls back to `open_url.dart`'s raw-file open, this
/// screen's original behaviour.
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
import 'package:asa/hubs/product/round_call_screen.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/escape_to_cancel.dart';
import 'package:asa/hubs/product/ui/hover_pencil.dart';
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
    this.onOpenLog,
    this.loadRoundText,
    this.onApproveRound,
    this.onRequestRoundChanges,
    this.onSetCharterSection,
    this.onClearCharterSection,
    this.onCreateCharterFile,
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

  /// Round 38 §C, L19 — "The Strategy 'waiting for your yes →' link opens
  /// the Log with the card" (§E). Null leaves the per-objective waiting
  /// pill inert rather than a link that goes nowhere.
  final VoidCallback? onOpenLog;

  /// Round 38 §C, L20 — "a round's own row inside an objective... goes to
  /// its Your call screen," the same three injected callbacks
  /// `RoundCallScreen` already needs, wired here the same way `LogView`
  /// wires them (`openRoundCall`, `round_call_screen.dart`). All three
  /// null together falls back to opening the raw project note instead —
  /// this screen's own older behaviour, kept as the graceful default for
  /// a caller (or a test) that hasn't wired real writers.
  final Future<String?> Function(String roundNumber)? loadRoundText;
  final Future<void> Function(
    String roundNumber, {
    required String roundTitle,
    String? feedback,
  })?
  onApproveRound;
  final Future<void> Function(String roundNumber, {required String what})?
  onRequestRoundChanges;

  /// ADR 0050 — fills an empty *Who it's for*/*Pain points* (the ＋,
  /// `oldValue` is `''`), fills a brand-new first *Objective* the same
  /// way, or rewrites one from ✎ on existing text. Null keeps every
  /// section read-only, for a caller (or test) not wired for it.
  final Future<void> Function(String heading, String oldValue, String newText)?
  onSetCharterSection;

  /// ADR 0050 — 🗑 in a filled *Who it's for*/*Pain points* own edit mode.
  /// Null keeps 🗑 off the edit row entirely.
  final Future<void> Function(String heading)? onClearCharterSection;

  /// ADR 0050 — the single ＋ a project with no `CHARTER.md` at all gets:
  /// creates the file with its four empty headings. Null falls back to
  /// the older "ask the AI to write CHARTER.md" line, for a caller (or
  /// test) not wired for it.
  final Future<void> Function()? onCreateCharterFile;

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

  /// ADR 0050 — the one empty place currently open for typing, keyed by
  /// its own heading (`"Who it's for"`, `"Pain points"`, `"Objectives"`);
  /// null when none is. One `Strategy` per project, unlike `PlanView`'s
  /// many areas, so the heading alone disambiguates.
  String? _addingSectionKey;
  final _sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final index = _objectiveIndex(widget.objectiveToOpen);
    if (index != null) _expanded.add(index);
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
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
    // ADR 0050 — no file at all is the one case with its own single line
    // and single ＋, never a per-section empty place with nothing to
    // attach to.
    if (!strategy.fileExists) return _noCharterBody();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel("Who it's for"),
        const SizedBox(height: AsaSpace.xs),
        _sectionField("Who it's for", strategy.whoItsFor, _whoItsFor),
        const SizedBox(height: AsaSpace.lg),
        const SectionLabel('Pain points'),
        const SizedBox(height: AsaSpace.xs),
        _sectionField(
          'Pain points',
          strategy.painPoints,
          (text) => Text(text, style: AsaText.body),
        ),
        const SizedBox(height: AsaSpace.lg),
        const SectionLabel('Objectives'),
        const SizedBox(height: AsaSpace.xs),
        if (strategy.objectives.isEmpty)
          _firstObjectiveField()
        else
          for (var i = 0; i < strategy.objectives.length; i++)
            _objectiveTile(strategy.objectives[i], i),
        const SizedBox(height: AsaSpace.md),
        _legend(),
      ],
    );
  }

  Widget _noCharterBody() {
    final create = widget.onCreateCharterFile;
    if (create == null) {
      return const EmptyLine(
        'No strategy yet. Start → Copy opener, and ask the AI to write '
        'CHARTER.md.',
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: EmptyLine('No strategy yet.')),
        Tooltip(
          message: 'add',
          child: InkWell(
            onTap: create,
            child: Text(
              '＋',
              style: AsaText.body.copyWith(color: AsaColors.blue),
            ),
          ),
        ),
      ],
    );
  }

  // --- Who it's for / Pain points: one free-text section each ----------

  /// ADR 0050 — one `CHARTER.md` section (`Who it's for`/`Pain points`),
  /// in whichever of its three states applies: empty (heading and ＋
  /// only), read (filled, ✎ revealed on hover once a writer is wired in),
  /// or being typed. Same shape `PlanView`'s own `_sectionField` already
  /// uses for an area's Goal/Plan, keyed by heading alone — one
  /// `CHARTER.md` per project, not many area pages.
  Widget _sectionField(
    String heading,
    String? rawValue,
    Widget Function(String displayText) renderFilled,
  ) {
    final write = widget.onSetCharterSection;
    final hasValue = rawValue != null && rawValue.isNotEmpty;

    if (write != null && _addingSectionKey == heading) {
      Future<void> submit() async {
        final text = _sectionController.text.trim();
        setState(() => _addingSectionKey = null);
        if (text.isEmpty || text == rawValue) return;
        await write(heading, rawValue ?? '', text);
        widget.onDataChanged?.call();
      }

      final clear = widget.onClearCharterSection;
      final field = EscapeToCancel(
        onEscape: () => setState(() => _addingSectionKey = null),
        child: TextField(
          controller: _sectionController,
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => submit(),
        ),
      );
      // ADR 0050 — 🗑 only once there is something to remove: the ＋ path
      // opens this same editing branch from empty.
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
                await clear(heading);
                widget.onDataChanged?.call();
              },
            ),
          ),
        ],
      );
    }

    if (!hasValue) {
      if (write == null) {
        return EmptyLine('No ${heading.toLowerCase()} yet.');
      }
      return Tooltip(
        message: 'add',
        child: InkWell(
          onTap: () => setState(() {
            _addingSectionKey = heading;
            _sectionController.clear();
          }),
          child: Text('＋', style: AsaText.body.copyWith(color: AsaColors.blue)),
        ),
      );
    }

    final content = renderFilled(_plain(rawValue));
    if (write == null) return content;

    return HoverPencil(
      onEdit: () => setState(() {
        _addingSectionKey = heading;
        _sectionController.text = rawValue;
      }),
      child: content,
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

  /// ADR 0050 — the Objectives section's own empty place: the heading
  /// and ＋ only, same as the other two, but what gets written is the
  /// minimal structural wrapper a real objective needs to parse at all
  /// (`charter.dart`'s `_objectiveMarker`/`_titleSpan`) — `1. **<typed
  /// text>**` — never invented prose beyond what the user typed. Adding
  /// a second objective, or editing one already there, is not in this
  /// round's own scope; only the empty case reaches this widget.
  Widget _firstObjectiveField() {
    const heading = 'Objectives';
    final write = widget.onSetCharterSection;

    if (write != null && _addingSectionKey == heading) {
      Future<void> submit() async {
        final text = _sectionController.text.trim();
        setState(() => _addingSectionKey = null);
        if (text.isEmpty) return;
        await write(heading, '', '1. **$text**\n');
        widget.onDataChanged?.call();
      }

      return EscapeToCancel(
        onEscape: () => setState(() => _addingSectionKey = null),
        child: TextField(
          controller: _sectionController,
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
          onSubmitted: (_) => submit(),
        ),
      );
    }

    if (write == null) return const EmptyLine('No objectives yet.');
    return Tooltip(
      message: 'add',
      child: InkWell(
        onTap: () => setState(() {
          _addingSectionKey = heading;
          _sectionController.clear();
        }),
        child: Text('＋', style: AsaText.body.copyWith(color: AsaColors.blue)),
      ),
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
            number: link.target,
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
                  // Round 38 §C, L19 — "the 'N waiting for your approval'
                  // pill becomes a link... it opens" the Log tab (§E's
                  // own Needs-your-yes card). Its own `InkWell`, nested
                  // inside the header row's own expand/collapse one — the
                  // more specific tap wins, same pattern the news marker
                  // on the overview row already relies on.
                  InkWell(
                    onTap: widget.onOpenLog,
                    borderRadius: BorderRadius.circular(100),
                    child: Pill(
                      '$waiting waiting for your yes →',
                      meaning: AsaMeaning.needsYou,
                    ),
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
                    _roundRow(round.number, round.milestone, round.state),
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

  Widget _roundRow(String number, Milestone milestone, RoundState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => _openRound(number, milestone),
        child: Row(
          children: [
            Expanded(child: Text(_plain(milestone.title), style: AsaText.body)),
            Pill(_stateLabel(state), meaning: _roundMeaning(state)),
          ],
        ),
      ),
    );
  }

  /// Round 38 §C, L20 — "a round's own row... goes to its Your call
  /// screen" once the three writer callbacks are actually wired in;
  /// falls back to this screen's own older behaviour (the raw project
  /// note) when they aren't, same graceful default `_adrChip`'s own ADR
  /// fallback already uses for an unloaded decision.
  Future<void> _openRound(String number, Milestone milestone) async {
    final loadRoundText = widget.loadRoundText;
    final onApproveRound = widget.onApproveRound;
    final onRequestRoundChanges = widget.onRequestRoundChanges;
    if (loadRoundText == null ||
        onApproveRound == null ||
        onRequestRoundChanges == null) {
      unawaited(openUrl(widget.projectSourceFile));
      return;
    }
    await openRoundCall(
      context,
      roundNumber: number,
      roundTitle: _plain(milestone.title),
      loadRoundText: loadRoundText,
      onApproveRound: onApproveRound,
      onRequestRoundChanges: onRequestRoundChanges,
      existingApproval: widget.approvals.approvalFor(number),
      onDataChanged: widget.onDataChanged,
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
