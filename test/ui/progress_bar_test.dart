import 'package:asa/hubs/product/ui/progress_bar.dart';
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
}
