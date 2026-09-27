import 'package:asa/hubs/product/ui/link_chip.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows its text in blue', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LinkChip('Objective 1 →')));
    final text = tester.widget<Text>(find.text('Objective 1 →'));
    expect(text.style?.color, AsaColors.blue);
  });

  testWidgets('taps call onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LinkChip('go', onTap: () => tapped = true)),
      ),
    );
    await tester.tap(find.text('go'));
    expect(tapped, isTrue);
  });

  testWidgets('with no onTap, still renders, nothing to tap', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LinkChip('go')));
    expect(find.byType(InkWell), findsNothing);
  });
}
