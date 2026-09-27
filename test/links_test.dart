// Round 36 cp4 — round-36.md §3's own link table, one test per row (18)
// plus the "one source for every count" test (19). Real disk, real
// ProjectsScreen, an invented fixture outside `projects\` (Gate 2).
//
// L14 ("open the page ↗" opens the area's own .md file in the OS default
// app) is never actually tapped here: `open_url.dart` shells out to
// `cmd /c start`, a real, unmocked `Process.run` with no injectable seam
// — the same untested-by-design shape every other `Process.run` call in
// this app already has (`start_menu.dart`'s "Open folder"/"Open code"
// included). Found the hard way: a real tap here really does launch a
// real subprocess regardless of `runAsync`, which on this machine hung
// the whole test run waiting on a real "how do you want to open this"
// prompt nothing here can answer. What this file verifies instead: the
// affordance exists and really is wired to a non-null `onTap`.

import 'dart:io';

import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/projects_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String settingsPath;
  late String root;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-links-test-');
    root = tempDir.path;
    settingsPath = '${tempDir.path}${Platform.pathSeparator}settings.json';
    _buildFixture(root);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<void> pumpAndLoad(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProjectsScreen(settingsPath: settingsPath)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), root);
    await tester.runAsync(() async {
      await tester.tap(find.text('Use this folder'));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  /// Every tap here goes through this, not a plain `tap` + `pumpAndSettle`
  /// — several of them (opening a project, ticking a task, refreshing)
  /// trigger a real `dart:io` read or write, and `pumpAndSettle` alone
  /// does not wait for one of those to finish, same lesson every other
  /// real-disk test in this repo already encodes
  /// (`project_screen_edit_test.dart`, `plan_area_ticking_test.dart`,
  /// `decision_detail_screen_test.dart`).
  ///
  /// **The `tester.pump()` right after the tap, still inside `runAsync`,
  /// is load-bearing, not filler.** Found while building this file: a tap
  /// that only flips state on the *same*, already-mounted widget (that
  /// existing precedent) starts its real I/O immediately, inside the tap
  /// call itself. A tap that pushes a new route (every navigation here)
  /// does not — `initState` on the new screen only runs once a frame is
  /// actually built, and `runAsync`'s own real-time window has to be open
  /// *while that happens*, or the read never gets real wall-clock time to
  /// finish before this helper moves on.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    // The default 800×600 test surface is shorter than a real Plan tab or
    // Tasks view — a target below the fold otherwise fails a real hit
    // test (found in the widget tree, but off-screen) rather than
    // throwing a clear "not found".
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(finder);
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // A second pump, still inside runAsync — some taps here open a
      // `PopupMenuButton` (its own pushed route) rather than a full
      // screen; one settled pump is not always enough for both that
      // route's own animation and the real I/O it kicks off to land
      // before this helper hands control back to plain `pumpAndSettle`.
      await tester.pump();
    });
    await tester.pumpAndSettle();
  }

  Future<void> flushHighlightTimer(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 2));

  testWidgets(
    "L1 — Overview, a project row, lands on that project's Plan tab",
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.text('Northwind partnership'));

      expect(find.text('Northwind partnership'), findsOneWidget); // header
      // Two: the area row's own heading, and the Next line's own area
      // chip — Sales also holds the project's effective next step.
      expect(find.text('Sales'), findsNWidgets(2));
    },
  );

  testWidgets(
    "L2 — Overview, an area's bar segment or label, Plan tab with that "
    'area already open',
    (tester) async {
      await pumpAndLoad(tester);

      // "Sales 1/2" — the overview's own segment label pairs the area's
      // name with its own fraction (asa-areas-everywhere-v1 §1).
      await tapAndSettle(tester, find.text('Sales 1/2'));

      expect(find.text('Serves Objective 1.'), findsOneWidget); // Sales open
    },
  );

  testWidgets(
    "L3 — Overview, the row's own next step text, opens the area holding "
    'that task',
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.text('Agree the shared account list'));

      expect(find.text('Serves Objective 1.'), findsOneWidget);
      await flushHighlightTimer(tester);
    },
  );

  testWidgets('L3 — a task not in an area opens "Not in an area" instead', (
    tester,
  ) async {
    await pumpAndLoad(tester);

    await tapAndSettle(tester, find.text('Home task'));

    // "Not in an area" is open: its own task list is visible without a
    // further tap.
    expect(find.text('Home task'), findsWidgets);
    await flushHighlightTimer(tester);
  });

  testWidgets(
    "L4 — a child or grandchild row lands on that project's Plan tab",
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.text('Other project')); // expand it
      await tapAndSettle(tester, find.text('Grandchild project'));

      expect(find.text('Grandchild project'), findsOneWidget); // header
    },
  );

  testWidgets(
    "L5 — Tasks view, a project's own group name, lands on its Plan tab",
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.byIcon(Icons.checklist)); // Tasks view
      await tapAndSettle(tester, find.text('Solo project'));

      expect(find.text('Solo project'), findsOneWidget); // header
    },
  );

  testWidgets(
    "L6 — Tasks view, an area's own sub-heading, that area already open",
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.byIcon(Icons.checklist));
      await tapAndSettle(tester, find.text('Sales'));

      expect(find.text('Serves Objective 1.'), findsOneWidget);
    },
  );

  testWidgets('L7 — Tasks view, a resolvable [[project]] chip, lands on that '
      "project's Plan tab", (tester) async {
    await pumpAndLoad(tester);

    await tapAndSettle(tester, find.byIcon(Icons.checklist));
    await tapAndSettle(tester, find.text('↳ northwind'));

    expect(find.text('Northwind partnership'), findsOneWidget);
  });

  testWidgets(
    'L8 — the back arrow returns to where you came from, state kept',
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.byIcon(Icons.checklist)); // Tasks view
      await tapAndSettle(tester, find.text('Solo project'));

      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));

      // Back on the Tasks view, not the Overview — the group name is
      // still visible, and so is the Tasks-view-only "Code tasks" filter.
      expect(find.text('Solo project'), findsOneWidget);
      expect(find.text('Code tasks'), findsOneWidget);
    },
  );

  testWidgets(
    "L9 — Plan tab, the Next line's own task, opens the area holding it",
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));

      // Collapsed at first — a plain L1-style landing opens nothing.
      expect(find.text('Serves Objective 1.'), findsNothing);

      await tapAndSettle(
        tester,
        find.text('Agree the shared account list').first,
      );

      expect(find.text('Serves Objective 1.'), findsOneWidget);
      await flushHighlightTimer(tester);
    },
  );

  testWidgets('L10 — Plan tab, Start → Copy opener names the project, the next '
      'task and its own area page', (tester) async {
    // This machine's own test environment has no working default mock for
    // the clipboard platform channel — a real `Clipboard.setData`/
    // `getData` call here hangs forever rather than resolving (found the
    // hard way: confirmed with a bare, app-free repro before touching
    // this test at all). A caller-installed mock handler, capturing the
    // exact argument `StartMenu` passes, sidesteps that entirely.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await pumpAndLoad(tester);
    await tapAndSettle(tester, find.text('Northwind partnership'));

    // .last — the header's own StartMenu (no next-task data) renders
    // first; the Next line's own StartMenu, the one this test is about,
    // renders second.
    await tapAndSettle(tester, find.byIcon(Icons.rocket_launch_outlined).last);
    await tapAndSettle(tester, find.text('Copy opener'));

    expect(copied, contains('Northwind partnership'));
    expect(copied, contains('Agree the shared account list'));
    expect(copied, contains('sales.md'));
  });

  testWidgets(
    'L11 — Plan tab, "What this project is for" → Strategy →, lands on '
    'the Strategy tab',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));

      await tapAndSettle(tester, find.text('Strategy →').first);

      expect(find.text('Grow the partner channel'), findsOneWidget);
    },
  );

  testWidgets("L12 — Plan tab, an area's Objective chip, Strategy with that "
      'objective already expanded', (tester) async {
    await pumpAndLoad(tester);
    await tapAndSettle(tester, find.text('Northwind partnership'));
    // .last — the area row's own heading, not the Next line's own chip
    // (Sales also holds the effective next step).
    await tapAndSettle(tester, find.text('Sales').last);

    await tapAndSettle(tester, find.text('Objective 1 →'));

    // The ADR chip only renders once the objective is expanded — proof
    // this landed already open, not merely on the right tab. Round 37
    // §D3 — both show both: the number with the (loaded) title.
    expect(find.text('0009 · Grow via partnership'), findsOneWidget);
  });

  testWidgets(
    "L13 — Plan tab, an area's ADR chip, decision detail; back → Plan, "
    'same area open',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Sales').last);

      // Round 37 §D3 — both show both: the number with the loaded
      // decision's own title, not just "ADR 0003".
      await tapAndSettle(
        tester,
        find.text('0003 · Deals go through the partner portal'),
      );

      expect(find.byType(DecisionDetailScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(find.text('Serves Objective 1.'), findsOneWidget);
    },
  );

  testWidgets(
    "L14 — an area's own \"open the page ↗\" is wired to a real onTap "
    "(never actually tapped — see this file's own header)",
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Sales').last);

      final linkFinder = find.ancestor(
        of: find.text('open the page ↗'),
        matching: find.byType(InkWell),
      );
      expect(linkFinder, findsOneWidget);
      expect(tester.widget<InkWell>(linkFinder).onTap, isNotNull);
    },
  );

  testWidgets(
    "L15 — Strategy tab, an objective's ADR chip, decision detail; back "
    '→ Strategy, same objective open',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Strategy →').first);
      await tapAndSettle(tester, find.byIcon(Icons.chevron_right));

      await tapAndSettle(tester, find.text('0009 · Grow via partnership'));

      expect(find.byType(DecisionDetailScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(DecisionDetailScreen), findsNothing);
      // still expanded
      expect(find.text('0009 · Grow via partnership'), findsOneWidget);
    },
  );

  testWidgets('L16 — Decisions tab, a row, decision detail; back → Decisions', (
    tester,
  ) async {
    await pumpAndLoad(tester);
    await tapAndSettle(tester, find.text('Northwind partnership'));
    await tapAndSettle(tester, find.text('Decisions'));

    await tapAndSettle(
      tester,
      find.text('Deals go through the partner portal'),
    );

    expect(find.byType(DecisionDetailScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(DecisionDetailScreen), findsNothing);
    expect(find.text('Deals go through the partner portal'), findsOneWidget);
  });

  testWidgets(
    "L17 — Decisions tab, a decision's own area chip, Plan tab with that "
    'area already open',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Decisions'));

      await tapAndSettle(
        tester,
        find.text('Deals go through the partner portal'),
      );
      await tapAndSettle(tester, find.text('Sales'));

      expect(find.byType(DecisionDetailScreen), findsNothing);
      expect(find.text('Serves Objective 1.'), findsOneWidget);
    },
  );

  testWidgets(
    'L18 — every tab name switches tabs; the project stays the same',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));

      for (final tab in ['Strategy', 'Decisions', 'Details', 'Plan']) {
        await tapAndSettle(tester, find.text(tab));
        expect(find.text('Northwind partnership'), findsOneWidget);
      }
    },
  );

  testWidgets(
    "one source for every count — a tick anywhere changes the area's own "
    "count, the overview's segment and next step, the Next line, and "
    'the Tasks view, all together',
    (tester) async {
      await pumpAndLoad(tester);

      // Before: the overview's own next-step text names the task.
      expect(find.text('Agree the shared account list'), findsOneWidget);

      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Sales').last);

      // Sales lists "Already done" first, then the one open task — its
      // own checkbox is the second one on the whole screen.
      await tapAndSettle(tester, find.byType(Checkbox).last);

      // The Next line and the area row both now read "all done".
      expect(find.text('No next step'), findsOneWidget);
      expect(find.text('nothing open — all done'), findsWidgets);

      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      // A plain pop does not itself re-scan — the same reload button
      // Nico would press for real, not an app-wide auto-refresh this
      // round never asked for.
      await tapAndSettle(tester, find.byIcon(Icons.refresh));

      // The overview's own next-step text changed too — same source.
      expect(find.text('Agree the shared account list'), findsNothing);
      expect(find.text('no next step'), findsOneWidget);
      // ...and so did its own bar segment's label — Sales now reads 2/2.
      expect(find.text('Sales 1/2'), findsNothing);
      expect(find.text('Sales 2/2'), findsOneWidget);

      // Every group starts expanded in the Tasks view — no further tap
      // needed to see Sales' own sub-group (tapping the group NAME would
      // navigate away, per L5, not expand it in place).
      await tapAndSettle(tester, find.byIcon(Icons.checklist));

      // The Tasks view shows no open Sales task either — "Show
      // completed" is the only way to see it now.
      expect(find.text('Agree the shared account list'), findsNothing);
      expect(find.textContaining('Show completed'), findsWidgets);
    },
  );
}

