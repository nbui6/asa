import 'package:asa/hubs/product/ui/asa_panel.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws a bordered box, no shadow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AsaPanel(child: Text('inside'))),
    );
    expect(find.text('inside'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AsaColors.panel);
    expect(decoration.boxShadow, isNull);
  });
}
