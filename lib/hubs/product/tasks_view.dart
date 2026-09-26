/// Product Hub — front page, Tasks view.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the front-page Tasks view."
/// Sketch: `asa-tasks-view.png`/`.html`, seventh and approved pass.
///
/// **Deviation from the sketch, deliberate:** the sketch draws a drag grip
/// on every task row. Reordering (and dragging a subtask out from under
/// its parent) is explicitly parked in the spec — no real project note has
/// a real subtask yet, so there is nothing to drag. An inert grip icon
/// would promise a capability that is not there; this version omits it
/// rather than build a decoration that misleads.
///
/// **Fixed 2026-09-13:** a task's text was shown raw, backticks and all —
/// visible on real content, `asa.md`'s own `## Tasks` section ("Fix
/// `decision_detail_screen_test.dart`'s flakiness"). `markdown.dart`'s
/// `stripCodeSpanMarkers`/`stripEmphasisMarkers` are applied here, at
/// display time — the parsed [Task.text] itself stays raw, same rule
/// `decision_detail_screen.dart` already follows for a decision's body.
///
/// **2026-09-13, later — parked tasks.** `HANDOVER.md`'s "parked items,
/// and the rule of two". A parked task shows a small bookmark chip, same
/// visual language the `(Code)` icon already set — but tappable, since
/// parking (unlike being Code's task) is something Nico toggles here.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:flutter/material.dart';

class TasksView extends StatefulWidget {
  const TasksView({
    required this.groups,
    required this.onToggleTask,
    required this.onMarkAllDone,
    required this.onToggleParked,
    this.onToggleAreaTask,
    this.pinnedProjectName,
    super.key,
  });

  final List<TaskGroup> groups;

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
      return const _Panel(
        child: Text(
          'No open Tasks sections in any project note yet — add a '
          '## Tasks list of `- [ ]` lines to one and reload.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _controlsRow(),
        const SizedBox(height: 16),
        for (final group in _orderedGroups()) _groupTile(group, depth: 0),
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

  Widget _groupTile(TaskGroup group, {required int depth}) {
    final key = _keyOf(group);
    final collapsed = _collapsed.contains(key);

    final visibleTasks = _showCode
        ? group.tasks
        : group.tasks.where((t) => !t.isCode).toList();
    final openTasks = visibleTasks.where((t) => !t.done).toList();
    final doneTasks = visibleTasks.where((t) => t.done).toList();
    final hiddenByCodeFilter = visibleTasks.isEmpty && group.tasks.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      collapsed ? Icons.chevron_right : Icons.expand_more,
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
                  IconButton(
                    icon: const Icon(Icons.check),
                    tooltip: 'Mark all done for this group',
                    onPressed: openTasks.isEmpty
                        ? null
                        : () => widget.onMarkAllDone(group.project),
                  ),
                  Text(
                    group.project.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (!collapsed) ...[
                if (hiddenByCodeFilter)
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      '${group.project.name} · ${group.tasks.length} tasks '
                      'hidden, marked code',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else ...[
                  for (final task in openTasks) _taskRow(group.project, task),
                  if (doneTasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4),
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
                              : 'Show completed (${doneTasks.length})',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  if (_showCompleted.contains(key))
                    for (final task in doneTasks) _taskRow(group.project, task),
                ],
              ],
              if (!collapsed)
                for (final areaGroup in group.areaGroups)
                  _areaGroupTile(areaGroup, depth: depth + 1),
              for (final child in group.children)
                _groupTile(child, depth: depth + 1),
            ],
          ),
        ),
      ),
    );
  }

  /// Round 34/E — an area's own tasks, indented under its project, same
  /// collapse/hide-done/"Code tasks" rules as any other group here. No
  /// "mark all done" and no parking: Round 34 F's amendment to ADR 0021
  /// covers checkbox state only, in an area's own file — the two writes
  /// this group deliberately does not offer.
  Widget _areaGroupTile(AreaTaskGroup areaGroup, {required int depth}) {
    final key = areaGroup.sourceFile;
    final collapsed = _collapsed.contains(key);

    final visibleTasks = _showCode
        ? areaGroup.tasks
        : areaGroup.tasks.where((t) => !t.isCode).toList();
    final openTasks = visibleTasks.where((t) => !t.done).toList();
    final doneTasks = visibleTasks.where((t) => t.done).toList();
    final hiddenByCodeFilter =
        visibleTasks.isEmpty && areaGroup.tasks.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
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
              Text(
                areaGroup.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (!collapsed)
            if (hiddenByCodeFilter)
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  '${areaGroup.name} · ${areaGroup.tasks.length} tasks '
                  'hidden, marked code',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else ...[
              for (final task in openTasks) _areaTaskRow(areaGroup, task),
              if (doneTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4),
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
                          : 'Show completed (${doneTasks.length})',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              if (_showCompleted.contains(key))
                for (final task in doneTasks) _areaTaskRow(areaGroup, task),
            ],
        ],
      ),
    );
  }

  Widget _taskRow(Project project, Task task) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 2, bottom: 2),
      child: Row(
        children: [
          Checkbox(
            value: task.done,
            onChanged: (_) => widget.onToggleTask(project, task),
          ),
          Expanded(
            child: Text(
              stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
              style: task.done ? TextStyle(color: Colors.grey.shade500) : null,
            ),
          ),
          if (task.crossProjectRef != null)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '↳ ${task.crossProjectRef}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          if (task.isCode)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: "This task is Code's, not yours",
                child: Icon(Icons.code, size: 16, color: Colors.grey.shade500),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: task.parked
                  ? 'Parked — tap to unpark'
                  : 'Tap to park this task',
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => widget.onToggleParked(project, task),
                child: Icon(
                  task.parked ? Icons.bookmark : Icons.bookmark_border,
                  size: 16,
                  color: task.parked
                      ? Colors.amber.shade800
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Round 34/E, F — an area's own task row: the checkbox ticks (when
  /// [TasksView.onToggleAreaTask] is set), same as any other task here.
  /// No parking icon — Round 34 F's amendment to ADR 0021 covers checkbox
  /// state only, and parking is a different write this group does not
  /// offer for an area's file.
  Widget _areaTaskRow(AreaTaskGroup areaGroup, Task task) {
    final onToggle = widget.onToggleAreaTask;
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 2, bottom: 2),
      child: Row(
        children: [
          Checkbox(
            value: task.done,
            onChanged: onToggle == null
                ? null
                : (_) => onToggle(areaGroup.sourceFile, task),
          ),
          Expanded(
            child: Text(
              stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
              style: task.done ? TextStyle(color: Colors.grey.shade500) : null,
            ),
          ),
          if (task.isCode)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: "This task is Code's, not yours",
                child: Icon(Icons.code, size: 16, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}
