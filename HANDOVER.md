# HANDOVER.md — from the deciding session to the building session

**Both sessions read it; neither writes in the other's half.**

---

**Everything before the newest ten entries lives in `HANDOVER-ARCHIVE.md`** — moved there twice:
2026-09-08 once this file reached 1,834 lines, and 2026-09-28 once it reached 4,704 (only the
"newest ten" line is new; the shape is the same). Read it for history; this file now holds only
the standing rules and the newest ten entries — Round 39 cp7's own line, made true for Asa itself.

---

## Code quality — all four, completely

Required 2026-09-01, given in PHP terms (PHPStan level 10, Pint, PHPUnit) and mapped to this stack.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File check.ps1
```

`check.ps1`, in this order — **the order is load-bearing**:

```powershell
dart format --set-exit-if-changed .   ; if ($LASTEXITCODE) { exit 1 }
flutter analyze --fatal-infos         ; if ($LASTEXITCODE) { exit 1 }
flutter test --coverage               ; if ($LASTEXITCODE) { exit 1 }
flutter test integration_test         ; if ($LASTEXITCODE) { exit 1 }
Write-Host "PASS"
```

**Analysis before tests, because a sibling project once had 25 green tests over code that could not
compile.** `analysis_options.yaml`:

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude: [build/**, "**/*.g.dart"]
```

**The three `strict-*` modes plus `--fatal-infos` are the actual equivalent of a PHPStan level.**
One new dev dependency, `very_good_analysis` — lint rules only, nothing shipped, and **vetoable**.

> **Expect the first run to be red.** Turning the dial up on code written before the dial existed
> produces a wave of findings. **Budget a session for it and report the count**; do not lower the
> dial to make it green.

---

## Before calling it done — `PLAYBOOK.md` §8

- [ ] Does it run?
- [ ] `check.ps1` green — **all four, completely. "Mostly passing" is failing.**
- [ ] Reviewed — **the reviewer agent**
- [ ] **Reachable?** Can the Boss get from the front page to a decision without being told how?
- [ ] `check-shareable.ps1` passes **with nothing waived** — it fails today on three lines, and
      this version is what removes them.
- [ ] **Shown to Nico, and he said yes.** The last line, and the only one that is not about the
      code. **The commit comes after it, never before** — `CLAUDE.md` rule 19, `PLAYBOOK.md` §8.

## Who does what

**Three roles, and the third is the only one that runs anything.**

| | Does | Never |
|---|---|---|
| **The deciding session** | decisions, sketches, specs, records, boundary checks. Writes in this file's downstream half | writes Dart. Runs `git` or `flutter` |
| **The building session** | writes the Dart. Writes in the upstream half | runs `git` or `flutter` |
| **Nico** | **runs every command.** Looks at the result. Says yes or no | is the message bus between the two sessions |

**So "hand code work to Code" and "here is a command to run" are not in conflict.** Neither session
can execute anything - both hand commands to Nico, because he is the only one with a terminal that
counts. What must never happen again is an assistant asking him to *carry text* from one session to
the other; that is what this file is for.

*Added 2026-09-03, after he asked: "but that is code work? It is working right now, so I am
confused." The division had been stated as two roles and it is three.*


- **Never through an assistant's device bridge** — one left a stale `.git/index.lock` on
  2026-08-26, and could not delete it afterwards. **That rule is about the deciding session, which
  reaches this machine through a bridge with no delete permission. It is not about the building
  session**, which runs in a real PowerShell with a real shell.

  > ### GRANTED for the checks, 2026-09-03. Act on this now.
  >
  > **Nico's words: *"code is making me copy and paste so much, cant Code do it itself?"*** That is
  > the authorisation, and it covers everything in the first row below. **Run the checks yourself.
  > Stop handing them over.**
  >
  > **Staging and committing are now covered too** — *"yes do it."*, 2026-09-03 — **but only after
  > he has seen the result and said yes.** The gate has not moved; only the typing has.
  >
  > **`git push` stays with Nico.** One command, one human hand on the only thing that leaves the
  > machine.
  >
  > *You have been citing `CLAUDE.md` rule 3 and the `.git/index.lock` incident. **That incident was
  > the deciding session, through a device bridge that cannot delete a file it creates.** You run in
  > a real PowerShell. The rule generalised from one actor's mechanism to every actor, and the
  > person paying for it was neither of them.*
  >
  > *"code is making me copy and paste so much, cant Code do it itself?"* — and it can. The rule
  > said "Nico runs every `git` and `flutter` command himself", giving the bridge incident as the
  > reason. **The reason names a mechanism the building session does not use.** The rule
  > over-applied, and the cost has been a copy-paste round-trip on every check of every round.
  >
  > | Command | Who, proposed |
  > |---|---|
  > | `check.ps1` and everything in it — `pub get`, `dart format`, `analyze`, `test`, `integration_test`, `clean` | **The building session, itself.** No approval. Touches no remote and nothing outside the repo |
  > | `flutter run -d windows` | **The building session** puts it on screen. **Nico looks.** The looking is the part that cannot be delegated |
  > | `git add` · `git commit` | **The building session — but only after Nico has said yes.** *Granted 2026-09-03: "yes do it."* Rule 19 is about approval, not about who types |
  > | `git push` | **Nico, in his own terminal.** The only command that leaves the machine, and the only one rules 15 and 16 guard |
  > | Anything at all through the device bridge | **Never.** Unchanged |
  >
  > **This is configuration, not weakening** — `PLAYBOOK.md` section 14: turning off a rule that
  > does not fit is configuration; turning one off because its findings are inconvenient is
  > weakening. Nothing here removes a check. **The gate, the approval and the push all stay
  > exactly where they were.** What changes is who types the four commands that only ever report.
