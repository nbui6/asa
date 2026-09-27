import 'package:asa/hubs/product/ui/area_chip.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the area name in violet', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AreaChip('Sales')));
    final text = tester.widget<Text>(find.text('Sales'));
    expect(text.style?.color, AsaColors.violet);
  });

  testWidgets('taps call onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AreaChip('Sales', onTap: () => tapped = true)),
      ),
    );
    await tester.tap(find.text('Sales'));
    expect(tapped, isTrue);
  });
}
