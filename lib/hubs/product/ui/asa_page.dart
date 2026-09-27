/// Round 37 — the one page header every screen uses.
///
/// Two shapes, both in `asa-one-look-v1.html`: a project screen or
/// decision detail (`onBack` set) gets a back arrow, then its name large
/// underneath at 26; the root screen (Overview/Tasks view, `onBack` null
/// — there is nowhere to go back to) gets its name inline at 18, same row
/// as its own actions, matching that sketch's own drawn Tasks-page mock.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class AsaPage extends StatelessWidget {
  const AsaPage({
    required this.name,
    required this.body,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  final String name;
  final Widget body;

  /// Null for the root screen — no back arrow, and the name sits inline
  /// in the top row instead of large underneath it.
  final VoidCallback? onBack;

  /// Start · Tasks · Refresh (or, on the root screen, the Bars/Tasks
  /// toggle and refresh) — right-aligned, same controls every page.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AsaColors.ground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AsaSpace.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: asaContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null) ...[
                  _topRow(
                    leading: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: AsaColors.ink2,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Back',
                    ),
                  ),
                  const SizedBox(height: AsaSpace.sm),
                  Text(name, style: AsaText.pageName),
                  const SizedBox(height: AsaSpace.lg),
                ] else ...[
                  _topRow(
                    leading: Text(name, style: AsaText.header),
                    leadingExpands: true,
                  ),
                  const SizedBox(height: AsaSpace.lg),
                ],
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRow({required Widget leading, bool leadingExpands = false}) {
    return Row(
      children: [
        if (leadingExpands) Expanded(child: leading) else leading,
        if (!leadingExpands) const Spacer(),
        for (final action in actions) ...[
          const SizedBox(width: AsaSpace.xs),
          action,
        ],
      ],
    );
  }
}
