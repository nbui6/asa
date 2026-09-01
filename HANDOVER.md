# HANDOVER.md — from the deciding session to the building session

**Lives in the repo root.** Both sessions read it; **neither writes in the other's half.**

---

## ⬇ Downstream — written by the deciding session, read before building

### Gate — read this first

| Check | State |
|---|---|
| Does this work change the structure of a screen? | **Yes** — both screens |
| Has the sketch been seen and approved by the Boss? | **Yes, 2026-09-01.** Front page: approved. Project page: approved. |
| Is the plan signed? | **Yes** — `PLAN.md`, Nico Bui, 2026-09-01 |
| Is anything sketched but **not** approved? | **Yes: the process tab (v2) is in review.** Do not build it. |

**The approved sketch is the target for the product, not for this version.** v0.1 is one step
towards it. Anything in the sketch not named below is out.

### Job zero — done 2026-09-01. What the app actually does today

It builds in 33.7 s and runs. Ten days after round 2 was committed, this was unknown.

**Projects screen** — a "Projects folder" text box with a hardcoded path and a Load button;
`2 projects — most stale first`; each row shows name, typed status, next step, milestone, and a
coloured age.

**Project screen** — a labelled table (Status · Milestone · Next step · Note updated by hand ·
Last moved (from git) · Repo), then **the source file path, the raw frontmatter, the exact git
command that was run, and its output.**

> **That provenance block is the best thing in this codebase and it must not be lost.** It is
> `PLAYBOOK.md` §7 built rather than written down — the screen shows where every value came from.
> **Everything v0.1 adds carries the same obligation: show the file it came from.**

**Three findings, all confirmed by looking:**

1. `status` is read from typed frontmatter. The charter says state is derived. **v0.2 fixes it —
   not this version.** Do not touch it now.
2. **Only two projects appear**, because only two folders have a project note. The kit and the
   German app are invisible to Asa. **This is a data gap, not a bug — do not "fix" it in code.**
3. The projects folder is a hardcoded path in a text box. **v0.1 fixes this** — see below.

### What to build — v0.1, and nothing else

**One sentence: the decisions already written in markdown become visible in Asa, and the app stops
containing anyone's username.**

#### 1. The decisions reader — `lib/core/`

**Pure Dart. No Flutter import.** That rule is what makes this portable and testable, and ADR 0005
depends on it staying true.

**Two sources, because two real formats exist and both are legitimate.** This is the second
`DecisionSource` implementation the SOLID section calls for — it is not hypothetical, it is
already on disk:

| Source | Shape | Where |
|---|---|---|
| **A folder of files** | `decisions/0001-slug.md`, one per decision, `# ADR 0001 - Title` | Asa's own project |
| **One log file** | `decisions.md`, one `## 0001 - Title` section per decision | A process project, which switched to it deliberately: *"too much file overhead for a project this size"* |

**Both are read. Neither is converted.** A project that has both is showing them merged, with the
file each came from — which is what the provenance rule already requires.

**The parse contract below is taken from real files in both formats, not invented** — check it
against them before writing anything:

| Field | Where it is | Notes |
|---|---|---|
| Number and title | First line: `# ADR 0004 — Asa is the operating layer.` | The dash is an em dash. Number may be absent — then the file has no number, which is fine. |
| Date | `**Date:** 2026-08-31` in the first five lines | **May share a line with Status**, separated by ` · `. Two of five do this. |
| Status | `**Status:** accepted` | **The value is sometimes bold and sometimes not** — `**Status:** **accepted 2026-08-22**`. Strip the markers. Values seen across two real projects: `accepted` · `accepted <date>` · `proposed — needs …` · **`superseded by 0008`** · **`accepted (supersedes 0005)`** · **`accepted (drafted by Claude, pending legal review)`**. |
| **Superseded by / supersedes** | Parsed **out of the status text** | `superseded by 0008` and `accepted (supersedes 0005)`. **Both already exist on a real project.** See criterion 8. |
| **Separator between Date and Status** | ` · ` **or** ` - ` | Asa's own ADRs use the middle dot; a second project's use a plain hyphen. **Accept both**, and do not require either. |
| Title dash | `—` **or** `-` | Same reason. `# ADR 0001 - Static serial per partner` is a real heading. |
| Why | The `## Why` section, if present | Verbatim first paragraph. **Never summarise.** |
| The decision | The `## Decision` section | **Present in 4 of 5.** The fifth has `## Recommendation`. Missing is normal — fall back to the title. |
| **What would change it** | The `## What would change this` section | **Show this. It is the highest-value field in the file** and the reason it is in v0.1: ADR 0001 listed four conditions that would invalidate it, three of them happened, and nobody noticed for ten days. |

