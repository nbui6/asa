/// Escape cancels an inline field — Round 42 §B: "Esc or an empty Enter
/// closes it" (the add field) / "Esc cancels" (editing a task's text);
/// Round 43 §A/§C: Esc closes a tick's own Result/Decision line, and the
/// Log's own "＋ Result"/"＋ Decision" form. One shared widget once a
/// second screen needed it, rather than a copy each.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EscapeToCancel extends StatelessWidget {
  const EscapeToCancel({
    required this.onEscape,
    required this.child,
    super.key,
  });
  final VoidCallback onEscape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onEscape();
        }
      },
      child: child,
    );
  }
}
