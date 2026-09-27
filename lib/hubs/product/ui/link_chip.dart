/// Round 37 — anything a person can tap to go somewhere else (an
/// objective, a decision, a Jira key): blue text, never a pill, never a
/// button. `LinkChip('Objective 1 →', onTap: ...)`.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class LinkChip extends StatelessWidget {
  const LinkChip(this.text, {this.onTap, super.key});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      style: const TextStyle(fontSize: 12, color: AsaColors.blue),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
