/// Round 37 — one progress bar style everywhere: an area's own done/
/// total, the overview's per-area segments, Strategy's per-round state.
/// One segment per fraction given; equal widths, a 2 px gap between
/// them, green by default (done/total) — Strategy's own segment is a
/// whole round in one of four states, not a fraction, so it names its
/// own `meanings` instead: filled, in that round's own meaning colour.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.segments,
    this.meanings,
    this.height = 6,
    super.key,
  });

  /// One entry per segment, each 0..1 done. A single-area bar passes one
  /// entry; the overview passes one per area. A round is either done (1)
  /// or not (0) — never partly.
  final List<double> segments;

  /// One meaning per segment, overriding the default green fill — a
  /// round's own state (completed/waiting/in progress/planned) is a
  /// distinct colour, not a shade of "done", so `asa-strategy-v3`'s own
  /// approved bar stays exactly as approved. Null (every other caller)
  /// fills every segment green.
  final List<AsaMeaning>? meanings;

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: _segment(segments[i], meanings?[i] ?? AsaMeaning.done),
          ),
        ],
      ],
    );
  }

  Widget _segment(double fraction, AsaMeaning meaning) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Positioned.fill — a bare ColoredBox in a Stack gets loose
            // constraints down to zero and paints nothing at all (found
            // against a real screenshot, round-37 cp4: every ProgressBar
            // on screen was an invisible strip). Filling the Stack's own
            // bounds is what actually makes the track and fill visible.
            const Positioned.fill(child: ColoredBox(color: AsaColors.soft)),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0, 1),
                child: ColoredBox(color: meaning.fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
