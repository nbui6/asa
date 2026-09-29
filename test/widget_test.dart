// Smoke test: the app builds and shows the projects list.
//
// The list loads from disk after the first frame, so this only checks the
// shell renders. Reading real folders in a test would break for the wrong
// reasons.

import 'package:asa/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app builds and shows the Product Hub', (tester) async {
    await tester.pumpWidget(const AsaApp());

    // Round 38 §G (ADR 0038, 0040) — the app's own name is now "Project
    // Management"; Asa appears only as a project.
    expect(find.text('Project Management'), findsOneWidget);
    expect(find.text('Projects folder'), findsOneWidget);
  });
}
