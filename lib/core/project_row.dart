/// Pure derivations one project's row needs — a Jira chip's label, a
/// humanized deadline, and the status pill's colour bucket. Pure Dart, no
/// Flutter import, same rule as everything else in `core/`.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the real Projects view, row
/// layout only." Checked against all 9 real projects. Renamed from
/// `project_bars.dart` 2026-09-09 — "Bars" is a retired term (rule 12);
/// the front page's row layout is now called the Projects view.
///
/// **2026-09-13 — an overdue signal.** `HANDOVER.md`, "an overdue signal
/// for `deadline`". `priority` and `deadline` already rendered; the real
/// gap was that nothing signalled a *passed* deadline. `isPastDeadline`
/// is that one pure check — no new field, no new pill.
library;

import 'package:asa/core/area.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/status_words.dart';
import 'package:asa/core/task.dart';

/// The last `/`-separated segment of a Jira URL — `CRM-557` from
/// `https://verbi.atlassian.net/browse/CRM-557`. Null when there is no
/// Jira URL — a project with no `jira:` value shows no chip, never an
/// empty one.
String? jiraLabel(String? jiraUrl) {
  if (jiraUrl == null || jiraUrl.trim().isEmpty) return null;
  final segments = jiraUrl
      .trim()
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  return segments.isEmpty ? null : segments.last;
}

/// A single `YYYY-MM`, or a period `YYYY-MM/YYYY-MM` (round-38.md §G,
/// ADR 0038/0040) — the "from" group always 1/2, the "to" group (a
/// period only) 3/4.
final RegExp _deadlineShape = RegExp(r'^(\d{4})-(\d{2})(?:/(\d{4})-(\d{2}))?$');

/// `MM.YY` — `2027-09` → `09.27`. Round 38 §G's own corrected display:
/// the earlier "Sep 2027" shape is retired (rule 12).
String _monthYear(String year, String month) => '$month.${year.substring(2)}';

/// `2027-09` → `09.27`; `2026-02/2026-03` → `02.26–03.26` (a period,
/// ADR 0040 — Details edits it as *from* and *to* months). Null when
/// [deadline] is null or blank; the row shows an em dash for that, the
/// same honest-absence convention the flat list already used. A value
/// that does not match either shape, or names a month outside 1-12, is
/// returned verbatim rather than mangled or hidden.
String? humanizeDeadline(String? deadline) {
  if (deadline == null || deadline.trim().isEmpty) return null;
  final trimmed = deadline.trim();

  final match = _deadlineShape.firstMatch(trimmed);
  if (match == null) return trimmed;

  final fromMonth = int.parse(match.group(2)!);
  if (fromMonth < 1 || fromMonth > 12) return trimmed;
  final from = _monthYear(match.group(1)!, match.group(2)!);

  final toYear = match.group(3);
  final toMonthText = match.group(4);
  if (toYear == null || toMonthText == null) return from;

  final toMonth = int.parse(toMonthText);
  if (toMonth < 1 || toMonth > 12) return trimmed;
  final to = _monthYear(toYear, toMonthText);

  return '$from–$to';
}

/// True when [deadline] (a single month or a period) has fully passed
/// relative to [now] — the period's own **end** month must be over, not
/// merely reached; a deadline ending in `now`'s own month is not yet
/// overdue. `now` is a parameter rather than `DateTime.now()` read
/// inside, same reasoning as every other derivation in this file: a test
/// passes a fixed date instead of depending on the clock.
///
/// A `deadline` that is null, blank, or does not match either shape
/// [humanizeDeadline] already parses is never overdue — same
/// honest-absence handling, not a guess at a shape that isn't there.
///
/// Suppressed for `done` and `canceled` (ADR 0041; was `shipped` and
/// `dropped`): a project that finished or was dropped has no deadline
/// left to miss. Every other status — `on-hold` included — still gets
/// the signal; an on-hold project sitting past its own deadline is
/// exactly what this exists to surface, not hide.
bool isPastDeadline(String? deadline, String status, DateTime now) {
  final canonical = canonicalStatus(status).toLowerCase();
  if (canonical == 'done' || canonical == 'canceled') return false;

  if (deadline == null || deadline.trim().isEmpty) return false;
  final match = _deadlineShape.firstMatch(deadline.trim());
  if (match == null) return false;

  // A period's own end month decides it; a single month is its own end.
  final endYearText = match.group(3) ?? match.group(1)!;
  final endMonthText = match.group(4) ?? match.group(2)!;
  final endMonth = int.parse(endMonthText);
  if (endMonth < 1 || endMonth > 12) return false;
  final endYear = int.parse(endYearText);

  return (endYear * 12 + endMonth) < (now.year * 12 + now.month);
}

