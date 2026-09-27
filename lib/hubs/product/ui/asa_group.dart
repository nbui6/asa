/// Round 37 — one collapsible group header everywhere a project (or a
/// nested child/grandchild project) heads a list of tasks: a triangle,
/// a mark-all-done tick, the name in normal case (never capitals), and
/// "N open". A nested project indents 22 px with a 2 px line on its
/// left — never a panel inside a panel.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class AsaGroup extends StatelessWidget {
  const AsaGroup({
    required this.name,
    required this.openCount,
    required this.expanded,
    required this.onToggleExpand,
    this.onNameTap,
    this.onMarkAllDone,
    this.children = const [],
    this.nested = false,
    super.key,
  });

  final String name;
  final int openCount;
  final bool expanded;

  /// The triangle's own tap — expand/collapse only. The name has its own,
  /// separate tap ([onNameTap]): round-36 §3 L5, opening the project,
  /// is a different action from opening this group in place.
  final VoidCallback onToggleExpand;

  /// Null leaves the name a plain label — a nested area's own heading
  /// (not a project) has nowhere further to open from here.
  final VoidCallback? onNameTap;

  /// Null hides the mark-all tick — a group with nothing to mark done.
  final VoidCallback? onMarkAllDone;
  final List<Widget> children;

  /// True for a child or grandchild project — indented, with its own
  /// left line, never its own panel.
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_header(), if (expanded) ...children],
    );
    if (!nested) return body;
    return Padding(
      padding: const EdgeInsets.only(left: 22, top: 4),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AsaColors.soft, width: 2)),
        ),
        child: Padding(padding: const EdgeInsets.only(left: 12), child: body),
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          InkWell(
            onTap: onToggleExpand,
            child: Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 14,
              color: AsaColors.ink3,
            ),
          ),
          const SizedBox(width: AsaSpace.xs),
          SizedBox(
            width: 16,
            child: onMarkAllDone == null
                ? null
                : InkWell(
                    onTap: onMarkAllDone,
                    child: const Tooltip(
                      message: 'Mark all done',
                      child: Icon(Icons.check, size: 14, color: AsaColors.ink3),
                    ),
                  ),
          ),
          const SizedBox(width: AsaSpace.xs),
          InkWell(
            onTap: onNameTap,
            child: Text(name, style: AsaText.rowName),
          ),
          const SizedBox(width: AsaSpace.sm),
          Text('$openCount open', style: AsaText.meta),
        ],
      ),
    );
  }
}
