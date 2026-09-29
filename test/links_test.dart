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
import 'package:flutter/gestures.dart';
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

  /// Round-37 §D4 — "Objective N" is now an inline link inside the Goal
  /// sentence's own `Text.rich`, not a separate tappable widget a plain
  /// `tester.tap(find.text(...))` can land on. Invokes the matching
  /// span's own `TapGestureRecognizer` directly instead of simulating a
  /// pixel-precise tap — the standard way to exercise an inline text link
  /// in a widget test.
  Future<void> tapObjectiveLink(WidgetTester tester, String label) async {
    void searchSpan(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text == label && span.recognizer is TapGestureRecognizer) {
          (span.recognizer! as TapGestureRecognizer).onTap!();
          return;
        }
        span.children?.forEach(searchSpan);
      }
    }

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    for (final richText in richTexts) {
      searchSpan(richText.text);
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    "L1 — Overview, a project row, lands on that project's Plan tab",
    (tester) async {
      await pumpAndLoad(tester);

      await tapAndSettle(tester, find.text('Northwind partnership'));

      expect(find.text('Northwind partnership'), findsOneWidget); // header
      // Three: the header's own Next-line area chip, the area tab strip's
      // own label (Round 38 §B), and "All"'s own summary-row heading —
      // Sales also holds the project's effective next step.
      expect(find.text('Sales'), findsNWidgets(3));
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

    // Round-37 §D4 — "Objective 1" is now the inline link inside the
    // Goal sentence itself, not a separate chip.
    await tapObjectiveLink(tester, 'Objective 1');

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

  testWidgets('L16 — Log tab, Decisions in force, decision detail; back → '
      'Decisions in force', (tester) async {
    await pumpAndLoad(tester);
    await tapAndSettle(tester, find.text('Northwind partnership'));
    await tapAndSettle(tester, find.text('Log'));
    // Round 38 §E — the Log opens on "What happened"; a decision's own
    // row only navigates straight to its detail screen in "Decisions in
    // force" (the timeline's own row expands in place instead).
    await tapAndSettle(tester, find.text('Decisions in force'));

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
    "L17 — Log tab, Decisions in force, a decision's own area chip, Plan "
    'tab with that area already open',
    (tester) async {
      await pumpAndLoad(tester);
      await tapAndSettle(tester, find.text('Northwind partnership'));
      await tapAndSettle(tester, find.text('Log'));
      await tapAndSettle(tester, find.text('Decisions in force'));

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

      for (final tab in ['Strategy', 'Log', 'Details', 'Plan']) {
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

      // The Next line already reads "all done".
      expect(find.text('No next step'), findsOneWidget);

      // Round 38 §B — Sales' own tab shows its full page now, not the
      // "All" summary row; switch back to "All" to see that row's own
      // count changed too, the same one source of truth.
      await tapAndSettle(tester, find.text('All'));
      expect(find.text('nothing open — all done'), findsWidgets);

      await tapAndSettle(tester, find.byIcon(Icons.arrow_back));
      // A plain pop does not itself re-scan — the same reload button
      // the user would press for real, not an app-wide auto-refresh this
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

  // round-38.md's own new link rows, L19-L29 — a real round waiting for
  // approval, a dated area result (for the Log's own area chip) and a
  // hidden-status project all needed, none of which the fixture above
  // has (adding a waiting round there once shifted the global Needs-you
  // card into almost every L1-L18 test's own text counts — a separate,
  // purpose-built fixture avoids that ripple entirely).
  group('Round 38 links — L19-L29', () {
    late Directory tempDir2;
    late String settingsPath2;
    late String root2;

    setUp(() {
      tempDir2 = Directory.systemTemp.createTempSync('asa-links-r38-test-');
      root2 = tempDir2.path;
      settingsPath2 = '${tempDir2.path}${Platform.pathSeparator}settings.json';
      _buildRound38Fixture(root2);
    });

    tearDown(() => tempDir2.deleteSync(recursive: true));

    Future<void> pumpAndLoad2(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ProjectsScreen(settingsPath: settingsPath2)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), root2);
      await tester.runAsync(() async {
        await tester.tap(find.text('Use this folder'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
    }

    testWidgets(
      'L19 — Strategy, the "N waiting for your yes →" pill opens the Log',
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);
        await tapAndSettle(tester, find.text('Strategy'));
        await tapAndSettle(tester, find.byIcon(Icons.chevron_right));

        await tapAndSettle(tester, find.text('1 waiting for your yes →'));

        // SectionLabel renders its own text upper-cased.
        expect(find.text('NEEDS YOUR YES'), findsOneWidget);
        expect(
          find.text('Round 1 — Strategy first, areas as tabs'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "L20, L22 — an objective's round row opens its own Your call "
      'screen; back returns to Strategy, same objective open',
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);
        await tapAndSettle(tester, find.text('Strategy'));
        await tapAndSettle(tester, find.byIcon(Icons.chevron_right));

        await tapAndSettle(
          tester,
          find.text('Round 1 — Strategy first, areas as tabs'),
        );

        expect(find.text('waiting for your yes'), findsWidgets);
        expect(find.textContaining('First line.'), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(
          find.text('Round 1 — Strategy first, areas as tabs'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'L21 — an "All" summary row opens that same area\'s own tab',
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);

        // "Marketing" names both the area tab strip's own label and
        // "All"'s own summary row — tapping the row (not the tab) still
        // lands on the same area page.
        await tapAndSettle(tester, find.text('Marketing').last);

        expect(find.text('Serves Objective 1.'), findsOneWidget);
      },
    );

    testWidgets(
      "L23 — the header's own Next line, an area chip, opens that area's "
      'tab',
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);

        // The header's Next line names the area holding the next open
        // task — tapping its own area chip switches straight to it.
        await tapAndSettle(tester, find.text('Marketing').first);

        expect(find.text('Serves Objective 1.'), findsOneWidget);
      },
    );

    testWidgets(
      'L24 — Yes on the Needs-your-yes card settles the round on '
      'Strategy too, adapted from the retired "Yes to selected": the '
      "card now cycles one item at a time (cp3b's own override of §C)",
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);
        await tapAndSettle(tester, find.text('Log'));

        await tapAndSettle(tester, find.text('Yes'));

        expect(find.text('Needs your yes'), findsNothing);

        await tapAndSettle(tester, find.text('Strategy'));
        await tapAndSettle(tester, find.byIcon(Icons.chevron_right));

        expect(find.text('1 of 1 completed'), findsOneWidget);
        expect(find.textContaining('waiting for your yes'), findsNothing);
      },
    );

    testWidgets(
      "L26 — the Needs-your-yes card's own title opens the round's "
      'Your call screen',
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);
        await tapAndSettle(tester, find.text('Log'));

        await tapAndSettle(
          tester,
          find.text('Round 1 — Strategy first, areas as tabs'),
        );

        expect(find.textContaining('First line.'), findsOneWidget);
      },
    );

    testWidgets(
      "L27 — \"What happened\"'s own area chip, on an expanded entry, "
      "opens that area's tab",
      (tester) async {
        await pumpAndLoad2(tester);
        await tapAndSettle(tester, find.text('Round Work').last);
        await tapAndSettle(tester, find.text('Log'));

        await tapAndSettle(tester, find.text('Launch went well.'));
        // Two matches until this tap: the header's own Next-line area
        // chip (visible on every tab) and this entry's own, now expanded.
        await tapAndSettle(tester, find.text('Marketing').last);

        expect(find.text('Serves Objective 1.'), findsOneWidget);
      },
    );

    testWidgets(
      "L28, L29 — the overview's own hidden line opens its groups; a "
      'row there opens that project',
      (tester) async {
        await pumpAndLoad2(tester);

        expect(find.text('Paused Project'), findsNothing);
        await tapAndSettle(tester, find.textContaining('show ›'));

        expect(find.text('Paused Project'), findsOneWidget);

        await tapAndSettle(tester, find.text('Paused Project'));

        expect(find.text('Paused Project'), findsOneWidget); // the header
      },
    );
  });
}

/// L19-L29's own fixture — separate from `_buildFixture` on purpose (see
/// this file's own comment just above the group that uses it). Shape:
///
/// - `roundwork\` — one area, `Marketing` (one open task, so the header's
///   own Next line names it; one dated result, so "What happened" gets a
///   real entry with a real area chip); `CHARTER.md` names Round 1, which
///   `roundwork.md`'s own `## Roadmap` checks off with no matching
///   `rounds\APPROVED.md` row yet — waiting for approval, everywhere that
///   state surfaces (Strategy's own pill and round row, the Log's own
///   Needs-your-yes card).
/// - `paused\` — `status: on-hold`, for L28/L29.
void _buildRound38Fixture(String root) {
  final sep = Platform.pathSeparator;

  void write(String relativePath, String contents) {
    final file = File('$root$sep$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  write('roundwork${sep}roundwork.md', '''
---
project: Round Work
status: building
updated: 2026-09-26
---

# Round Work

## Roadmap
- [x] Round 1 — Strategy first, areas as tabs
''');

  write('roundwork${sep}CHARTER.md', '''
# Round Work — Strategy

## Origin
Why this project exists.

## Who it's for
The user.

## Pain points
1. A pain worth naming.

## Objectives
1. **Ship the thing** — Would show: it ships. Served by Round 1.
''');

  write('roundwork${sep}rounds${sep}round-1.md', '''
# Round 1 — Strategy first, areas as tabs

**Area:** App

## The finish line

1. First line.

## How it's tested

1. Open Asa.
''');

  write('roundwork${sep}plan${sep}marketing.md', '''
# Marketing

## Goal
Serves Objective 1.

## Tasks
- [ ] Promote the launch

## Results
- 2026-09-20 — Launch went well.
''');

  write('paused${sep}paused.md', '''
---
project: Paused Project
status: on-hold
updated: 2026-09-01
---

# Paused Project
''');
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
The user.

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
