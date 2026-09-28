import 'package:asa/hubs/product/ui/source_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows only the file name, never the full path', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SourceLine(r'C:\Users\test\workspace\projects\asa\northwind.md'),
      ),
    );
    expect(find.text('Read from: northwind.md'), findsOneWidget);
    expect(find.textContaining(r'C:\'), findsNothing);
  });
}
