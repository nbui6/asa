/// Round 37 — an area's own identity, wherever it shows up as a small
/// tag rather than a full sub-heading (a decision's own chip, a Plan-tab
/// task's cross-area reference). Always violet — the one colour reserved
/// for "this is an area."
library;

import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class AreaChip extends StatelessWidget {
  const AreaChip(this.name, {this.onTap, super.key});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Pill(name, meaning: AsaMeaning.area);
    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: pill,
    );
  }
}
