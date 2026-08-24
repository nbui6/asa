/// Product Hub — one project's state, in detail.
///
/// Round 1, changed in Round 2: the folder now arrives from the projects list
/// instead of being typed here. The text field moved to the home screen.
library;

import 'package:flutter/material.dart';

import '../../core/git_state.dart';
import '../../core/project.dart';
import '../../core/project_reader.dart';

class ProjectScreen extends StatefulWidget {
  final String folder;
  const ProjectScreen({super.key, required this.folder});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  ProjectReadResult? _read;
  GitState? _git;
  bool _loading = true;

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

    if (!mounted) return;
    setState(() {
      _read = read;
      _git = git;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final read = _read;

    return Scaffold(
      appBar: AppBar(
        title: Text(read?.project?.name ?? 'Project'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const Text('Loading…'),
            if (read != null) ..._results(read),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(ProjectReadResult read) {
    if (!read.isSuccess) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not read the project',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(read.error ?? 'Unknown problem'),
            ],
          ),
        ),
      ];
    }

    final project = read.project!;
    final git = _git;

    return [
      _Field('Status', project.status),
      _Field('Milestone', project.milestone),
      _Field('Next step', project.nextStep),
      _Field('Note updated by hand', project.updated),
      _Field('Last moved (from git)', _lastMovedText(git)),
      _Field('Repo', project.repoPath.isEmpty ? '(no code yet)' : project.repoPath),
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
          Expanded(child: SelectableText(value)),
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
