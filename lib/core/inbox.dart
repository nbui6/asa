/// The inbox — free-floating tasks captured with no project chosen. Pure
/// Dart, no Flutter import, same rule as everything else in `core/`.
///
/// Spec: `HANDOVER.md`, 2026-09-13 entry, "Round 8 — quick capture (the
/// inbox)". Decided in `0014-roadmap-tasks-progress.md`'s two 2026-09-08
/// addenda: capture never classifies (one input, always `## Tasks`), and
/// one inbox, not per-project, for a task typed with no project open.
///
/// There is nothing new to parse here — an inbox is just one more file
/// with a `## Tasks` section, and `task.dart`'s [parseTasks] already reads
/// that shape. This file only names where that file is and what an
/// absence of it means.
library;

import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/task.dart';

/// Reads the inbox's tasks — `homePath`'s own `## Tasks` section, exactly
/// as any project's is read. Absent file and absent section both read as
/// an empty inbox, not an error: the very first capture creates the file
/// or the section (`task_writer.dart`'s `captureTask`), so "nothing typed
/// yet" and "nothing there yet" are the same state, not two.
Future<List<Task>> readInbox(String homePath, FileAccess files) async {
  final String contents;
  try {
    contents = await files.readFile(homePath);
  } on Object {
    return const [];
  }
  return parseTasks(contents);
}
