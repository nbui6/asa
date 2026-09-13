/// Parses a project note's `## Roadmap` section into milestones, and
/// derives the effective "current milestone" once one exists — ADR 0014,
/// ADR 0015. Pure Dart, no Flutter import.
///
/// The contract below is checked against the two real fixtures that carry
/// a `## Roadmap` today: `asa.md` (7 milestones, one — Round 5 — done,
/// mixed nested task states, milestone titles wrapped in `**...**`) and
/// `partner-trial-process.md` (8 milestones, none done, no nested tasks,
/// no bold markers at all — a milestone line is plain text there).
///
/// **2026-09-13 — phases.** `PLAN.md`'s 2026-09-13 section closes v0.2's
/// "Open A": a segmented progress bar's segment is a **phase**, not a
/// Round and not a milestone — a `###` grouping inside `## Roadmap`,
/// ordinary markdown structure in a file the human already writes, not a
/// new field to maintain. [Phase] and [groupPhases] are the data half of
/// that; no screen reads them yet. **No real project's roadmap has a
/// `###` heading today** — every one, `asa.md`'s own included, is
/// exactly the flat-list shape the fixtures below already cover, and
/// [groupPhases] must keep returning an empty list for it, unchanged.
library;

import 'package:asa/core/markdown.dart';
import 'package:asa/core/task.dart';

/// One top-level `- [ ]` / `- [x]` line under `## Roadmap`.
class Milestone {
  const Milestone({
    required this.title,
    required this.done,
    this.tasks = const [],
    this.phase,
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

  /// The `###` heading text this milestone sits under, inside
  /// `## Roadmap` — null when the roadmap has no such heading at all, or
  /// this milestone comes before the first one. See [Phase].
  final String? phase;
}

final RegExp _topLevelCheckbox = RegExp(r'^-\s*\[([ xX])\]\s*(.*)$');
final RegExp _boldSpan = RegExp(r'\*\*(.+?)\*\*');
final RegExp _phaseHeading = RegExp(r'^###\s*(.+?)\s*$');

/// Reads the `## Roadmap` section as an ordered list of milestones, in
/// file order — never sorted or re-ranked. Returns an empty list, never
/// an error, when there is no `## Roadmap` section — six of nine real
/// projects are exactly that case today (ADR 0014's own survey).
List<Milestone> parseRoadmap(String fileContents) {
  final section = sectionText(fileContents, 'Roadmap');
  if (section == null) return const [];

  final milestones = <Milestone>[];
  List<Task>? currentTasks;
  String? currentPhase;

  for (final line in section.split('\n')) {
    // A `###` heading with no leading whitespace starts a new phase —
    // checked before the milestone checkbox below, since neither pattern
    // can match the same line.
    if (!line.startsWith(' ')) {
      final headingMatch = _phaseHeading.firstMatch(line);
      if (headingMatch != null) {
        currentPhase = headingMatch.group(1)!.trim();
        continue;
      }
    }

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
      milestones.add(
        Milestone(
          title: title,
          done: done,
          tasks: currentTasks,
          phase: currentPhase,
        ),
      );
      continue;
    }

    if (currentTasks == null) continue; // stray line before any milestone
    final task = parseTaskLine(line);
    if (task != null) currentTasks.add(task);
  }

  return milestones;
}

/// A `###` grouping inside a project's `## Roadmap` — several Rounds
/// under one named phase. `PLAN.md`, 2026-09-13: the unit a segmented
/// progress bar's segment actually is.
class Phase {
  const Phase({required this.name, required this.milestones});

  final String name;

  /// This phase's own Rounds, in file order — never all of the roadmap's.
  final List<Milestone> milestones;

  /// How many of this phase's Rounds are checked, out of how many —
  /// counted from real checkbox state, never typed. "3 of 7", not a
  /// percentage: three items means every tick jumps a third, and the
  /// last is never the same size as the first — same reasoning ADR 0014
  /// already gives for the bar this feeds.
  int get doneCount => milestones.where((m) => m.done).length;

  int get totalCount => milestones.length;
}

/// Groups a roadmap's milestones by the `###` heading each sits under —
/// phases in file order, and each phase's own milestones in file order.
/// A milestone with no phase (nothing under it, or it comes before the
/// first heading) is not represented in any [Phase] and is not counted
/// anywhere here — [parseRoadmap]'s own flat list still has it.
///
/// **No `###` heading anywhere in [roadmap] returns an empty list** —
/// absent, not empty, same rule already used for priority, deadline and
/// the Jira chip. Every real project's roadmap today, including `asa.md`'s
/// own sixteen-Round flat list, is exactly this case, and must keep
/// reporting zero phases rather than one invented to hold everything.
List<Phase> groupPhases(List<Milestone> roadmap) {
  final byPhase = <String, List<Milestone>>{};

  for (final milestone in roadmap) {
    final phase = milestone.phase;
    if (phase == null) continue;
    byPhase.putIfAbsent(phase, () => []).add(milestone);
  }

  return [
    for (final entry in byPhase.entries)
      Phase(name: entry.key, milestones: entry.value),
  ];
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