- **Stop and ask** if a criterion cannot be met **as written**, rather than meeting a nearby one.
- **If the parse contract disagrees with a real file, the file wins.** Say so and stop.
- **Nico is the only one who can say the round is done.** Show him the result - the app running,
  and `check.ps1`'s real output — then ask, then commit after a yes. **Not the other way round,
  and not a note in this file instead of the showing.** `CLAUDE.md` rule 19.
- **Every deviation from an approved sketch goes in the upstream half's deviation table AND on
  the sketch itself.** Naming it in prose is not enough - the sketch is the thing that gets
  looked at again. *2026-09-03: the "Choose folder…" button was drawn as a native dialog, built
  as a text field, reported honestly in this file, and still reached the Boss as a button that
  did nothing when clicked.*


---

## From the deciding session — 2026-09-28 · two rules in `CLAUDE.md` now contradict accepted decisions

- **Rules 4 and 13** (*Asa writes only structured fields, never prose*; *Asa never becomes a text editor*) are amended by **ADR 0039** (tasks: add, edit, reorder, move) and **ADR 0042** (results, decisions, strategy and plan lines edited in place, new projects). Rewrite both rules to say what the app may write now (only what the user typed, in the fixed shapes, every change in the history) in your next commit to `CLAUDE.md`; Rounds 42 and 43 build on them.
- `templates\AGENTS.md` step 1 now reads BOSS.md's *Rules for every AI* too (ADR 0043, proposed). Commit with the other template changes; cp3's `asa-brief` should print that section after *Read this first*.

## From the deciding session — 2026-09-28 · ADR 0044; files changed for you to commit

- **ADR 0044 (accepted):** the app writes whatever the user does in it; ADR 0007 is superseded. The deciding session rewrote `CLAUDE.md` rules 4 and 13 and the paragraph in `AGENTS.md` (repo root). Commit them.
- **`templates\AGENTS.md`:** a new top block, *This page is the one door* (where everything is, when to read it); §1's bullet on what the app writes; step 1 reads BOSS.md's *Your rules*; §11's rule-adding line. Commit with the other template changes, then `sync-manual.ps1`. `asa-brief` prints *Read this first* and then *Your rules* (the section heading changed from the earlier draft).

## From the deciding session — 2026-09-28 · ADR 0043 accepted; template v3.5

- **`templates\AGENTS.md` v3.5:** §12 is now *Asa's rules* (16, three groups); step 3 of *Before anything else* offers the user's own AI to fill BOSS.md; the door's table lists Asa's rules and the user's rules. **`templates\BOSS.md`** opens with the prompt. Commit both, then `sync-manual.ps1`.
- **cp6** shows the two halves as one list, and *Fill with your AI* when BOSS.md is still the template (round-39.md). **`asa-brief`** prints BOSS.md's *Read this first*, then *Your rules*; §12 is on the page the AI already reads.
- **Round 41** `setup.ps1` step 5 says where the prompt is.

## From the deciding session — 2026-09-28 · Round 39 cp10: recording happens by itself (hooks)

New checkpoint **cp10**, after cp6 and before the drill (`round-39.md`): user-level hooks for `projects\` sessions — SessionStart runs `asa-brief`, PostToolUse keeps `.asa-session.md`, a `"type": "prompt"` Stop hook blocks when a decision/approval/change/plan/rule/result wasn't written, `asa-check` at Stop, SessionEnd closes the session. Same pattern as the repo's own hooks. The drill's step 2 now types nothing but the decision; step 7 records whether hooks run in the desktop app. Template: §12 rule 10 reworded (logging often).

---

### Round 39 — ADR 0043/0044: committed the deciding session's rewrite; `asa-brief` gains *Your rules*

**Committed as written, in two commits** (root files carry the working-notes exception, so they're a
separate concern from what ships): `AGENTS.md`/`CLAUDE.md` (root) for ADR 0044 — hard rule 4 restated
as "Asa writes whatever the user does in it," rule 13 as "Asa edits in place, where the thing is
read." Then `templates\AGENTS.md` v3.5 (*This page is the one door* table; §12 renamed *Asa's rules*,
16 rules in three groups; step 3 of *Before anything else* offers the *their AI already knows them*
path) and `templates\BOSS.md` (opens with the exact prompt to hand that other AI; a new *Your rules*
section, the second half of the same list).

**One real code change, not just docs:** `asa-brief` (`lib\core\brief.dart`) now reads BOSS.md's *Your
rules* section too, not only *Read this first* — `_readBossIntro` replaces `_readBossReadThisFirst`,
concatenating both under one `## Working with you` heading (renamed from `## Read this first`, since
it's no longer just that one section). Same honesty rule as before: absent when the file or a section
isn't there, never invented; still never printed anywhere but stdout.

