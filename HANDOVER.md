# HANDOVER.md — from the deciding session to the building session

**Both sessions read it; neither writes in the other's half.**

---

## ⬇ Downstream — read before building

### Gate

| Check | State |
|---|---|
| Plan signed? | **Yes** — `projects\asa\PLAN.md`, Nico Bui, 2026-09-01 |
| Does this change a screen's structure? | **Yes, in two small places** — see below |
| Sketch seen and approved? | **Yes** — `projects\asa\sketches\asa-v01b.png`, the Decisions tab and the folder picker |
| Anything sketched but **not** approved? | **Yes, and most of it.** The whole front page as drawn (`asa-front2`), the project page's full tab row (`asa-proc2` — *"not entirely happy"*). **Do not build any of it.** |
| Unapproved decisions? | **ADR 0007** (Asa writes fields) and **ADR 0008** (links) are *proposed*. **Nothing in this version depends on either.** |

### The shape of this version, and why

**Build the model. Barely touch the screen.**

The front-page row changed four times on 2026-09-01. The decisions reader did not change once
after real files were read. **So this version lands everything that has stopped moving, and nothing
that is still being drawn.** Full reasoning in `projects\asa\ANALYSIS-BEFORE-V01-SPEC-2026-09-01.md`
§7.

**Consequence you will notice while working:** you will parse five fields that appear nowhere on
screen. **That is deliberate, not an oversight.** Every later version reads them.

### Job zero — done, do not redo

The app builds in ~34 s and runs. It lists projects and opens a project screen showing the values,
the source file, the raw frontmatter, and the git command with its output.

> **That provenance block is the best thing in this codebase.** Do not restyle it, do not collapse
> it. **Everything added here carries the same obligation: show the file it came from.**

---

## 1. `lib/core/decision.dart` — new. Pure Dart, no Flutter import.

**Parse one decision from text.** The contract below is taken from **real files in two projects**,
not invented. Check it against them before writing anything.

| Field | Where | Notes |
|---|---|---|
| Number | `# ADR 0004 — …` or `## 0004 - …` | May be absent. Absent is valid. |
| Title | The rest of that heading line | **The dash is `—` in one project and `-` in another. Accept both.** |
| Date | `**Date:** 2026-08-31` in the first ~5 lines | **May share the line with Status**, separated by ` · ` **or** ` - `. Both occur. |
| Status | `**Status:** accepted` | **The value is sometimes bold, sometimes not.** Strip the markers. |
| Supersedes / superseded by | **Parsed out of the status text** | `superseded by 0008` · `accepted (supersedes 0005)`. **Both are live on a real project.** |
| Why | The `## Why` section | **Verbatim first paragraph. Never summarise.** |
| Decision | The `## Decision` section | Present in 4 of 5 in one project; the fifth has `## Recommendation`. **Missing is normal — fall back to the title.** |
| What would change this | The `## What would change this` section | **The highest-value field in the file.** ADR 0001 listed four conditions, three happened, nobody noticed for ten days. |
| Source path | — | **Every decision keeps the file it came from.** Non-negotiable. |

**A file that cannot be parsed produces an `unreadable` result carrying its path and its raw text.
Silent skipping is banned** — `project.dart` already works this way; follow it.

## 2. `lib/core/decisions_reader.dart` — new. Two sources.

**This is the second implementation the SOLID section calls for, and it is not hypothetical — both
formats are on disk right now.**

| Source | Shape |
|---|---|
| **A folder** | `decisions/0001-slug.md`, one decision per file |
| **One log** | `decisions.md`, one `## 0001 - Title` section per decision |

**Both are read. Neither is converted. A project with both yields one merged list, each item
naming its own file.** One project switched from the first to the second the same day, for a stated
reason — *"too much file overhead for a project this size"* — so neither is the "right" one.

**Define `DecisionSource` with one method.** The ADR-folder reader and the log reader are its two
implementations. **A third format must be addable without editing either.**

