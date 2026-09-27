/// Round 37 — an empty state, always exactly this: one grey sentence,
/// never an invented icon or illustration.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class EmptyLine extends StatelessWidget {
  const EmptyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AsaColors.ink3,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
