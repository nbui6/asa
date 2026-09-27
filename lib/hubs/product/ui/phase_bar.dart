/// The segmented progress bar — `asa-front2.html`'s own layout, one
/// segment per phase.
///
/// Spec: `HANDOVER.md`, 2026-09-13, "the segmented progress bar itself".
/// `PLAN.md`'s 2026-09-13 section, closing v0.2's "Open A": a segment is a
/// **phase** — a `###` heading inside a project's `## Roadmap` — never a
/// Round and never a milestone. Built on top of `roadmap.dart`'s `Phase`
/// and `groupPhases`, shipped the round before this one.
///
/// **No phases, no bar — absent, not empty**, same rule already used for
/// priority, deadline and the Jira chip. The caller (`ProjectsView`) only
/// builds this widget when `groupPhases(project.roadmap)` is non-empty;
/// every real project's roadmap today has zero phases, so this widget
/// does not render anywhere yet — it is proven only against invented
/// data, per Gate 2.
///
/// Each segment fills left to right by `doneCount / totalCount` — an
/// exact fraction derived from real checkbox counts, not a typed or
/// guessed percentage (ADR 0014's own reasoning, one level up). Round 37
/// moved this into `ui/` and onto the shared [ProgressBar] for the visual
/// bar itself — one of the three progress-bar copies ADR 0029 names —
/// the per-phase name labels underneath stay this file's own, the same
/// shape `_AreaBar` in `projects_view.dart` already uses for the same
/// reason (a name plus a fraction is not one of the named parts).
library;

import 'package:asa/core/roadmap.dart';
import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class PhaseBar extends StatelessWidget {
  const PhaseBar({required this.phases, super.key});

  final List<Phase> phases;

  double _fractionOf(Phase phase) =>
      phase.totalCount == 0 ? 0.0 : phase.doneCount / phase.totalCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(segments: [for (final phase in phases) _fractionOf(phase)]),
        const SizedBox(height: AsaSpace.xs),
        Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(child: _label(phases[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _label(Phase phase) {
    return Tooltip(
      message:
          '${phase.name}: ${phase.doneCount} of ${phase.totalCount} '
          'Rounds done',
      child: Text(
        phase.name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AsaText.sectionLabel.copyWith(
          letterSpacing: 0,
          fontWeight: FontWeight.normal,
          color: AsaColors.ink3,
        ),
      ),
    );
  }
}