/// One fixture, real files, invented data only (Gate 2). Shape:
///
/// - `northwind\` — no home tasks, so its next step is Sales's own open
///   task; `plan\sales.md` (Goal names Objective 1 and ADR 0003, one open
///   task) and `plan\finance.md` (nothing open); `CHARTER.md` (one
///   objective, naming ADR 0009); `decisions\0003...md` and
///   `decisions\0009...md`.
/// - `solo\` — no areas, one open home task and one `[[northwind]]`
///   cross-reference, for L3's "not in an area" case and L7.
/// - `other\` → `child\` (parent: other) → `grandchild\` (parent: child)
///   — a real two-level chain, for L4.
void _buildFixture(String root) {
  final sep = Platform.pathSeparator;

  void write(String relativePath, String contents) {
    final file = File('$root$sep$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  write('northwind${sep}northwind.md', '''
---
project: Northwind partnership
status: building
updated: 2026-09-26
---

# Northwind partnership
''');

  write('northwind${sep}CHARTER.md', '''
# Northwind partnership — Strategy

## Origin
Why this project exists.

## Who it's for
Nico.

## Pain points
1. Manual account matching wastes time.

## Objectives
1. **Grow the partner channel** — Would show: more joint deals close.
   Served by ADR 0009.
''');

  write('northwind${sep}plan${sep}sales.md', '''
# Sales

## Goal
Serves Objective 1.

## Plan
Two joint pitches a month.

## Tasks
- [x] Already done
- [ ] Agree the shared account list

## Results
- 2026-09-20 — First joint pitch closed.

## Decisions
ADR 0003 — deals go through the partner portal.
''');

  write('northwind${sep}plan${sep}finance.md', '''
# Finance

## Tasks
- [x] Reconcile Q3
''');

  write('northwind${sep}decisions${sep}0003-partner-portal.md', '''
# ADR 0003 - Deals go through the partner portal

**Date:** 2026-09-01 · **Status:** accepted

## Decision

Every deal is routed through the partner portal.
''');

  write('northwind${sep}decisions${sep}0009-partner-channel.md', '''
# ADR 0009 - Grow via partnership

**Date:** 2026-09-05 · **Status:** accepted

## Decision

We invest in the partner channel.
''');

  write('solo${sep}solo.md', '''
---
project: Solo project
status: building
updated: 2026-09-26
---

# Solo project

## Tasks
- [ ] Home task
- [ ] Depends on Northwind — [[northwind]]
''');

  // A trivial area with no tasks of its own — enough to keep PlanView on
  // its areas-based screen (never the Round 27 fallback, which has no
  // "Not in an area" row at all) without contesting the home task's own
  // claim to being the effective next step.
  write('solo${sep}plan${sep}misc.md', '# Misc\n');

  write('other${sep}other.md', '''
---
project: Other project
status: idea
updated: 2026-09-26
---

# Other project
''');

  write('child${sep}child.md', '''
---
project: Child project
status: building
parent: other
updated: 2026-09-26
---

# Child project

## Tasks
- [ ] Child task
''');

  write('grandchild${sep}grandchild.md', '''
---
project: Grandchild project
status: building
parent: child
updated: 2026-09-26
---

# Grandchild project

## Tasks
- [ ] Grandchild task
''');
}
