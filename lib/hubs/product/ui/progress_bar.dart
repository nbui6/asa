/// Round 37 — one progress bar style, always green, used for a single
/// area's own done/total, the overview's per-area segments, and
/// Strategy's phases. One segment per fraction given; equal widths,
/// a 2 px gap between them.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.segments, this.height = 6, super.key});

  /// One entry per segment, each 0..1 done. A single-area bar passes one
  /// entry; the overview and Strategy pass one per area/phase.
  final List<double> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(child: _segment(segments[i])),
        ],
      ],
    );
  }

  Widget _segment(double fraction) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const ColoredBox(color: AsaColors.soft),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0, 1),
              child: const ColoredBox(color: AsaColors.green),
            ),
          ],
        ),
      ),
    );
  }
}
