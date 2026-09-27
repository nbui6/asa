# CLAUDE.md - Asa

**`AGENTS.md`, in this same folder, is the canonical onboarding file — read it first, before
this one.** It holds everything that is true regardless of tool: what Asa is, how to find the
workspace, the three roles, Gate 1 and Gate 2, the doorman, the feedback channel. This file adds
only what is specific to running inside Claude Code: the machine check and its hook, and the
numbered Hard Rules contract (their numbers are cited throughout `HANDOVER.md`, `ASA-LOG.md` and
the `decisions\` files, so they stay put here rather than move to AGENTS.md).

One product, several hubs. Only the Product Hub exists. The others are named so the shell is
built to accept them, and naming them is the entire investment.

`ARCHITECTURE.md` is the map of the code. Read it before adding a file, and update it in the
same commit as the part it describes.

## Where we are

**Pick up here — 2026-09-27. Round 37 is done, cp0 through cp5, and ready for Nico's own test
alongside Round 36's.** Full spec and its own finish line: `projects\asa\rounds\round-37.md`.
`HANDOVER.md`'s own cp0–cp5 entries have the real detail; the short version: every page under
`lib/hubs/product/` (except `ui/` itself) now composes one shared set of parts and tokens
(`lib/hubs/product/ui/`, ADR 0029) instead of its own private colours, sizes and widgets, enforced by
`test/one_look_test.dart`. Built under ADR 0027/0028 (no per-checkpoint yes needed), with one real
mid-round check-in from the deciding session (2026-09-27 19:36) answering an open question (§D4) and
confirming two colour calls, rather than waiting for Nico. **Three real bugs found and fixed along the
way, none by any of the 525 unit tests — all by actually looking at a screenshot or running the
feature test:** `ProgressBar` painted at zero size (a bare `ColoredBox` in a `Stack` with no
`Positioned.fill` — every bar in the app was invisible until cp4's own screenshot review caught it); a
project's one-line description showed raw `**markdown**` asterisks (pre-existing, not introduced by
this round); `click_through_test.dart` and the real-folder screenshot test both had real bugs of their
own (stale tap targets after the parts move; a stale-State bug reusing `ProjectScreen` across
`pumpWidget` calls with no distinguishing `Key`). `check.ps1` is green, the release exe rebuilt and
confirmed starting outside the IDE. **One small, non-blocking finding carried to a future round:** the
"What changed" panel's plain `Round N` chips have no visible separator between consecutive ones,
unlike the ADR chips' own `NNNN · Title` format — named in cp4's own `HANDOVER.md` entry, not fixed
(pre-dates this round, and "no layout changes" is this round's own boundary). **Not yet done: Nico's
own test** — round-37.md's own line: *"does it look like the same app as the page before?"*, one
question per page, alongside Round 36's still-outstanding 30-minute test. Nothing here waits on more
code, only on his yes.

**Superseded 2026-09-27 by the line above; kept for history:**

**Round 36 is ready for Nico's own test, again — cp8 closed the gap the
deciding session found against the real folder.** Full spec and its own finish line:
`projects\asa\rounds\round-36.md`. Every checkpoint (cp0–cp8) built, self-tested and committed under
ADR 0027/0028 (no per-checkpoint yes needed) — `HANDOVER.md`'s own cp0 through cp8 entries have the
real detail. **cp8's own real find:** 12 of the 13 real projects have neither `PLAN.md` nor `plan\`,
and used to skip the Plan tab entirely, landing on Decisions — silently failing Nico's own step 2 on
almost every real project. Fixed: every project opens on Plan now, with a real body for the no-plan
case; confirmed 13 of 13 against the real folder. Two other cp8 pieces: `templates\HOW-ASA-WORKS.md`
is generic again (the doorman block and the `PROCESS.md` line were asa-only), and the overview's rows
now share one bordered panel with hairlines, not a `Card` each, matching `asa-front2` closer.
**Two honest, named-not-fixed gaps carried since cp6:** a Plan↔Strategy tab switch, and the
overview's own Bars↔Tasks toggle, still reset whatever area or group was open — a bigger change
(mounting every tab at once) than any checkpoint's own scope so far. `check.ps1` is green, the
release exe rebuilt and confirmed starting outside the IDE. **Not yet done: Nico's own 30-minute
test, round-36.md §8, written out in `HANDOVER.md`'s cp7 entry.** Nothing here waits on more code —
only on his yes, recorded as `Round 36: approved by Nico <date>` once he gives it.

**Superseded 2026-09-27 by the line above; kept for history:**

**Pick up here — 2026-09-25. The goal narrowed to one thing: a working overview of all 13 projects, kept current by Claude.** Seven steps, who does each and what to expect: `projects\asa\PLAN.md`, "2026-09-25 — the goal narrowed". Research behind it: `projects\asa\RESEARCH-SIMILAR-TOOLS-2026-09-25.md`. **Revised the same day: steps 1, 5 and 6 are now one round, Round 32** (`projects\asa\rounds\round-32.md`). One build, self-tested, then one 20-minute test by Nico. Code: read that file end to end and build it. Round 28 and the rest are parked until after step 7, not cancelled.

**Superseded 2026-09-25 by the line above; kept for history:**

**Pick up here — logged 2026-09-14 so a session in a few days doesn't have to re-derive this.**

1. **Open Asa. This is the actual next step, and it has been waiting all session.** Look at the
   real Strategy and Plan tabs. Nothing below matters until this happens once.
2. **Correct or confirm the five candidate objectives in `CHARTER.md`'s `## Objectives`** — they
   are still Claude's wording, drafted from your own words elsewhere, never approved by you.
3. **Add or correct rows in `rounds\APPROVED.md`** for whatever you actually confirm in step 1.
   Six historical yeses are already backfilled (Rounds 9 ×2, 11, 19, 20, 24); Rounds 26, 27, 29
   and 16 are not, on purpose — that look hasn't happened yet.
4. **Decide ADR 0024** (an area is the unit of the plan) — still genuinely `proposed`, no `## Your
   call`. Cheap: nothing needs to be built against it for Asa specifically right now, so this is a
   short decision, not a project.
5. **Once 1–4 have happened, the next build candidates, in order:** Round 28 (typed links, both
   ends) → Round 14 (the Roadmap tab, newly claimed by an objective) → Round 31 (blocked on the
   real ADR 0021 question, named there — not a build to schedule until that's answered).
6. **Known, named, not yet fixed:** Round links on the Strategy and Plan tabs open the whole
   `asa.md` file, not the specific Round — no deep link yet. Not a bug, just not built.

**Current as of 2026-09-14 — points at `projects\asa\PLAN.md`'s own dated entries rather than
restating them, since this section had drifted a full session behind by the time this line was
added.** Rounds 26, 27, 29 and 16 are all built and committed, not pushed; all four sit at
**waiting for your approval** — built, none of them opened as the real running app yet, which is
the actual next step, not more code. **Corrected here 2026-09-14 — this line, and `asa.md`'s own
next-step and Round 16 entry, all said "ADR 0024/0025/0026 are all accepted."** Only 0025 and 0026
are; **ADR 0024 has no `## Your call` and its header still reads "proposed"** — found by Code
reading the ADR file itself rather than trusting the claim, same failure ADR 0004 exists to name.
Nothing was built on the false premise (Round 16's own spec says ADR 0024 doesn't apply to Asa),
but three files asserted it anyway, now fixed. Everything below this line is the Round 9/19-24
narrative from 2026-09-13 and earlier — still accurate for what it covers, just not the whole
picture anymore.

**v1's feature list is complete; the goal it was redefined around is not yet proven.** Full
reasoning in `projects\asa\PLAN.md`. The short version: Asa shows what it was built to show, but
"does Nico open it without being reminded" is still unanswered.

**Round 9 finished and confirmed — both pieces, same day (2026-09-13).** Parked items
(`13a4a1d`, 228 tests) and the overdue-deadline signal (`7d52a90`, 237 tests). Both shown as
real running throwaway demos, both got Nico's "yes," both committed after. Round 9's two other
original pieces (process view, project relations) were not part of either build and remain open.

**ADR 0007 — "Asa writes structured fields, never prose" — found accepted 2026-09-01 and
unbuilt for 12 days.** Caught by the doorman's own decisions-sweep, added the same day it caught
this. Addressed by sequencing four rounds, not by rewriting the ADR:

| Round | What | Status |
|---|---|---|
| 19 | The write path itself (`project_writer.dart`) + the write log, `core/` only, no screen | **Specced, sent to Code. Not yet built or confirmed.** |
| 20 | The five whitelisted fields become editable on the project screen | Roadmapped, not yet specced in detail. |
| 21 | The Log tab, closing guardrail 3 | Pulled forward ahead of schedule, at Nico's choice. Roadmapped, not yet specced. |
| 22 | `next-step` derives from the first open task (ADR 0020, accepted 2026-09-13) instead of being a maintained field | Roadmapped, not yet specced. |
| 23 | A decision shows whether it ever became work — Nico's own idea | Roadmapped, not yet specced. |

**Rounds 19, 20 and 24 all built, verified against real files, shown, confirmed, committed —
2026-09-13.** `53e8a44` (19+20), `eba90b2` (24). 268 tests, `check.ps1` clean. Verified honestly
before trusting the claim: real file listing (`device_bash` still blocked by the September 8
issue), not just Code's word — `project_writer.dart`, `write_log.dart`, a grown `task_writer.dart`,
`project_screen_edit_test.dart`, `.claude\skills\doorman\` at project scope, `kit\SKILLS.md` freshly
touched, all present and roughly the size the build report implied. The write log lives in
`%APPDATA%\Asa\`, gitignored — Gate 2 held, checked, not assumed.

- **Round 19** — `project_writer.dart`'s `setProjectField`, the whitelist, drift refusal,
  single-line replacement; `write_log.dart`, append-only, closing ADR 0007's guardrail 3, unmet
  since Rounds 8/9. Existing checkbox writers retrofitted to log too.
- **Round 20** — the five whitelisted fields editable on the project screen. **Its own spec's
  premise was wrong** — only `status` was actually shown before this round, not all five; Code
  caught it, asked Nico rather than guessing, built the missing four rows as well as the editing.
  This is the round that makes "work directly from the Asa UI" literally true.
- **Round 24** — the doorman installed at both project and user scope, verified by real file
  listing and the manifest. **Firing itself still only provable by a future fresh session** — the
  build report says so honestly rather than overclaiming. Caught two things beyond the ask:
  `kit\skills\doorman\`'s own source had never been committed (only the installed copy would have
  been, leaving a fresh clone nothing to install from); `ship-it` had the identical
  never-added-to-`$coreSkills` gap as doorman, fixed alongside it.
- **The Release build was refreshed too**, confirmed opening outside the IDE.

**Round 25 — retracted the same day it was specced, never built.** The plan had been an in-app
button that stamps a bare `status: idea` onto a folder with no Asa-shaped note yet. Nico said no:
*"how about let claude works on the notes and make it into Asa properly there?"* Right call —
Asa does not think, so Asa should not guess a real project's status. Replaced with a section in
`AGENTS.md` telling any Claude session to read a real project's own material and hand-write its
note with a real judgment call — no code needed.

**`AGENTS.md` written 2026-09-13**, pulling Round 18's portability item forward: one canonical,
tool-agnostic onboarding file, so a fresh Claude session on another machine can bootstrap itself
without this file. This file (`CLAUDE.md`) was reduced to point at it the same day.

**Pushed to GitHub — 2026-09-13.** Before pushing, Code committed the deciding session's own
pending edits on her behalf (`AGENTS.md`, `CLAUDE.md`, `FOR-YOUR-FORK.md`, `kit/KIT-LOG.md`,
`kit/PLAYBOOK.md`, `kit/skills/roadmap/SKILL.md` — real files she'd written through the device
bridge but never `git commit`s herself), then ran `check-shareable.ps1` — it exited 1, and every
finding behind that exit code was individually read rather than pushed past: 38 are the existing
`ios/`/`.idea/` waiver, unchanged; the other 11 all use the deliberate `test` placeholder or are
prose describing that same pattern, none a real leak. **One real leak found and fixed while doing
this, not part of the original ask:** `.claude/.kit-manifest.json` and
`.claude/skills/.kit-version`, written by Round 24's install, baked in the real local username —
now gitignored and untracked (`6eed49a`). Repo confirmed still private by a real, unauthenticated
check (HTTP 404), not assumed. **Nico pushed it himself, per the standing role split** — 6 commits
(`53e8a44`, `eba90b2`, `a3c2c1d`, `47db78e`, `2cda519`, `6eed49a`), confirmed by `.git`'s own
remote-tracking ref moving to match local `main` (`device_bash` still can't run `git log` directly
to double-check the commit-by-commit content, so this is ref evidence plus Nico's own word, not a
full `git log origin/main` read).

**Not done, still open, not hidden:**

- **The actual test hasn't happened yet.** Everything above is proven on throwaway demo data and a
  real file listing — not on Nico's own real projects on the other laptop. That's the next real
  milestone: clone this repo there, bring real projects in per `AGENTS.md`, then edit them through
  Round 20, for real.
- Round 21 (Log tab), Round 22 (`next-step` from tasks), Round 23 (a decision shows whether it
  became work) — roadmapped, not yet specced.
- The front page still does not match `asa-front2`, the sketch Nico signed off on.
- Tasks are denser than he wants; no way yet to type a new task, or drag one to reorder or
  re-parent it; no way to drag-reorder or drag-to-re-parent a project on the front page itself.
- ADR 0019 (a layer above the project — "areas") remains proposed, not accepted, deliberately
  behind everything above.
- **`projects\` getting its own local-only git repo — settled, 2026-09-14: no.** ADR 0023, run
  through the kit's `counter-proposal` skill, rejects it (five questions, all against; the real
  gap was a backup gap, not a version-control gap). See below.

**2026-09-14 — v2 opened, and it moved fast: ADR 0008, 0021, 0022 accepted; Round 26 and Round 29
built, verified, committed; not yet pushed.**

Nico: *"Each projects need a plan layer that links to everything else... a plan could be many
pages, but everything has to be interconnected."* Full reasoning in `projects\asa\PLAN.md` and
`projects\asa\RESEARCH-PLANNING-LAYER-2026-09-14.md` (real external research, not designed from
intuition alone). What got decided, in order:

- **ADR 0008** (typed vs. derived links) — accepted, Nico's amendment: derived by default, typed
  only where direction matters.
- **ADR 0021** ("the plan is many pages") — accepted after a research-driven revision: a plan is
  a folder of pages keyed to a named aspect, `PLAN.md` is the front page, Asa shows and links
  pages but **never writes one** — keeps ADR 0007 and hard rule 13 intact.
- **ADR 0022** ("the plan holds now, decisions hold why, the archive holds before") — accepted.
  Corrections go straight into the plan, ungated; decisions still need Nico's yes; superseded plan
  text moves to `PLAN-ARCHIVE.md`, never into a decision. **Done the same day:** `PLAN.md` split
  from ~52 KB to ~40 KB, `PLAN-ARCHIVE.md` created, verified programmatically that no heading was
  lost.
- **ADR 0023** ("no git repo for `projects\`, it gets a backup instead") — the counter-proposal
  above. Reframed the real gap as *no backup at all*. Two backups specced: automatic local
  snapshots (`kit\backup-projects.ps1` — **specced in `HANDOVER.md`, not yet built**) and a
  manual, occasional, work-projects-only copy to the company network (Nico's own hands, nothing
  automated — see ADR 0013's amendment, corrected same day to drop an over-engineered allowlist).

**Round 26 (read the plan) and Round 29 (sketch approvals as a third `DecisionSource`) — both
built, verified against real files, committed 2026-09-14 (`22a1c26`, `80fa9e8`).** `check.ps1`
clean, **289 tests total.** Verified honestly before trusting the claim, the same way as always:
real file listing over the device bridge (`device_bash` still blocked by the same September 8
issue) — `lib/core/plan.dart`, `lib/core/decisions_reader.dart`'s grown `SketchApprovalsSource`,
`markdown.dart`'s grown `parseSections`, `test/plan_test.dart`, `test/sketch_approvals_source_test.dart`
all present, sized and timestamped consistently with the commit log, not just Code's word. **Local
`main` is ahead of `origin/main` by these two commits — not pushed yet**, which is fine; that step
is Nico's alone.

**Real judgment calls flagged in the build, not silently guessed:** Round 26's `pagesLinkingTo`
wikilink match is untested against any real project; a markdown table row with no periods parses
as one run-on sentence. Nico deferred judging the actual data shape until Round 27 gives him a
screen (*"I am unsure, I will test it when I see the app. Continue"*) — recorded as a deferral,
not a yes on the shape itself.

**What's actually next: Round 27, the Plan tab** — the visible half of Round 26, and the round
Round 15 was always trying to be. **Nothing specced for Code yet.**

**Last updated:** 2026-09-14, by the deciding session, after verifying Round 26 and Round 29
against real files and updating `asa.md`'s Roadmap and `next-step` to match.

## The machine check

```
flutter test                                        # must print "All tests passed"
powershell -File .claude/hooks/test-hooks.ps1       # the check for the hooks themselves
```

A PreToolUse hook blocks `git commit` until `flutter test` has passed since the last change
under `lib/` or `test/`. It is not advice; it refuses. `--no-verify` is the escape hatch, and
using it means saying why in the commit message.

## Definition of done

The standing bar for everything, not restated per session:

> Criteria met - handover check written - reviewed - `CLAUDE.md` updated - **for any round that
> touches `lib/`: release exe rebuilt and confirmed starting outside the IDE** (doc-only commits
> are exempt) - **result shown to Nico and a yes back** - the yes recorded in a commit.

**Commit as often as possible along the way; the round is done only after Nico's yes.** Rule 19,
as changed by ADR 0028 on 2026-09-26.

## Hard rules

Written as what to do. Cap is about 20; adding one asks which one retires.

1. **Write acceptance criteria before code** - one human line, one machine line. When there
   cannot be a machine line, write `Machine: none, because <reason>`.
2. **`core/` never imports Flutter.** The tests import `core/` directly to keep it that way.
3. **`hubs/` may import `core/`** - never the reverse, and never each other.
4. **Asa writes only structured fields, never prose.**
5. **Show the raw data at every boundary.** This rule has already found a bug with no code run.
6. **Show every failure with its reason.** A folder that cannot be read is listed and
   explained; a folder that vanishes from a list is indistinguishable from one that never was.
7. **Say it in words as well as colour.** Colour is a hint, never the only signal.
8. **Test against the real contract.** When a hook, payload or API is involved, capture one
   real payload and assert against that. Round 2's recorder read a field name that never
   existed and its test invented the same name, so the test agreed with the bug for a week.
9. **Fix the encoding, never the assertion.** A test that expects a mangled string turns a
   visible defect into a passing suite.
10. **Write every `.ps1` with a UTF-8 BOM.** Without one, PowerShell 5.1 reads it as
    Windows-1252 and em dashes arrive as garbage.
11. **Update `ARCHITECTURE.md` in the same commit** as any change that adds, moves or removes
    a part.
12. **A retired term is a banned term.**
13. **Asa never becomes a text editor.** That is the line.
14. **Read the repo before proposing anything for it.** Not the notes about it - the repo:
    `ARCHITECTURE.md`, this file, and the vault's `CHARTER.md`. On 2026-08-31 an assistant
    proposed "Asa, day one" - a fresh charter, roadmap and CLAUDE.md - for this repo, after an
    hour of discussing Asa. Three rounds were already committed. A belief formed from
    conversation is not evidence and reads exactly like knowledge from the inside.

15. **No git remote is ever added, and nothing is ever pushed, without Nico saying so in that
    session.** Not to company infrastructure, not to a personal host, not "just to back it up".
    Verified 2026-09-01: `dev/asa` and `dev/assistant` have **no remote configured** and the vault
    is not a repository. If a remote ever appears in `.git/config` and Nico did not ask for it,
    stop and say so before doing anything else.

16. **Nothing is pushed without `check-shareable.ps1` passing.** The repository is shared; the
    projects Asa reads are not. Run it, read the output, then push:
    `powershell -NoProfile -ExecutionPolicy Bypass -File check-shareable.ps1`
    **Three checks always run: a machine path, an email address, and whether the repository is
    actually private.** The name list starts empty.

    > **The visibility check exists because the premise was false.** On 2026-09-02 this repository
    > was found to be **public**. It had been believed private for two days, and that belief was
    > written into this rule and into the script as the *justification* for the empty list and for
    > the waiver below. Nobody had checked. The script now asks GitHub's public API, with no token,
    > whether a stranger can read the repository - and **fails closed** if it cannot find out.
    > **A security property that nothing verifies is a hope.**

    The list stays empty for a narrower reason than before: the two built-in checks catch what is
    genuinely damaging wherever this ends up, and a hand-maintained list was tried twice and
    thrown away both times because a noisy check gets switched off. Add a name when something
    turns up that a reader should not see - not pre-emptively. Same shape as
    `kit/check-boundaries.ps1`, including the `-SelfTest` that proves it still catches things.
    *Two more elaborate versions were written and thrown away first — one with a hand-maintained
    list, one that derived the list from folder names, git and the private notes. Both solved a
    problem this project does not have. The second was written while the proven checker sat
    unread in the folder it had just been copied into.*

    > **Named exception, open until the scaffold round. Added 2026-09-04.** The check reports
    > **~44 findings, of which 38 are `ios/` and `.idea/` files** tracked early in this repository's
    > history and never ignored. They surfaced only because the check now scans more file types.
    > **Real leaks: zero.** Pushing is allowed past these, **and only these**, until the small round
    > that extends `.gitignore` and decides whether an iOS scaffold belongs in a Windows-only
    > repository at all. *A gate that is routinely overridden is not a gate, so this waiver has an
    > end condition and a count: 38. If the number changes, stop and read the new ones.*

    > **Retired 2026-09-13 — checked, not assumed, and the reason is gone.** This waiver named
    > three lines (`projects_screen.dart`'s default folder, two fixtures in `test/project_test.dart`)
    > that carried the owner's real Windows username. Code checked directly while pushing v1: the
    > hardcoded default is already gone, and both fixtures already use the `test` placeholder every
    > other test in this repo uses. **The waiver's own stated reason no longer applies to anything.**
    > The checker still flags those two lines — its regex matches the *shape* of a Windows path, not
    > whether the name in it is real, so `C:\Users\test\...` and a real path look identical to it —
    > but that is the same, already-known limitation the waiver above (`ios/`/`.idea/`) already
    > exists to hand-read past, not a new leak. Left here as a standing fact about the checker's own
    > blind spot rather than a live exception with an expiry, now that there's nothing left to
    > excuse.


17. **The workspace has one root: `%USERPROFILE%\workspace\`.**

    | | |
    |---|---|
    | `asa\` | **this repository** — the app and `kit\`. Shared. |
    | `projects\` | every project's material. **Never in git**, and it cannot be — it is outside the repository root. |
    | `workshop\` | `MACHINE.md`, `BOSS.md`, `hub\`. This machine, this Boss. Never in git. |

    This is `PLAYBOOK.md` §14 *Three homes* made physical. The rule was prose for three weeks and
    was broken anyway — a product skill filed into the kit, a glossary filled with one product's
    build log. **A folder boundary cannot be broken by being helpful.**

    *Moved 2026-09-01, ADR 0006. Not moved: the Flutter SDK (a tool, not part of this
    system) and the German app's code, until that project is dealt with on its
    own terms.*

18. **Project feedback is collected, not chased.** Every project folder has `FEEDBACK.md` — one
    dated line per finding about *the way of working*, written by whoever is in that folder, even
    a session that cannot see this repository at all.

    ```
    powershell -NoProfile -ExecutionPolicy Bypass -File collect-feedback.ps1
    ```

    Reads every project's `FEEDBACK.md`, appends the new lines to `kit\FEEDBACK.md`, and **holds
    back any line containing a machine path or an email address** — not copied, not deleted, and
    named so it can be rewritten. Nothing else ever leaves a project folder.

    **Run it before a commit.** It reports and never blocks. `-SelfTest` proves it still works.

    *Added 2026-09-01, after two sessions gave opposite structural advice on one project an hour
    apart because neither could see the other. The folder is the only channel between sessions, and
    a folder cannot notify anyone — so something has to go and look.*

19. **Commit as often as possible. No round ends until Nico has seen the result and said yes.**
    Changed 2026-09-26 by ADR 0028 (`projects\asa\decisions\0028-commit-as-often-as-possible.md`).
    Nico: *"always tell code to commit as often as possible. write that as rule now"*. Every time,
    in this order:

    | # | | |
    |---|---|---|
    | 1 | **Commit often** | After every piece that passes `flutter test` (the hook enforces it), and at once for doc-only changes. Small commits, one piece each, message starting `Round N:`. Never push. |
    | 2 | **Show** | The screen itself, or the command and its real pasted output. A summary of a result is not a result. |
    | 3 | **Ask** | *"Is this right?"* - asked out loud, as a question. Handing something over does not ask it. |
    | 4 | **Record the yes** | One commit, `Round N: approved by Nico <date>`, plus the `HANDOVER.md` line. If he names a fix, make it (committing as you go) and show it again - back to line 2. Something he rejects is undone with a new commit, never by rewriting history. |

    **A round reported done with nothing shown and nothing committed is not done.** That is what
    happened on 2026-09-02 with v0.1, in his words: *"Show me result, ask me if everything is
    okay, then commit after I approve or fix what I ask to. No round is finished before this."*

    This is the fifth line of `PLAYBOOK.md` §8 and the fourth entry in its row of near-misses
    (§14, *Done is not delivered*) - after *installed is not fired*, *tested is not compiled* and
    *rendered is not seen*. Same shape every time: **completion leaves an artefact, delivery does
    not.**

20. **The second developer's fork is one-way, and the boundary runs both ways.** A colleague
    builds her own features into her own fork of this repository. She keeps them; we never see
    them.

    | | |
    |---|---|
    | **Never fetch, pull, merge or cherry-pick from her fork.** Not to look, not to help, not to back it up. | The only code that comes back is a pull request **she** opened. |
    | **Nothing about her projects enters this repository.** | Not an issue, not a test fixture, not a doc comment. Our own data rule, pointed the other way. |
    | **`lib/local/` is empty here and stays empty.** | It exists so her screens live where our releases never write. A non-empty `local/` in this repo is a leak, not a feature. |
    | **`lib/core/`'s public surface is a contract.** | Her code compiles against it. Every release names what moved in `core/`; a rename is no longer free. |

    *`projects\asa\decisions\0010-second-developer-and-forks.md`, and `FOR-YOUR-FORK.md` is the
    page she reads. The seams are agreed and land in v0.1.1 - two of the three are not built yet,
    and that file says so rather than describing them as if they shipped.*

> **The list is now at 20, which is the cap.** The next rule added has to say which one retires.
> Candidates when that happens: **10** (UTF-8 BOM in `.ps1`) belongs in `workshop\MACHINE.md` -
> it is a fact about this machine, not about this project; **12** (a retired term is a banned term)
> belongs in the kit's glossary discipline.

## At the end of every session

**Append to `HANDOVER.md`, upstream half:** what was built · **what was decided that the spec did
not cover** · what could not be done · anything changed by hand that the agreed design still shows
the old way.

That half carries the reasoning no diff contains, and it is the half that gets skipped. This line is
why it will not be.

## Where the process lives

The playbook and the kit log are **in this repo**, under `kit\` - `kit/PLAYBOOK.md`,
`kit/KIT-LOG.md`. This project's own material is outside it, at
`%USERPROFILE%\workspace\projects\asa\` (charter, plan, persona, decisions, sketches, round
notes). `asa.md` there is the project's own note, and Asa reads it like any other project.

*Corrected 2026-09-02. This section still pointed at the Obsidian vault, which rule 17 and ADR
0006 replaced on 2026-09-01.*

**For the reasoning behind rule 17's workspace shape, Gate 2, the second-developer fork
boundary (rule 20), and the feedback channel — read `AGENTS.md`, not this file.** It says the
same thing once, in a way that does not assume Claude Code, so a session on another machine or
in another tool has the same rules without needing this file translated for it.
