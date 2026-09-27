import 'package:asa/hubs/product/ui/asa_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AsaRow(child: Text('row'))),
      ),
    );
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('taps call onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsaRow(onTap: () => tapped = true, child: const Text('row')),
        ),
      ),
    );
    await tester.tap(find.text('row'));
    expect(tapped, isTrue);
  });
}
