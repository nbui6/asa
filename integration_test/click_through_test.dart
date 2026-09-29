// Round 36 cp6 — round-36.md §6's own 10-step script, run against a fresh
// temp copy of the committed fixture (test\fixtures\round-36\), never the
// committed copy itself: step 3 reverts its own edit, but step 5 (accepting
// a proposed decision) does not, and the committed fixture has to stay
// pristine for cp5's own screenshots and for a future run of this file.
//
// Two testWidgets, not two process runs: both point at the SAME temp copy
// and the SAME settingsPath, made once in setUpAll, so the second one
// really does start from whatever the first one left on disk — the "does
// reopening break anything" proof round-36.md §6 asks for, not two fresh
// starts that would look identical either way.
//
// Real engine (`flutter test integration_test -d windows`), real async —
// no `runAsync` needed here, the same as `app_test.dart`.
//
// **One honest adaptation, named rather than silently skipped:** §6 step 7
// says Copy Opener should name `plan\<area>.md`. This fixture's Northwind
// also carries a home-note task ("Quarterly check-in with the partner"),
// on purpose, for the "not in an area" case §5 step 1 itself asks for —
// and the project's own overall "next" always prefers an open home task
// over an area task (the same rule the overview uses). That makes the
// project-level Next line name the home task throughout this script, never
// an area task, so its own Start → Copy opener never carries a
// `plan\*.md` path. Asserted as what actually happens, not forced to match
// a script written against a fixture with no home tasks at all.

import 'dart:io';