**Take file access as a constructor argument** — a small interface with *list files in a folder* and
*read a file as text*. Two methods, not twenty. Production passes the real one; **every test passes
an in-memory one and touches no disk.**

## 3. `lib/core/project.dart` — extend. Parse, do not display.

Add, all optional, all absent-tolerant:

```
parent · priority (low|medium|high) · deadline (free text, e.g. "Oct–Dec") · jira · links
```

`links` is a list of `type: target` pairs — `relates to`, `blocks`, `blocked by`,
`shares <aspect> with`, `supersedes`, `superseded by`. **Parse and expose them. Show none of them.**

**`status` stays exactly as it is** — read from frontmatter, untouched. It becomes derived in a
later version and that is not this one's business.

## 4. `lib/core/settings.dart` — new. The only thing this version writes.

The chosen projects folder, in `%APPDATA%\Asa\settings.json`, via
`Platform.environment['APPDATA']`. **No new package.**

**This writes the app's own settings — never a note.** ADR 0007, which would allow writing notes,
is *proposed and not accepted*. **Nothing in this version writes to `projects\`.**

## 5. The screen — two changes, and no more

**a. The folder picker.** First run: an empty state and a **Choose folder…** button. The choice is
saved. **Six lines of source contain the owner's Windows username and the default path is broken on
every machine but his** — the teamlead has agreed to test, so this is a blocker, not polish.

**b. A Decisions tab on the project screen.** Two tabs: **Decisions** (default) and **Details**.
Details holds the existing labelled table. **The provenance block stays below both, unchanged.**

Decisions tab: newest first. Each row — title, status, date. **A superseded one is visibly
superseded and names what replaced it.** Tap opens: title, date, status, the decision, *why*, *what
would change this*, and the file path.

**Empty state: `Nothing decided yet.`** No box, no spinner. **Two of six projects are in this state.**

**Nothing else on either screen moves.**

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

### Tests

| Test | Proves |
|---|---|
| Each of the five real ADR files parses | The contract, against reality |
| A `decisions.md` log parses | The second real format |
| A project with both yields one merged list, each item naming its file | The case that exists today |
| `—` and `-` in a title both parse | Two projects write it differently |
| Date on its own line, and sharing a line with Status | Both occur |
| Bold and plain `**Status:**` | Both occur in one folder |
| `superseded by NNNN` and `accepted (supersedes NNNN)` exposed | Live on a real project |
| Missing `## Decision` falls back, does not crash | One of five |
| A malformed file yields **unreadable**, not silence | Banned failure mode |
| No decisions yields an empty list, not an error | Two of six projects |
| `parent`, `priority`, `deadline`, `jira`, `links` parse; absent is fine | The model |
| Settings round-trip: write, read, missing file | The picker |
| **`lib/core` imports nothing from Flutter** | The architecture rule, and ADR 0005's exit door |
| **Feature test** — launch, choose a folder, open a project, see a decision, see one marked superseded | It works for a person |

### SOLID, concretely

`project.dart` / `project_reader.dart` already split *the thing* from *the thing that fetches it*.
Follow it.

- **Single responsibility** — `decision.dart` parses text. `decisions_reader.dart` finds files.
  Neither does the other's job.
- **Open/closed** — a third decision format is addable without editing the two that exist.
- **Liskov** — every `DecisionSource` returns the same result type, **including for `unreadable`**.
- **Interface segregation** — two methods for file access, not a filesystem object.
- **Dependency inversion** — that interface arrives as a constructor argument. **Every parser test
  runs with no disk, and behaves identically on the teamlead's machine.**

> **Take an interface only where a second implementation is genuinely coming.** Two are coming for
> `DecisionSource`; one is coming for file access. **Nowhere else.** A `const` constructor with a
> new mutable field broke the sibling project's build while every test stayed green — boring beats
> clever, `CLAUDE.md` rule 7.

---

## Not in this version

The front page as drawn · groups on screen · status pills · priority or deadline **displayed** ·
the Jira chip **displayed** · the Tasks view · drag and drop of anything · links displayed or
created · derived status · the process tab · the full tab row · **any write to any note** · any AI.

