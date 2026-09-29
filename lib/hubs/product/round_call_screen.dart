/// Product Hub — a round's own "Your call" screen (Round 38 §C).
///
/// Pushed when a waiting round is tapped (Strategy's own round row, or —
/// once §E lands — the Log's own *Needs your yes* card). Same layout as
/// `decision_detail_screen.dart`: title, pills, what was built, how to
/// check it, the file, then Your call. **Yes** appends one row to
/// `rounds\APPROVED.md`; **Needs changes** appends one row to
/// `rounds\CHANGES.md` — both through `round_call_writer.dart`, ADR
/// 0021/0026's own narrow amendment (2026-09-28). After either, the block
/// becomes one line, the same way it does for a decision.
///
/// **Reading and writing are both injected, not called directly** — the
/// caller (wherever this screen is pushed from) wires
/// `loadRoundText`/`onApprove`/`onRequestChanges` to the real
/// `round_file.dart`/`round_call_writer.dart` functions in production,
/// and a fake in a test. Found necessary, not merely tidy: a widget test
/// driving this screen's own Yes/Needs-changes buttons through the real
/// `dart:io`-backed functions hit the exact same reproducible hang
/// `plan_view.dart`'s `+ Add area` dialog test did (a second real async
/// disk call, this time triggered from inside a button's own `onPressed`
/// rather than an un-awaited callback) — a `runAsync`/`FakeAsync`
/// interaction specific to this test binding, not a production risk.
/// Isolating the real functions behind an injectable seam, proven
/// separately by `round_file_test.dart`/`round_call_writer_test.dart`,
/// sidesteps it without leaving this screen's own logic unverified.
library;

import 'package:asa/core/changes_file.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_file.dart';
import 'package:asa/hubs/product/ui/asa_page.dart';
import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Pushes [RoundCallScreen] for one real round, wiring the same three
/// injected callbacks every caller needs (`loadRoundText`, `onApprove`,
/// `onRequestChanges`) to that round's own number and title — the one
/// place this push happens, shared by the Log tab's own *Needs your yes*
/// card and the Strategy tab's own round row (round-38.md §C: "a round's
/// own row inside an objective... goes to its *Your call* screen"),
/// rather than two copies of the same `Navigator.push` that could drift.
Future<void> openRoundCall(
  BuildContext context, {
  required String roundNumber,
  required String roundTitle,
  required Future<String?> Function(String roundNumber) loadRoundText,
  required Future<void> Function(
    String roundNumber, {
    required String roundTitle,
    String? feedback,
  })
  onApproveRound,
  required Future<void> Function(String roundNumber, {required String what})
  onRequestRoundChanges,
  RoundApproval? existingApproval,
  ChangeRequest? existingChangeRequest,
  VoidCallback? onDataChanged,
}) async {
  final changed = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => RoundCallScreen(
        roundNumber: roundNumber,
        loadRoundText: () => loadRoundText(roundNumber),
        onApprove: ({required feedback}) => onApproveRound(
          roundNumber,
          roundTitle: roundTitle,
          feedback: feedback,
        ),
        onRequestChanges: ({required what}) =>
            onRequestRoundChanges(roundNumber, what: what),
        onOpenRoundFile: () {},
        existingApproval: existingApproval,
        existingChangeRequest: existingChangeRequest,
      ),
    ),
  );
  if (changed ?? false) onDataChanged?.call();
}

class RoundCallScreen extends StatefulWidget {
  const RoundCallScreen({
    required this.roundNumber,
    required this.loadRoundText,
    required this.onApprove,
    required this.onRequestChanges,
    required this.onOpenRoundFile,
    this.existingApproval,
    this.existingChangeRequest,
    super.key,
  });

  final String roundNumber;

  /// Reads `rounds\round-<roundNumber>.md`'s own text — the real
  /// `readRoundFileText` in production.
  final Future<String?> Function() loadRoundText;

  /// Appends one row to `rounds\APPROVED.md` — the real `approveRound` in
  /// production, already bound to the project folder and the round's own
  /// title.
  final Future<void> Function({required String? feedback}) onApprove;

  /// Appends one row to `rounds\CHANGES.md` — the real
  /// `requestRoundChanges` in production.
  final Future<void> Function({required String what}) onRequestChanges;

  /// Opens the real round file — `open_url.dart`'s `openUrl`, bound to
  /// the real path, in production.
  final VoidCallback onOpenRoundFile;

