/// Round 39 cp6 — the Instruction for AI screen, un-blackboxing what
/// every AI is told to do and what it found. Sketch approved 2026-09-28:
/// `sketches\asa-instruction-for-ai-v5.html`. Five parts: How it works,
/// Instructions, Skills & agents, Working with you, Checks.
library;

import 'dart:io';

import 'package:asa/core/check.dart';
import 'package:asa/core/manual_status.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/repo_remote.dart';
import 'package:asa/core/round_file.dart' show sectionTextContaining;
import 'package:asa/core/settings.dart';
import 'package:asa/core/skills_catalog.dart';
import 'package:asa/core/status_words.dart' show isHiddenStatus;
import 'package:asa/hubs/product/ui/asa_panel.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Part { howItWorks, instructions, skillsAgents, workingWithYou, checks }

class InstructionForAiScreen extends StatefulWidget {
  const InstructionForAiScreen({this.settingsPath, super.key});

  /// Overrides where settings are read from. Production never sets
  /// this — same reasoning as every other screen's own test seam.
  final String? settingsPath;

  @override
  State<InstructionForAiScreen> createState() => _InstructionForAiScreenState();
}

class _InstructionForAiScreenState extends State<InstructionForAiScreen> {
  _Part _part = _Part.howItWorks;
  bool _loading = true;
  String? _error;

  ManualSyncStatus? _manualStatus;
  DateTime? _manualDate;
  String? _manualMessage;
  String? _manualSource;

  /// Round 41 §C — the asa repo's own `origin` remote, read fresh each
  /// load (never hard-coded, never a machine path) so the setup
  /// sentence's own "clone" address can never go stale the way a typed
  /// one would the moment the remote changes.
  String? _asaRemoteUrl;

  List<SkillInfo> _skills = const [];
  List<AgentInfo> _agents = const [];

  bool _bossExists = false;
  bool _bossIsTemplate = false;
  String? _bossReadThisFirst;
  String? _bossYourRules;
  String? _bossFillPrompt;

  List<({String project, Finding finding})> _findings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await readSettings(path: widget.settingsPath);
    final root = settings.projectsFolder;
    if (root == null) {
      setState(() {
        _error = 'No projects folder chosen yet.';
        _loading = false;
      });
      return;
    }

    final asaRepo = asaRepoPathFrom(root);

    if (asaRepo != null) {
      _manualStatus = await manualSyncStatus(asaRepo, root);
      final changed = await manualLastChanged(asaRepo);
      _manualDate = changed.date;
      _manualMessage = changed.message;
      final sourceFile = File(_joined(asaRepo, 'templates', 'AGENTS.md'));
      _manualSource = sourceFile.existsSync()
          ? sourceFile.readAsStringSync()
          : null;
      _skills = await readSkillsCatalog(asaRepo);
      _agents = await readAgentsCatalog(asaRepo);
      _asaRemoteUrl = repoRemoteUrl(asaRepo);
    }

    final bossFile = File('$root${Platform.pathSeparator}BOSS.md');
    if (bossFile.existsSync()) {
      _bossExists = true;
      final text = await bossFile.readAsString();
      _bossIsTemplate = isEmptyBossTemplate(text);
      _bossReadThisFirst = sectionTextContaining(text, 'read this first');
      _bossYourRules = sectionTextContaining(text, 'your rules');
    }
    if (asaRepo != null) {
      final templateFile = File(_joined(asaRepo, 'templates', 'BOSS.md'));
      if (templateFile.existsSync()) {
        _bossFillPrompt = bossFillPrompt(await templateFile.readAsString());
      }
    }

