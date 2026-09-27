/// Round 37, ADR 0029 — a status pill, picked by meaning, never by a raw
/// colour. `Pill('accepted', meaning: AsaMeaning.done)`, never
/// `Pill('accepted', color: Colors.green)`.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  const Pill(this.text, {required this.meaning, this.fontSize = 11, super.key});

  final String text;
  final AsaMeaning meaning;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AsaSpace.sm, vertical: 1),
      decoration: BoxDecoration(
        color: meaning.bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: meaning.fg,
        ),
      ),
    );
  }
}
