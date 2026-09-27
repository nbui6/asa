/// Product Hub — front page, Tasks view.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the front-page Tasks view."
/// Sketch: `asa-tasks-view.png`/`.html`, seventh and approved pass — the
/// content and controls that sketch approved (triangle, mark-all, name,
/// "Show completed (N)", the Code-tasks switch, one expand/collapse menu)
/// are unchanged; round 37 (`asa-one-look-v1`) only changes the parts
/// this screen is drawn from, per ADR 0029 — one panel instead of a card
/// per project, `AsaGroup`/`TaskRow` instead of this file's own copies,
/// areas before "Not in an area" (was the opposite order).
///
/// **Deviation from the sketch, deliberate:** the sketch draws a drag grip
/// on every task row. Reordering (and dragging a subtask out from under
/// its parent) is explicitly parked in the spec — no real project note has
/// a real subtask yet, so there is nothing to drag. An inert grip icon
/// would promise a capability that is not there; this version omits it
/// rather than build a decoration that misleads.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:asa/hubs/product/ui/asa_group.dart';
import 'package:asa/hubs/product/ui/asa_panel.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/task_row.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class TasksView extends StatefulWidget {
  const TasksView({
    required this.groups,
    required this.onToggleTask,
    required this.onMarkAllDone,
    required this.onToggleParked,
    required this.onOpenProject,
    required this.folderBySlug,
    this.onToggleAreaTask,
    this.pinnedProjectName,
    super.key,
  });

  final List<TaskGroup> groups;

  /// Round-36 §3, L5/L6/L7 — a project's group name, an area's own
  /// sub-heading, and a resolvable `[[project]]` chip all open the named
  /// project's Plan tab this way, the same shared navigation the overview
  /// already uses.
  final void Function(ProjectOpenTarget target) onOpenProject;

  /// Round-36 §3, L7 — every scanned project's folder, by slug, so a
  /// `[[project]]` chip can resolve to a real project even one with no
  /// tasks of its own, and so absent from [groups] itself. A slug this
  /// does not contain leaves the chip inert, same as before this round.
  final Map<String, String> folderBySlug;

  /// Round 27's navigation fix — when set, the top-level group whose
  /// `project.name` matches sorts first. Nothing else about the grouping
  /// changes: not the nested `children`, not which tasks are visible.
  /// Null (the ordinary front-page-toggle path) leaves [groups] exactly
  /// as given.
  final String? pinnedProjectName;

  /// Flips one task's checkbox. The screen re-reads the file afterwards
  /// rather than trusting the flip happened — same discipline as the
  /// decision detail screen.
  final Future<void> Function(Project project, Task task) onToggleTask;

  /// Marks every open task in one project's own `## Tasks` section done.
  final Future<void> Function(Project project) onMarkAllDone;

  /// Toggles one task's `(parked)` tag — `PLAN.md` v0.3, "the rule of
  /// two". Orthogonal to [onToggleTask]; parking never touches the
  /// checkbox.
  final Future<void> Function(Project project, Task task) onToggleParked;

  /// Round 34/E, F — ticks a task inside one of a project's own areas
  /// (checkbox state only, in that area's `plan\*.md` page). Null keeps
  /// every area task here read-only.
  final Future<void> Function(String areaSourceFile, Task task)?
  onToggleAreaTask;

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  bool _showCode = true;

  // Keyed by the project's source file — stable across a data reload, so
  // checking one task does not reset every group's open/closed state.
  final Set<String> _collapsed = {};
  final Set<String> _showCompleted = {};

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const EmptyLine(
        'No open Tasks sections in any project note yet — add a '
        '## Tasks list of `- [ ]` lines to one and reload.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _controlsRow(),
        const SizedBox(height: AsaSpace.lg),
        AsaPanel(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in _orderedGroups())
                  _groupTile(group, depth: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// `widget.groups`, with the pinned project's group moved first — the
  /// rest keep their existing relative order. No-op when nothing is
  /// pinned or nothing matches, rather than silently reordering by guess.
  List<TaskGroup> _orderedGroups() {
    final pinned = widget.pinnedProjectName;
    if (pinned == null) return widget.groups;

    final match = <TaskGroup>[];
    final rest = <TaskGroup>[];
    for (final group in widget.groups) {
      (group.project.name == pinned ? match : rest).add(group);
    }
    return [...match, ...rest];
  }

  Widget _controlsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Tooltip(
          message: 'Hides every task marked (Code), everywhere',
          child: FilterChip(
            avatar: const Icon(Icons.code, size: 16),
            label: const Text('Code tasks'),
            selected: _showCode,
            onSelected: (value) => setState(() => _showCode = value),
          ),
        ),
        PopupMenuButton<bool>(
          tooltip: 'Expand or collapse every group',
          icon: const Icon(Icons.menu),
          onSelected: (expand) => setState(() {
            if (expand) {
              _collapsed.clear();
            } else {
              _collapsed
                ..clear()
                ..addAll(_allGroupKeys(widget.groups));
            }
          }),
          itemBuilder: (context) => const [
            PopupMenuItem(value: true, child: Text('Expand all')),
            PopupMenuItem(value: false, child: Text('Collapse all')),
          ],
        ),
      ],
    );
  }

  Set<String> _allGroupKeys(List<TaskGroup> groups) {
    final keys = <String>{};
    void visit(TaskGroup group) {
      keys.add(_keyOf(group));
      for (final areaGroup in group.areaGroups) {
        keys.add(areaGroup.sourceFile);
      }
      group.children.forEach(visit);
    }

    groups.forEach(visit);
    return keys;
  }

  String _keyOf(TaskGroup group) => group.project.sourceFile;

  /// A project note's own `sourceFile` (`projects/demo/demo.md`) to its
  /// containing folder (`projects/demo`) — the one thing every navigation
  /// target here actually needs, derived rather than threaded down as a
  /// second field alongside `Project` everywhere it is used.
  String _folderOf(String sourceFile) {
    final separator = sourceFile.contains(r'\') ? r'\' : '/';
    final index = sourceFile.lastIndexOf(separator);
    return index == -1 ? sourceFile : sourceFile.substring(0, index);
  }

  Widget _groupTile(TaskGroup group, {required int depth}) {
    final key = _keyOf(group);
    final collapsed = _collapsed.contains(key);

    final visibleTasks = _showCode
        ? group.tasks
        : group.tasks.where((t) => !t.isCode).toList();
    final openTasks = visibleTasks.where((t) => !t.done).toList();
    final totalOpen =
        group.tasks.where((t) => !t.done).length +
        group.areaGroups.fold<int>(
          0,
          (sum, a) => sum + a.tasks.where((t) => !t.done).length,
        );

    return AsaGroup(
      name: group.project.name,
      openCount: totalOpen,
      expanded: !collapsed,
      nested: depth > 0,
      onToggleExpand: () => setState(() {
        if (collapsed) {
          _collapsed.remove(key);
        } else {
          _collapsed.add(key);
        }
      }),
      // L5 — the project's own name opens its Plan tab.
      onNameTap: () =>
          widget.onOpenProject(openTarget(_folderOf(group.project.sourceFile))),
      onMarkAllDone: openTasks.isEmpty
          ? null
          : () => widget.onMarkAllDone(group.project),
      children: [
        // Round 37 §D1 — areas first, "Not in an area" last, same order
        // as the Plan tab.
        for (final areaGroup in group.areaGroups)
          _areaGroupTile(
            areaGroup,
            projectFolder: _folderOf(group.project.sourceFile),
          ),
        if (group.tasks.isNotEmpty)
          _notInAnAreaTile(
            group,
            projectFolder: _folderOf(group.project.sourceFile),
          ),
        for (final child in group.children) _groupTile(child, depth: depth + 1),
      ],
    );
  }

  /// Round 34/E — an area's own tasks, indented under its project, same
  /// collapse/hide-done/"Code tasks" rules as any other group here. No
  /// "mark all done" and no parking: Round 34 F's amendment to ADR 0021
  /// covers checkbox state only, in an area's own file — the two writes
  /// this group deliberately does not offer.
  Widget _areaGroupTile(
    AreaTaskGroup areaGroup, {
    required String projectFolder,
  }) {
    final key = areaGroup.sourceFile;
    final collapsed = _collapsed.contains(key);

    final visibleTasks = _showCode
        ? areaGroup.tasks
        : areaGroup.tasks.where((t) => !t.isCode).toList();
    final openTasks = visibleTasks.where((t) => !t.done).toList();
    final doneTasks = visibleTasks.where((t) => t.done).toList();
    final hiddenByCodeFilter =
        visibleTasks.isEmpty && areaGroup.tasks.isNotEmpty;
    final nextTask = openTasks.isEmpty ? null : openTasks.first;

    return Padding(
      padding: const EdgeInsets.only(left: AsaSpace.lg, top: AsaSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => widget.onOpenProject(
              openTarget(projectFolder, areaSourceFile: areaGroup.sourceFile),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AsaColors.violet,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AsaSpace.xs),
                Text(
                  areaGroup.name,
                  style: AsaText.rowName.copyWith(color: AsaColors.violet),
                ),
                const SizedBox(width: AsaSpace.xs),
                Text('${openTasks.length} open', style: AsaText.meta),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 16,
            ),
            tooltip: collapsed
                ? 'Expand this area'
                : 'Collapse this area — click again to reopen',
            onPressed: () => setState(() {
              if (collapsed) {
                _collapsed.remove(key);
              } else {
                _collapsed.add(key);
              }
            }),
          ),
          if (!collapsed)
            if (hiddenByCodeFilter)
              Padding(
                padding: const EdgeInsets.only(left: AsaSpace.xl),
                child: Text(
                  '${areaGroup.name} · ${areaGroup.tasks.length} tasks '
                  'hidden, marked code',
                  style: AsaText.meta,
                ),
              )
            else ...[
              for (final task in openTasks)
                _areaTaskRow(areaGroup, task, isNext: task == nextTask),
              if (doneTasks.isNotEmpty)
                _showCompletedLink(key, doneTasks.length),
              if (_showCompleted.contains(key))
                for (final task in doneTasks)
                  _areaTaskRow(areaGroup, task, isNext: false),
            ],
        ],
      ),
    );
  }

  /// A project's own home-note tasks, shown last (round 37 §D1) under the
  /// same "Not in an area" heading the Plan tab already uses.
  Widget _notInAnAreaTile(TaskGroup group, {required String projectFolder}) {
    final key = '${group.project.sourceFile}#home';
    final collapsed = _collapsed.contains(key);
    final visibleTasks = _showCode
        ? group.tasks
        : group.tasks.where((t) => !t.isCode).toList();
    final openTasks = visibleTasks.where((t) => !t.done).toList();
    final doneTasks = visibleTasks.where((t) => t.done).toList();
    final hiddenByCodeFilter = visibleTasks.isEmpty && group.tasks.isNotEmpty;
    final nextTask = openTasks.isEmpty ? null : openTasks.first;

    return Padding(
      padding: const EdgeInsets.only(left: AsaSpace.lg, top: AsaSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                widget.onOpenProject(openTarget(projectFolder, openHome: true)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AsaColors.ink3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AsaSpace.xs),
                Text(
                  'Not in an area',
                  style: AsaText.rowName.copyWith(color: AsaColors.ink2),
                ),
                const SizedBox(width: AsaSpace.xs),
                Text('${openTasks.length} open', style: AsaText.meta),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 16,
            ),
            tooltip: collapsed
                ? 'Expand this group'
                : 'Collapse this group — click again to reopen',
            onPressed: () => setState(() {
              if (collapsed) {
                _collapsed.remove(key);
              } else {
                _collapsed.add(key);
              }
            }),
          ),
          if (!collapsed)
            if (hiddenByCodeFilter)
              Padding(
                padding: const EdgeInsets.only(left: AsaSpace.xl),
                child: Text(
                  '${group.project.name} · ${group.tasks.length} tasks '
                  'hidden, marked code',
                  style: AsaText.meta,
                ),
              )
            else ...[
              for (final task in openTasks)
                _taskRow(group.project, task, isNext: task == nextTask),
              if (doneTasks.isNotEmpty)
                _showCompletedLink(key, doneTasks.length),
              if (_showCompleted.contains(key))
                for (final task in doneTasks)
                  _taskRow(group.project, task, isNext: false),
            ],
        ],
      ),
    );
  }

  Widget _showCompletedLink(String key, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: AsaSpace.xl, top: AsaSpace.xs),
      child: InkWell(
        onTap: () => setState(() {
          if (_showCompleted.contains(key)) {
            _showCompleted.remove(key);
          } else {
            _showCompleted.add(key);
          }
        }),
        child: Text(
          _showCompleted.contains(key)
              ? 'Hide completed'
              : 'Show completed ($count)',
          style: AsaText.meta,
        ),
      ),
    );
  }

  Widget _taskRow(Project project, Task task, {required bool isNext}) {
    return TaskRow(
      text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
      done: task.done,
      isNext: isNext,
      isCodeTask: task.isCode,
      indent: AsaSpace.xl,
      onToggle: (_) => widget.onToggleTask(project, task),
      crossProjectChip: task.crossProjectRef == null
          ? null
          : _crossProjectChip(task),
      parked: task.parked,
      onPark: () => widget.onToggleParked(project, task),
    );
  }

  /// Round-36 §3, L7 — a `[[project]]` reference, tappable when
  /// [TasksView.folderBySlug] can resolve it to a real project; inert
  /// otherwise, same as every task here already was before this round.
  Widget _crossProjectChip(Task task) {
    final folder = widget.folderBySlug[task.crossProjectRef];
    final chip = Text(
      '↳ ${task.crossProjectRef}',
      style: AsaText.meta.copyWith(fontFamily: 'monospace'),
    );
    if (folder == null) return chip;
    return InkWell(
      onTap: () => widget.onOpenProject(openTarget(folder)),
      child: chip,
    );
  }

  /// Round 34/E, F — an area's own task row: the checkbox ticks (when
  /// [TasksView.onToggleAreaTask] is set), same as any other task here.
  /// No parking icon — Round 34 F's amendment to ADR 0021 covers checkbox
  /// state only, and parking is a different write this group does not
  /// offer for an area's file.
  Widget _areaTaskRow(
    AreaTaskGroup areaGroup,
    Task task, {
    required bool isNext,
  }) {
    final onToggle = widget.onToggleAreaTask;
    return TaskRow(
      text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
      done: task.done,
      isNext: isNext,
      isCodeTask: task.isCode,
      indent: AsaSpace.xl,
      onToggle: onToggle == null
          ? null
          : (_) => onToggle(areaGroup.sourceFile, task),
    );
  }
}