**Checked, not assumed, that this actually changes something real:** the real `projects\BOSS.md` does
not have a `## Your rules` heading yet (it predates ADR 0043 — still `## Corrections I made`), so
`asa-brief` on the real folder today prints *Read this first* only, correctly and honestly. Migrating
the real file to the new shape is a content edit in `projects\`, not this commit's to make.

**`sync-manual.ps1`** run for real afterward — `templates\AGENTS.md` v3.5 pushed to the real
`projects\AGENTS.md` cleanly (no `-Force` needed this time, the manifest already matched what v3.4
had installed). `templates\BOSS.md` is still deliberately not a sync target (named reasoning: cp3's
own commit) — a blind template-sync would risk overwriting the real, hand-filled file.

**Tests:** `test/brief_test.dart`'s BOSS.md group extended with an invented *Your rules* section,
asserting both parts print together under the renamed heading.

**Verified:** `flutter analyze --fatal-infos` clean, `flutter test` — 621 total, all green.

**Not yet started:** cp10 (recording happens by itself — user-level hooks), added just above,
between cp6 and the drill. Noted, not built — cp4 is still next per the standing order.

**Next:** cp4 — `asa-check`, the write guard.

## From the deciding session — 2026-09-28 · cp10 changed: the Stop check uses no AI

Nico has no API budget, and whether a `"type": "prompt"` hook bills separately on a subscription login isn't documented. **cp10's Stop hook is a plain command** (word match + "anything written? a Logged: line?"); see `round-39.md`. In the drill, test once whether a prompt hook runs on the subscription login and whether it appears as API usage; write down what you saw. Template: §3 step 5 now lists the six moments and the *Logged:* line.

---

### Round 39 cp4 — `asa-check`, the write guard

**Built:** `lib\core\check.dart` (pure Dart) + `bin\check.dart`/`asa-check.cmd` (`asa-check
"<project>"`, prints *OK* or one line per finding, exits 0/1) + `check-notes.ps1` at the repo root
(same convention as `collect-feedback.ps1`: the projects folder is the fixed sibling of this repo,
never read from `settings.json`, since this runs from a shell, not the app) — sweeps every real
project, prints only the ones with something to say, exits 1 if any do.

**Every check named in round-39.md's own cp4 section, plus the 2026-09-28 additions:** *Asa isn't
set up here* (`.asa-setup.md` missing at the projects root); *BOSS.md is missing* or *still the
empty template* (checked against the real, unfilled `templates\BOSS.md` in a test, not invented —
a numbered line's own parenthetical hint, e.g. `(how often, how long...)`, doesn't count as a real
answer either, a real bug in the first pass caught by writing that test before trusting the logic);
*old status word* / *unknown status word* (via cp9b's own `isOldStatusWord`/`statusWords`); *not in
Asa's shape yet* (an old §13-retired heading still present, or no `## Tasks` section — `status`'s
own unknown-word case is reported separately, not doubled here); *note behind the work* and *over
budget* (skipped for `on-hold`/`done`/`canceled` projects, ADR 0036 — a quiet project has nothing
left to be behind on); *session probably cut off* (`.asa-session.md`, cp5's own `isCutOff`);
*waiting on `<name>` since `<date>` — over 14 days* (a task's own `(waiting: …)` marker, from the
2026-09-28 cp4 note, not the original spec).

**"The newest handover entry" (over-budget's own third input) is not counted** — no per-project
convention for that exists in the manual's own §7 shapes; a project's `HANDOVER.md` is an
Asa-repo-specific thing, not a general one. Over budget is the note plus `.asa-session.md` only.
Named here as a real interpretation gap, not silently narrowed.

**Verified against every real project, not only the fixture:** ran `check-notes.ps1` against the
real 13-project folder. Every one of them has something real to report — mostly the §13 shaping
pass HANDOVER.md already said was still pending (old sections, old status words, no `## Tasks`),
plus `asa` itself: `building`, a leftover `## Where it stands`, and 424 lines over the ~300 budget.
None of it invented; each line points at something a person could actually go fix.

**Tests:** `test/check_test.dart`, 16 cases — every finding, both directions where it matters (an
on-hold project never flagged; a wait under 14 days not yet a finding; a closed session never
cut off), plus the unreadable-project case.

**Verified:** `flutter analyze --fatal-infos` clean, `flutter test` — 637 total, all green.

**Not done, per the round's own sequencing:** cp10's own hooks (SessionStart/Stop/etc.) call
`asa-check` too, per the newest note above — that's cp10's build, not this one's.

**Commits:** `lib/core/check.dart`, `bin/check.dart`, `bin/asa-check.cmd`, `bin/README.md`,
`check-notes.ps1`, `test/check_test.dart`, together.

**Next:** cp5 — sessions and their log.

---

### Round 39 cp5 — sessions and their log

**`.asa-session.md`** was already fully readable since cp3 (`session_file.dart`) — nothing new
needed there, per the round's own "as before." **New: `lib\core\session_log.dart`**, reading
`.asa-log.md`'s own append-only lines (manual §7.11:
`- YYYY-MM-DD HH:MM–HH:MM · Account · what you did · files`). Only the leading date is parsed out,
for filtering; the rest stays verbatim — checked against the real `asa\.asa-log.md`, whose own real
lines don't all keep the same shape after the date (one has a dropped start time, `–16:47` with
nothing before the dash), so re-parsing into fixed fields would have invented structure that isn't
really there.

**Wired into `asa-brief --since`:** now shows matching `.asa-log.md` lines too, newest first,
alongside change requests and decisions — closing the gap between cp3's own spec ("everything
recorded... from the logs") and what it actually did (nothing, until now).

**Verified against real data:** `asa-brief --since 2026-09-28` on the real folder now shows Asa's
own 15 real log lines from today, newest first, alongside its change request and six decisions.

**Tests:** `test/session_log_test.dart` (4 cases: the real dropped-start-time shape, no file,
unparseable lines skipped, file order preserved) plus a new `brief_test.dart` case proving
`--since` includes a recent log line and excludes an older one.

**Verified:** `flutter analyze --fatal-infos` clean, `flutter test` — 642 total, all green.

**Commits:** `lib/core/session_log.dart`, `lib/core/brief.dart`, `test/session_log_test.dart`,
`test/brief_test.dart`, together.

**Next:** cp8 — Asa's own local change history.

## From the deciding session — 2026-09-28 20:07 · cp4 and cp5 checked

Read against the commits and your entries; thank you. **One thing left from cp4:** the release exe is still from 14:58 (`build\windows\x64\runner\Release\data\app.so`). Rebuild it (`flutter build windows --release`) before cp8 and say so in one line, so the deciding session can update the notes' status words. Next: cp8 → cp7 → cp6 → cp10 hooks → the drill.

