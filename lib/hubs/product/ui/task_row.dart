/// Round 37 — one task row everywhere: 26 px, the same checkbox, green
/// tick and grey strikethrough when done, an amber "next" pill, a `</>`
/// code marker, an optional cross-project chip, and the park icon —
/// showing only on hover, same as every other icon-with-a-tooltip this
/// app already uses (the Tasks view's own seventh pass).
library;

import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class TaskRow extends StatefulWidget {
  const TaskRow({
    required this.text,
    required this.done,
    this.onToggle,
    this.isNext = false,
    this.isCodeTask = false,
    this.crossProjectChip,
    this.parked = false,
    this.onPark,
    this.indent = 0,
    this.highlighted = false,
    this.leading,
    this.textChild,
    this.onTapText,
    this.trailing,
    super.key,
  });

  final String text;
  final bool done;
  final ValueChanged<bool?>? onToggle;
  final bool isNext;
  final bool isCodeTask;

  /// Round 42 — an optional widget shown before the checkbox (the Tasks
  /// view's own drag handle, shown on hover). Reserve the width whether or
  /// not it's visible right now — pass an `Opacity`-wrapped icon rather
  /// than swapping the widget itself in and out, so the row doesn't
  /// jitter.
  final Widget? leading;

  /// Round 42 — replaces the built-in `Text` entirely when set (the Tasks
  /// view's own click-to-edit field). The caller owns its own tap
  /// handling in this case; [onTapText] is ignored.
  final Widget? textChild;

  /// Round 42 — wraps the built-in `Text` in an `InkWell` when
  /// [textChild] is null (the Tasks view's own click-to-edit-in-place).
  final VoidCallback? onTapText;

  /// Round 42 — extra content after the cross-project chip and park icon
  /// (the Tasks view's own waiting chip and indent/outdent buttons).
  final Widget? trailing;

  /// Round-36 §3, L3/L9 — briefly true right after this task is the one
  /// just navigated to, so it's visible without hunting the row down.
  /// The caller owns the ~2 s timer; this just draws the highlight while
  /// it's set.
  final bool highlighted;

  /// A `[[project]]` cross-reference, already resolved to a tappable
  /// widget by the caller (round-36's own `_crossProjectChip`) — this
  /// row just makes room for it, never builds it.
  final Widget? crossProjectChip;

  /// Already parked — shows the filled bookmark, amber, always visible
  /// (not just on hover: an already-parked task's own state is something
  /// worth seeing without pointing at it first). An unparked task's own
  /// outline bookmark still only shows on hover, per the sketch.
  final bool parked;

  final VoidCallback? onPark;

  /// Extra left indent — an area's own tasks sit one level in.
  final double indent;

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: widget.highlighted ? AsaColors.highlight : Colors.transparent,
        height: 26,
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: AsaSpace.xs),
            ],
            SizedBox(width: widget.indent),
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: widget.done,
                onChanged: widget.onToggle,
                // Round 37 cp6, §D6 item 4 — a bare Checkbox takes the
                // Theme's own seed colour (purple) with no activeColor of
                // its own; done means green everywhere, never a theme
                // leak.
                activeColor: AsaColors.green,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AsaSpace.sm),
            // Flexible, not Expanded — item 3: the "next" pill should sit
            // right after the text, not pinned to the row's far edge.
            Flexible(child: widget.textChild ?? _defaultText()),
            if (widget.isNext) ...[
              const SizedBox(width: AsaSpace.xs),
              const Pill('next', meaning: AsaMeaning.needsYou, fontSize: 10),
            ],
            if (widget.isCodeTask) ...[
              const SizedBox(width: AsaSpace.xs),
              const _CodeMarker(),
            ],
            if (widget.crossProjectChip != null) ...[
              const SizedBox(width: AsaSpace.xs),
              widget.crossProjectChip!,
            ],
            if (widget.onPark != null) ...[
              const SizedBox(width: AsaSpace.xs),
              Opacity(
                opacity: widget.parked || _hovering ? 1 : 0,
                child: Tooltip(
                  message: widget.parked
                      ? 'Parked — tap to unpark'
                      : 'Park this task',
                  child: InkWell(
                    onTap: widget.onPark,
                    child: Icon(
                      widget.parked ? Icons.bookmark : Icons.bookmark_border,
                      size: 14,
                      color: widget.parked ? AsaColors.amber : AsaColors.ink3,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: AsaSpace.xs),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultText() {
    final text = Text(
      widget.text,
      overflow: TextOverflow.ellipsis,
      style: AsaText.body.copyWith(
        color: widget.done ? AsaColors.ink3 : AsaColors.ink,
        decoration: widget.done ? TextDecoration.lineThrough : null,
      ),
    );
    if (widget.onTapText == null) return text;
    return InkWell(onTap: widget.onTapText, child: text);
  }
}

class _CodeMarker extends StatelessWidget {
  const _CodeMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AsaColors.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '</>',
        style: TextStyle(
          fontSize: 11,
          color: AsaColors.ink3,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
