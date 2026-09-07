/// Product Hub — every project on one screen, most stale first.
///
/// Round 2. This is the home screen.
library;

import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/settings.dart';
import 'package:asa/hubs/product/project_screen.dart';
import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, this.settingsPath, this.pickFolder});

  /// Overrides where settings are read from and written to. Production
  /// never sets this — it exists so the feature test can choose a folder
  /// without touching the real `%APPDATA%\Asa\settings.json`.
  final String? settingsPath;

  /// Opens a folder dialog and returns the chosen path, or null if the
  /// person cancelled.
  ///
  /// **Null on this machine, and that is the whole story.** A native
  /// folder dialog needs a Flutter plugin; on Windows any plugin needs
  /// symlink support, which needs Developer Mode or admin rights, which
  /// are not available here or on the other machine this has to build on.
  /// So Asa asks for a pasted path, and **the button does not pretend
  /// otherwise** — it says "Use this folder", not "Choose folder…".
  ///
  /// Pass a function here and the dialog appears, the label changes, and
  /// nothing else in this file has to move:
  ///
  /// ```dart
  /// // with file_selector in pubspec.yaml, on a machine that can build it
  /// ProjectsScreen(pickFolder: getDirectoryPath)
  /// ```
  ///
  /// *Left in deliberately on 2026-09-03 after the plugin was reverted.
  /// The constraint is this machine's, not the design's.*
  final Future<String?> Function()? pickFolder;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _rootField = TextEditingController();

  ScanResult? _scan;
  bool _loading = false;

  // First run: nobody has chosen a folder yet, so there is nothing to load
  // and no hardcoded path to fall back on — a default that does not exist
  // on a second person's machine is a broken first run, not a convenience.
  bool _folderChosen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _rootField.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final settings = await readSettings(path: widget.settingsPath);
    if (!mounted) return;

    final saved = settings.projectsFolder;
    if (saved == null || saved.isEmpty) return;

    _rootField.text = saved;
    setState(() => _folderChosen = true);
    await _load();
  }

  /// The button. Opens a dialog if one was supplied, otherwise uses what
  /// is typed in the box. **Never returns silently** — hard rule 6: show
  /// every failure with its reason. A click that appeared to do nothing
  /// is why this screen was rejected on 2026-09-03.
  Future<void> _chooseFolder() async {
    final picker = widget.pickFolder;

    if (picker != null) {
      final picked = await picker();
      if (picked != null && picked.isNotEmpty) {
        _rootField.text = picked;
        await _useFolder(picked);
        return;
      }
      // Cancelled. Use a typed path if there is one, otherwise say so.
      final typed = _rootField.text.trim();
      if (typed.isNotEmpty) {
        await _useFolder(typed);
        return;
      }
      _say(
        'No folder chosen. Pick one, or paste a path in the box and '
        'press Enter.',
      );
      return;
    }

    // No dialog on this build. The box is the only way in, so the button
    // and the box do the same thing and the button says so.
    await _submitTypedFolder();
  }

  /// Enter in the text field. Same destination, different door.
  Future<void> _submitTypedFolder() async {
    final typed = _rootField.text.trim();
    if (typed.isEmpty) {
      _say(
        'That box is empty. Paste the path to your projects folder, or '
        'use the Choose folder button.',
      );
      return;
    }
    await _useFolder(typed);
  }

  Future<void> _useFolder(String folder) async {
    await writeSettings(
      Settings(projectsFolder: folder),
      path: widget.settingsPath,
    );
    if (!mounted) return;
    setState(() => _folderChosen = true);
    await _load();
  }

  /// Never says "Choose folder…" unless something can actually be chosen.
  /// An ellipsis is a promise that a dialog opens.
  String get _buttonLabel {
    if (_loading) return 'Loading…';
    if (_folderChosen) return 'Load';
    return widget.pickFolder == null ? 'Use this folder' : 'Choose folder…';
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: _folderChosen ? null : r'C:\path\to\projects',
                    ),
                    onSubmitted: (_) =>
                        _folderChosen ? _load() : _submitTypedFolder(),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : (_folderChosen ? _load : _chooseFolder),
                  child: Text(_buttonLabel),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_folderChosen)
              _Panel(
                title: 'No folder chosen yet',
                child: Text(
                  widget.pickFolder == null
                      ? 'Paste the path to your projects folder above — in '
                            'File Explorer, Shift+right-click the folder '
                            'and choose "Copy as path" — then press Enter. '
                            'Asa remembers it for next time.'
                      : 'Press Choose folder to pick it, or paste the path '
                            'above and press Enter. Asa remembers it for '
                            'next time.',
                ),
              ),
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
          'A project is a subfolder containing a markdown note with '
          'frontmatter.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${projects.length} projects — most stale first',
          style: const TextStyle(color: Colors.grey),
        ),
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
          MaterialPageRoute<void>(
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
                    Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.status,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.nextStep),
                    const SizedBox(height: 4),
                    Text(
                      project.milestone,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
              child: Text(
                '${item.folder} — ${item.reason}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.isError = false,
  });

  final String title;
  final Widget child;
  final bool isError;

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