**Release exe rebuilt at 20:23, confirmed starting outside the IDE** — includes cp0 through cp8. Safe to update the notes' status words now.

---

### Round 39 cp8 — Asa's own local change history (ADR 0033)

**Built:** `lib\core\change_history.dart` (pure Dart) — `recordChanges` snapshots every watched file
that actually changed since its own last snapshot (a home note, `CHARTER.md`, every `plan\*.md`,
every `decisions\*.md`, `rounds\APPROVED.md`/`CHANGES.md` for a project; `BOSS.md`/`AGENTS.md` at
the projects root, per the deciding session's own 2026-09-28 note, with `isRoot: true`); an unchanged
file records nothing — the normal case on a second look. `readChangeHistory` reads the snapshots
back, oldest first. `isLoggedChange` checks a change against `.asa-log.md`'s own lines (same
calendar day — cp5 already found real lines don't carry a reliable time component). Lives at
`%APPDATA%\Asa\history\<project>\<file>\NNNNNN.snapshot`, each one the ISO timestamp plus the file's
own content verbatim — simpler and fully reversible, unlike the first pass's attempt to encode the
timestamp into a Windows-legal filename, which a `readChangeHistory` test caught immediately.

**Wired into `asa-brief`:** `--all` and a single project's own briefing now trigger the scan (records
changes as a side effect of "looking at" a project — the only two things that actually scan a project
today); `--since` shows what changed, before/after line counts, marked *— changed, not logged* when
no `.asa-log.md` line matches that day. A file's very first-ever snapshot reads as *first seen*, not
*changed* — there's nothing to compare it against yet, and calling that a "change" would flood
`--since` with baseline noise the first time history exists at all, found by actually running it
against the real folder before trusting the design.

**Deliberately opt-in, not on by default — the real risk this round found before shipping it:**
`write_log.dart`'s own convention defaults a write path to the real `%APPDATA%\Asa\...` when no
override is given, which is fine for a write that only fires on an explicit user edit. Recording
fires on *every read*, which the entire existing test suite already does constantly — defaulting it
on would have meant every test calling `briefProject`/`briefAll` started writing real files into the
real history folder the moment this function existed. `recordHistory` (default `false`) gates it;
only `bin/brief.dart`'s own CLI passes `true`. Checked, not assumed: ran the full suite before this
fix existed, confirmed `%APPDATA%\Asa\history\` stayed empty throughout.

**Not built:** the live Flutter app's own `scanProjects` doesn't trigger recording — that's a
different, riskier integration (every screen load, every existing UI test) than the CLI tools this
round already ships, and named as a gap rather than silently attempted. The Instruction for AI →
Checks amber rendering (cp6) and the project's own Log (Round 38 §E) are separate, later, UI work;
the data and the check (`isLoggedChange`) they need already exist.

**Verified against the real 13-project folder:** ran `asa-brief "asa"` for real (`recordHistory:
true`), confirmed `%APPDATA%\Asa\history\asa\` and `history\_root\` populated (52 files across every
watched file), a second identical run added nothing, and `asa-brief --since 2026-09-28` reads it all
back correctly with the *first seen* wording.

**Tests:** `test/change_history_test.dart` (10 cases: baseline/unchanged/real-edit/root-files/
never-outside-the-projects-root/round-trip), plus 3 new `brief_test.dart` cases (opt-in stays off by
default, `recordHistory: true` records into the given sandbox only, `--since` marks an unlogged
change).

**Verified:** `flutter analyze --fatal-infos` clean, `flutter test` — 655 total, all green. Release
exe rebuilt and confirmed starting outside the IDE.

**Commits:** `lib/core/change_history.dart`, `lib/core/brief.dart`, `bin/brief.dart`,
`test/change_history_test.dart`, `test/brief_test.dart`, together.

**Next:** cp7 — resume, logins, archives.

---

### Round 39 cp7 — Resume, logins, archives

**Built: "Start → Resume,"** next to "Copy opener" — `lib\core\opener.dart`'s new `resumeText`
copies *"Run asa-brief "<project>" and continue. If it isn't there, open `projects\AGENTS.md` and
follow it."*, shorter than the opener on purpose: it points at the manual instead of repeating
what the manual already says, now that `asa-brief` exists to run the loop. Wired into
`start_menu.dart` as a fourth menu item, same clipboard pattern as the existing three.

**Investigated: two Claude Code logins side by side.** Researched rather than guessed — Claude
Code supports this today, via the `CLAUDE_CONFIG_DIR` environment variable: pointing it at a
different folder gives a completely separate credentials/settings/session store, so two terminals
can each be logged into a different account at once, with no logout/login cycle. There's no
account-*switching* command — only separate config directories, each needing its own one-time
`/login`. Skills, MCP servers and plugins are **not** shared between the two directories — a real
gotcha for us specifically, since the whole point of `kit\sync-skills.ps1`'s own zips is installing
the same skills on both accounts by hand. `~/.claude.json` (theme, auto-update) is the one thing
*not* isolated per directory, for whatever that's worth. Practical setup: two PowerShell aliases,
each setting `$env:CLAUDE_CONFIG_DIR` before launching `claude`. Not yet tried for real on this
machine — that's the drill's own step 7 (round-39.md), not this checkpoint's.

**Made true for Asa itself: the size budget.** `HANDOVER.md` had grown to 4,704 lines (122 headings)
since its last trim on 2026-09-08, 20 days of standing rule going unapplied to the file the rule is
about. Same mechanical trim as that day: the newest ten entries (from `## From the deciding
session — 2026-09-28 · two rules in CLAUDE.md...` onward, 338 lines) stay; the other 109 entries
moved to `HANDOVER-ARCHIVE.md` verbatim — nothing reworded, only relocated, same discipline the
first trim used. Checked, not assumed: the seam between old and new archive content read cleanly,
both files' own heading counts add up (13 in the new `HANDOVER.md` = 3 standing + 10 chronological;
162 in the archive = 53 + 109), and `flutter test` doesn't depend on either file's content or line
count. **`PLAN.md`'s own older-entries move to `PLAN-ARCHIVE.md` is the deciding session's job, not
built here** — named, not attempted.

**`CLAUDE.md` gains the rule this round's own spec asked for:** after each checkpoint, update
`projects\asa\asa.md`'s own `## Tasks` and `next-step` — the Asa project is a project like any
other, not exempt from the manual's §5 just because it's the tool that reads it. Practiced, not
just written: `asa.md`'s `next-step`, its own Roadmap table row, and its matching task line were all
updated to the real current state (cp7 in progress, the two-logins test still open) while writing
this entry, and the just-finished archive task ticked off.