**Each is a later version in `PLAN.md`. Anything invented from here goes to `BACKLOG.md`.**

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

- **Nico runs every `git` and `flutter` command himself, in Windows PowerShell.** Never through an
  assistant's device bridge — one left a stale `.git/index.lock` on 2026-08-26.
- **Stop and ask** if a criterion cannot be met **as written**, rather than meeting a nearby one.
- **If the parse contract disagrees with a real file, the file wins.** Say so and stop.
- **Nico is the only one who can say the round is done.** Show him the result - the app running,
  and `check.ps1`'s real output — then ask, then commit after a yes. **Not the other way round,
  and not a note in this file instead of the showing.** `CLAUDE.md` rule 19.

---

## ⬆ Upstream — appended by the building session at the end of every session

### 2026-09-02 — v0.1 built, `check.ps1` not yet run

**Built:** `lib/core/decision.dart` (parser, two real shapes) · `decisions_reader.dart`
(`FileAccess`, `DecisionSource`, `AdrFolderSource`, `DecisionLogSource`, `DiskFileAccess`, sort) ·
`settings.dart` (APPDATA read/write) · `project.dart` extended with `parent` / `priority` /
`deadline` / `jira` / `links` and `parseLinks` · `projects_screen.dart` gained a folder picker and
empty state · `project_screen.dart` gained the Decisions/Details tabs, provenance block unmoved ·
new `decision_detail_screen.dart` for the tap-through view · `check.ps1` (new, UTF-8 BOM) ·
`analysis_options.yaml` and `pubspec.yaml` updated for `very_good_analysis` and `integration_test`
· `ARCHITECTURE.md` updated in this commit · six tests files, one new (`decision_test.dart`,
`decisions_reader_test.dart`, `settings_test.dart`, extended `project_test.dart`) plus
`integration_test/app_test.dart`.

**Decided that the spec did not say:**

- **`HANDOVER.md` vs `v0.1-decisions.md` disagreed on whether `project.dart` gets touched.**
  `v0.1-decisions.md`'s "Files expected to change" table (written the morning of 2026-09-01) says
  it is not. `HANDOVER.md` §3 (written after the evening reversal in
  `ANALYSIS-BEFORE-V01-SPEC-2026-09-01.md` §7) says to extend it. Built to `HANDOVER.md`, per this
  session's instructions — the round note is stale on this one point, not wrong about anything
  else. Worth a line in `v0.1-decisions.md` so the next reader is not confused by the same
  contradiction.
- **The folder picker is a text field, not a native OS dialog.** "No new package" in §4 is scoped
  to settings; nothing in the spec says how §5a's picker works mechanically. Flutter has no
  built-in folder browser, and adding a package (`file_picker`, with its own Windows plugin
  registration) felt disproportionate for "barely touch the screen." The existing path `TextField`
  now reads "Choose folder…" on first run and persists the value on submit — meets acceptance
  criterion 6 (clone, run, choose a folder, see your own projects, no source edit) without a new
  dependency. Revisit if pasting a path proves too rough for the teamlead's actual first run.
- **`ProjectsScreen` grew an optional `settingsPath` constructor parameter**, defaulting to null
  (production behaviour unchanged). It exists only so the feature test can choose a folder without
  ever touching the real `%APPDATA%\Asa\settings.json` — the alternative was a feature test that
  overwrites whatever folder a real person has already chosen there, which is worse.
- **`parseFrontmatter` now skips indented lines.** Needed so `links:`'s nested list (parsed
  separately by `parseLinks`) does not also get read as flat top-level keys by the existing parser.
  No real file exercises this today, but the existing flat parser would otherwise silently invent
  keys like `- relates to` the moment anyone adds a `links:` block.
- **`Decision.why`/`.decision`/`.whatWouldChangeThis` are `''` when absent, not a placeholder.**
  Matches how `project.dart` treats the five new absent-tolerant fields, and there is no screen
  yet for a placeholder string to be honest or dishonest on.

