import 'package:asa/hubs/product/ui/task_row.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('is 26 px tall', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskRow(text: 'Open task', done: false)),
      ),
    );
    final size = tester.getSize(find.byType(TaskRow));
    expect(size.height, 26);
  });

  testWidgets('done shows a strikethrough, grey text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskRow(text: 'Done task', done: true)),
      ),
    );
    final text = tester.widget<Text>(find.text('Done task'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a ticked box paints done-green, never the theme colour '
      '(round 37 cp6, §D6 item 4)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskRow(text: 'Done task', done: true)),
      ),
    );
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.activeColor, AsaColors.green);
  });

  testWidgets('a next task shows the amber pill', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TaskRow(text: 'Next task', done: false, isNext: true),
        ),
      ),
    );
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets("the next pill sits within 16 px of the text's own end "
      '(round 37 cp6, §D6 item 3 — Flexible, not Expanded)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TaskRow(text: 'Next task', done: false, isNext: true),
        ),
      ),
    );
    final textRight = tester.getTopRight(find.text('Next task')).dx;
    final pillLeft = tester.getTopLeft(find.text('next')).dx;
    expect(pillLeft - textRight, lessThanOrEqualTo(16));
  });

  testWidgets('a code task shows the </> marker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TaskRow(text: 'Code task', done: false, isCodeTask: true),
        ),
      ),
    );
    expect(find.text('</>'), findsOneWidget);
  });

  testWidgets('a parked task shows the filled bookmark, always visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            text: 'Parked task',
            done: false,
            parked: true,
            onPark: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1); // visible without hovering
  });

  testWidgets('the park icon is invisible until hovered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(text: 'Hover me', done: false, onPark: () {}),
        ),
      ),
    );
    final opacityBefore = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacityBefore.opacity, 0);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(TaskRow)));
    await tester.pumpAndSettle();

    final opacityAfter = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacityAfter.opacity, 1);
  });

  testWidgets('tapping the checkbox calls onToggle', (tester) async {
    bool? toggledTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            text: 'Tap me',
            done: false,
            onToggle: (value) => toggledTo = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Checkbox));
    expect(toggledTo, isTrue);
  });
}
