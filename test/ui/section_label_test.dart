import 'package:asa/hubs/product/ui/section_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders normal-case text as capitals', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SectionLabel('Goal')));
    expect(find.text('GOAL'), findsOneWidget);
    expect(find.text('Goal'), findsNothing);
  });
}