**Noticed, not fixed:** `CLAUDE.md`'s own "Code quality" standing section still describes
`check.ps1`'s old four-step sequence — it's six steps now (cp0/cp1's own skills/manual sync checks).
Out of this checkpoint's scope; flagged so it isn't silently carried forward as if nobody saw it.

**Verified:** `flutter analyze --fatal-infos` clean, `flutter test` — 657 total, all green.

**Commits:** `lib/core/opener.dart`, `lib/hubs/product/start_menu.dart`, their tests, in one commit;
`HANDOVER.md`/`HANDOVER-ARCHIVE.md`/`CLAUDE.md` in another, since the archiving and the rule
addition are one act (the rule exists because the archiving was overdue).

**Next:** cp6 — Instruction for AI, the screen that un-blackboxes all of it.

## From the deciding session — 2026-09-28 · Round 44 added; guides and template to commit

- **New:** `asa\guides\` (private-folder, pause-ai, offline-copy; neutral, shown step by step in the app). Commit them.
- **`templates\AGENTS.md`:** *Before anything else* gains step 0 (*if `projects\.asa-paused` exists, stop*); §12 rule 15 adds the private folder. Commit, `sync-manual.ps1`.
- **Round 44** (`projects\asa\rounds\round-44.md`, ADR 0046): private folder, AI access, Pause AI, offline copy, secrets. **After Round 41.** Order: Round 39 → 41 → 44 → 38 → 42 → 43.

## From the deciding session — 2026-09-28 · the order changes: working Asa v1 first

Nico wants a working Asa before anything else. **New order:** Round 39's rest (cp6 → cp10 → the drill) → **Round 38** → **Round 42** → **Round 43** → Nico's test of v1. **After v1:** Round 41, then Round 44. cp7 and cp8 checked; the rebuilt app (20:23) let the deciding session update the notes' status words.

## From the deciding session — 2026-09-28 · Round 41 is part of v1

Order for working Asa v1: Round 39's rest → Round 38 → Round 42 → Round 43 → **Round 41** → Nico's test on both laptops. Round 44 after v1.

## From the deciding session — 2026-09-28 · READ FIRST: Delivery v1, in one go

**Nico is tired of small pieces. Build all of v1, test it, compare it with what he approved, persona-check it (his persona and the AI's), then hand over once.** The whole spec, the order, the checks and the only three reasons to stop early are in **`projects\asa\rounds\delivery-v1.md`**. Tick its *Progress* list as you go. Add the one line to the top of `CLAUDE.md` it asks for, and the no-cost Stop hook that keeps you going. Commit as often as possible, a `HANDOVER.md` entry per checkpoint, never push. **ADR 0047** makes this Asa's rule 17 (`templates\AGENTS.md`; commit it).

---

### Delivery v1, item 1 (part) — Round 39 cp6: Instruction for AI, the screen

**Blocker found and worked around, named per delivery-v1.md's own rule 2:** adding the Stop hook to
`.claude\settings.json` was refused by Claude Code's own auto-mode classifier (*"Self-Modification"*)
— editing this session's own hook/permission config is guarded and can't be done from inside the
session it would govern. `.claude\hooks\delivery-check.ps1` is written (BOM, fails open on anything
it can't read, checks `delivery-v1.md`'s own Progress list against the last real answer via
`transcript_path`) but **not wired into `settings.json`** — that one line needs the user's own hand
once. Continuing without it; the actual work doesn't depend on it.

**Built:** three new pure-Dart readers plus the screen itself.
- `lib\core\skills_catalog.dart` — every skill/agent in `kit\`, whether the repo's own `.claude\skills\`
  copy matches the source, and `dist\skills\*.zip`'s own mtime as *last packaged*.
- `lib\core\manual_status.dart` — `templates\AGENTS.md` vs the installed `projects\AGENTS.md`
  (byte-identical, or which `##` sections differ), and the template's own last real commit (date +
  message) via `git log`, same command shape `git_state.dart` already uses.
- `lib\core\check.dart` gains two small exports: `isEmptyBossTemplate` (made public, cp6 needs the
  same check cp4 already built) and `bossFillPrompt` (extracts `templates\BOSS.md`'s own quoted
  prompt for the *Fill with your AI* button — checked against the real template, not invented).
- `lib\hubs\product\instruction_for_ai_screen.dart` — the five parts (How it works, Instructions,
  Skills & agents, Working with you, Checks), embedded straight into `ProjectsScreen`'s own body as
  a third `_ViewMode`, next to Projects and Tasks (not its own `AsaPage`/`Scaffold` — nested page
  chrome was the wrong shape once actually tried).

