/// Product Hub — one decision, in full.
///
/// Pushed from the Decisions tab on `ProjectScreen` when a row is tapped.
/// v0.1's whole reason to exist: title, date, status, the decision, why,
/// what would change this, and the file it came from. 2026-09-07 (ADR
/// 0011): a proposed decision can also be decided here — Asa's first
/// write to a decision file, ever, and append-only. Round 37 (ADR 0029)
/// moves this screen onto `AsaPage` — the same header every page uses,
/// where this one used its own small `AppBar` title next to the arrow —
/// and shows its number with its title (§D3: "both show both"), never
/// just one.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/decision_writer.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/hubs/product/ui/area_chip.dart';
import 'package:asa/hubs/product/ui/asa_page.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/source_line.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class DecisionDetailScreen extends StatefulWidget {
  const DecisionDetailScreen({
    required this.decision,
    this.areasNaming = const [],
    this.onOpenArea,
    super.key,
  });

  final Decision decision;

  /// Round-36 §3, L17 — every area (any project's, in practice the
  /// caller's own) whose `decisionNumbers` names this decision. Empty
  /// shows no chip at all, same absence rule as everywhere else.
  final List<Area> areasNaming;

  /// Pops this screen, then tells the caller which area to open on its
  /// own Plan tab. Null keeps every chip here inert, for a caller not
  /// wired for it yet.
  final void Function(Area area)? onOpenArea;

  @override
  State<DecisionDetailScreen> createState() => _DecisionDetailScreenState();
}

class _DecisionDetailScreenState extends State<DecisionDetailScreen> {
  late Decision _decision;
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _error;

  /// Round 36 cp6 — found by the click-through test: recording a verdict
  /// only ever updated this screen's own local `_decision`. A caller that
  /// pushed this screen (the Decisions tab row, an area's own ADR chip, an
  /// objective's own ADR chip) kept its own, now-stale cached decisions
  /// list, so accepting or rejecting here and then coming back — by the
  /// plain back button or by this screen's own area chip — showed the
  /// *old* status until an unrelated reload happened to run. Popping with
  /// this flag lets every caller reload only when something actually
  /// changed, not on every visit.
  bool _verdictJustRecorded = false;

  @override
  void initState() {
    super.initState();
    _decision = widget.decision;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  /// Writes the verdict, then re-reads the file rather than trusting what
  /// this session assumes it wrote — the same discipline ADR 0011 asks
  /// for, and the only way to be sure a half-written file never shows as
  /// decided when it is not.
  ///
  /// **The `if (_saving) return` guard is load-bearing, not defensive
  /// filler.** Found on `0012-the-doorman.md`: five identical `## Your
  /// call` blocks from one real Accept click. The button's own `onPressed:
  /// _saving ? null : …` disables it, but only once a rebuild has actually
  /// happened — two tap events recognised in the same frame, before that
  /// rebuild lands, both reach this method while `_saving` is still
  /// false. Checking `_saving` here, synchronously, before the first
  /// `await`, closes that window: Dart runs the two calls one after the
  /// other, never concurrently, so the second one always sees what the
  /// first one just set.
  Future<void> _recordVerdict(bool accepted) async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await appendVerdict(
        _decision.sourceFile,
        accepted: accepted,
        reason: _reasonController.text,
        date: DateTime.now(),
      );
      final reread = await rereadDecision(_decision.sourceFile);
      if (!mounted) return;
      if (!reread.isSuccess) {
        setState(() {
          _saving = false;
          _error =
              'Wrote the verdict, but could not re-read it back: '
              '${reread.error}';
        });
        return;
      }
      setState(() {
        _decision = reread.decision!;
        _saving = false;
        _verdictJustRecorded = true;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final decision = _decision;

    return AsaPage(
      name: _titleWithNumber(decision),
      onBack: () => Navigator.of(context).pop(_verdictJustRecorded),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusLine(decision),
          if (widget.areasNaming.isNotEmpty) ...[
            const SizedBox(height: AsaSpace.sm),
            Wrap(
              spacing: AsaSpace.xs,
              runSpacing: AsaSpace.xs,
              children: [
                for (final area in widget.areasNaming)
                  AreaChip(area.name, onTap: () => _openArea(area)),
              ],
            ),
          ],
          const SizedBox(height: AsaSpace.xl),
          _block('Decision', decision.decision),
          if (decision.why.isNotEmpty) ...[
            const SizedBox(height: AsaSpace.xl),
            _block('Why', decision.why),
          ],
          if (decision.whatWouldChangeThis.isNotEmpty) ...[
            const SizedBox(height: AsaSpace.xl),
            _block('What would change this', decision.whatWouldChangeThis),
          ],
          const SizedBox(height: AsaSpace.xl),
          const Divider(height: 1),
          const SizedBox(height: AsaSpace.xl),
          if (decision.verdict != null)
            _recordedVerdict(decision.verdict!)
          else if (decision.isProposed && canAppendVerdict(decision.sourceFile))
            _yourCall()
          else if (decision.isProposed)
            // A proposed decision from a shared decisions.md log — see
            // canAppendVerdict's own reasoning. Read-only here; deciding
            // it stays a hand edit, same as before this round.
            const Text(
              'Proposed. This project keeps its decisions in a shared '
              'log, so recording a call here is not supported yet — '
              'edit the file directly.',
              style: TextStyle(color: AsaColors.ink3),
            ),
          if (_error != null) ...[
            const SizedBox(height: AsaSpace.md),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: AsaSpace.xl),
          SourceLine(decision.sourceFile),
        ],
      ),
    );
  }

