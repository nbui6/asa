/// Round 43 §D — "✎ on hover of any line the user can write." Reveals a
/// pencil beside its own child only while the pointer is over the row; a
/// `MouseRegion` on a desktop pointer is enough — there is no touch
/// target on this platform to also cover. One shared widget once a third
/// screen (the decision detail screen, after the Plan tab's own two
/// uses) needed it, rather than a copy each.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class HoverPencil extends StatefulWidget {
  const HoverPencil({required this.child, required this.onEdit, super.key});
  final Widget child;
  final VoidCallback onEdit;

  @override
  State<HoverPencil> createState() => _HoverPencilState();
}

class _HoverPencilState extends State<HoverPencil> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: widget.child),
          if (_hovering) ...[
            const SizedBox(width: AsaSpace.xs),
            Tooltip(
              message: 'edit',
              child: InkWell(
                onTap: widget.onEdit,
                child: const Icon(Icons.edit, size: 14, color: AsaColors.ink3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
