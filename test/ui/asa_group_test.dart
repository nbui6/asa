import 'package:asa/hubs/product/ui/asa_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the name in normal case, never capitals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsaGroup(
            name: 'Northwind partnership',
            openCount: 7,
            expanded: true,
            onToggleExpand: () {},
          ),
        ),
      ),
    );
    expect(find.text('Northwind partnership'), findsOneWidget);
    expect(find.text('NORTHWIND PARTNERSHIP'), findsNothing);
    expect(find.text('7 open'), findsOneWidget);
  });

  testWidgets('children only show when expanded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsaGroup(
            name: 'Kundenakte',
            openCount: 1,
            expanded: false,
            onToggleExpand: () {},
            children: const [Text('a child task')],
          ),
        ),
      ),
    );
    expect(find.text('a child task'), findsNothing);
  });

  testWidgets('tapping the header calls onToggleExpand', (tester) async {
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsaGroup(
            name: 'Kundenakte',
            openCount: 1,
            expanded: false,
            onToggleExpand: () => toggled = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Kundenakte'));
    expect(toggled, isTrue);
  });

  testWidgets('no mark-all tick when onMarkAllDone is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsaGroup(
            name: 'Kundenakte',
            openCount: 1,
            expanded: false,
            onToggleExpand: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