  /// Already recorded, if any — read once by the caller (the same
  /// `RoundApprovals`/`readChangeRequests` it already loaded for the list
  /// this screen was pushed from), so this screen never has to guess
  /// whether a round waiting a moment ago is still waiting now.
  final RoundApproval? existingApproval;
  final ChangeRequest? existingChangeRequest;

  @override
  State<RoundCallScreen> createState() => _RoundCallScreenState();
}

class _RoundCallScreenState extends State<RoundCallScreen> {
  bool _loading = true;
  String? _roundText;
  RoundApproval? _approval;
  ChangeRequest? _changeRequest;
  final _feedbackController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _approval = widget.existingApproval;
    _changeRequest = widget.existingChangeRequest;
    _load();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final text = await widget.loadRoundText();
    if (!mounted) return;
    setState(() {
      _roundText = text;
      _loading = false;
    });
  }

  String get _title {
    final text = _roundText;
    final fallback = 'Round ${widget.roundNumber}';
    return text == null ? fallback : parseRoundTitle(text, fallback: fallback);
  }

  /// Whether anything is already settled — either kind, whichever
  /// happened. A round can only ever have one live outcome at a time
  /// here: this screen is only reached from a *waiting* round row, so
  /// finding one already means this screen's own action just recorded it.
  bool get _settled => _approval != null || _changeRequest != null;

  Future<void> _recordYes() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final feedback = _feedbackController.text.trim();
      await widget.onApprove(feedback: feedback.isEmpty ? null : feedback);
      if (!mounted) return;
      setState(() {
        _approval = (
          date: _isoToday(),
          words: feedback.isEmpty ? 'in Asa' : '"$feedback"',
          result: _title,
        );
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

  Future<void> _recordChanges() async {
    if (_saving) return;
    final what = _feedbackController.text.trim();
    if (what.isEmpty) {
      setState(() => _error = 'Say what needs to change first.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onRequestChanges(what: what);
      if (!mounted) return;
      setState(() {
        _changeRequest = (
          date: _isoToday(),
          round: widget.roundNumber,
          what: '"$what"',
        );
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

  String _isoToday() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AsaPage(
      name: _title,
      onBack: () => Navigator.of(context).pop(_settled),
      body: _loading
          ? const Text('Loading…', style: AsaText.body)
          : _body(),
    );
  }

  Widget _body() {
    final text = _roundText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusLine(),
        const SizedBox(height: AsaSpace.xl),
        if (text == null)
          const Text(
            'No round file found for this number.',
            style: TextStyle(color: AsaColors.ink3),
          )
        else ...[
          _block('What was built', cutToLines(parseRoundFinishLine(text), 5)),
          const SizedBox(height: AsaSpace.xl),
          _block('How to check it', cutToLines(parseRoundTest(text), 5)),
          const SizedBox(height: AsaSpace.md),
          LinkChip('open the round file ↗', onTap: widget.onOpenRoundFile),
        ],
        const SizedBox(height: AsaSpace.xl),
        const Divider(height: 1),
        const SizedBox(height: AsaSpace.xl),
        if (_settled) _recordedOutcome() else _yourCall(),
        if (_error != null) ...[
          const SizedBox(height: AsaSpace.md),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _statusLine() {
    return Pill(
      _settled ? 'settled' : 'waiting for your yes',
      meaning: _settled ? AsaMeaning.done : AsaMeaning.needsYou,
    );
  }

  Widget _block(String label, String? body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: AsaSpace.sm),
        if (body == null || body.isEmpty)
          const Text('Not stated.', style: TextStyle(color: AsaColors.ink3))
        else
          SelectableText(body, style: AsaText.body),
      ],
    );
  }

  Widget _yourCall() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Your call'),
        const SizedBox(height: AsaSpace.sm),
        TextField(
          controller: _feedbackController,
          maxLines: 3,
          enabled: !_saving,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Anything to add? (optional for Yes, required for '
                'Needs changes)',
          ),
        ),
        const SizedBox(height: AsaSpace.md),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AsaColors.ink2,
                side: const BorderSide(color: AsaColors.line),
              ),
              onPressed: _saving ? null : _recordChanges,
              child: const Text('Needs changes'),
            ),
            const SizedBox(width: AsaSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AsaColors.green),
              onPressed: _saving ? null : _recordYes,
              child: Text(_saving ? 'Saving…' : "Yes, it's right"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recordedOutcome() {
    final approval = _approval;
    final changes = _changeRequest;
    final text = approval != null
        ? 'Yes — ${approval.date}'
        : 'Needs changes — ${changes!.what}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Your call. ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(text),
          ],
        ),
      ],
    );
  }
}