/// The status pill's colour bucket. Real `status:` values checked across
/// all 9 projects are five words, not the sketch's three: `in progress`,
/// `on hold`, `planning`, `idea`, `building`. Bucketed by substring match
/// so a status word never seen before falls back to [neutral] cleanly
/// rather than throwing or guessing a colour that isn't there.
///
/// **Known gap, not part of the 2026-09-09 resume:** ADR 0017 unified the
/// status enum since this was written — `on hold` is now `paused`
/// (falls into [neutral] anyway, via the fallback, so no visible change)
/// and `ongoing` is a new sixth value with no bucket of its own yet (also
/// falls into [neutral] today; no real project uses it yet either). Left
/// alone here per this round's own scope — verify, rename, show, commit,
/// not re-derive the status rule.
enum StatusEmphasis { active, neutral }

StatusEmphasis statusEmphasis(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('progress') ||
      lower.contains('building') ||
      lower.contains('ongoing')) {
    return StatusEmphasis.active;
  }
  return StatusEmphasis.neutral;
}

/// Round 32/B, ADR 0020 (accepted); extended by Round 34/E: a project's
/// next step comes from its tasks, never the typed field alone. The first
/// open, unparked task in the home note's own `## Tasks`, if there is one;
/// otherwise the first open, unparked task of the first area that has one,
/// in area order; otherwise [typedNextStep], if it is a real value;
/// otherwise null — the caller shows "no next step" for that, honest
/// absence rather than blank. [typedNextStep] stays in the file either
/// way, unwritten and unremoved (ADR 0020's own rule) — this only decides
/// what to show, never what to save. [areas] defaults to none, so every
/// existing caller keeps today's two-step chain until it opts in.
String? effectiveNextStep(
  List<Task> tasks,
  String typedNextStep, {
  List<Area> areas = const [],
}) => effectiveNextStepWithArea(tasks, typedNextStep, areas: areas).text;

/// Same chain as [effectiveNextStep], plus which [Area] (if any) the
/// returned text actually came from — round-36 §2 b's own "Next" line
/// needs this, for the small area chip next to the task text. Null area
/// means the home note's own task, the typed field, or honest absence —
/// never an area, so a caller never has to guess which case it got.
///
/// **`task` — round-36 §3, L3/L9/L10:** the real [Task] the text came
/// from, when it came from a real task at all (home or area) — null for
/// the typed field or honest absence, same as `area`. A caller that needs
/// to highlight the exact row just tapped, or name it in a clipboard
/// opener, needs the task itself, not only its already-stripped text.
({String? text, Area? area, Task? task}) effectiveNextStepWithArea(
  List<Task> tasks,
  String typedNextStep, {
  List<Area> areas = const [],
}) {
  for (final task in tasks) {
    if (!task.done && !task.parked) {
      return (
        text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
        area: null,
        task: task,
      );
    }
  }

  for (final area in areas) {
    for (final task in area.tasks) {
      if (!task.done && !task.parked) {
        return (
          text: stripCodeSpanMarkers(stripEmphasisMarkers(task.text)),
          area: area,
          task: task,
        );
      }
    }
  }

  final typed = typedNextStep.trim();
  if (typed.isEmpty || typed == '(not set)') {
    return (text: null, area: null, task: null);
  }
  return (
    text: stripCodeSpanMarkers(stripEmphasisMarkers(typed)),
    area: null,
    task: null,
  );
}

/// A project forest's roots, split into the flat "work" list and the
/// single "other" root, if a project literally named `other` is present
/// in this scan — see `other.md`'s own framing: *"a group, not a
/// project... it exists so the front page shows work first."* Everything
/// under `other` — however many levels deep — renders as that one
/// collapsible group; every other root is a real, standalone work
/// project.
typedef ProjectBuckets = ({List<ProjectNode> work, ProjectNode? other});

ProjectBuckets splitByBucket(List<ProjectNode> forest) {
  ProjectNode? other;
  final work = <ProjectNode>[];

  for (final root in forest) {
    if (slugOf(root.folder) == 'other') {
      other = root;
    } else {
      work.add(root);
    }
  }

  return (work: work, other: other);
}

/// How many projects sit under [node], not counting [node] itself — the
/// count shown next to the "Other project" group's own name.
int countDescendants(ProjectNode node) {
  var count = node.children.length;
  for (final child in node.children) {
    count += countDescendants(child);
  }
  return count;
}

/// How many of a project's own tasks are parked — `PLAN.md` v0.3, "the
/// rule of two". Shown on the row **only when this is greater than
/// zero** — absent, not a "0 parked" line nobody needs to see, same rule
/// already used for priority, deadline, the Jira chip and the phase bar.
int countParked(List<Task> tasks) => tasks.where((t) => t.parked).length;