import 'package:asa/core/write_log.dart';
import 'package:asa/hubs/product/decision_detail_screen.dart';
import 'package:asa/hubs/product/projects_screen.dart';
import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _pristineFixture =
    r'C:\Users\nico.bui\workspace\asa\test\fixtures\round-36';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String root;
  late String settingsPath;
  late File salesFile;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('asa-r36-click-');
    root = tempDir.path;
    _copyDir(Directory(_pristineFixture), Directory(root));
    settingsPath = '${tempDir.path}${Platform.pathSeparator}s.json';
    salesFile = File(
      '$root${Platform.pathSeparator}northwind${Platform.pathSeparator}plan'
      '${Platform.pathSeparator}2-sales.md',
    );
  });

  // No tearDownAll deleting tempDir — app_test.dart's own lesson: a
  // background write can still be in flight when the last test ends, and
  // deleting the folder out from under it throws. The OS reclaims
  // Directory.systemTemp on its own.

  // A real disk write or a real folder scan is a genuine async gap with no
  // animation in between — `pumpAndSettle()` alone has already been found
  // to return before that kind of gap actually closes (this round's own
  // `decision_detail_screen_test.dart` and the real-folder screenshot
  // test both hit this). Polling for the expected result, real engine or
  // not, is the fix that already held up there.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for $finder');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  /// Round 38 §F's own done-tasks fold means a tick's own visible effect
  /// (the count text `waitFor` used to poll for) no longer exists on the
  /// area's own dedicated tab — the fold auto-expands on toggle (its own
  /// local `setState`, immediate) well before the real write actually
  /// lands, so it can't stand in for "the write finished" either. Polling
  /// the file itself sidesteps the widget tree entirely — the one signal
  /// that only changes once the real write actually has.
  Future<void> waitForFileChange(
    WidgetTester tester,
    File file,
    String before, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (file.readAsStringSync() == before) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for ${file.path} to change');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pumpAndLoad(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProjectsScreen(settingsPath: settingsPath)),
    );
    await tester.pumpAndSettle();
    if (find.text('Use this folder').evaluate().isNotEmpty) {
      await tester.enterText(find.byType(TextField), root);
      await tester.tap(find.text('Use this folder'));
    }
    // Round 38 §F, ADR 0036 — Kundenakte (`paused`, canonically on-hold)
    // no longer shows on the main overview at all, so it can't be this
    // helper's own "finished loading" signal any more; Northwind (never
    // hidden) always is. Not `.last` here — `waitFor`'s own polling calls
    // `.evaluate()` before either match exists at all, and `.last` throws
    // on an empty candidate set rather than reporting it empty.
    await waitFor(tester, find.text('Northwind partnership'));
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> assertNoErrorText(WidgetTester tester) async {
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('Error'), findsNothing);
  }

  /// Round-37 §D4 — "Objective N" is now an inline link inside the Goal
  /// sentence's own `Text.rich`, not a separate tappable widget a plain
  /// `tester.tap(find.text(...))` can land on. Invokes the matching
  /// span's own `TapGestureRecognizer` directly instead.
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

    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      searchSpan(richText.text);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('first pass — round-36.md §6, steps 1-10', (tester) async {
    // 1. Start on the overview. Every fixture project, once each, nested
    // right — "other" only toggles expand/collapse, it never opens its
    // own screen (projects_view.dart's own `_otherGroup`), so its children
    // only show once it's tapped open.
    //
    // Round 38 §F, ADR 0036 — real behaviour on real fixture data, not
    // assumed: Kundenakte (`paused`) and Legacy app (`on hold`) both
    // canonicalise to `on-hold` and now leave the main list for the
    // overview's own hidden line instead. Legacy app was "other"'s only
    // child and named the parent legacy-app-docs nests under — with it
    // filtered out before the forest is built, `buildProjectForest`'s own
    // documented rule ("or when that field names a project not present in
    // this scan") promotes legacy-app-docs to a root in its place, so it
    // shows directly now, "other" tap or not.
    await pumpAndLoad(tester);
    expect(find.text('Kundenakte'), findsNothing);
    expect(find.text('Legacy app'), findsNothing);
    // Two, not one — Round 38 §E's own Needs-you card also names the
    // project holding decision 0011 (proposed from the fixture's own
    // start), above the list, real and expected, not a stray duplicate.
    expect(find.text('Northwind partnership'), findsNWidgets(2));
    expect(find.text('Vibe coding kit'), findsOneWidget);
    expect(find.text('Toolkit plugin'), findsOneWidget); // nested, no tap
    expect(find.text('Legacy app docs'), findsOneWidget); // promoted to root

    // The hidden line names both, folded; opened, both are real rows.
    expect(find.textContaining('On hold 2'), findsOneWidget);
    await tap(tester, find.textContaining('show ›'));
    expect(find.text('Kundenakte'), findsOneWidget);
    expect(find.text('Legacy app'), findsOneWidget);

    // 2. Click Northwind partnership → Plan tab, Next line, five area rows.
    // `.last` — the needs-you card's own pill is the other match.
    await tap(tester, find.text('Northwind partnership').last);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('Quarterly check-in with the partner'), findsWidgets);
    // Round 38 §B — each area's name now shows twice on the default
    // "All" view: the area tab strip's own label, and "All"'s own
    // summary row for it.
    for (final area in ['Marketing', 'Sales', 'Enablement', 'Finance']) {
      expect(find.text(area), findsNWidgets(2));
    }
    expect(find.text('Not in an area'), findsOneWidget);

    // 3. Open Sales → tick its next open task → assert Sales' own count,
    // the overview segment and the Tasks view all changed. Assert the
    // file: exactly one line differs, and the write log grew by one entry.
    // Untick → the file is byte-identical to before.
    //
    // Round 38 §F — Sales' own real 5 tasks are 2 done, 3 open; done
    // tasks now fold behind "✓ N done · show ›" by default, so only the
    // 3 open ones show here, not all 5 — "Second demo" (the real fixture
    // file's own third line, the first *open* one) is the first
    // *visible* checkbox now, index 0, not index 2. The "2 / 5"/"3 / 5"
    // counts this step used to read lived on the "All" row's own summary
    // (`_areaSummaryRow`), never on this dedicated area tab — §B replaced
    // "expand in place" with a real tab switch, and that summary line
    // never came with it. `waitForFileChange` replaces the old
    // count-text polling as this step's own "the write actually landed"
    // signal — the fold's own local `setState` (ticking a task
    // auto-reveals its own list, so it never vanishes mid-tap) fires
    // before the real write does, so it can't be that signal either.
    final beforeTick = salesFile.readAsStringSync();
    final logCountBefore = (await readWriteLog()).length;

    // `.first` — Round 38 §B — the area tab strip's own label; the "All"
    // row underneath repeats the same name, either one switches tabs.
    await tap(tester, find.text('Sales').first);
    await waitFor(tester, find.text('GOAL')); // only renders once expanded
    expect(
      find.text(
        'Serves Objective 1 — would show: 3 deals registered by the '
        'partner this quarter.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('✓ 2 done'), findsOneWidget);

    // The checkbox, not the label — only the Checkbox itself has an
    // onChanged; the row's own Text is plain, unclickable.
    await tap(tester, find.byType(Checkbox).at(0));
    await waitForFileChange(tester, salesFile, beforeTick);

    final afterTick = salesFile.readAsStringSync();
    final tickDiff = _diffLines(beforeTick, afterTick);
    expect(tickDiff.length, 1);
    expect(tickDiff.single.$1, contains('[ ] Second demo'));
    expect(tickDiff.single.$2, contains('[x] Second demo'));

    final logAfterTick = await readWriteLog();
    expect(logAfterTick.length, logCountBefore + 1);
    expect(logAfterTick.last.field, 'task-done');

    // Back to the overview, refresh, check the Sales segment there too —
    // a plain pop does not itself re-scan.
    await tap(tester, find.byIcon(Icons.arrow_back));
    await tap(tester, find.byIcon(Icons.refresh));
    await waitFor(tester, find.text('Sales 3/5'));
    expect(find.text('Sales 2/5'), findsNothing);

    // The Tasks view: the ticked task is done now, folded away behind
    // "✓ N done" — Round 42's rebuild opens on Next up by default, so this
    // holds regardless of which project (if any) is selected.
    await tap(tester, find.byIcon(Icons.checklist));
    expect(
      find.text('Second demo for the account from the first pitch'),
      findsNothing,
    );
    await tap(tester, find.byIcon(Icons.view_agenda_outlined)); // back to Bars

    // Untick — the file returns to byte-identical. Re-opening the project
    // fresh (through the overview, just above) starts a brand new PlanView
    // with nothing expanded, so Sales needs one tap here — but *not* a
    // second one after the untick's own reload: that reload no longer
    // collapses it (see project_screen.dart's own "Round 36 cp6" comment
    // on why the whole tab body must stay mounted through a reload).
    //
    // Round 38 §F — Sales is now 3 done, 2 open; "Second demo" is done
    // again and folded away, so it needs the fold opened first, same as
    // the file's own real shape, not the number "2" this step's own name
    // would suggest at a glance.
    await tap(tester, find.text('Northwind partnership').last);
    await tap(tester, find.text('Sales').first);
    await waitFor(tester, find.text('GOAL'));
    await tap(tester, find.textContaining('✓ 3 done'));
    // Expanded, tasks show in the file's own order again — "Second
    // demo" is the third line there, same index §6 always used.
    await tap(tester, find.byType(Checkbox).at(2));
    await waitForFileChange(tester, salesFile, afterTick);
    expect(salesFile.readAsStringSync(), beforeTick);
    expect(find.text('GOAL'), findsOneWidget); // still expanded, not reset

    // 4. Objective chip → Strategy, that objective open. Back → Plan.
    //
    // **One honest adaptation, found rather than assumed:** round-36.md §6
    // step 4 says "Sales still open" here, and after the reload fix above
    // it genuinely does survive a reload — but this is a *tab switch*
    // (Plan → Strategy → Plan), a different mechanism: `_tabBody`'s own
    // `switch (_activeTab)` returns a different widget type per tab, so
    // Flutter cannot preserve PlanView's element across the round trip
    // regardless of the reload fix — the same reason L13's "back, same
    // area open" test relies on a *pushed route* (decision detail, popped
    // back to the same still-mounted screen) rather than a tab switch.
    // Fixing this would mean keeping every tab's body mounted at once
    // (an IndexedStack in place of that switch) — a real, larger change,
    // named here and in this checkpoint's own HANDOVER entry rather than
    // attempted inside cp6 or silently left unmentioned.
    await tapObjectiveLink(tester, 'Objective 1');
    // Round 37 §D3 — both show both: the number with the loaded
    // decision's own title, not just "ADR 0003". Only shows expanded.
    expect(
      find.text('0003 · Deals go through the partner portal'),
      findsOneWidget,
    );
    // Round 38 §B — `_selectedAreaTab` is owned by `ProjectScreen`, not
    // `PlanView`; a Strategy round trip doesn't touch it, so this lands
    // back on Sales' own tab, not "All" — a real improvement over the
    // old expand-in-place model's own collapse-on-return, found here
    // rather than assumed still true.
    await tap(tester, find.text('Plan'));
    expect(find.text('Sales'), findsOneWidget); // its own tab, still active
    expect(
      find.text(
        'Serves Objective 1 — would show: 3 deals registered by the '
        'partner this quarter.',
      ),
      findsOneWidget,
    );

    // 5. Log → the proposed decision, on its own Needs-your-yes card →
    // Accept with a reason → assert it moves off that card and the
    // verdict is readable by the parser (the screen itself re-reads the
    // file through it). Round 38 §E (ADR 0034) retired the old flat
    // Decisions tab and its "Needs a look" group in favour of this one
    // card, reached from the tab now named Log.
    await tap(tester, find.text('Log'));
    expect(find.text('NEEDS YOUR YES'), findsOneWidget);
    // `.first` — the card's own title, above the fold; "What happened"'s
    // own timeline names every decision too, proposed ones included, as
    // its own row further down (tapping that one expands it in place,
    // it doesn't push this screen).
    await tap(tester, find.text('Run the webinar before any paid ads').first);
    expect(find.byType(DecisionDetailScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Marketing already has the platform booked — no reason to wait.',
    );
    await tap(tester, find.text('Accept'));
    // `_recordedVerdict` renders "Accepted — ..." in a bare `RichText`,
    // not a `Text` — `find.text`/`textContaining` only match `Text` and
    // `EditableText`, so a plain string finder here always finds zero,
    // accepted or not. A predicate on the real `RichText.text` is the
    // only way to actually read it.
    final acceptedFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Accepted —'),
    );
    await waitFor(tester, acceptedFinder);

    final decisionFile = File(
      '$root${Platform.pathSeparator}northwind${Platform.pathSeparator}'
      'decisions${Platform.pathSeparator}0011-webinar-before-ads.md',
    );
    // appendVerdict never rewrites the original "**Status:** proposed"
    // line — the file's real, decided-or-not state is the presence of a
    // verdict (`decision.verdict != null`), read back from this same
    // appended section, never from that original line.
    final onDisk = decisionFile.readAsStringSync();
    expect(onDisk, contains('**Date:** 2026-09-24 · **Status:** proposed'));
    expect(onDisk, contains('## Your call'));
    expect(onDisk, contains('**Accepted**'));
    expect(onDisk, contains('already has the platform booked'));

    // 6. Decision's own area chip → Plan, that area open.
    await tap(tester, find.text('Marketing'));
    expect(find.byType(DecisionDetailScreen), findsNothing);
    expect(
      find.text(
        'Serves Objective 2 — would show: 20 leads from the joint webinar.',
      ),
      findsOneWidget,
    );

    // Back on Log, the Needs-your-yes card is gone — nothing left
    // waiting. "Decisions in force" now shows this decision settled,
    // alongside the project's other two, one flat list, no empty group
    // header ever shown.
    await tap(tester, find.text('Log'));
    expect(find.text('NEEDS YOUR YES'), findsNothing);
    await tap(tester, find.text('Decisions in force'));
    expect(find.text('Run the webinar before any paid ads'), findsOneWidget);
    expect(find.text('Deals go through the partner portal'), findsOneWidget);
    // Two, not one — ADR 0006 is named back by both Sales' and Finance's
    // own `## Decisions` sections; "Decisions in force" groups a decision
    // under every area that names it (Round 34's own real two-areas
    // case), so it's a real row in both groups, not a duplicate.
    expect(
      find.text('No discount beyond the standard partner margin'),
      findsNWidgets(2),
    );

    // 7. Start → Copy opener → assert the clipboard names the project and
    // the actual resolved next task. See this file's own header for why
    // this fixture's own resolved next is a home task, not an area task.
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
    await tap(tester, find.text('Plan'));
    await tap(tester, find.byIcon(Icons.rocket_launch_outlined).last);
    await tap(tester, find.text('Copy opener'));
    expect(copied, contains('Northwind partnership'));
    expect(copied, contains('Quarterly check-in with the partner'));

    // 8. Back → overview.
    //
    // **A second honest adaptation.** This step's own script step 3, just
    // above, already visited the Tasks view once (to check the ticked
    // task disappears from it) and came back — `projects_screen.dart`
    // only ever builds `ProjectsView` while `_viewMode == projects`, so
    // that round trip unmounts and remounts it, same as the Plan/Strategy
    // tab switch noted above, and "other"'s own expand state (a plain
    // local bool, `_otherExpanded`) resets with it. Verified directly:
    // still open right after the pop-and-refresh a few lines up (before
    // that Tasks-view visit), gone right after switching back from Tasks
    // view to Bars. Not a round-36 regression — the same architectural
    // shape as the Plan/Strategy finding, on the overview instead of a
    // project screen, and out of scope for the same reason.
    await tap(tester, find.byIcon(Icons.arrow_back));
    // Round 38 §F — still absent, now because it's on-hold and hidden
    // globally, not because "other" reset to collapsed (it has nothing
    // left to reveal either way — legacy-app was its only child).
    expect(find.text('Legacy app'), findsNothing);

    // Tasks view → select the project in the rail (Round 42 — one project
    // at a time, not the old flat everything-at-once list) → an area
    // sub-heading → Plan, that area open.
    // Round 37 §D1 — the sub-heading is normal case now, not all-caps.
    await tap(tester, find.byIcon(Icons.checklist));
    await tap(tester, find.text('Northwind partnership'));
    await tap(tester, find.text('Enablement'));
    expect(
      find.text(
        "Serves Objective 2 — would show: the partner's two consultants "
        'can demo on their own.',
      ),
      findsOneWidget,
    );

    // 9. The project without areas → Plan opens and shows its tasks;
    // Strategy, Log, Details open with no error text.
    await tap(tester, find.byIcon(Icons.arrow_back)); // Northwind → overview
    await tap(tester, find.byIcon(Icons.view_agenda_outlined)); // Tasks → Bars
    // Round 38 §F — Kundenakte is on-hold now; the hidden line is the
    // only way to it.
    await tap(tester, find.textContaining('show ›'));
    await tap(tester, find.text('Kundenakte'));
    // cp8, round-36.md §9 point 1 — Kundenakte has neither `PLAN.md` nor
    // `plan\`, and used to skip the Plan tab entirely, landing on
    // Decisions instead (matching the real "Customer ID System" case
    // confirmed in cp5 at the time). Fixed the same checkpoint: Plan now
    // always shows and is always the tab a project opens on, with a real,
    // honest body for a project with no plan pages — its own home tasks
    // under "Not in an area", open by default since it's the only row.
    _expectPlanIsActiveTab(tester);
    expect(
      find.text('Decide whether this restarts this quarter'),
      findsWidgets,
    );
    expect(find.textContaining('No areas yet'), findsOneWidget);
    for (final tabName in ['Details', 'Log']) {
      await tap(tester, find.text(tabName));
      await assertNoErrorText(tester);
    }

    // A count test, round-36.md §9's own ask: every fixture project opens
    // on Plan, not just Kundenakte.
    await tap(tester, find.byIcon(Icons.arrow_back));
    for (final projectName in [
      'Northwind partnership',
      'Vibe coding kit',
      'Toolkit plugin',
      'Legacy app docs', // Round 38 §F — promoted to a root, see step 1
    ]) {
      // `.last` — Northwind's own needs-you pill is otherwise a second,
      // inert match (Round 38 §E).
      await tap(tester, find.text(projectName).last);
      _expectPlanIsActiveTab(tester);
      await tap(tester, find.byIcon(Icons.arrow_back));
    }
    // Round 38 §F — Legacy app is on-hold; the hidden line reaches it,
    // "other" no longer does (nothing left under it, see step 1).
    if (find.textContaining('show ›').evaluate().isNotEmpty) {
      await tap(tester, find.textContaining('show ›'));
    }
    await tap(tester, find.text('Legacy app'));
    _expectPlanIsActiveTab(tester);
    await tap(tester, find.byIcon(Icons.arrow_back));

    // 10. Every tab of every fixture project opens once, no exception and
    // no red error text. Not every project has all four — Strategy needs
    // a CHARTER.md, Plan/Log/Details always exist now. Tapping only the
    // tabs actually on screen is the point of this step, not an
    // assumption to work around. Legacy app is on-hold (§F) — the hidden
    // line, re-expanded defensively, is what reaches it, not a plain tap.
    for (final projectName in [
      'Northwind partnership',
      'Vibe coding kit',
      'Toolkit plugin',
      'Legacy app docs',
    ]) {
      await tap(tester, find.text(projectName).last);
      for (final tabName in ['Plan', 'Strategy', 'Log', 'Details']) {
        if (find.text(tabName).evaluate().isEmpty) continue;
        await tap(tester, find.text(tabName));
        await assertNoErrorText(tester);
      }
      await tap(tester, find.byIcon(Icons.arrow_back));
    }
    if (find.textContaining('show ›').evaluate().isNotEmpty) {
      await tap(tester, find.textContaining('show ›'));
    }
    await tap(tester, find.text('Legacy app'));
    for (final tabName in ['Plan', 'Strategy', 'Log', 'Details']) {
      if (find.text(tabName).evaluate().isEmpty) continue;
      await tap(tester, find.text(tabName));
      await assertNoErrorText(tester);
    }
    await tap(tester, find.byIcon(Icons.arrow_back));
  });

  testWidgets(
    'second pass — reopening the same, now-mutated fixture breaks nothing',
    (tester) async {
      // The folder is already remembered in settingsPath — no "Use this
      // folder" prompt this time, straight to the overview. Decision 0011
      // is already accepted from the first pass; Sales' own file is back
      // to its original bytes (ticked, then unticked, in the first pass).
      await pumpAndLoad(tester);
      expect(find.text('Use this folder'), findsNothing);
      expect(find.text('Northwind partnership'), findsOneWidget);

      await tap(tester, find.text('Northwind partnership'));
      await tap(tester, find.text('Sales').first);
      await waitFor(tester, find.text('GOAL'));
      // Round 38 §F — sales.md is back to its original 2 done, 3 open;
      // the fold names the count now, not a "2 / 5" line on this tab
      // (see step 3's own comment).
      expect(find.textContaining('✓ 2 done'), findsOneWidget); // untick landed

      await tap(tester, find.text('Log'));
      // Nothing waiting — the accepted decision from pass one stayed
      // accepted; it shows in "Decisions in force" now, not the card.
      expect(find.text('NEEDS YOUR YES'), findsNothing);
      await tap(tester, find.text('Decisions in force'));
      expect(find.text('Run the webinar before any paid ads'), findsOneWidget);
      await tap(tester, find.text('Run the webinar before any paid ads'));
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Accepted —'),
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Every tab of every fixture project opens once, no exception and
      // no red error text — the same step 10, proving reopening doesn't
      // break anything. Round 38 §F — Kundenakte is on-hold; the hidden
      // line reaches it, a plain tap on the overview no longer does.
      await tap(tester, find.byIcon(Icons.arrow_back)); // Northwind → overview
      await tap(tester, find.textContaining('show ›'));
      await tap(tester, find.text('Kundenakte'));
      for (final tabName in ['Plan', 'Strategy', 'Log', 'Details']) {
        if (find.text(tabName).evaluate().isEmpty) continue;
        await tap(tester, find.text(tabName));
        await assertNoErrorText(tester);
      }
      await tap(tester, find.byIcon(Icons.arrow_back));
      for (final projectName in [
        'Northwind partnership',
        'Vibe coding kit',
        'Toolkit plugin',
      ]) {
        await tap(tester, find.text(projectName));
        for (final tabName in ['Plan', 'Strategy', 'Log', 'Details']) {
          if (find.text(tabName).evaluate().isEmpty) continue;
          await tap(tester, find.text(tabName));
          await assertNoErrorText(tester);
        }
        await tap(tester, find.byIcon(Icons.arrow_back));
      }
    },
  );
}

