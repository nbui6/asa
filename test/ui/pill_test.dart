import 'package:asa/hubs/product/ui/pill.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows its text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Pill('accepted', meaning: AsaMeaning.done)),
    );
    expect(find.text('accepted'), findsOneWidget);
  });

  testWidgets('colours come from its meaning, not a literal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Pill('proposed', meaning: AsaMeaning.needsYou)),
    );
    final text = tester.widget<Text>(find.text('proposed'));
    expect(text.style?.color, AsaMeaning.needsYou.fg);
  });
}