**Surprised us — where the spec was wrong about reality:**

- **Most real ADR files have no section literally named `## Why`.** Checked all eight files in
  `asa/decisions/`: only 0001 and 0002 have an exact `## Why` heading. 0003 has
  `## Why the toggle is off by default`; 0007 has two "Why ..." headings, neither literally "Why";
  0004, 0005, 0006, 0008 have none at all. The parser only matches an exact heading — anything
  looser risks guessing which prose is "the why," which rule 8/criterion 2 explicitly bans. The
  practical effect: most decisions currently show an empty *why* on screen. That is the file
  disagreeing with the template it is supposed to follow, not a parser bug — flagged rather than
  papered over, per this session's instructions.
- **`## What would change this` is absent from `0004` and `0006`**, both accepted, real decisions
  — not the "one of five" the spec's template implied. Confirmed absent-tolerant handling matters
  more in practice than the spec's own phrasing suggested.
- **The real header line packs more than Date and Status.** `partner-trial-process/decisions.md`
  puts `**Decided by:** Nico` on the *same line* as Date and Status
  (`**Date:** ... - **Status:** accepted - **Decided by:** Nico`). A first implementation that cut
  status off only at `**Status:**` would have wrongly captured `"accepted - **Decided by:** Nico"`
  as the status text. Fixed before it shipped: the cutoff is now "the next `**Field:**` marker,
  whichever field that is," not "the next occurrence of `**Status:**` specifically." Caught by
  tracing a real fixture by hand, not by running a test suite I do not have permission to run.
- **`links:` has no real usage anywhere yet** — the only example is illustrative text inside
  `asa/decisions/0008-project-links.md`'s body, not a real project's frontmatter. `parseLinks`
  follows that shape unchecked against an actual file; it is the one piece of this contract rule 8
  could not apply to, because there is no real payload yet.
- **Six occurrences of the owner's username, not the "three lines" `CLAUDE.md` rule 16 names** —
  `projects_screen.dart:20` (1) plus `project_test.dart` (2, same literal on two lines). Both
  removed: the screen no longer has a hardcoded default, and the test fixtures use
  `C:\Users\test\...`.

**Left undone, and whether it blocks anything:**

- **`check.ps1` has not been run.** This session does not run `flutter` or `git` (hard rule 3) —
  Nico runs it. **Expect it red on the first pass**, per `HANDOVER.md`'s own framing: turning on
  `very_good_analysis` + the three `strict-*` modes + `--fatal-infos` on code written before the
  dial existed (all of Round 0–2) will surface findings in files this session did not touch
  (`git_state.dart`, `main.dart`, `projects_scan.dart`). `dart format` has also never run against
  the new files. **Blocks:** the "before it is called done" checklist, and the commit gate
  (`.claude/hooks/gate-commit.ps1`) until a passing run is recorded.
- **`very_good_analysis: ^7.0.0` in `pubspec.yaml` is an unverified guess** — this session cannot
  run `flutter pub get` to confirm the constraint resolves against the `^3.13.1` SDK. If it does
  not, that is the first thing `check.ps1` will fail on, before analysis even starts.
- **The integration test is unverified.** `integration_test/app_test.dart` was written and traced
  by hand against the parser and widget code, but never executed — this session cannot run
  `flutter test integration_test`. It may need adjustment once it actually runs (timing, widget
  finders, or `integration_test`'s Windows-desktop setup, which this session has not confirmed
  works out of the box).
