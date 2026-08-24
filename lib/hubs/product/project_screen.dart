/// Product Hub — one project's state on one screen.
///
/// Round 1. Deliberately one project, not several.
library;

import 'package:flutter/material.dart';

import '../../core/git_state.dart';
import '../../core/project.dart';
import '../../core/project_reader.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  // Pre-filled with Nico's projects folder. Editable, so this is a default
  // rather than a hard-coded path.
  final _pathField = TextEditingController(
    text: r'C:\Users\nico.bui\Documents\Claude\Vibe Coding\projects\asa',
  );

  ProjectReadResult? _read;
  GitState? _git;
  bool _loading = false;

  @override
  void dispose() {
    _pathField.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _read = null;
      _git = null;
    });

    final read = await readProject(_pathField.text.trim());

    GitState? git;
    if (read.isSuccess) {
      git = await readGitState(read.project!.repoPath);
    }

    if (!mounted) return;
    setState(() {
      _read = read;
      _git = git;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asa — Product Hub')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project folder'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathField,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _loading ? null : _load,
                  child: Text(_loading ? 'Loading…' : 'Load'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_read != null) ..._results(_read!),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(ProjectReadResult read) {
    if (!read.isSuccess) {
      return [
        _Message(
          title: 'Could not read the project',
          detail: read.error ?? 'Unknown problem',
          isError: true,
        ),
      ];
    }

    final project = read.project!;
    final git = _git;

    return [
      Text(project.name, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      _Field('Status', project.status),
      _Field('Milestone', project.milestone),
      _Field('Next step', project.nextStep),
      _Field('Note updated by hand', project.updated),
      _Field('Last moved (from git)', _lastMovedText(git)),
      const SizedBox(height: 32),
      // Rule 5: show the raw data at every boundary.
      _RawBlock(
        title: 'Read from: ${project.sourceFile}',
        body: read.rawFrontmatter,
      ),
      const SizedBox(height: 16),
      if (git != null)
        _RawBlock(
          title: git.command,
          body: git.error == null
              ? git.rawOutput
              : '${git.error}\n\n${git.rawOutput}',
        ),
    ];
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
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String detail;
  final bool isError;
  const _Message({required this.title, required this.detail, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isError ? Colors.red : Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(detail),
        ],
      ),
    );
  }
}

class _RawBlock extends StatelessWidget {
  final String title;
  final String body;
  const _RawBlock({required this.title, required this.body});

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
