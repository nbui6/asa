/// Round 38 §E — the overview's own markers: a blue *N new* or amber
/// *changed without a note* on a project row, and the one global *Needs
/// you* card above the list. Derived from the same sources
/// `log_entries.dart`/`log_view.dart` already read for one project's own
/// Log tab — nothing new written, nothing new stored beyond
/// `log_visit.dart`'s existing "since you were last here."
library;

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/log_entries.dart';
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_state.dart';

/// What a project row shows, at a glance — round-38.md §E's own two
/// markers. [newCount] is entries since the last visit, capped at
/// nothing (a real count, however large); zero means no blue marker.
class ProjectNews {
  const ProjectNews({required this.newCount, required this.hasUnloggedChange});

  final int newCount;
  final bool hasUnloggedChange;

  bool get hasAnything => newCount > 0 || hasUnloggedChange;

  static const none = ProjectNews(newCount: 0, hasUnloggedChange: false);
}

/// One real project's own news since [lastVisit] (null — never opened —
/// counts everything as new, same as `LogView`'s own "since you were
/// last here" line — read it with `log_visit.dart`'s `lastLogVisit` and
/// pass the result in here). [historyRoot] is for a test; production
/// never passes it.
Future<ProjectNews> readProjectNews(
  String projectFolder,
  FileAccess files, {
  DateTime? lastVisit,
  String? historyRoot,
}) async {
  final entries = await readLogEntries(
    projectFolder,
    files,
    historyRoot: historyRoot,
  );
  final newCount = lastVisit == null
      ? entries.length
      : entries.where((e) => e.date.isAfter(lastVisit)).length;
  final hasUnlogged = entries.any(
    (e) => e.type == LogEntryType.changedWithoutNote,
  );
  return ProjectNews(newCount: newCount, hasUnloggedChange: hasUnlogged);
}

/// One thing waiting for a yes, anywhere across every project — the
/// global *Needs you* card's own source, "order: oldest waiting first."
/// [projectFolder]/[projectName] let a caller navigate there and open the
/// Log tab on arrival.
class WaitingAcrossProjects {
  const WaitingAcrossProjects({
    required this.projectFolder,
    required this.projectName,
    required this.title,
    required this.date,
  });

  final String projectFolder;
  final String projectName;
  final String title;

  /// When it started waiting — a proposed decision's own date, or a
  /// round's own roadmap entry has none reliably, so a round without a
  /// dated decision sorts after every dated item, oldest of *those*
  /// first by project scan order (stable, never reshuffled from one
  /// refresh to the next for two rounds with no date at all).
  final DateTime? date;
}

/// Every proposed decision and every round waiting for approval, across
/// every project named in [projects] — [projects] is `(folder, name,
/// decisions, roadmap, approvals)` tuples, so this stays a pure function
/// over data the caller already read (the overview's own scan), not a
/// second disk pass of its own.
List<WaitingAcrossProjects> waitingAcrossProjects(
  List<
    ({
      String folder,
      String name,
      List<DecisionReadResult> decisions,
      List<Milestone> roadmap,
      RoundApprovals approvals,
    })
  >
  projects,
) {
  final items = <WaitingAcrossProjects>[];
  for (final p in projects) {
    for (final result in p.decisions) {
      if (!(result.decision?.isProposed ?? false)) continue;
      final date = DateTime.tryParse(result.decision!.date ?? '');
      items.add(
        WaitingAcrossProjects(
          projectFolder: p.folder,
          projectName: p.name,
          title: result.decision!.title,
          date: date,
        ),
      );
    }
    for (final milestone in p.roadmap) {
      if (roundStateOf(milestone, p.approvals) !=
          RoundState.waitingForApproval) {
        continue;
      }
      items.add(
        WaitingAcrossProjects(
          projectFolder: p.folder,
          projectName: p.name,
          title: milestone.title,
          date: null,
        ),
      );
    }
  }

  items.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    return a.date!.compareTo(b.date!);
  });
  return items;
}
