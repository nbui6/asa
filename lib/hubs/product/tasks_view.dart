/// Product Hub — front page, Tasks view. Round 42 rebuilt this screen
/// entirely, `asa-tasks-v3.html` §2-§4: one project at a time, a left
/// rail (⭐ Next up · 📥 Inbox · every visible project with its own open
/// count), add anywhere, edit in place, drag to reorder or move.
///
/// **Replaces the old flat "every project, all its tasks, nested" view**
/// (`HANDOVER.md`, 2026-09-07) — 2026-09-28: *"Tasks is hard to use for me
/// right now. I imagine it a bit like google task, where I easily move
/// tasks around drag and drop, type new in anywhere."*
///
/// **One honest adaptation, named rather than silently built different:**
/// the sketch draws the subtask indent itself as a rightward drag. A
/// horizontal drag gesture across a vertical list of drop targets has no
/// reliable, discoverable hit-test on a desktop pointer — this screen
/// gives indent/outdent their own small ›/‹ buttons, shown on hover next
/// to the drag handle, instead. Every other drag `asa-tasks-v3` draws
/// (reorder, move to another section, onto a project, onto Inbox) is a
/// real `Draggable`/`DragTarget` here, unchanged from the sketch.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/project_open_target.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/tasks_board.dart';
import 'package:asa/hubs/product/ui/asa_panel.dart';
import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:asa/hubs/product/ui/task_row.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A task mid-drag, and the file it is dragged **from** — the one thing
/// every drop target needs to decide "reorder" (same file) from "move"
/// (a different one).
class _DraggedTask {
  const _DraggedTask({required this.path, required this.task});
  final String path;
  final Task task;
}

class TasksView extends StatefulWidget {
  const TasksView({
    required this.snapshots,
    required this.nextUp,
    required this.inboxTasks,
    required this.homePath,
    required this.folderBySlug,
    required this.onOpenProject,
    required this.onToggleTask,
    required this.onAddTaskAtTop,
    required this.onAddTaskAtBottom,
    required this.onEditText,
    required this.onSetIndent,
    required this.onReorder,
    required this.onMove,
    required this.onMoveToTop,
    required this.onCaptureInbox,
    required this.onDataChanged,
    this.initialSelectedFolder,
    super.key,
  });

  final List<ProjectTasksSnapshot> snapshots;
  final List<NextUpItem> nextUp;
  final List<Task> inboxTasks;

  /// `HOME.md`'s own path — null when no folder is chosen at all, in
  /// which case the Inbox row is inert (nothing to read or write).
  final String? homePath;

  /// Round-36 §3, L7 — every scanned project's folder, by slug, so a
  /// `[[project]]` chip can resolve to a real project even one with no
  /// tasks of its own.
  final Map<String, String> folderBySlug;

  final void Function(ProjectOpenTarget target) onOpenProject;

  final Future<void> Function(
    String path, {
    required String rawLine,
    required bool done,
  })
  onToggleTask;
  final Future<void> Function(String path, String text) onAddTaskAtTop;
  final Future<void> Function(String path, String text) onAddTaskAtBottom;
  final Future<void> Function(
    String path, {
    required String rawLine,
    required String oldText,
    required String newText,
  })
  onEditText;
  final Future<void> Function(
    String path, {
    required String rawLine,
    required int indent,
  })
  onSetIndent;
  final Future<void> Function(
    String path, {
    required List<String> currentOrder,
    required List<String> newOrder,
  })
  onReorder;
  final Future<void> Function({
    required String fromPath,
    required String toPath,
    required String rawLine,
  })
  onMove;
  final Future<void> Function({
    required String fromPath,
    required String toPath,
    required String rawLine,
  })
  onMoveToTop;
  final Future<void> Function(String text) onCaptureInbox;

  /// Called after every write here lands — the parent (`ProjectsScreen`)
  /// re-reads everything fresh, the same discipline the overview and
  /// every project screen already follow.
  final VoidCallback onDataChanged;

  /// Round 27's own navigation fix, carried into Round 42: opened from a
  /// project's own "Tasks" button, that project is selected on arrival.
  final String? initialSelectedFolder;

  @override
  State<TasksView> createState() => _TasksViewState();
}

