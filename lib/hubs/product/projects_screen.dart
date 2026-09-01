/// Product Hub — every project on one screen, most stale first.
///
/// Round 2. This is the home screen.
library;

import 'package:flutter/material.dart';

import '../../core/projects_scan.dart';
import 'project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _rootField = TextEditingController(
    text: r'C:\Users\nico.bui\workspace\projects',
  );

  ScanResult? _scan;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Load once on open, so the app is useful without a click.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _rootField.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _scan = null;
    });

    final scan = await scanProjects(_rootField.text.trim());

    if (!mounted) return;
    setState(() {
      _scan = scan;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = _scan;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asa — Product Hub'),
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
            const Text('Projects folder'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rootField,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
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
            if (scan?.error != null)
              _Panel(
                title: 'Could not read the projects folder',
                isError: true,
                child: Text(scan!.error!),
              ),
            if (scan != null && scan.error == null) ...[
              _projectsTable(sortByStaleness(scan.projects, now), now),
              if (scan.skipped.isNotEmpty) ...[
                const SizedBox(height: 32),
                _skippedTable(scan.skipped),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _projectsTable(List<ProjectSummary> projects, DateTime now) {
    if (projects.isEmpty) {
      return const _Panel(
        title: 'No projects here yet',
        child: Text(
          'A project is a subfolder containing a markdown note with frontmatter.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${projects.length} projects — most stale first',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        for (final summary in projects) _row(summary, now),
      ],
    );
  }

  Widget _row(ProjectSummary summary, DateTime now) {
    final project = summary.project;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectScreen(folder: summary.folder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(project.status,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.nextStep),
                    const SizedBox(height: 4),
                    Text(project.milestone,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 110,
                child: Text(
                  stalenessLabel(summary, now),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _stalenessColour(summary.daysStale(now)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Colour is a hint, never the only signal — the words say it too.
  /// See the non-functional skill: meaning never carried by colour alone.
  Color _stalenessColour(int? days) {
    if (days == null) return Colors.grey;
    if (days >= 21) return Colors.red.shade700;
    if (days >= 7) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  Widget _skippedTable(List<SkippedFolder> skipped) {
    return _Panel(
      title: '${skipped.length} folders skipped',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in skipped)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${item.folder} — ${item.reason}',
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isError;
  const _Panel({required this.title, required this.child, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          child,
        ],
      ),
    );
  }
}