  /// Round-37 §D3 — "both show both": the header names the decision's own
  /// number alongside its title, same as the Decisions tab row and the
  /// Plan tab's own ADR chip already do.
  String _titleWithNumber(Decision decision) {
    return decision.number == null
        ? decision.title
        : '${decision.number} · ${decision.title}';
  }

  void _openArea(Area area) {
    final onOpenArea = widget.onOpenArea;
    if (onOpenArea == null) return;
    Navigator.of(context).pop(_verdictJustRecorded);
    onOpenArea(area);
  }

  Widget _statusLine(Decision decision) {
    final parts = <String>[
      if (decision.date != null) decision.date!,
      if (decision.displayStatus.isNotEmpty) decision.displayStatus,
    ];

    return Wrap(
      spacing: AsaSpace.md,
      children: [
        for (final part in parts) Text(part, style: AsaText.meta),
        if (decision.supersededBy != null)
          Text(
            'Superseded by ${decision.supersededBy}',
            style: const TextStyle(
              color: AsaColors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (decision.supersedes != null)
          Text('Supersedes ${decision.supersedes}', style: AsaText.meta),
      ],
    );
  }

  /// The reason box and Reject/Accept buttons — `asa-decision-call.png`,
  /// state 1. Shown only while nothing has been recorded yet.
  Widget _yourCall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Your call'),
        const SizedBox(height: AsaSpace.sm),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          enabled: !_saving,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText:
                "Why are you deciding this way? (optional, but it's what "
                'next session reads)',
          ),
        ),
        const SizedBox(height: AsaSpace.md),
        Row(
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => _recordVerdict(false),
              child: const Text('Reject'),
            ),
            const SizedBox(width: AsaSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AsaColors.green),
              onPressed: _saving ? null : () => _recordVerdict(true),
              child: Text(_saving ? 'Saving…' : 'Accept'),
            ),
          ],
        ),
      ],
    );
  }

  /// State 3 of the sketch — the block replaced by one line, same visual
  /// language as "Why."
  Widget _recordedVerdict(Verdict verdict) {
    final verb = verdict.accepted ? 'Accepted' : 'Rejected';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(
                text: 'Your call. ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: '$verb — "${verdict.reason}"'),
            ],
          ),
        ),
        const SizedBox(height: AsaSpace.xs),
        Text(
          'Recorded ${verdict.date}, in this file. This is what next '
          'session reads.',
          style: AsaText.meta,
        ),
      ],
    );
  }

  Widget _block(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AsaSpace.sm),
        // stripEmphasisMarkers: found on ADR 0012's real content — this
        // screen shows prose as plain text, so a literal `**` on screen
        // is a defect, not raw data worth preserving. The parsed
        // Decision fields themselves stay verbatim; only the display
        // strips markers.
        SelectableText(stripEmphasisMarkers(body), style: AsaText.body),
      ],
    );
  }
}
