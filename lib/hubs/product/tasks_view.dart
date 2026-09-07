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
library;

import 'package:asa/core/project.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_reader.dart';
import 'package:flutter/material.dart';

class TasksView extends StatefulWidget {
  const TasksView({
    required this.groups,
    required this.onToggleTask,
    required this.onMarkAllDone,
    super.key,
  });

  final List<TaskGroup> groups;

  /// Flips one task's checkbox. The screen re-reads the file afterwards
  /// rather than trusting the flip happened — same discipline as the
  /// decision detail screen.
  final Future<void> Function(Project project, Task task) onToggleTask;

  /// Marks every open task in one project's own `## Tasks` section done.
  final Future<void> Function(Project project) onMarkAllDone;

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
        for (final group in widget.groups) _groupTile(group, depth: 0),
      ],
    );
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
              for (final child in group.children)
                _groupTile(child, depth: depth + 1),
            ],
          ),
        ),
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
              task.text,
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
