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

import 'package:asa/core/markdown.dart';
import 'package:asa/core/project_tree.dart';
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

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `2027-09` → `Sep 2027` — every real `deadline:` value today is a bare
/// `YYYY-MM`, never a range. Null when [deadline] is null or blank; the
/// row shows an em dash for that, the same honest-absence convention the
/// flat list already used. A value that does not match that shape is
/// returned verbatim rather than mangled or hidden.
String? humanizeDeadline(String? deadline) {
  if (deadline == null || deadline.trim().isEmpty) return null;
  final trimmed = deadline.trim();

  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(trimmed);
  if (match == null) return trimmed;

  final monthIndex = int.parse(match.group(2)!);
  if (monthIndex < 1 || monthIndex > 12) return trimmed;

  return '${_months[monthIndex - 1]} ${match.group(1)}';
}

/// True when [deadline] names a `YYYY-MM` that has fully passed relative
/// to [now] — the month itself must be over, not merely reached; a
/// deadline of `now`'s own month is not yet overdue. `now` is a parameter
/// rather than `DateTime.now()` read inside, same reasoning as every
/// other derivation in this file: a test passes a fixed date instead of
/// depending on the clock.
///
/// A `deadline` that is null, blank, or does not match the bare `YYYY-MM`
/// shape [humanizeDeadline] already parses is never overdue — same
/// honest-absence handling, not a guess at a shape that isn't there.
///
/// Suppressed for `shipped` and `dropped`: a project that finished or was
/// dropped has no deadline left to miss. Every other status — `paused`
/// included — still gets the signal; a paused project sitting past its
/// own deadline is exactly what this exists to surface, not hide.
bool isPastDeadline(String? deadline, String status, DateTime now) {
  final lowerStatus = status.toLowerCase();
  if (lowerStatus == 'shipped' || lowerStatus == 'dropped') return false;

  if (deadline == null || deadline.trim().isEmpty) return false;
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(deadline.trim());
  if (match == null) return false;

  final month = int.parse(match.group(2)!);
  if (month < 1 || month > 12) return false;
  final year = int.parse(match.group(1)!);

  return (year * 12 + month) < (now.year * 12 + now.month);
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

/// Round 32/B, ADR 0020 (accepted): a project's next step comes from its
/// tasks, never the typed field alone. The first open task in `## Tasks`
/// that isn't parked, if there is one; otherwise [typedNextStep], if it is
/// a real value; otherwise null — the caller shows "no next step" for
/// that, honest absence rather than blank. [typedNextStep] stays in the
/// file either way, unwritten and unremoved (ADR 0020's own rule) — this
/// only decides what to show, never what to save.
String? effectiveNextStep(List<Task> tasks, String typedNextStep) {
  for (final task in tasks) {
    if (!task.done && !task.parked) {
      return stripCodeSpanMarkers(stripEmphasisMarkers(task.text));
    }
  }

  final typed = typedNextStep.trim();
  if (typed.isEmpty || typed == '(not set)') return null;
  return stripCodeSpanMarkers(stripEmphasisMarkers(typed));
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
