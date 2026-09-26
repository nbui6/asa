/// Product Hub — every project on one screen, most stale first.
///
/// Round 2. This is the home screen.
///
/// **2026-09-13 — the inbox, Round 8.** `HOME.md` — the vault door,
/// `%USERPROFILE%\workspace\HOME.md`, one level above whatever folder is
/// chosen below — gets its own `## Tasks` section for quick capture with
/// no project open. Assigning an unfiled item to a project is a drag onto
/// one of `ProjectsView`'s rows; see `InboxPanel` and `core/inbox.dart`.
library;

import 'dart:io';

import 'package:asa/core/decisions_reader.dart' show DiskFileAccess;
import 'package:asa/core/inbox.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/settings.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/task_writer.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:asa/hubs/product/inbox_panel.dart';
import 'package:asa/hubs/product/project_screen.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:flutter/material.dart';

/// The front page has two views onto the same project scan — Projects and
/// Tasks. The Projects view got its real row layout (`asa-front2.png`)
/// 2026-09-07, after the toggle shipped ahead of it and showed the old
/// flat list was never actually rebuilt to match that sketch. Renamed
/// from "Bars" 2026-09-09 — "Bars" is a retired term (rule 12).
enum _ViewMode { projects, tasks }

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
  List<TaskGroup>? _taskGroups;
  List<Task>? _inboxTasks;
  bool _loading = false;
  _ViewMode _viewMode = _ViewMode.projects;

  /// Round 27's navigation fix — set when `ProjectScreen`'s Tasks button
  /// pops back here, so [TasksView] sorts that project's group first.
  /// Sticky on purpose: nothing in the spec asks for it to clear itself,
  /// and a project staying pinned until another one takes its place is
  /// the least surprising default.
  String? _pinnedProjectName;

  /// `HOME.md`, one level above the chosen projects folder — rule 17's
  /// fixed layout (`asa\`, `projects\`, `workshop\`, `HOME.md`, all
  /// siblings under one workspace root). Null before a folder is chosen —
  /// there is nothing to derive it from yet.
  String? get _homePath {
    final root = _rootField.text.trim();
    if (root.isEmpty) return null;
    return '${Directory(root).parent.path}${Platform.pathSeparator}HOME.md';
  }

  // First run: nobody has chosen a folder yet, so there is nothing to load
  // and no hardcoded path to fall back on — a default that does not exist
  // on a second person's machine is a broken first run, not a convenience.
  bool _folderChosen = false;

  /// Round 35/B — once a folder is saved, the field/button/explanation that
  /// used to fill the top third of the screen on every launch collapses to
  /// one line. Starts false: a fresh launch with a saved folder should
  /// never show the full box first and then shrink it. "· change" sets
  /// this true; loading again while already chosen sets it back.
  bool _folderRowExpanded = false;

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

  /// The field/button's own submit action, whichever door it came through
  /// (Enter in the box, or the button). Round 35/B: once a folder is
  /// already chosen, submitting it again collapses the box back to one
  /// line — the box only stays open while there's a real decision to make.
  Future<void> _submitFolderField() async {
    if (_folderChosen) {
      await _load();
      if (mounted) setState(() => _folderRowExpanded = false);
    } else {
      await _chooseFolder();
    }
  }

  /// Round 35/B — the one line a saved folder collapses to, so the folder
  /// box stops taking the top third of the screen on every launch. The
  /// whole line opens the field back up; "change" is the visible
  /// affordance for that, not the only place a tap works.
  Widget _folderSummaryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _folderRowExpanded = true),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.grey.shade700),
              children: [
                TextSpan(text: 'Projects: ${_rootField.text}'),
                TextSpan(
                  text: '  ·  change',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
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
      _taskGroups = null;
      _inboxTasks = null;
    });

    final scan = await scanProjects(_rootField.text.trim());
    final taskGroups = scan.error == null
        ? await buildTaskGroups(scan.projects, const DiskFileAccess())
        : const <TaskGroup>[];
    final home = _homePath;
    final inboxTasks = home == null
        ? const <Task>[]
        : await readInbox(home, const DiskFileAccess());

    if (!mounted) return;
    setState(() {
      _scan = scan;
      _taskGroups = taskGroups;
      _inboxTasks = inboxTasks;
      _loading = false;
    });
  }

  /// Re-reads the inbox from disk after a capture or an assignment — never
  /// trusts that the write happened as assumed, same discipline as every
  /// other write in this file.
  Future<void> _reloadInbox() async {
    final home = _homePath;
    if (home == null) return;
    final inboxTasks = await readInbox(home, const DiskFileAccess());
    if (!mounted) return;
    setState(() => _inboxTasks = inboxTasks);
  }

  /// One line typed into [InboxPanel], with no project chosen. ADR 0014:
  /// never classified, always lands in `## Tasks` — here, `HOME.md`'s own.
  Future<void> _captureInboxTask(String text) async {
    final home = _homePath;
    if (home == null) return;
    try {
      await captureTask(home, text);
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _reloadInbox();
  }

  /// An inbox task dropped on one of [ProjectsView]'s rows — the drag that
  /// assigns it, per ADR 0014's addendum. Moves the line out of `HOME.md`
  /// and into that project's own `## Tasks` section. **Round 32/B:** a
  /// full reload, not just the task groups — the newly-arrived task can
  /// become that project's own next step (ADR 0020), which the Projects
  /// view's row reads from `Project.tasks`, populated at scan time.
  Future<void> _assignInboxTask(Task task, ProjectNode node) async {
    final home = _homePath;
    if (home == null) return;
    try {
      await moveTask(
        fromPath: home,
        toPath: node.project.sourceFile,
        rawLine: task.rawLine,
      );
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _reloadInbox();
    await _load();
  }

  /// Round 32/B — reloads everything, not just the task groups.
  /// `ProjectsView`'s row now derives its next step from `Project.tasks`
  /// (ADR 0020), populated at scan time — same reasoning `_toggleParked`
  /// already established for the "N parked" count, extended here because
  /// a checked-off task can now change what a row's next step says.
  Future<void> _toggleTask(Project project, Task task) async {
    try {
      await setTaskDone(
        project.sourceFile,
        rawLine: task.rawLine,
        done: !task.done,
      );
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _load();
  }

  /// Toggles a task's `(parked)` tag — `PLAN.md` v0.3, "the rule of two".
  /// Reloads everything, not just the task groups: `ProjectsView`'s own
  /// "N parked" count reads `Project.tasks`, populated at scan time, so a
  /// parked toggle has to refresh the scan too, not only the Tasks view.
  Future<void> _toggleParked(Project project, Task task) async {
    try {
      await setTaskParked(
        project.sourceFile,
        rawLine: task.rawLine,
        parked: !task.parked,
      );
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _load();
  }

  /// Round 34/F — the same narrow amendment to ADR 0021 the Plan tab
  /// already exercises, from the Tasks view instead: checkbox state only,
  /// in an area's own `plan\*.md` page, via the same `setTaskDone` every
  /// other checkbox in this app already goes through.
  Future<void> _toggleAreaTask(String areaSourceFile, Task task) async {
    try {
      await setTaskDone(
        areaSourceFile,
        rawLine: task.rawLine,
        done: !task.done,
      );
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _load();
  }

  /// Round 32/B — same reasoning as `_toggleTask`: the next step can
  /// change here too.
  Future<void> _markAllDone(Project project) async {
    try {
      await markAllTasksDone(project.sourceFile);
    } on Object catch (e) {
      _say('Could not save: $e');
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scan = _scan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asa'),
        actions: [
          if (scan != null && scan.error == null) ...[
            _viewToggle(),
            const SizedBox(width: 8),
          ],
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
            if (_folderChosen && !_folderRowExpanded)
              _folderSummaryRow()
            else ...[
              const Text('Projects folder'),
              Text(
                'Where Asa reads project state from. Change it here any time '
                "— it's remembered for next launch.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('projectsFolderField'),
                      controller: _rootField,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        isDense: true,
                        hintText: _folderChosen ? null : r'C:\path\to\projects',
                      ),
                      onSubmitted: (_) => _submitFolderField(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submitFolderField,
                    child: Text(_buttonLabel),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            if (_folderChosen && _inboxTasks != null) ...[
              InboxPanel(tasks: _inboxTasks!, onCapture: _captureInboxTask),
              const SizedBox(height: 32),
            ],
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
              if (_viewMode == _ViewMode.projects) ...[
                ProjectsView(
                  forest: buildProjectForest(scan.projects),
                  onOpenProject: (folder) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProjectScreen(
                        folder: folder,
                        onOpenTasks: (projectName) {
                          Navigator.of(context).pop();
                          setState(() {
                            _viewMode = _ViewMode.tasks;
                            _pinnedProjectName = projectName;
                          });
                        },
                      ),
                    ),
                  ),
                  onAssignTask: _assignInboxTask,
                ),
                if (scan.skipped.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _skippedTable(scan.skipped),
                ],
              ] else if (_taskGroups == null)
                const Center(child: CircularProgressIndicator())
              else
                TasksView(
                  groups: _taskGroups!,
                  onToggleTask: _toggleTask,
                  onMarkAllDone: _markAllDone,
                  onToggleParked: _toggleParked,
                  onToggleAreaTask: _toggleAreaTask,
                  pinnedProjectName: _pinnedProjectName,
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Projects / Tasks — `asa-front2.png`. Still icon-only, with a hover
  /// tooltip carrying the plain-English label, same as every other icon
  /// control on this screen.
  Widget _viewToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleButton(
            icon: Icons.view_agenda_outlined,
            mode: _ViewMode.projects,
            tooltip: 'Projects view',
          ),
          _viewToggleButton(
            icon: Icons.checklist,
            mode: _ViewMode.tasks,
            tooltip: 'Tasks view',
          ),
        ],
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required _ViewMode mode,
    required String tooltip,
  }) {
    final selected = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.indigo.shade900 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
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
