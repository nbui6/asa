/// Round 37 — a small grey capitalised label (GOAL, NEEDS A LOOK). The
/// only place `.toUpperCase()` happens; a page passes normal-case text.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AsaText.sectionLabel);
  }
}
