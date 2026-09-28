/// A Round's state — ADR 0026: "a round is planned, in progress, waiting
/// for approval, or completed. One checkbox cannot hold that, and today it
/// is lying." Five values, the user's own words, four of them derived from
/// files that already exist; nothing here is typed or maintained.
library;

import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';

enum RoundState {
  planned,
  inProgress,
  waitingForApproval,
  completed,
  noApprovalNeeded,
}

final RegExp _commitHash = RegExp('`[0-9a-f]{7}`');

/// Reused, not reinvented — the identical pattern `plan.dart`'s own Round
/// link already matches, against [Milestone.title] rather than free text.
final RegExp _roundNumber = RegExp(r'Round\s*(\d+)', caseSensitive: false);

/// Derives [milestone]'s state — ADR 0026's own rules, in the order the
/// ADR gives them: the explicit tag overrides everything else, then the
/// checkbox splits "not built yet" from "built."
RoundState roundStateOf(Milestone milestone, RoundApprovals approvals) {
  final body = milestone.body;

  if (body.contains('(no approval needed)')) return RoundState.noApprovalNeeded;

  if (!milestone.done) {
    final looksStarted =
        _commitHash.hasMatch(body) || body.toLowerCase().contains('specced');
    return looksStarted ? RoundState.inProgress : RoundState.planned;
  }

  final number = _roundNumber.firstMatch(milestone.title)?.group(1);
  return approvals.hasApprovalFor(number)
      ? RoundState.completed
      : RoundState.waitingForApproval;
}
