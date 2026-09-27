import 'package:asa/hubs/product/ui/progress_bar.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draws one segment per fraction given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProgressBar(segments: [0.5, 1, 0])),
    );
    // One Expanded per segment, inside the bar's own Row.
    expect(find.byType(Expanded), findsNWidgets(3));
  });

  testWidgets('a single-area bar takes one segment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProgressBar(segments: [0.4])),
    );
    expect(find.byType(Expanded), findsOneWidget);
  });

  testWidgets('with no meanings given, every segment fills green', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProgressBar(segments: [1, 1])),
    );
    final fill = tester.widgetList<ColoredBox>(find.byType(ColoredBox)).last;
    expect(fill.color, AsaColors.green);
  });

  testWidgets("Strategy's own round state colours a segment by meaning", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProgressBar(
          segments: [1, 1],
          meanings: [AsaMeaning.needsYou, AsaMeaning.moving],
        ),
      ),
    );
    final fills = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    // One ColoredBox per segment is the soft background; the other is
    // its own fill — checking both fills carry their own meaning colour.
    expect(fills.map((c) => c.color), contains(AsaMeaning.needsYou.fg));
    expect(fills.map((c) => c.color), contains(AsaMeaning.moving.fg));
  });
}