**Every decision keeps the path of the file it came from.** Non-negotiable — see the provenance
rule above.

#### 2. The screen

Add a **Decisions** section to the project screen, below the existing table and **above** the
provenance block.

- Count in the heading: `Decisions · 5`
- One row each: **title · date · status**. Tap opens the decision.
- The decision view: title, date, status, *the decision*, *why*, **what would change it**, and the
  file path it was read from.

#### 3. The folder picker — removes the username from the source

Six lines of source contain `C:\Users\<username>\`. A second person reading this repo does not need
them, and **the hardcoded default is broken on every machine except this one.**

- First run: an empty state and a **Choose folder…** button
- Store the choice in `%APPDATA%\Asa\settings.json` — `Platform.environment['APPDATA']`, **no new
  package**
- The text box may stay, pre-filled from the saved setting
- Test fixtures use a neutral path


### Code quality — the standard, and the Dart equivalents

**Required from 2026-09-01.** The standard was given in PHP terms — PHPStan level 10, Pint,
PHPUnit — so here is the mapping to this stack. **Each of these must pass completely, not mostly.**

| Asked for | This stack | Command |
|---|---|---|
| Pint (style) | `dart format` | `dart format --set-exit-if-changed .` |
| PHPStan level 10 (max static analysis) | `flutter analyze` **with strict modes on** | `flutter analyze --fatal-infos` |
| PHPUnit (unit) | `flutter test` | `flutter test --coverage` |
| Feature tests | `integration_test` — **ships with the Flutter SDK, not a package** | `flutter test integration_test` |

**`analysis_options.yaml` — the level-10 equivalent. Add exactly this:**

```yaml
include: package:very_good_analysis/analysis_options.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_return: error
    dead_code: error
    unused_import: error
  exclude: [build/**, "**/*.g.dart"]
```

**The three `strict-*` modes are the actual equivalent of raising a PHPStan level** — they turn
implicit `dynamic`, unannotated generics and silent downcasts into errors. `--fatal-infos` makes
every hint fail the build, which is what "level 10" means in practice.

> **One new dev dependency: `very_good_analysis`.** It is a list of lint rules and nothing else —
> no runtime code, nothing shipped in the app. Explained in two sentences, as `CLAUDE.md` requires,
> and **vetoable**: without it, `flutter_lints` plus the three strict modes gets most of the way.

**One command that says pass or fail — `check.ps1` in the repo root:**

```powershell
dart format --set-exit-if-changed .   ; if ($LASTEXITCODE) { exit 1 }
flutter analyze --fatal-infos         ; if ($LASTEXITCODE) { exit 1 }
flutter test --coverage               ; if ($LASTEXITCODE) { exit 1 }
flutter test integration_test         ; if ($LASTEXITCODE) { exit 1 }
Write-Host "PASS"
```

**Order matters and it is not arbitrary.** Formatting first because it is instant; analysis before
tests because **25 green tests once ran over code that could not compile** on the sibling project,
2026-08-26. A test suite that passes over unanalysable code is measuring nothing.

### SOLID, concretely — not as a slogan

The existing `project.dart` / `project_reader.dart` split is already right: **the thing, and the
thing that fetches it, are separate files.** Follow it. What each letter means for *this* work:

| | Here |
|---|---|
| **Single responsibility** | `decision.dart` parses text into a decision. `decisions_reader.dart` finds files. **Neither does the other's job.** |
| **Open/closed** | A second decision source — a table inside a note — must be addable **without editing the ADR parser**. Define `DecisionSource` with one method; the ADR reader is the first implementation. |
| **Liskov** | Every `DecisionSource` returns the same result type, including for "unreadable". No source signals failure differently. |
| **Interface segregation** | The reader needs *list files in a folder* and *read a file as text*. **It does not need a filesystem object.** Two methods, not twenty. |
| **Dependency inversion** | `decisions_reader` takes that small interface **as a constructor argument**. Production passes the real one; tests pass an in-memory one. |

**Dependency inversion is the one that pays today:** every parser test runs with no disk, no
fixtures folder and no temp directory — fast, hermetic, and identical on your teamlead's machine.

> **The trap to avoid, and it has already happened once here.** A `const` constructor with a new
> mutable field broke the build on the sibling project while every test stayed green. **An
> interface is not free — take it only where a second implementation is genuinely coming.** Two are
> coming for `DecisionSource` (ADR files, tables in notes) and one for the file access (real,
> in-memory). **Nowhere else.** `CLAUDE.md` rule 7: boring beats clever.

### What must keep working

- **The provenance block on the project screen.** Do not restyle it, do not collapse it.
- The projects list, its sort, and its age colouring — untouched this version.
- `flutter analyze` clean, then `flutter test` green. **In that order.**
- **Nothing in `lib/core/` imports Flutter.**

### Not in this piece of work — each is a later version in `PLAN.md`

Progress bars · derived stage · any change to `status` · tabs of any kind · the process tab (**not
approved**) · parked items · links, parent/child or "shared with" · the log · the HR tab ·
priorities and deadlines · **any editing of any note — Asa reads** · any AI.

### Files expected to change

| File | |
|---|---|
| `lib/core/decision.dart` | new — the decision and the parse result |
| `lib/core/decisions_reader.dart` | new — find and read them |
| `lib/core/settings.dart` | new — read/write the chosen folder in `%APPDATA%` |
| `lib/hubs/product/project_screen.dart` | the decisions section |
| `lib/hubs/product/projects_screen.dart` | empty state and Choose folder… |
| `test/decision_test.dart`, `test/decisions_reader_test.dart`, `test/settings_test.dart` | new — unit, **no disk access** |
| `integration_test/decisions_flow_test.dart` | new — feature test: launch, choose a folder, open a project, see a decision |
| `analysis_options.yaml`, `pubspec.yaml`, `check.ps1` | the quality tooling above |
| `test/project_test.dart` | neutral fixture paths |

**`project.dart` and `projects_scan.dart` are not touched.**

### Acceptance criteria

**Human — the Boss says yes or no, once:**

1. Open Asa, click a project, see its decisions **without opening a file**.
2. Each decision shows **what, when, and why**, in the words written at the time.
3. **What would change this** is visible on a decision that has one.
4. A project with no decisions says so plainly — **no empty box, no spinner.**
5. A file that cannot be parsed is shown as **unreadable, with its path and its raw text.** Silent
   skipping is banned.
6. It reads the five real ADRs **unedited**. *If a real file must be reformatted to be read, the
   reader is wrong, not the file.*
7. A person who is not the owner can clone, run, choose a folder, and see their own projects
   **without editing source**.
8. **A superseded decision is visibly superseded in the list** — not only inside its own file, and
   it names what replaced it.

   > **This is not hypothetical and it is why it is in v0.1.** On a real project, decision 0005 is
   > superseded by 0008 and the two are about the same mechanism. **A list that shows both as
   > "accepted" will cause the wrong thing to be built.** A decisions list that misleads is worse
   > than no decisions list, and this project's whole argument is that the record can be trusted.

**Machine — run, not assumed. All four, in order:**

```
powershell -NoProfile -ExecutionPolicy Bypass -File check.ps1
```

`dart format --set-exit-if-changed` -> no diff · `flutter analyze --fatal-infos` -> clean ·
`flutter test --coverage` -> green · `flutter test integration_test` -> green.
**"Mostly passing" is failing.**

| Test | Proves |
|---|---|
| Parses each of the five real ADR shapes | The contract above, against reality |
| **Parses a `decisions.md` log with `## NNNN - Title` sections** | The second real format |
| **A project with both formats yields one merged list, each item naming its file** | The case that exists today |
| Bold and plain `**Status:**` both parse | Two shapes exist in the same folder |
| Date sharing a line with Status parses | Two of five do this |
| A missing `## Decision` falls back, does not crash | One of five |
| **`superseded by NNNN` is parsed and exposed** | Real, on a second project |
| **`accepted (supersedes NNNN)` is parsed and exposed** | Its other half |
| **A hyphen separator parses as well as a middle dot** | Two projects write it differently |
| A malformed file yields **unreadable**, not silence | Criterion 5 |
| No decisions yields an empty list, not an error | Criterion 4 |
| Settings round-trip: write, read back, missing file | The picker |
| `lib/core` imports no Flutter | The architecture rule |

### Before calling it done — `PLAYBOOK.md` §8

- [ ] Does it run?
- [ ] `check.ps1` green — **all four, completely**
- [ ] Reviewed — **the reviewer agent**
- [ ] **Reachable?** Can the Boss get to a decision from the front page without being told how?
- [ ] `check-shareable.ps1` passes — **it fails today on purpose**, and this version is what makes
      it pass.

### Where to stop, and who does what

- **Nico runs every `git` and `flutter` command, in Windows PowerShell.** Never through the
  assistant's device bridge — a subagent doing that left a stale `.git/index.lock` on 2026-08-26.
- Stop and ask if a criterion cannot be met **as written** rather than meeting a nearby one.
- Stop if the parse contract disagrees with the real files. **The files win.**

---

## ⬆ Upstream — appended by the building session at the end of every session

**Built:** <one or two lines. The diff has the detail; this is the index.>

**Decided that the spec did not say:** <the important half. The diff cannot show this.>

**Surprised us:** <anything the spec got wrong about reality.>

**Left undone:** <and whether it blocks anything.>
