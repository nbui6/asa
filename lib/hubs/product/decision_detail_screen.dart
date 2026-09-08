/// Product Hub — one decision, in full.
///
/// Pushed from the Decisions tab on `ProjectScreen` when a row is tapped.
/// v0.1's whole reason to exist: title, date, status, the decision, why,
/// what would change this, and the file it came from. 2026-09-07 (ADR
/// 0011): a proposed decision can also be decided here — Asa's first
/// write to a decision file, ever, and append-only.
library;

import 'package:asa/core/decision.dart';
import 'package:asa/core/decision_writer.dart';
import 'package:asa/core/markdown.dart';
import 'package:flutter/material.dart';

class DecisionDetailScreen extends StatefulWidget {
  const DecisionDetailScreen({required this.decision, super.key});

  final Decision decision;

  @override
  State<DecisionDetailScreen> createState() => _DecisionDetailScreenState();
}

class _DecisionDetailScreenState extends State<DecisionDetailScreen> {
  late Decision _decision;
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _error;

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

    return Scaffold(
      appBar: AppBar(title: Text(decision.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusLine(decision),
            const SizedBox(height: 24),
            _block('Decision', decision.decision),
            if (decision.why.isNotEmpty) ...[
              const SizedBox(height: 24),
              _block('Why', decision.why),
            ],
            if (decision.whatWouldChangeThis.isNotEmpty) ...[
              const SizedBox(height: 24),
              _block('What would change this', decision.whatWouldChangeThis),
            ],
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            if (decision.verdict != null)
              _recordedVerdict(decision.verdict!)
            else if (decision.isProposed &&
                canAppendVerdict(decision.sourceFile))
              _yourCall()
            else if (decision.isProposed)
              // A proposed decision from a shared decisions.md log — see
              // canAppendVerdict's own reasoning. Read-only here; deciding
              // it stays a hand edit, same as before this round.
              const Text(
                'Proposed. This project keeps its decisions in a shared '
                'log, so recording a call here is not supported yet — '
                'edit the file directly.',
                style: TextStyle(color: Colors.grey),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 32),
            Text(
              'Read from: ${decision.sourceFile}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(Decision decision) {
    final parts = <String>[
      if (decision.number != null) 'ADR ${decision.number}',
      if (decision.date != null) decision.date!,
      if (decision.displayStatus.isNotEmpty) decision.displayStatus,
    ];

    return Wrap(
      spacing: 12,
      children: [
        for (final part in parts)
          Text(part, style: const TextStyle(color: Colors.grey)),
        if (decision.supersededBy != null)
          Text(
            'Superseded by ${decision.supersededBy}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (decision.supersedes != null)
          Text(
            'Supersedes ${decision.supersedes}',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  /// The reason box and Reject/Accept buttons — `asa-decision-call.png`,
  /// state 1. Shown only while nothing has been recorded yet.
  Widget _yourCall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR CALL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => _recordVerdict(false),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
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
        const SizedBox(height: 4),
        Text(
          'Recorded ${verdict.date}, in this file. This is what next '
          'session reads.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _block(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // stripEmphasisMarkers: found on ADR 0012's real content — this
        // screen shows prose as plain text, so a literal `**` on screen
        // is a defect, not raw data worth preserving. The parsed
        // Decision fields themselves stay verbatim; only the display
        // strips markers.
        SelectableText(stripEmphasisMarkers(body)),
      ],
    );
  }
}
