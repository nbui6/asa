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

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/inbox.dart';
import 'package:asa/core/log_visit.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_news.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/settings.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/task_writer.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:asa/hubs/product/inbox_panel.dart';
import 'package:asa/hubs/product/instruction_for_ai_screen.dart';
import 'package:asa/hubs/product/project_screen.dart';
import 'package:asa/hubs/product/projects_view.dart';
import 'package:asa/hubs/product/tasks_view.dart';
import 'package:asa/hubs/product/ui/asa_page.dart';
import 'package:asa/hubs/product/ui/asa_panel.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

/// The front page has two views onto the same project scan — Projects and
/// Tasks. The Projects view got its real row layout (`asa-front2.png`)
/// 2026-09-07, after the toggle shipped ahead of it and showed the old
/// flat list was never actually rebuilt to match that sketch. Renamed
/// from "Bars" 2026-09-09 — "Bars" is a retired term (rule 12).
enum _ViewMode { projects, tasks, instructionForAi }

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

  /// Round 38 §E — one project's own news (a blue *N new*, an amber
  /// *changed without a note*), keyed by its folder. Empty for a project
  /// this scan's own gathering step could not read for some reason —
  /// same honest-absence rule as everywhere else, never a guess.
  Map<String, ProjectNews> _news = const {};

  /// Round 38 §E — every proposed decision and round waiting for
  /// approval, across every project, oldest first — the global *Needs
  /// you* card's own source.
  List<WaitingAcrossProjects> _waiting = const [];

  int _needsYouIndex = 0;

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

  /// Round 38 §G — the folder path line, no longer sitting under the
  /// title on every launch; a small menu next to ↻ instead. One item,
  /// the same "Projects: `<path>`  ·  change" line Round 35/B drew inline,
  /// still the one place that reopens the editable field.
  Widget _settingsMenu() {
    return PopupMenuButton<void>(
      tooltip: 'Settings',
      icon: const Icon(Icons.settings_outlined),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          onTap: () => setState(() => _folderRowExpanded = true),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(color: AsaColors.ink2),
              children: [
                TextSpan(text: 'Projects: ${_rootField.text}'),
                const TextSpan(
                  text: '  ·  change',
                  style: TextStyle(
                    color: AsaColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    // Round 36 cp6 — found by the click-through test, same shape as
    // project_screen.dart's own "Round 36 cp6" comment: nulling `_scan`
    // up front unmounted `ProjectsView` for the length of every reload,
    // including a plain refresh tap, discarding its own local UI state
    // (the "other" group's expand/collapse) every time. Keeping the old
    // scan on screen until the new one actually lands fixes that, the
    // same way.
    setState(() => _loading = true);

    final scan = await scanProjects(_rootField.text.trim());
    final taskGroups = scan.error == null
        ? await buildTaskGroups(scan.projects, const DiskFileAccess())
        : const <TaskGroup>[];
    final home = _homePath;
    final inboxTasks = home == null
        ? const <Task>[]
        : await readInbox(home, const DiskFileAccess());
    final newsAndWaiting = scan.error == null
        ? await _readNewsAndWaiting(scan.projects)
        : (
            news: const <String, ProjectNews>{},
            waiting: const <WaitingAcrossProjects>[],
          );

    if (!mounted) return;
    setState(() {
      _scan = scan;
      _taskGroups = taskGroups;
      _inboxTasks = inboxTasks;
      _news = newsAndWaiting.news;
      _waiting = newsAndWaiting.waiting;
      _loading = false;
    });
  }

  /// Round 38 §E — one extra real-disk pass per project, alongside the
  /// scan itself: its own news since its own last Log visit, and whether
  /// it has anything waiting for a yes. Read here rather than inside
  /// `ProjectsView`'s own row so a slow read never blocks the row it
  /// belongs to from painting with whatever it already has.
  Future<({Map<String, ProjectNews> news, List<WaitingAcrossProjects> waiting})>
  _readNewsAndWaiting(List<ProjectSummary> projects) async {
    const files = DiskFileAccess();
    final news = <String, ProjectNews>{};
    final waitingInputs =
        <
          ({
            String folder,
            String name,
            List<DecisionReadResult> decisions,
            List<Milestone> roadmap,
            RoundApprovals approvals,
          })
        >[];

    for (final summary in projects) {
      final decisions = await readAllDecisions(summary.folder, files);
      final approvals = await readRoundApprovals(summary.folder, files);
      final lastVisit = await lastLogVisit(summary.folder);
      news[summary.folder] = await readProjectNews(
        summary.folder,
        files,
        lastVisit: lastVisit,
      );
      waitingInputs.add((
        folder: summary.folder,
        name: summary.project.name,
        decisions: decisions,
        roadmap: summary.project.roadmap,
        approvals: approvals,
      ));
    }

    return (news: news, waiting: waitingAcrossProjects(waitingInputs));
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

  /// Round-36 §3, L1-L7 — the one place every link that lands on a
  /// project actually navigates, shared by [ProjectsView] and [TasksView]
  /// so both sets of links (the overview's, the Tasks view's) open the
  /// same way. [target]'s optional fields carry where inside the project
  /// to land — an area, "Not in an area", a task to highlight — through
  /// to [ProjectScreen]'s own `initial*` constructor params.
  void _openProject(ProjectOpenTarget target) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectScreen(
          folder: target.folder,
          initialAreaToOpen: target.areaSourceFile,
          initialOpenHome: target.openHome,
          initialHighlightRawLine: target.highlightRawLine,
          initialOpenLog: target.openLog,
          onOpenTasks: (projectName) {
            Navigator.of(context).pop();
            setState(() {
              _viewMode = _ViewMode.tasks;
              _pinnedProjectName = projectName;
            });
          },
        ),
      ),
    );
  }

  /// Round-36 §3, L7 — every scanned project's folder, by slug, so a
  /// `[[project]]` chip in the Tasks view can resolve to a real project
  /// even one with no tasks of its own (and so absent from `_taskGroups`,
  /// which only ever groups projects that have some).
  Map<String, String> _folderBySlug(List<ProjectSummary> projects) => {
    for (final summary in projects) slugOf(summary.folder): summary.folder,
  };

  @override
  Widget build(BuildContext context) {
    final scan = _scan;

    return AsaPage(
      // Round 38 §G (ADR 0038, 0040) — the app's own on-screen name is
      // "Project Management"; Asa appears only as a project.
      name: 'Project Management',
      actions: [
        if (scan != null && scan.error == null) ...[
          _viewToggle(),
          const SizedBox(width: AsaSpace.sm),
        ],
        // Round 38 §G — the folder path line moves off the body and into
        // this menu, ↻'s own neighbour; only once a folder is actually
        // chosen, same as the summary row it replaces.
        if (_folderChosen) ...[
          _settingsMenu(),
          const SizedBox(width: AsaSpace.sm),
        ],
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reload',
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_folderChosen || _folderRowExpanded) ...[
            const Text('Projects folder'),
            const Text(
              'Where Asa reads project state from. Change it here any time '
              "— it's remembered for next launch.",
              style: AsaText.meta,
            ),
            const SizedBox(height: AsaSpace.sm),
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
                const SizedBox(width: AsaSpace.lg),
                FilledButton(
                  onPressed: _loading ? null : _submitFolderField,
                  child: Text(_buttonLabel),
                ),
              ],
            ),
          ],
          const SizedBox(height: AsaSpace.xl),
          if (_folderChosen && _inboxTasks != null) ...[
            InboxPanel(tasks: _inboxTasks!, onCapture: _captureInboxTask),
            const SizedBox(height: AsaSpace.xl),
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
          if (_folderChosen && _viewMode == _ViewMode.instructionForAi)
            InstructionForAiScreen(settingsPath: widget.settingsPath)
          else if (scan != null && scan.error == null) ...[
            if (_viewMode == _ViewMode.projects) ...[
              if (_waiting.isNotEmpty) ...[
                _needsYouPanel(),
                const SizedBox(height: AsaSpace.lg),
              ],
              ProjectsView(
                forest: buildProjectForest(scan.projects),
                onOpenProject: _openProject,
                onAssignTask: _assignInboxTask,
                news: _news,
              ),
              if (scan.skipped.isNotEmpty) ...[
                const SizedBox(height: AsaSpace.xl),
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
                onOpenProject: _openProject,
                folderBySlug: _folderBySlug(scan.projects),
                pinnedProjectName: _pinnedProjectName,
              ),
          ],
        ],
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
        color: AsaColors.greyBg,
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
          _viewToggleButton(
            icon: Icons.info_outline,
            mode: _ViewMode.instructionForAi,
            tooltip: 'Instruction for AI',
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
            color: selected ? AsaColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? AsaColors.panel : AsaColors.ink2,
          ),
        ),
      ),
    );
  }

  /// Round 38 §E — one item at a time, oldest waiting first, across
  /// every project. **A named simplification, not the round's own literal
  /// wording:** "Yes"/"Changes…" here open that project on its Log tab
  /// (where the real, fully-working Needs-your-yes panel already lives)
  /// rather than writing inline from this screen too — one write path,
  /// not two copies of the same logic to keep in sync.
  Widget _needsYouPanel() {
    final index = _needsYouIndex % _waiting.length;
    final item = _waiting[index];
    return Container(
      padding: const EdgeInsets.all(AsaSpace.md),
      decoration: BoxDecoration(
        color: AsaMeaning.needsYou.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Needs you', style: AsaText.rowName),
              const SizedBox(width: AsaSpace.sm),
              Pill(item.projectName, meaning: AsaMeaning.area),
            ],
          ),
          const SizedBox(height: AsaSpace.xs),
          InkWell(
            onTap: () => _openProject(
              openTarget(item.projectFolder, openLog: true),
            ),
            child: Text(item.title, style: AsaText.body),
          ),
          const SizedBox(height: AsaSpace.sm),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AsaColors.green,
                ),
                onPressed: () => _openProject(
                  openTarget(item.projectFolder, openLog: true),
                ),
                child: const Text('Yes'),
              ),
              const SizedBox(width: AsaSpace.sm),
              OutlinedButton(
                onPressed: () => _openProject(
                  openTarget(item.projectFolder, openLog: true),
                ),
                child: const Text('Changes…'),
              ),
              const Spacer(),
              Text('${index + 1} of ${_waiting.length}', style: AsaText.meta),
              if (_waiting.length > 1)
                TextButton(
                  onPressed: () => setState(() => _needsYouIndex++),
                  child: const Text('next ›'),
                ),
            ],
          ),
        ],
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
              padding: const EdgeInsets.only(bottom: AsaSpace.xs),
              child: Text(
                '${item.folder} — ${item.reason}',
                style: AsaText.meta,
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
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isError ? Colors.red : AsaColors.ink,
              ),
            ),
            const SizedBox(height: AsaSpace.sm),
            child,
          ],
        ),
      ),
    );
  }
}