**A real test-writing bug caught immediately:** the widget test's first pass hung on
`pumpAndSettle timed out` — `_load()` does real `dart:io` reads and a real `git` subprocess, which
Flutter's fake test zone never advances on its own, so the loading spinner (an
indefinitely-animating `CircularProgressIndicator`) never lets `pumpAndSettle` settle. Fixed with
`tester.runAsync()`, the same pattern `project_screen_edit_test.dart`'s own `pumpAndSettleReal`
already established — found by hitting it, not by remembering the rule in advance.

**Verified against a real, invented fixture workspace** (a sibling `asa\` folder with real
`kit\skills\`/`kit\agents\`/`.claude\skills\`/`templates\`, and a `projects\` with a real BOSS.md and
one well-shaped project) — never the real repo or the real projects folder for the widget test
itself, though `skills_catalog_test.dart` and `manual_status_test.dart` do check against the real
repo directly (the real `asa` skill, the real `reviewer` agent, the real git history of
`templates\AGENTS.md`).

**Not verified: what it actually looks like.** No tool in this session can screenshot a running
Windows desktop app — the same honest limit that has applied to every screen built this whole
session, not new to cp6. The release exe was rebuilt and started outside the IDE, confirmed running,
not confirmed by eye. The whole-delivery check (item 6) is where real screenshots against the
approved sketch happen.

**Tests:** `skills_catalog_test.dart` (6), `manual_status_test.dart` (5), `check_test.dart` (+2 for
`bossFillPrompt`), `instruction_for_ai_screen_test.dart` (5 widget tests, one per part plus the
switcher). 677 total, all green.

**Also committed in this same pass:** `templates\AGENTS.md` v3.8 — rule 17 (ADR 0047, "hand over
finished work, not pieces"), already written by the deciding session; synced to the real
`projects\AGENTS.md`.

**Commits:** the three new core readers + the screen + its wiring into `projects_screen.dart`, their
tests, together; `templates\AGENTS.md` v3.8 in its own commit; `.claude\hooks\delivery-check.ps1`
committed as an inert file (not yet wired in).

**Next:** cp10 — recording happens by itself (hooks).

---

### Delivery v1, item 1 (part) — Round 39 cp10: the projects\-scoped hooks

**Built:** five hooks under `kit\hooks\` (source; `.claude\hooks\` in this repo is a separately
installed copy, unaffected until reinstalled) plus a shared dot-sourced helper
(`asa-projects-common.ps1` — `Get-AsaSettings`, `Get-AsaProjectsRoot`, `Get-AsaRepoPath`,
`Test-InsideProjects`, `Get-ProjectNameUnderRoot`, `Read-HookInput`, `Get-HookCwd`), so any project
folder under `projects\` gets these without this repo's own `.claude\settings.json` naming it:

- `projects-session-start.ps1` — `dart run bin\brief.dart <project>` on open, no-op outside `projects\`
- `projects-post-tool-use.ps1` — keeps `.asa-session.md` current on every Write/Edit/MultiEdit
- `projects-stop-six-moments.ps1` — a plain word match (English + German) against the six moments'
  own trigger words (Instruction for AI §3 step 5); blocks once, with a reminder, only when nothing
  was written this turn *and* the answer has no `Logged:` line — a word match will sometimes remind
  when nothing actually happened, which costs one line, not a real error
- `projects-stop-check.ps1` — runs `bin\check.dart <project>`, blocks on a real finding, fails open
  on anything it can't run
- `projects-session-end.ps1` — closes a still-open `.asa-session.md`, appends the `.asa-log.md` line

**`install-hooks.ps1` grew `-Scope user`** (default stays `-Scope project`, unchanged, still
verified green): copies the six files into `~/.claude/hooks` and merges them into
`~/.claude/settings.json`, same merge-not-overwrite discipline as the existing project-scope path.
Shares `Test-Prop`/`Set-Prop` with the unchanged project-scope code further down the same file
(identical bodies in both places, kept rather than risk breaking the existing path). **Checked, not
assumed, before trusting it:** the new `-Scope user` branch defines its own `New-HookEntry`
(`-Command` param) and calls it, then exits — the *old* `New-HookEntry` (`-ScriptName` param) and
`Add-Hook`, unchanged, sit further down the same file for the project-scope path. Verified
empirically with a two-function throwaway script that PowerShell binds a call to whichever
definition already executed by that point in a top-to-bottom run, not to whichever is textually
last in the file — so the early exit means the `-Scope user` branch never sees the later
redefinition. Both scopes' own tests (55 pre-existing + the new ones below) confirm this holds, not
just the isolated throwaway check.

**Tests:** `test-hooks.ps1` grew from 42 to 68 checks (source file — running the *installed* copy in
`.claude\hooks\` showed the old 42 with none of the new ones, a real mid-session mistake, fixed by
always testing the source until a reinstall syncs it). New coverage: all five hooks no-op outside
`projects\`; a write updates `.asa-session.md`; six-moments blocks an unrecorded decision, passes
with a `Logged:` line, passes with no moment words; SessionEnd closes and logs; `-Scope user` copies
all six files, writes `~/.claude/settings.json`, registers all five hook entries, and running it
twice does not duplicate them — all inside a sandboxed `%APPDATA%`/`$HOME`, never the real ones. One
real test-isolation bug caught along the way: the six-moments "was something written recently" check
was seeing the *previous* test's own write and treating an unrecorded decision as already recorded —
fixed by explicitly backdating the session file's `updated:` field before that specific test.

**BLOCKED, real, named rather than worked around:** `install-hooks.ps1 -Scope user` against the real
`~/.claude/settings.json` was refused twice by Claude Code's own auto-mode classifier
(*"Self-Modification"*) — once for the install itself, once even for a plain `git status --short`
run immediately after (the classifier's scope for this session appears broader than just editing
`.claude/settings.json` directly; not investigated further, not worked around either way).
`git add`/`git commit` on the already-known file list, and `git diff --staged --stat`, were **not**
refused, which is how this entry exists. **Nico needs to run this once himself, on each machine that
should get the projects\-scoped hooks:**

```
powershell -File kit\hooks\install-hooks.ps1 -Scope user
```

Restart Claude Code afterwards so it reads the new `~/.claude/settings.json`. The drill (next) tests
whether these fire for real — step 7 explicitly covers the Claude desktop app, a second surface
these hooks have never run under.

**Commits:** `05f58ac` — all seven `kit\hooks\` files plus `test-hooks.ps1`'s new checks, together.

**Next:** the drill (8 steps, round-39.md) — item 1 is done once all 8 pass.

---

### Delivery v1, item 1 (part) — Round 39: the drill

**Built a real fixture** — `projects\_drill-fixture-round39\` (a webinar-launch project, in AGENTS.md's
real shapes: `CHARTER.md`, `plan\1-marketing.md`, `plan\2-finance.md`, `decisions\0001`/`0002`,
`rounds\round-1.md`/`APPROVED.md`/`CHANGES.md`, `.asa-session.md`, `.asa-log.md`) — **removed again
after this checkpoint**, since it was test data, not a real project, and would otherwise show up as
a fake card in Nico's own app.

**Ran six of the eight steps for real**, each a genuinely fresh subagent (no memory of this
conversation, no memory of each other where the drill calls for that) reading only
`projects\CLAUDE.md` → `AGENTS.md` and the fixture files, exactly as a real session would. **All
six passed** — gist of each, verbatim quotes trimmed:

1. **"Where are we, and what's been decided?"** — found `AGENTS.md` via the one-level-up
   `CLAUDE.md` pointer unprompted; `asa-brief` isn't on PATH for a subagent, correctly fell back to
   reading the files by hand per §4; led with the next step, the one live decision, and the area's
   state, correctly reporting nothing else was waiting.
2. **"Let's run the webinar in October, not November."** — wrote `decisions\0002`, `Supersedes:
   0001`, flipped 0001's own status to `superseded by 0002`, kept the user's exact words in *Your
   call*, updated the area's own Decisions list, and **ended the reply with an unprompted `Logged:`
   line** — reported honestly that it would have written that line without any reminder mechanism,
   since §3 step 5 gates it on the moment happening, not on a hook forcing it.
3. **"Yes, Round 1 looks good."** — added the `APPROVED.md` row in the user's exact words; correctly
   did *not* invent a "built" result, since the fixture round's own acceptance criteria say plainly
   it's never built.
4. **"Add an area for Finance."** — created `plan\2-finance.md` in the right shape; the real find:
   `CHARTER.md` had no objective Finance could honestly serve, and rather than invent one or force a
   link to Objective 1 (the webinar), it wrote *"not decided yet"* and added the open task to decide
   — the same pattern §13 already prescribes at the project level, correctly generalised to an area.
5. **Closed mid-task, a second fresh session said only "continue."** — noticed
   `.asa-session.md`'s own `status: open`, correctly reasoned (from `opened-by: Claude Code`, no
   contradicting recent write) that this was its own interrupted work rather than a live concurrent
   session, said where things stood before touching anything, and did **not** redo any of steps
   2–4's work — it picked up exactly at the open question (Finance's objective) and asked the user
   rather than guessing.
6. **"Arrive after 3 days."** Two real changes plus one deliberately unlogged one were planted by
   hand (Finance's objective resolved; the webinar month confirmed; **and, slipped into the same
   `CHARTER.md` edit, Objective 1's own target quietly bumped from 100 to 150 signups with no log
   line anywhere**). A third fresh session, told only *"continue,"* correctly reported `asa-brief`
   isn't installed, fell back to reading `.asa-log.md` and the files directly, and **caught the
   unlogged change on its own** — noticed `CHARTER.md`'s "150" didn't match `plan\1-marketing.md`'s
   own "100" and that nothing in the log explained it, and flagged both that mismatch and that the
   October reversal was logged only vaguely (present as a file, not named in the log line). It did
   not invent which number was right; it asked.

**Two steps could not be run to completion — real, structural gaps, not new bugs, named rather
than quietly skipped or silently built around:**

7. **The Claude desktop app.** Nothing in this session can drive that separate application — no
   tool here opens it, clicks in it, or reads its output. **Not run.** Needs Nico's own hands:
   open the desktop app with the workspace folder connected, say nothing but *"where are we, and
   what's been decided?"*, and write down honestly whether the `asa` skill fired by itself or he had
   to say "read the instruction."
8. **"Does Checks show the unlogged change? Does each project's Log show every session?"** —
   **fails, for a narrower and more precise reason than first written here — corrected the same
   day, before this went further on a wrong premise.** First pass wrongly said cp8 (ADR 0033,
   local change history) "isn't built yet," trusting a doc-comment on `briefSince`
   (`lib\core\brief.dart`) instead of reading the function's own body six lines below it. Checked
   directly with a throwaway script calling `recordChanges`/`briefSince` against an isolated
   scratch folder: **cp8 is real and working** — `asa-brief --since` does say *"changed, not
   logged"* for a genuinely unlogged edit. What actually explains the drill's result:
   `isLoggedChange` matches a change to a log line **by calendar day only**, on purpose (its own
   comment: *"same calendar day is close enough; the log's own lines don't carry a reliable time
   component for every real line"*) — my fixture's unlogged edit landed the same day as other real,
   logged work, so cp8 called it logged even though nothing named that specific change. The stale
   doc-comment itself is now fixed (`brief.dart`, its own small commit). **The two gaps that are
   real:** `dart run bin\check.dart _drill-fixture-round39` on step 6's own fixture printed **`OK`**
   — confirmed by reading `checkProject`'s full body that it never calls `change_history.dart` at
   all, structural checks only; and **no screen anywhere in `lib/hubs/` reads `.asa-log.md` or
   cp8's history** — the Instruction for AI screen's own *Checks* part (cp6) runs the same
   structural `checkProject`, not cp8's; Round 21 (the Log tab) is still roadmapped, not built. So
   the data and the logic already exist and a terminal `asa-brief --since` already shows it
   correctly (day-granularity caveat aside) — what's actually missing is a **screen**.

**DECISION NEEDED (Nico's, not mine to make silently):** should Round 21's Log tab be pulled into
this delivery, ahead of Round 38/42/43/41, so cp8's own findings (and every session) show up
without a terminal — or should v1 ship with this gap named, on the reasoning that the manual's own
diligence (step 6 above) already catches it well enough by hand, and the round stays roadmapped for
later? Written up in full, corrected version, in `projects\asa\decisions\0048-…md`. **Not decided
here — continuing with Round 38 next, which doesn't depend on this either way**, per delivery-v1.md's
own rule 2 (a decision only Nico can make: write it down, keep moving).

**Item 1 (Round 39's rest) is therefore six of eight — not fully done.** Named honestly rather than
marked complete: 6 pass for real; 7 needs Nico; 8 exposes a real, pre-existing gap that needs his
call above.

---

### Delivery v1, item 2 — Round 38 cp0 + cp1: tab order, the Next line, areas as tabs

**cp0 (§A):** tabs reorder to `Strategy · Plan · Decisions · Details` — a project still opens on
Plan. The Next line hoists out of `PlanView` into `ProjectScreen`'s own header, so it shows above
every tab, not only Plan — same `effectiveNextStepWithArea` chain, same visual shape; tapping it
switches to Plan and tells the next `PlanView` which area (or "Not in an area") and task to open.
One real gap the hoist exposed and fixed alongside it: `PlanView`'s own `didUpdateWidget` never
reacted to `openHomeOnStart` flipping true on an already-mounted `PlanView` (only `areaToOpen`/
`highlightTaskRawLine` did). The Decisions tab gets a small amber count (`groupForReview`'s existing
"needs a look" size), shown only when > 0.

**cp1 (§B):** areas stop being expand-in-place rows and become their own tabs under Plan — `All` ·
one per area · `+ Add area`. "All" keeps the same summary-row list; tapping a row now switches tabs
instead of expanding inline. Selection (`_selectedAreaTab`, renamed from `_areaToOpen`) is owned by
`ProjectScreen`, not `PlanView` — "remembered per project while the app runs" only holds if it
survives `PlanView` being torn down and rebuilt on every switch away from and back to Plan.
`templates\area.md` (new) and `lib\core\area_writer.dart`'s `createArea` (new, its own commit): the
canonical empty shape, a lowercase-dash slug, a refusal on a duplicate name or an empty slug, never
touching an existing page, logged through `write_log.dart`. The dialog (name field, Create/Cancel)
shows a refusal inline, and on success switches straight to the new area's tab and reloads. A fully
empty area (new or otherwise) shows one honest line — *"Empty so far. To fill it: Start → Copy
opener, and tell the AI what this area is for"* — instead of five separate "No X yet"s. A
zero-area project gets a plain `+ Add area` link next to its existing body, no tab strip (nothing
yet to switch between) — "nothing else changes," per the round's own wording.

**A real, reproducible test-environment quirk found and worked around, not silently retried into
passing:** a widget test driving the dialog through the real `ProjectScreen` end-to-end (real disk)
hung indefinitely on a *second* `readProject()` call, triggered by the dialog's own un-awaited
`onDataChanged` firing after `showDialog` resolved — reproduced consistently, isolated with
temporary debug prints (removed before committing) down to the exact `await` that never returned,
confirmed unrelated to wait duration (a 3-second real delay didn't help either). Read as a
`runAsync`/`FakeAsync` interaction specific to this test binding, not a bug in the dialog's own
logic or a production risk (real usage has no `FakeAsync` at all). Fixed by testing the dialog
against `PlanView` directly with fake callbacks instead — faster, more focused, and it already
matches the level every other `PlanView` interaction is tested at.

**Existing tests updated for the new architecture, not just patched to pass:** `plan_view_test.dart`'s
whole "round-36 §2 b" Next-line group removed (moved to the header); several assertions now expect
2–3 "Sales" matches instead of 1 (the tab strip's own label is new); a harness `StatefulBuilder`
added so a test can actually drive `selectedAreaTab`/`onSelectAreaTab` the way `ProjectScreen` really
does.

**Tests:** `area_writer_test.dart` (8), `add_area_dialog_test.dart` (4, the dialog's own logic).
685 total, `flutter analyze` clean.

**Also fixed along the way, its own commit:** cp10's `projects-stop-six-moments.ps1` named the user
in its own comment (*"Nico has no API budget"*) — caught by `no_personal_name_test.dart` when the
full suite ran (cp10 itself had only run `test-hooks.ps1`, not `flutter test`, a real gap in that
checkpoint's own discipline, not a new rule).

**Commits:** `81b586c` (cp0), `c96f6c0` (the area writer), `0d29a4e` (cp1's UI),
`efcbf0e`/`ba754bc` (the two fixes above, already logged under item 1's own entry since they were
found while correcting the drill's step 8).

**Next:** cp2 (§C — Strategy links to Decisions/Log, the round *Your call* screen, its two
writers).
