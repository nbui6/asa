/// Round 37 — one row inside an `AsaPanel`, a thin line between it and
/// the next. The last row in a panel still gets the line; the panel's
/// own border sits right under it, which reads as one edge, not two.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class AsaRow extends StatelessWidget {
  const AsaRow({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AsaSpace.lg,
      vertical: AsaSpace.sm,
    ),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AsaColors.soft)),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
