/// Parses a project note's `## Roadmap` section into milestones, and
/// derives the effective "current milestone" once one exists — ADR 0014,
/// ADR 0015. Pure Dart, no Flutter import.
///
/// The contract below is checked against the two real fixtures that carry
/// a `## Roadmap` today: `asa.md` (7 milestones, one — Round 5 — done,
/// mixed nested task states, milestone titles wrapped in `**...**`) and
/// `partner-trial-process.md` (8 milestones, none done, no nested tasks,
/// no bold markers at all — a milestone line is plain text there).
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/task.dart';

/// One top-level `- [ ]` / `- [x]` line under `## Roadmap`.
class Milestone {
  const Milestone({
    required this.title,
    required this.done,
    this.tasks = const [],
  });

  /// Just the `**...**`-wrapped span, markers stripped, when the line has
  /// one — real shape on `asa.md`. Bold again at render time; this is
  /// display text with no markup in it, not markdown to be re-parsed. On
  /// a line with no bold span at all — real shape on
  /// `partner-trial-process.md` — this is the whole line, trimmed.
  final String title;

  final bool done;

  /// Lines indented two spaces under this milestone — same checkbox
  /// syntax as `## Tasks`, one level of nesting only. Empty when the
  /// milestone has none of its own, which is the common case today.
  final List<Task> tasks;
}

final RegExp _topLevelCheckbox = RegExp(r'^-\s*\[([ xX])\]\s*(.*)$');
final RegExp _boldSpan = RegExp(r'\*\*(.+?)\*\*');

/// Reads the `## Roadmap` section as an ordered list of milestones, in
/// file order — never sorted or re-ranked. Returns an empty list, never
/// an error, when there is no `## Roadmap` section — six of nine real
/// projects are exactly that case today (ADR 0014's own survey).
List<Milestone> parseRoadmap(String fileContents) {
  final section = sectionText(fileContents, 'Roadmap');
  if (section == null) return const [];

  final milestones = <Milestone>[];
  List<Task>? currentTasks;

  for (final line in section.split('\n')) {
    // A checkbox line with no leading whitespace starts a new milestone.
    // One indented under it is that milestone's own task — checked via
    // parseTaskLine below, not here, so plain wrapped prose (a long
    // milestone description continuing onto the next line, indented the
    // same as a real task but with no checkbox syntax) is correctly
    // skipped rather than mistaken for one.
    final topMatch = line.startsWith(' ')
        ? null
        : _topLevelCheckbox.firstMatch(line);

    if (topMatch != null) {
      final done = topMatch.group(1)!.toLowerCase() == 'x';
      final rest = topMatch.group(2)!.trim();
      final bold = _boldSpan.firstMatch(rest);
      final title = bold != null ? bold.group(1)!.trim() : rest;

      currentTasks = <Task>[];
      milestones.add(Milestone(title: title, done: done, tasks: currentTasks));
      continue;
    }

    if (currentTasks == null) continue; // stray line before any milestone
    final task = parseTaskLine(line);
    if (task != null) currentTasks.add(task);
  }

  return milestones;
}

/// The milestone value to show anywhere the UI displays "the milestone" —
/// ADR 0014 point 3, "one source at a time." Once a project has a real
/// `## Roadmap`, the typed `milestone:` frontmatter value stops being
/// read for display (it stays in the file — nothing here deletes it).
///
/// - Non-empty [roadmap]: the first milestone, in file order, that is not
///   done. If every milestone is done, the last one, with a "— done"
///   suffix, rather than showing nothing.
/// - Empty [roadmap] (no `## Roadmap` section, or an empty one):
///   unchanged — [typedMilestone] (`Project.milestone`), exactly as
///   before this existed. Takes the plain fields rather than a `Project`
///   itself so this file never needs to import `project.dart`.
String effectiveMilestone(List<Milestone> roadmap, String typedMilestone) {
  if (roadmap.isEmpty) return typedMilestone;

  for (final milestone in roadmap) {
    if (!milestone.done) return milestone.title;
  }

  return '${roadmap.last.title} — done';
}
