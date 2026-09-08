/// Product Hub — one project's state, in detail.
///
/// Built 2026-09-04 to match the approved sketch, `asa-v01b.png`: a quiet
/// typographic list — no Material AppBar, no cards, no uppercase tabs. The
/// provenance block stays, collapsed behind one line — it is the best
/// thing in this codebase, not deleted, not moved. The one-line
/// description under the project name landed the same day, once
/// `project_reader.dart` could expose it.
library;

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_reader.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:flutter/material.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({required this.folder, super.key});

  final String folder;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectReadResult? _read;
  GitState? _git;
  List<DecisionReadResult>? _decisions;
  bool _loading = true;
  int _tabIndex = 0;
  bool _provenanceExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
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

    if (!mounted) return;
    setState(() {
      _read = read;
      _git = git;
      _decisions = decisions;
      _loading = false;
    });
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
              if (_tabIndex == 0) _decisionsTab(read) else _detailsTab(read),
              const SizedBox(height: 24),
              _provenanceSection(read),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
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
  Widget _tabRow() {
    return Row(
      children: [
        _tabLabel('Decisions', 0),
        const SizedBox(width: 24),
        _tabLabel('Details', 1),
      ],
    );
  }

  Widget _tabLabel(String label, int index) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
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
        _Field('Status', project.status),
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