    final scan = await scanProjects(root);
    final findings = <({String project, Finding finding})>[];
    // Round 38 §F, ADR 0036 — on-hold/done/canceled projects leave the
    // Checks the same way they leave the overview list, the Tasks view
    // and the N-new markers; opening one directly still shows it as
    // usual, this only keeps it out of the aggregate list here.
    for (final summary in scan.projects) {
      if (isHiddenStatus(summary.project.status)) continue;
      for (final finding in await checkProject(summary.folder)) {
        findings.add((project: summary.project.name, finding: finding));
      }
    }
    _findings = findings;

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Embedded straight into `ProjectsScreen`'s own body, next to Projects
  /// and Tasks (a third `_ViewMode`) — not its own `AsaPage`/`Scaffold`,
  /// so the page title, refresh button and scrolling stay the one the
  /// host screen already provides, never nested twice.
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) return Text(error, style: AsaText.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _partSwitch(),
        const SizedBox(height: AsaSpace.lg),
        switch (_part) {
          _Part.howItWorks => _howItWorks(),
          _Part.instructions => _instructions(),
          _Part.skillsAgents => _skillsAgentsPart(),
          _Part.workingWithYou => _workingWithYou(),
          _Part.checks => _checksPart(),
        },
      ],
    );
  }

  Widget _partSwitch() {
    return Wrap(
      spacing: AsaSpace.sm,
      children: [
        for (final part in _Part.values) _partButton(part, _partLabel(part)),
      ],
    );
  }

  String _partLabel(_Part part) => switch (part) {
    _Part.howItWorks => 'How it works',
    _Part.instructions => 'Instructions',
    _Part.skillsAgents => 'Skills & agents',
    _Part.workingWithYou => 'Working with you',
    _Part.checks => 'Checks (${_findings.length})',
  };

  Widget _partButton(_Part part, String label) {
    final selected = _part == part;
    return OutlinedButton(
      onPressed: () => setState(() => _part = part),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AsaColors.greyBg : null,
      ),
      child: Text(label),
    );
  }

  Widget _howItWorks() {
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('The loop, every session'),
            const SizedBox(height: AsaSpace.sm),
            const Text(
              '1. Catch up: run asa-brief; the whole picture first, then '
              "the job's slice.\n"
              '2. Say where things stand, in three lines or fewer.\n'
              '3. Open the session: write .asa-session.md.\n'
              '4. Work with the user.\n'
              '5. Record as it happens — the six moments, then a Logged: '
              'line.\n'
              '6. Check what was written: asa-check.\n'
              '7. Hand over: the first open task is the next step.',
              style: AsaText.body,
            ),
            const SizedBox(height: AsaSpace.lg),
            const SectionLabel('Catching up — what to read for which job'),
            const SizedBox(height: AsaSpace.sm),
            const Text(
              'asa-brief --all — every project, freshness, what waits.\n'
              'asa-brief --since <date> — everything recorded since then.\n'
              'asa-brief "<project>" — the next step for that project.\n'
              '... --area <name> — that area alone.\n'
              '... --round <N> — that round alone.',
              style: AsaText.body,
            ),
            const SizedBox(height: AsaSpace.lg),
            _setupSentenceRow(),
          ],
        ),
      ),
    );
  }

  /// Round 41 §C — "Set up another laptop or another Claude" · Copy.
  /// Neutral text, no name, same rule 16 any shipped text already follows;
  /// the clone address itself is read fresh from this repo's own `origin`
  /// remote (`repo_remote.dart`), never typed by hand, so it can't go
  /// stale the moment the remote changes.
  String? _setupSentence() {
    final url = _asaRemoteUrl;
    if (url == null) return null;
    return 'Set up Asa on this laptop: clone $url into '
        r'%USERPROFILE%\workspace\asa, run asa\setup.ps1, then open '
        r'projects\AGENTS.md and start at "Before anything else".';
  }

  Widget _setupSentenceRow() {
    final sentence = _setupSentence();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'Set up another laptop or another Claude',
            style: AsaText.body,
          ),
        ),
        const SizedBox(width: AsaSpace.sm),
        OutlinedButton(
          onPressed: sentence == null
              ? null
              : () => Clipboard.setData(ClipboardData(text: sentence)),
          child: const Text('Copy'),
        ),
      ],
    );
  }

  String _manualChangedLine() {
    final date = _manualDate;
    if (date == null) return 'Last changed: unknown';
    final dateText = date.toIso8601String().split('T').first;
    return 'Last changed $dateText — ${_manualMessage ?? ""}';
  }

  Widget _instructions() {
    final status = _manualStatus;
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == null)
              const Text(
                'Could not find the asa repo next to the projects folder.',
                style: AsaText.body,
              )
            else ...[
              Row(
                children: [
                  Pill(
                    status.matches ? 'installed copy matches ✓' : 'differs ✗',
                    meaning: status.matches
                        ? AsaMeaning.done
                        : AsaMeaning.needsYou,
                  ),
                ],
              ),
              if (!status.matches && status.differingSections.isNotEmpty) ...[
                const SizedBox(height: AsaSpace.xs),
                Text(
                  'Differing sections: ${status.differingSections.join(", ")}',
                  style: AsaText.meta,
                ),
              ],
              const SizedBox(height: AsaSpace.sm),
              Text(_manualChangedLine(), style: AsaText.meta),
              const SizedBox(height: AsaSpace.lg),
              FilledButton(
                onPressed: _manualSource == null
                    ? null
                    : () => Clipboard.setData(
                        ClipboardData(text: _manualSource!),
                      ),
                child: const Text('Copy for any AI'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skillsAgentsPart() {
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Skills'),
            const SizedBox(height: AsaSpace.sm),
            if (_skills.isEmpty) const Text('None found.', style: AsaText.body),
            for (final skill in _skills) _skillRow(skill),
            const SizedBox(height: AsaSpace.lg),
            const SectionLabel('Agents'),
            const SizedBox(height: AsaSpace.sm),
            if (_agents.isEmpty) const Text('None found.', style: AsaText.body),
            for (final agent in _agents) _agentRow(agent),
            const SizedBox(height: AsaSpace.sm),
            const Text(
              "Which Claude accounts have it installed can't be read from "
              'here.',
              style: AsaText.meta,
            ),
          ],
        ),
      ),
    );
  }

  String _lastPackagedLine(SkillInfo skill) {
    final packaged = skill.lastPackaged;
    if (packaged == null) return 'last packaged: never';
    final dateText = packaged.toIso8601String().split('T').first;
    return 'last packaged for accounts $dateText';
  }

  Widget _skillRow(SkillInfo skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(skill.name, style: AsaText.rowName),
              const SizedBox(width: AsaSpace.sm),
              Pill(
                skill.inRepo ? 'in the repo ✓' : 'in the repo ✗',
                meaning: skill.inRepo ? AsaMeaning.done : AsaMeaning.needsYou,
              ),
            ],
          ),
          Text(skill.description, style: AsaText.meta),
          Text(_lastPackagedLine(skill), style: AsaText.meta),
        ],
      ),
    );
  }

  Widget _agentRow(AgentInfo agent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsaSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(agent.name, style: AsaText.rowName),
          Text(agent.description, style: AsaText.meta),
        ],
      ),
    );
  }

  Widget _workingWithYou() {
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_bossExists)
              const Text('BOSS.md is missing.', style: AsaText.body)
            else if (_bossIsTemplate) ...[
              const Text(
                'BOSS.md is still the empty template.',
                style: AsaText.body,
              ),
              const SizedBox(height: AsaSpace.sm),
              FilledButton(
                onPressed: _bossFillPrompt == null
                    ? null
                    : () => Clipboard.setData(
                        ClipboardData(text: _bossFillPrompt!),
                      ),
                child: const Text('Fill with your AI'),
              ),
            ] else ...[
              const SectionLabel('Read this first'),
              const SizedBox(height: AsaSpace.xs),
              Text(
                _bossReadThisFirst ?? '(none written yet)',
                style: AsaText.body,
              ),
              const SizedBox(height: AsaSpace.lg),
              const SectionLabel('Your rules'),
              const SizedBox(height: AsaSpace.xs),
              Text(_bossYourRules ?? '(none written yet)', style: AsaText.body),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checksPart() {
    if (_findings.isEmpty) {
      return const AsaPanel(
        child: Padding(
          padding: EdgeInsets.all(AsaSpace.lg),
          child: Text('OK — nothing to report.', style: AsaText.body),
        ),
      );
    }
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in _findings)
              Padding(
                padding: const EdgeInsets.only(bottom: AsaSpace.sm),
                child: Text(
                  '${row.project}: ${row.finding.message}',
                  style: AsaText.body,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _joined(String base, String a, String b) =>
    '$base${Platform.pathSeparator}$a${Platform.pathSeparator}$b';
