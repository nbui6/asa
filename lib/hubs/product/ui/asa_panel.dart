/// Round 37 — one white panel per list, thin line, 8 px radius, no shadow.
/// Never a panel inside a panel; a nested project or area indents instead
/// (see `AsaGroup`).
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class AsaPanel extends StatelessWidget {
  const AsaPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AsaColors.panel,
        border: Border.all(color: AsaColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