- **`v0.1-decisions.md`'s "Files expected to change" table is now stale** on the `project.dart`
  point above; not corrected in `projects\`, since this session writes nothing there. Worth a note
  from whoever next opens that file.
- **No attempt made to pre-satisfy `very_good_analysis`'s `public_member_api_docs`** or similar
  documentation-coverage lints beyond normal doc comments — several public fields (e.g.
  `Decision.number/title/date/status`) have no individual doc comment. Left for the first
  `check.ps1` run to enumerate rather than guessed at.
- **`check-shareable.ps1` and `collect-feedback.ps1` were not run** — no commit has been made this
  session for them to gate.

### 2026-09-02, later the same day — first `check.ps1` run, worked through live

**Not an end-of-session note — appended mid-session, because Nico asked this file be used that
way: a place to reach the building session for a second opinion, not only a place read after the
session ends.** Recorded here so the practice itself is visible to whoever reads this next, not
just this one instance of it.

**What happened:** Nico ran `dart format`, `flutter analyze --fatal-infos`, `flutter test
--coverage`, `flutter test integration_test` by hand and pasted the output back. First run: 134
analyzer findings (2 `warning`, 132 `info`), 2 real test failures, `integration_test` never
reached. Worked through it live rather than waiting to be asked:

- **2 real test failures**, both in `decisions_reader_test.dart`'s `sortDecisionsNewestFirst`
  group — my own test fixture used a heading shape (`# ADR - $title`, the word "ADR" with no
  number) that matches neither real contract, so the parser correctly left the dash in the title
  instead of stripping it. Fixed the fixture, not the parser — that shape does not occur in either
  real project.
- **2 `warning`s** — `MaterialPageRoute`'s type argument could not be inferred at both call sites
  (`project_screen.dart`, `projects_screen.dart`). Fixed: `MaterialPageRoute<void>`.
- **The other 132 `info` findings, categorised and fixed one category at a time** — import style
  (`always_use_package_imports`, `directives_ordering`), constructor/parameter ordering
  (`sort_constructors_first`, `always_put_required_named_parameters_first`), synchronous file
  checks (`avoid_slow_async_io`: `.existsSync()` over `await .exists()`), line length, string-quote
  style (`avoid_escaping_inner_quotes`, `use_raw_strings`), two stray dartdoc `[bracket]`
  references to names not in scope (`comment_references`), `pubspec.yaml` dependency order. One
  deliberate suppression: `decisions_reader.dart`'s `DecisionSource` is flagged by
  `one_member_abstracts` for having exactly one method — that shape is what this file's own spec
  section required, for Open/Closed reasons, so it carries `// ignore: one_member_abstracts` with
  the reason written next to it, not a rewrite that would remove the seam the spec asked for.
- **`public_member_api_docs`** — ~63 of the 134 findings, one rule. Asked Nico rather than guessing:
  wrote up the tradeoff (a doc comment restating a field name is worse than silence — it goes stale
  the moment the field is renamed — and the codebase's own habit is already comment-the-why,
  stay-quiet-otherwise) and gave three options. **Decided: off, everything else stays on.** Recorded
  as **ADR 0009** (`projects\asa\decisions\0009-lint-strictness.md`), including the test for any
  future rule-off — *does this rule catch a class of mistake that could hurt the project?* — which
  is the reusable part, not the one-off answer. `analysis_options.yaml` now carries
  `public_member_api_docs: false` with that reasoning inline and a pointer to the ADR.
- **One finding this session had missed on the first pass**, found only by re-deriving the full
  134-item list by hand to check the count Nico asked for: `avoid_escaping_inner_quotes` on
  `project_test.dart:149` (an escaped `\'` inside a single-quoted string). Fixed the same way as
  the other two instances of it — switched the outer quote to `"`.

**Reconciled count, reconstructed by hand against the original 134-line output — not from a fresh
run, since this session still does not run `flutter`:** every non-`public_member_api_docs` finding
from that run is now addressed (63 were the disabled rule; the other 71 are fixed, including the
one missed on the first pass). **Zero known outstanding findings from that snapshot.** This is a
reconstruction, not a verification — the edits above (mostly mechanical reordering) have not
themselves been run through the analyzer, so there is a real chance one of them introduces a
finding that was not visible before. **The next `check.ps1` run is what actually confirms this**,
including whether `very_good_analysis: ^7.0.0` resolves at all (still unverified — see above) and
whether `integration_test` runs cleanly (still never executed).