/// Round-36.md §9's own count test: not just that a "Plan" label exists
/// (it's also in the tab row when a *different* tab is active), but that
/// it's rendered as the *active* one — bold, per `project_screen.dart`'s
/// own `_tabLabel`.
void _expectPlanIsActiveTab(WidgetTester tester) {
  final label = tester.widget<Text>(find.text('Plan'));
  // Round 37 §D2 — every tab label keeps the same bold weight whether
  // active or not (so switching tabs never shifts its neighbours);
  // "active" now shows only in colour (AsaColors.ink, not ink3).
  expect(label.style?.color, AsaColors.ink);
}

void _copyDir(Directory src, Directory dst) {
  dst.createSync(recursive: true);
  for (final entity in src.listSync()) {
    final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final newPath = '${dst.path}${Platform.pathSeparator}$name';
    if (entity is Directory) {
      _copyDir(entity, Directory(newPath));
    } else if (entity is File) {
      entity.copySync(newPath);
    }
  }
}

/// Every line present in exactly one of the two texts, oldest-first,
/// paired (before, after) by position — good enough to assert "exactly
/// one line differs" without pulling in a real diff library.
List<(String, String)> _diffLines(String before, String after) {
  final beforeLines = before.split('\n');
  final afterLines = after.split('\n');
  final result = <(String, String)>[];
  for (var i = 0; i < beforeLines.length && i < afterLines.length; i++) {
    if (beforeLines[i] != afterLines[i]) {
      result.add((beforeLines[i], afterLines[i]));
    }
  }
  return result;
}
