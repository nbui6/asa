/// Round 43 §B — "the result knows its task, its area and its file":
/// derived both ways, from what's already parsed, nothing stored twice. A
/// task shows its own result/decision; a result or decision shows its own
/// task. Matched by a task's own display text ([Task.text]), not its raw
/// checkbox line — a tick or a text edit changes the line, not what a
/// result or decision once named.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/task.dart';

/// The result naming [task] via its own `task:` field, if any. The first
/// match in file order (newest first, since [AreaResult.date] already
/// sorts that way) — a task is expected to gain one result per tick, not
/// several competing ones.
AreaResult? resultForTask(Task task, List<AreaResult> results) {
  for (final result in results) {
    if (result.task == task.text) return result;
  }
  return null;
}

/// Every decision naming [task] via its own `Task:` link — the whole
/// list, not just the first: more than one decision can legitimately name
/// the same task (round-43.md §B only ever removes one direction of this
/// ambiguity, the result's).
List<Decision> decisionsForTask(Task task, List<Decision> decisions) {
  return [
    for (final decision in decisions)
      if (decision.links.tasks.contains(task.text)) decision,
  ];
}

/// Whether [result]'s own named task still exists among [tasks] — false
/// both when it names none and when it names one that's gone. The caller
/// uses this to decide between a real chip and "task (gone)": round-43.md
/// §B is explicit that a result naming a vanished task still shows, it
/// just can't link to it any more.
bool resultTaskExists(AreaResult result, List<Task> tasks) {
  final named = result.task;
  if (named == null) return false;
  return tasks.any((t) => t.text == named);
}

/// Same as [resultTaskExists], for one of a decision's own `Task:` links.
bool decisionTaskExists(String taskText, List<Task> tasks) {
  return tasks.any((t) => t.text == taskText);
}