enum _AddPosition { top, bottom }

class _TasksViewState extends State<TasksView> {
  static const _nextUpKey = '\u0000next-up';
  static const _inboxKey = '\u0000inbox';

  late String _selected;
  bool _railShowAll = false;

  /// Round 42 §A — "done tasks fold into ✓ N done · show › **per
  /// project**": one toggle for the whole right pane, every section's
  /// own done tasks together, not one fold per section.
  final Set<String> _doneShown = {};

  String? _editingKey;
  final _editController = TextEditingController();

  final Set<String> _openAddFields = {};
  final Map<String, TextEditingController> _addControllers = {};

  final _inboxCaptureController = TextEditingController();

  /// Round 42 §B — the old per-screen "Code tasks" `FilterChip` moves into
  /// a small filter menu; shown by default, same as before.
  bool _showCode = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedFolder ?? _nextUpKey;
  }

  @override
  void didUpdateWidget(TasksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only react to a genuinely new request — same guard `PlanView`'s own
    // `didUpdateWidget` uses, so a plain reload never re-fires this.
    if (widget.initialSelectedFolder != null &&
        widget.initialSelectedFolder != oldWidget.initialSelectedFolder) {
      _selected = widget.initialSelectedFolder!;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _inboxCaptureController.dispose();
    for (final controller in _addControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _editKey(String path, String rawLine) => '$path\u0000$rawLine';
  String _addKey(String path, _AddPosition position) => '$path\u0000$position';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 230, child: _rail()),
        const SizedBox(width: AsaSpace.md),
        Expanded(child: _main()),
      ],
    );
  }

  /// A header row shared by all three right-pane bodies (Next up, Inbox,
  /// one project): the panel's own title on the left, the Code-tasks
  /// filter menu on the right — same position regardless of which body is
  /// showing, so "hides every task marked (Code), everywhere" reads as one
  /// switch, not three.
  Widget _paneHeader(Widget title) {
    return Row(
      children: [
        Expanded(child: title),
        _codeFilterMenu(),
      ],
    );
  }

  /// Round 42 §B — "the *Code tasks* switch moves into a small filter
  /// menu ((Code) tasks hidden or shown)", replacing the old inline
  /// `FilterChip` this screen's predecessor showed per group.
  Widget _codeFilterMenu() {
    return PopupMenuButton<bool>(
      tooltip: 'Hides every task marked (Code), everywhere',
      icon: const Icon(Icons.filter_list, size: 18, color: AsaColors.ink3),
      onSelected: (value) => setState(() => _showCode = value),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<bool>(
          value: !_showCode,
          checked: _showCode,
          child: const Text('Code tasks'),
        ),
      ],
    );
  }

  bool _codeVisible(Task task) => _showCode || !task.isCode;

  // --- The left rail ------------------------------------------------

  Widget _rail() {
    final shown = _railShowAll
        ? widget.snapshots
        : widget.snapshots.take(10).toList();
    final more = widget.snapshots.length - shown.length;

    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AsaSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _railItem(
              label: '⭐ Next up',
              count: widget.nextUp.length,
              selected: _selected == _nextUpKey,
              onTap: () => setState(() => _selected = _nextUpKey),
            ),
            _railInboxItem(),
            const Padding(
              padding: EdgeInsets.only(
                left: AsaSpace.md,
                top: AsaSpace.sm,
                bottom: 2,
              ),
              child: SectionLabel('Projects'),
            ),
            for (final snapshot in shown) _railProjectItem(snapshot),
            if (more > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AsaSpace.md,
                  vertical: AsaSpace.xs,
                ),
                child: InkWell(
                  onTap: () => setState(() => _railShowAll = true),
                  child: Text('+ $more more', style: AsaText.meta),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _railItem({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      color: selected ? AsaColors.violetBg : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AsaSpace.md,
            vertical: AsaSpace.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AsaText.body.copyWith(
                    color: selected ? AsaColors.violet : AsaColors.ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Text('$count', style: AsaText.meta),
            ],
          ),
        ),
      ),
    );
  }

  /// Round 42 §A — "onto Inbox" is one of the sketch's own named drop
  /// targets (§3): dragging a task here moves it to `HOME.md`'s own
  /// `## Tasks`, the same file quick capture already writes to.
  Widget _railInboxItem() {
    final home = widget.homePath;
    final content = _railItem(
      label: '📥 Inbox',
      count: widget.inboxTasks.length,
      selected: _selected == _inboxKey,
      onTap: () => setState(() => _selected = _inboxKey),
    );
    if (home == null) return content;

    return DragTarget<_DraggedTask>(
      onWillAcceptWithDetails: (details) => details.data.path != home,
      onAcceptWithDetails: (details) =>
          _moveTask(dragged: details.data, toPath: home, atTop: false),
      builder: (context, candidates, rejected) => Container(
        decoration: candidates.isNotEmpty
            ? BoxDecoration(
                border: Border.all(color: AsaColors.blue, width: 2),
                color: AsaColors.blueBg,
              )
            : null,
        child: content,
      ),
    );
  }

  Widget _railProjectItem(ProjectTasksSnapshot snapshot) {
    final content = _railItem(
      label: snapshot.project.name,
      count: snapshot.openCount,
      selected: _selected == snapshot.folder,
      onTap: () => setState(() => _selected = snapshot.folder),
    );

    // Round 42 §A — "drop it on a project: it goes to the top of that
    // project's tasks (into Not in an area if it has areas)" —
    // moveTaskToTop always targets the project's own home file, which is
    // exactly "Not in an area" once the project has any areas at all.
    return DragTarget<_DraggedTask>(
      onWillAcceptWithDetails: (details) =>
          details.data.path != snapshot.project.sourceFile,
      onAcceptWithDetails: (details) => _moveTask(
        dragged: details.data,
        toPath: snapshot.project.sourceFile,
        atTop: true,
      ),
      builder: (context, candidates, rejected) => Container(
        decoration: candidates.isNotEmpty
            ? BoxDecoration(
                border: Border.all(color: AsaColors.blue, width: 2),
                color: AsaColors.blueBg,
              )
            : null,
        child: content,
      ),
    );
  }

  // --- The right pane -------------------------------------------------

  Widget _main() {
    if (_selected == _nextUpKey) return _nextUpBody();
    if (_selected == _inboxKey) return _inboxBody();
    final snapshot = widget.snapshots
        .where((s) => s.folder == _selected)
        .firstOrNull;
    if (snapshot == null) return _nextUpBody();
    return _projectBody(snapshot);
  }

  Widget _nextUpBody() {
    final visible = widget.nextUp
        .where((item) => _codeVisible(item.task))
        .toList();
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _paneHeader(const Text('Next up', style: AsaText.rowName)),
            const SizedBox(height: AsaSpace.sm),
            if (visible.isEmpty)
              const EmptyLine('Nothing waiting — every project is caught up.')
            else
              for (final item in visible) _nextUpRow(item),
            const SizedBox(height: AsaSpace.xs),
            const Text(
              "Tick one, and that project's next task takes its place.",
              style: AsaText.meta,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextUpRow(NextUpItem item) {
    final waiting = waitingOn(item.task, DateTime.now());
    return TaskRow(
      text: item.text,
      done: item.task.done,
      onToggle: (_) => _toggle(item.path, item.task),
      trailing: waiting == null ? null : _waitingChip(waiting),
      // Round 42's own L31 — the project name, not the task text, is the
      // link: tapping it shows that project's own list, same destination
      // as clicking it in the left rail (L30) rather than pushing a new
      // screen. Same inline-span pattern `plan_view.dart`'s Goal text
      // already uses for its own "Objective N" link.
      textChild: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: item.text, style: AsaText.body),
            TextSpan(
              text: '  · ${item.projectName}',
              style: AsaText.meta,
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _selected = item.projectFolder),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _inboxBody() {
    final home = widget.homePath;
    final visibleInboxTasks = widget.inboxTasks.where(_codeVisible).toList();
    return AsaPanel(
      child: Padding(
        padding: const EdgeInsets.all(AsaSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _paneHeader(const Text('Inbox', style: AsaText.rowName)),
            const SizedBox(height: AsaSpace.xs),
            const Text(
              'Type here when a task has no project yet; drag it onto one '
              'later.',
              style: AsaText.meta,
            ),
            const SizedBox(height: AsaSpace.sm),
            if (home != null)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inboxCaptureController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Quick capture — type anything',
                      ),
                      onSubmitted: (_) => _submitInboxCapture(),
                    ),
                  ),
                  const SizedBox(width: AsaSpace.sm),
                  IconButton(
                    onPressed: _submitInboxCapture,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add to the inbox',
                  ),
                ],
              ),
            const SizedBox(height: AsaSpace.sm),
            if (visibleInboxTasks.isEmpty)
              const EmptyLine('Inbox empty — nothing unfiled right now.')
            else
              for (final task in visibleInboxTasks)
                if (home != null)
                  _draggableTaskRow(
                    path: home,
                    task: task,
                    sectionTasks: widget.inboxTasks,
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitInboxCapture() async {
    final text = _inboxCaptureController.text.trim();
    if (text.isEmpty) return;
    _inboxCaptureController.clear();
    await widget.onCaptureInbox(text);
    widget.onDataChanged();
  }

  Widget _projectBody(ProjectTasksSnapshot snapshot) {
    final expanded = _doneShown.contains(snapshot.folder);
    final totalDone =
        snapshot.homeTasks.where((t) => t.done && _codeVisible(t)).length +
        snapshot.areas.fold<int>(
          0,
          (sum, area) =>
              sum + area.tasks.where((t) => t.done && _codeVisible(t)).length,
        );

    return SingleChildScrollView(
      child: AsaPanel(
        child: Padding(
          padding: const EdgeInsets.all(AsaSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _paneHeader(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Round-36 §3, L5 — the project's own name opens its
                    // Plan tab, same as every other project-name link.
                    InkWell(
                      onTap: () =>
                          widget.onOpenProject(openTarget(snapshot.folder)),
                      child: Text(
                        snapshot.project.name,
                        style: AsaText.rowName,
                      ),
                    ),
                    const SizedBox(width: AsaSpace.sm),
                    Pill(
                      snapshot.project.status,
                      meaning: meaningForStatus(snapshot.project.status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AsaSpace.sm),
              if (snapshot.areas.isEmpty)
                ..._sectionBody(
                  path: snapshot.project.sourceFile,
                  tasks: snapshot.homeTasks,
                  showDone: expanded,
                  addPosition: _AddPosition.top,
                )
              else ...[
                const SectionLabel('Not in an area'),
                const SizedBox(height: 2),
                ..._sectionBody(
                  path: snapshot.project.sourceFile,
                  tasks: snapshot.homeTasks,
                  showDone: expanded,
                  addPosition: _AddPosition.top,
                ),
                for (final area in snapshot.areas) ...[
                  const SizedBox(height: AsaSpace.sm),
                  InkWell(
                    onTap: () => widget.onOpenProject(
                      openTarget(
                        snapshot.folder,
                        areaSourceFile: area.sourceFile,
                      ),
                    ),
                    child: Text(
                      area.name,
                      style: AsaText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AsaColors.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  ..._sectionBody(
                    path: area.sourceFile,
                    tasks: area.tasks,
                    showDone: expanded,
                    addPosition: _AddPosition.bottom,
                  ),
                ],
              ],
              if (totalDone > 0) ...[
                const SizedBox(height: AsaSpace.xs),
                InkWell(
                  onTap: () => setState(() {
                    if (expanded) {
                      _doneShown.remove(snapshot.folder);
                    } else {
                      _doneShown.add(snapshot.folder);
                    }
                  }),
                  child: Text(
                    expanded ? 'Hide' : '✓ $totalDone done  show ›',
                    style: AsaText.meta.copyWith(
                      color: AsaColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sectionBody({
    required String path,
    required List<Task> tasks,
    required bool showDone,
    required _AddPosition addPosition,
  }) {
    final visible = (showDone ? tasks : tasks.where((t) => !t.done))
        .where(_codeVisible)
        .toList();
    final addField = _addField(path: path, position: addPosition);

    return [
      if (addPosition == _AddPosition.top) addField,
      DragTarget<_DraggedTask>(
        onWillAcceptWithDetails: (details) => details.data.path != path,
        onAcceptWithDetails: (details) =>
            _moveTask(dragged: details.data, toPath: path, atTop: false),
        builder: (context, candidates, rejected) => Container(
          decoration: candidates.isNotEmpty
              ? const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AsaColors.blue, width: 2),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final task in visible)
                _draggableTaskRow(path: path, task: task, sectionTasks: tasks),
            ],
          ),
        ),
      ),
      if (addPosition == _AddPosition.bottom) addField,
    ];
  }

  // --- One task row: drag source, drop target, edit-in-place ---------

  Widget _draggableTaskRow({
    required String path,
    required Task task,
    required List<Task> sectionTasks,
  }) {
    final row = _taskRow(path: path, task: task);

    return DragTarget<_DraggedTask>(
      onWillAcceptWithDetails: (details) =>
          details.data.task.rawLine != task.rawLine ||
          details.data.path != path,
      onAcceptWithDetails: (details) => _handleDropOnRow(
        dragged: details.data,
        path: path,
        target: task,
        sectionTasks: sectionTasks,
      ),
      builder: (context, candidates, rejected) => Container(
        decoration: candidates.isNotEmpty
            ? const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AsaColors.blue, width: 2),
                ),
              )
            : null,
        child: Draggable<_DraggedTask>(
          data: _DraggedTask(path: path, task: task),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(
                horizontal: AsaSpace.md,
                vertical: AsaSpace.sm,
              ),
              color: AsaColors.panel,
              child: Text(
                stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: row),
          child: row,
        ),
      ),
    );
  }

  Widget _taskRow({required String path, required Task task}) {
    final editKey = _editKey(path, task.rawLine);
    final editing = _editingKey == editKey;
    final waiting = waitingOn(task, DateTime.now());

    return _HoverRow(
      builder: ({required hovering}) => TaskRow(
        text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
        done: task.done,
        indent: task.indent * AsaSpace.lg,
        onToggle: (_) => _toggle(path, task),
        leading: Opacity(
          opacity: hovering ? 1 : 0,
          child: const Icon(
            Icons.drag_indicator,
            size: 14,
            color: AsaColors.ink3,
          ),
        ),
        textChild: editing ? _editField(path: path, task: task) : null,
        onTapText: editing ? null : () => _startEdit(path, task),
        crossProjectChip: task.crossProjectRef != null
            ? _crossProjectChip(task)
            : null,
        trailing: !hovering && waiting == null
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (waiting != null) _waitingChip(waiting),
                  if (hovering && !editing) ...[
                    if (waiting != null) const SizedBox(width: AsaSpace.xs),
                    Tooltip(
                      message: task.indent == 0
                          ? 'Indent — make it a subtask'
                          : 'Un-indent',
                      child: InkWell(
                        onTap: () =>
                            _setIndent(path, task, task.indent == 0 ? 1 : 0),
                        child: Icon(
                          task.indent == 0
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          size: 16,
                          color: AsaColors.ink3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _waitingChip(({String name, int days, String since}) waiting) {
    final overdue = waiting.days >= 14;
    return Text(
      'waiting on ${waiting.name} · ${waiting.days} days',
      style: AsaText.meta.copyWith(
        color: overdue ? AsaColors.amber : AsaColors.ink3,
        fontWeight: overdue ? FontWeight.bold : null,
      ),
    );
  }

  /// Round-36 §3, L7 — a `[[project]]` reference, tappable when it
  /// resolves to a real project, inert otherwise — same fallback every
  /// cross-project chip in this app already uses.
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

  Widget _editField({required String path, required Task task}) {
    return _SubmitOnEscape(
      onEscape: _cancelEdit,
      child: TextField(
        controller: _editController,
        autofocus: true,
        decoration: const InputDecoration(isDense: true, isCollapsed: true),
        onSubmitted: (_) => _submitEdit(path, task),
        onTapOutside: (_) => _submitEdit(path, task),
      ),
    );
  }

  void _startEdit(String path, Task task) {
    setState(() {
      _editingKey = _editKey(path, task.rawLine);
      _editController.text = task.text;
    });
  }

  void _cancelEdit() => setState(() => _editingKey = null);

  Future<void> _submitEdit(String path, Task task) async {
    final newText = _editController.text.trim();
    setState(() => _editingKey = null);
    if (newText.isEmpty || newText == task.text) return;
    await widget.onEditText(
      path,
      rawLine: task.rawLine,
      oldText: task.text,
      newText: newText,
    );
    widget.onDataChanged();
  }

  // --- "＋ Add a task" --------------------------------------------------

  Widget _addField({required String path, required _AddPosition position}) {
    final key = _addKey(path, position);
    final open = _openAddFields.contains(key);
    if (!open) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: () => setState(() {
            _addControllers[key] = TextEditingController();
            _openAddFields.add(key);
          }),
          child: Text(
            '＋ Add a task',
            style: AsaText.body.copyWith(color: AsaColors.blue),
          ),
        ),
      );
    }

    final controller = _addControllers[key]!;
    return _SubmitOnEscape(
      onEscape: () => _closeAddField(key),
      child: SizedBox(
        height: 26,
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(isDense: true, isCollapsed: true),
          onSubmitted: (_) => _submitAddField(path, position, key, controller),
        ),
      ),
    );
  }

  void _closeAddField(String key) {
    setState(() {
      _addControllers.remove(key)?.dispose();
      _openAddFields.remove(key);
    });
  }

  Future<void> _submitAddField(
    String path,
    _AddPosition position,
    String key,
    TextEditingController controller,
  ) async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      _closeAddField(key);
      return;
    }
    controller.clear();
    if (position == _AddPosition.top) {
      await widget.onAddTaskAtTop(path, text);
    } else {
      await widget.onAddTaskAtBottom(path, text);
    }
    widget.onDataChanged();
    // Round 42 §B — "Enter writes the line and opens the next empty
    // field": stays open, ready for the next one, rather than closing.
  }

  // --- Writers, wired to real callbacks --------------------------------

  Future<void> _toggle(String path, Task task) async {
    await widget.onToggleTask(path, rawLine: task.rawLine, done: !task.done);
    widget.onDataChanged();
  }

  Future<void> _setIndent(String path, Task task, int indent) async {
    await widget.onSetIndent(path, rawLine: task.rawLine, indent: indent);
    widget.onDataChanged();
  }

  Future<void> _handleDropOnRow({
    required _DraggedTask dragged,
    required String path,
    required Task target,
    required List<Task> sectionTasks,
  }) async {
    if (dragged.path == path) {
      final current = [for (final t in sectionTasks) t.rawLine];
      final fromIndex = current.indexOf(dragged.task.rawLine);
      final toIndex = current.indexOf(target.rawLine);
      if (fromIndex == -1 || toIndex == -1 || fromIndex == toIndex) return;
      final newOrder = [...current]..removeAt(fromIndex);
      final insertAt = fromIndex < toIndex ? toIndex - 1 : toIndex;
      newOrder.insert(insertAt, dragged.task.rawLine);
      await widget.onReorder(path, currentOrder: current, newOrder: newOrder);
    } else {
      await widget.onMove(
        fromPath: dragged.path,
        toPath: path,
        rawLine: dragged.task.rawLine,
      );
    }
    widget.onDataChanged();
  }

  Future<void> _moveTask({
    required _DraggedTask dragged,
    required String toPath,
    required bool atTop,
  }) async {
    if (atTop) {
      await widget.onMoveToTop(
        fromPath: dragged.path,
        toPath: toPath,
        rawLine: dragged.task.rawLine,
      );
    } else {
      await widget.onMove(
        fromPath: dragged.path,
        toPath: toPath,
        rawLine: dragged.task.rawLine,
      );
    }
    widget.onDataChanged();
  }
}

/// A small wrapper reporting hover state to its own builder — the drag
/// handle and the indent/outdent buttons only show once the pointer is
/// actually over this row, same as `TaskRow`'s own park icon elsewhere.
class _HoverRow extends StatefulWidget {
  const _HoverRow({required this.builder});
  final Widget Function({required bool hovering}) builder;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: widget.builder(hovering: _hovering),
    );
  }
}

/// Escape cancels an inline field — Round 42 §B: "Esc or an empty Enter
/// closes it" (the add field) / "Esc cancels" (editing a task's text).
class _SubmitOnEscape extends StatelessWidget {
  const _SubmitOnEscape({required this.onEscape, required this.child});
  final VoidCallback onEscape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onEscape();
        }
      },
      child: child,
    );
  }
}
