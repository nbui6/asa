import 'package:asa/hubs/product/ui/empty_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows its own sentence', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EmptyLine('Nothing decided yet.')),
    );
    expect(find.text('Nothing decided yet.'), findsOneWidget);
  });
}
