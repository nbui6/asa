// Replaces the widget test that `flutter create` generates, which tests the
// counter app and would fail now that main.dart is Asa.
//
// A smoke test only: it proves the app builds and shows the Product Hub.
// Nothing here touches the file system — reading only happens when Load is
// pressed.

import 'package:flutter_test/flutter_test.dart';

import 'package:asa/main.dart';

void main() {
  testWidgets('the app builds and shows the Product Hub', (tester) async {
    await tester.pumpWidget(const AsaApp());

    expect(find.text('Asa — Product Hub'), findsOneWidget);
    expect(find.text('Load'), findsOneWidget);
  });
}
