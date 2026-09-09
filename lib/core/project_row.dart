/// Pure derivations one project's row needs — a Jira chip's label, a
/// humanized deadline, and the status pill's colour bucket. Pure Dart, no
/// Flutter import, same rule as everything else in `core/`.
///
/// Spec: `HANDOVER.md`, 2026-09-07 entry, "the real Projects view, row
/// layout only." Checked against all 9 real projects. Renamed from
/// `project_bars.dart` 2026-09-09 — "Bars" is a retired term (rule 12);
/// the front page's row layout is now called the Projects view.
library;

import 'package:asa/core/project_tree.dart';

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
  if (lower.contains('progress') || lower.contains('building')) {
    return StatusEmphasis.active;
  }
  return StatusEmphasis.neutral;
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
