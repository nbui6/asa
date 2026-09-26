// Round 27 — the Plan tab. Pure widget tests: a Plan is built by hand in
// memory (Round 26 already proves parsing against real files), so these
// only check what this screen does with data it is handed.

import 'package:asa/core/markdown.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/hubs/product/plan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Section _section(String heading, {int level = 2, String body = ''}) {
  return Section(level: level, heading: heading, body: body);
}

Future<void> _pump(WidgetTester tester, Plan plan) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PlanView(
          plan: plan,
          decisions: const [],
          projectSourceFile: 'asa.md',
        ),
      ),
    ),
  );
}

void main() {
  group('the outline — collapsed by default', () {
    testWidgets('a section with children starts collapsed; the child is '
        'not shown until the chevron is tapped', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('Parent section'),
          _section('Child section', level: 3),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('Parent section'), findsOneWidget);
      expect(find.text('Child section'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Child section'), findsOneWidget);
    });

    testWidgets('a leaf section (no children) shows no expand chevron at '
        'all', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [_section('A section with nothing nested under it')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('more than 6 top-level groups shows only 6, with a '
        '"more, collapsed" reveal — persona-check, real screen: row count '
        'alone can overwhelm even when every row is collapsed', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [for (var i = 1; i <= 8; i++) _section('Section $i')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      for (var i = 1; i <= 6; i++) {
        expect(find.text('Section $i'), findsOneWidget);
      }
      expect(find.text('Section 7'), findsNothing);
      expect(find.text('Section 8'), findsNothing);
      expect(find.text('+ 2 more, collapsed ↓'), findsOneWidget);

      await tester.tap(find.text('+ 2 more, collapsed ↓'));
      await tester.pump();

      expect(find.text('Section 7'), findsOneWidget);
      expect(find.text('Section 8'), findsOneWidget);
    });

    testWidgets('an aspect page gets its own top-level group, collapsed, '
        'named by its aspect', (tester) async {
      const front = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [],
        links: [],
      );
      final budget = PlanPage(
        aspect: 'budget',
        sourceFile: 'plan/budget.md',
        sections: [_section('Q4 spend')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [front, budget]));

      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Q4 spend'), findsNothing); // collapsed by default

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(find.text('Q4 spend'), findsOneWidget);
    });
  });

  group('what changed — the date sort', () {
    testWidgets('newest date first, and among equal dates the one later '
        'in the file wins', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('2026-09-01 — oldest'),
          _section('2026-09-14 — earlier the same day'),
          _section('2026-09-14 — later the same day'),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      final order = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();

      final laterIndex = order.indexOf('later the same day');
      final earlierIndex = order.indexOf('earlier the same day');
      final oldestIndex = order.indexOf('oldest');

      expect(laterIndex, greaterThanOrEqualTo(0));
      expect(laterIndex, lessThan(earlierIndex));
      expect(earlierIndex, lessThan(oldestIndex));
    });

    testWidgets('only the 3 most recent show; the rest sit behind one '
        '"older" line until tapped', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section('2026-09-01 — first'),
          _section('2026-09-02 — second'),
          _section('2026-09-03 — third'),
          _section('2026-09-04 — fourth'),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      // Exact match: the stripped "what changed" text ("fourth"), not the
      // outline's own unstripped heading ("2026-09-04 — fourth") — the
      // outline always shows every heading, so a substring match here
      // would pass regardless of whether "what changed" truncates at all.
      expect(find.text('fourth'), findsOneWidget);
      expect(find.text('third'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
      expect(find.text('older (1) ↓'), findsOneWidget);

      await tester.tap(find.text('older (1) ↓'));
      await tester.pump();

      expect(find.text('first'), findsOneWidget);
    });

    testWidgets('a chip renders for an ADR or a Round link, never for a '
        'wikilink', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [
          _section(
            '2026-09-14 — shipped',
            body:
                'This follows ADR 0007, closes Round 26, and mentions '
                '[[budget]].',
          ),
        ],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('ADR 0007'), findsOneWidget);
      expect(find.text('Round 26'), findsOneWidget);
      expect(find.textContaining('budget'), findsNothing);
    });

    testWidgets('a page with nothing dated shows a plain empty state, not '
        'a crash', (tester) async {
      final page = PlanPage(
        aspect: null,
        sourceFile: 'PLAN.md',
        sections: [_section('No date in this heading at all')],
        links: const [],
      );
      await _pump(tester, Plan(pages: [page]));

      expect(find.text('Nothing dated yet.'), findsOneWidget);
    });

    testWidgets(
      'Round 35/C — an entry with many links caps its chips at 3 and shows '
      '"+N", never squeezing its own sentence to nothing',
      (tester) async {
        final page = PlanPage(
          aspect: null,
          sourceFile: 'PLAN.md',
          sections: [
            _section(
              '2026-09-07 — the goal narrowed: one working overview of all '
              '13 projects, kept current by Claude',
              body:
                  'Round 2 Round 6 Round 3 Round 28 Round 14 Round 10 '
                  'Round 31 Round 32',
            ),
          ],
          links: const [],
        );
        await _pump(tester, Plan(pages: [page]));

        expect(tester.takeException(), isNull);
        // The sentence itself must still be one real, un-mangled Text —
        // not sliced into single characters by a starved Expanded.
        expect(
          find.text(
            'the goal narrowed: one working overview of all 13 projects, '
            'kept current by Claude',
          ),
          findsOneWidget,
        );
        expect(find.text('Round 2'), findsOneWidget);
        expect(find.text('Round 6'), findsOneWidget);
        expect(find.text('Round 3'), findsOneWidget);
        expect(find.text('Round 28'), findsNothing);
        expect(find.text('+5'), findsOneWidget);
      },
    );
  });
}
