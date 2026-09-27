/// Round 37, ADR 0029 — a status pill, picked by meaning, never by a raw
/// colour. `Pill('accepted', meaning: AsaMeaning.done)`, never
/// `Pill('accepted', color: Colors.green)`.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    required this.meaning,
    this.fontSize = 11,
    this.maxWidth = 160,
    super.key,
  });

  final String text;
  final AsaMeaning meaning;
  final double fontSize;

  /// A status can be any of ADR 0017's seven words, but one real note had
  /// a whole paragraph as its value. A pill with no width limit would
  /// widen or wrap the row for that; this one clips to a single line with
  /// an ellipsis instead, however long the real value is — shown as
  /// written, never rewritten or hidden.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AsaSpace.sm,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: meaning.bg,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: meaning.fg,
          ),
        ),
      ),
    );
  }
}
