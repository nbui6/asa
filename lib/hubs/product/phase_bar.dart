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
/// guessed percentage (ADR 0014's own reasoning, one level up). Colours
/// come from [ColorScheme] rather than literal shades, so this reads
/// correctly in both a light and dark Windows theme even though nothing
/// else in this app has needed that distinction yet.
library;

import 'package:asa/core/roadmap.dart';
import 'package:flutter/material.dart';

class PhaseBar extends StatelessWidget {
  const PhaseBar({required this.phases, super.key});

  final List<Phase> phases;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(child: _segment(phases[i], colors)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Text(
                  phases[i].name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: colors.outline),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _segment(Phase phase, ColorScheme colors) {
    final fraction = phase.doneCount / phase.totalCount;

    return Tooltip(
      message:
          '${phase.name}: ${phase.doneCount} of ${phase.totalCount} '
          'Rounds done',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              // The track — what an untouched phase looks like on its
              // own: no fill at all, just this.
              Container(color: colors.surfaceContainerHighest),
              // The fill — a finished phase covers the whole track in
              // this colour; an untouched one (fraction 0) draws none of
              // it, leaving the track showing through instead.
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
