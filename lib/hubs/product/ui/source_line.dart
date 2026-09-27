/// Round 37 — "Read from: `<file name>`", the same small line everywhere a
/// screen names its own source file. The file name only, never the full
/// `C:\` path (round-37 §D 7 — a decision detail used to show the whole
/// path).
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class SourceLine extends StatelessWidget {
  const SourceLine(this.sourceFile, {super.key});

  final String sourceFile;

  @override
  Widget build(BuildContext context) {
    final name = sourceFile.split(RegExp(r'[\\/]')).last;
    return Text(
      'Read from: $name',
      style: const TextStyle(fontSize: 12, color: AsaColors.ink3),
    );
  }
}
