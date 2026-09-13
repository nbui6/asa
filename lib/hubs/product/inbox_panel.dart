/// Product Hub — front page, the inbox.
///
/// Spec: `HANDOVER.md`, 2026-09-13 entry, "Round 8 — quick capture (the
/// inbox)". Decided in `0014-roadmap-tasks-progress.md`'s two 2026-09-08
/// addenda: **capture never classifies** — one input, type anything, it
/// lands in `## Tasks`, always, no project prompt — and **one inbox, not
/// per-project** — a task typed with no project open lands here, and
/// assigning it to a project afterward is a drag, same as promoting a task
/// to a milestone would be.
///
/// This widget is only the source side of that drag. `ProjectsView`'s rows
/// are the target side; the write itself (`moveTask`) lives in
/// `ProjectsScreen`, same layering as every other write in this app.
///
/// **Fixed 2026-09-13:** the status line below the capture box only
/// rendered once at least one task existed — at zero it vanished
/// entirely, which is exactly what made this panel invisible in Nico's
/// own screenshots. It now always shows a line, empty or not, so the
/// inbox's presence is never in question.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/task.dart';
import 'package:flutter/material.dart';

class InboxPanel extends StatefulWidget {
  const InboxPanel({required this.tasks, required this.onCapture, super.key});

  /// The unfiled tasks — `HOME.md`'s own `## Tasks` section.
  final List<Task> tasks;

  /// One line typed and submitted. Never asked what it is, per ADR 0014 —
  /// classification is a drag made later, not a question asked now.
  final Future<void> Function(String text) onCapture;

  @override
  State<InboxPanel> createState() => _InboxPanelState();
}

class _InboxPanelState extends State<InboxPanel> {
  final _captureField = TextEditingController();

  // Closed by default — "keep it small, one glance," per the spec. Reopens
  // itself once something is actually captured, so the first thing typed
  // is immediately visible rather than filed out of sight.
  bool _expanded = false;

  @override
  void dispose() {
    _captureField.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _captureField.text.trim();
    if (text.isEmpty) return;
    _captureField.clear();
    setState(() => _expanded = true);
    await widget.onCapture(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('inboxCaptureField'),
                controller: _captureField,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Quick capture — type anything, sort it later',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              tooltip: 'Add to the inbox',
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (widget.tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Inbox empty — nothing unfiled right now.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          )
        else ...[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.tasks.length} unfiled — drag onto a project',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final task in widget.tasks) _inboxRow(task),
        ],
      ],
    );
  }

  Widget _inboxRow(Task task) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Tooltip(
            message: 'Drag onto a project to file it there',
            child: Icon(
              Icons.drag_indicator,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(stripCodeSpanMarkers(stripEmphasisMarkers(task.text))),
          ),
        ],
      ),
    );

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Text(
            stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: content),
      child: content,
    );
  }
}
