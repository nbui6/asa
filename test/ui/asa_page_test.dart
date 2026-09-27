import 'package:asa/hubs/product/ui/asa_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a project page: back arrow, name large underneath', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AsaPage(
          name: 'Northwind partnership',
          onBack: () {},
          body: const Text('body'),
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('Northwind partnership'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('the root page: no back arrow, name inline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AsaPage(name: 'Asa', body: Text('body')),
      ),
    );
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.text('Asa'), findsOneWidget);
  });

  testWidgets('tapping back calls onBack', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AsaPage(
          name: 'A project',
          onBack: () => backTapped = true,
          body: const Text('body'),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backTapped, isTrue);
  });

  testWidgets('actions render on the header row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AsaPage(
          name: 'A project',
          onBack: () {},
          actions: const [Icon(Icons.refresh)],
          body: const Text('body'),
        ),
      ),
    );
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
