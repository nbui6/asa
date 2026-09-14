# Architecture — Asa

One page. Updated in the same commit as any change that adds, moves or removes a part.
Last checked against the folder tree: 2026-09-14 (Round 27 — the Plan tab).

---

## In one sentence

A Windows desktop app that reads project state out of plain markdown files and out of git, and
shows it. It writes structured fields to its own settings, and — since ADR 0011 — may append one
dated, append-only verdict section to a decision file. It never edits, deletes, or reorders
anything that already exists on disk.

## The layers

```
main.dart        ← the shell: theme, which hub is shown
     ↓
hubs/            ← one folder per hub. Only `product` exists.
     ↓
core/            ← reading files and git. Imports nothing above it.

local/           ← someone else's fork. EMPTY HERE, AND IT STAYS EMPTY.
                   May import core/ and hubs/. Nothing imports it but the
                   one registration point. Planned for v0.1.1.
```

## Rules, and how each is enforced

| Rule | Enforced by |
|---|---|
| **`core/` never imports Flutter** | The tests. Every file in `test/` (except `widget_test.dart`) imports `core/` directly — if Flutter leaked in, it would still compile but core would stop being testable without a widget harness. Checked by eye at each checkpoint. |
| `hubs/` may import `core/`. Never the reverse, never each other. | Review, for now. A lint is the trigger at the second hub. |
| **`lib/local/` is empty in this repository.** It exists so a fork has somewhere to put its own screens that our releases never touch. | `check-shareable.ps1` — a non-empty `local/` here means someone else's work has arrived in our repo, which is a leak. *Planned for v0.1.1; not built yet.* |
| **`core/`'s public surface is a contract with a second developer.** Renaming a public field breaks someone else's build. | The release note names what moved in `core/`. See `projects\asa\decisions\0010-second-developer-and-forks.md`. |
| **A decision file's existing bytes are never modified, deleted or reordered — only appended to.** | `decision_writer.dart`'s `appendVerdict`: read, concatenate, write to a temp file, rename over the original. A feature test asserts the file's content before the new section is byte-identical to what it was. See `projects\asa\decisions\0011-append-only-verdicts.md`. |
| **A project note's `## Tasks` section may be written to — checkbox lines and their order, nothing else in the file.** ADR 0007 (accepted 2026-09-01) whitelists exactly this. | `task_writer.dart`: `setTaskDone`, `markAllTasksDone` (2026-09-07), `captureTask`, `moveTask` (2026-09-13). Every one matches or replaces a specific line and rewrites nothing else; a feature test per function round-trips a real file whose other bytes must come back untouched. |
| **A project note's frontmatter may be written to — five named fields, nothing else.** ADR 0007's own whitelist, in code: `parent`, `status`, `priority`, `deadline`, `jira`. Ten fields re-decides the ADR rather than extending it. | `project_writer.dart`'s `setProjectField` — refuses any other field with a `StateError`; refuses on drift (the frontmatter changed on disk since it was read); a round-trip test per field. |
| **Every write in `core/` is logged — what, when, which file, what it was, what it became.** ADR 0007 guardrail 3, unmet for twelve days after the ADR was accepted. | `write_log.dart`'s `appendWriteLogEntry`, append-only, in `%APPDATA%\Asa\write-log.jsonl` next to `settings.json` — never inside `projects\`. Every function in `task_writer.dart` and `project_writer.dart` calls it after a successful write. |
| Every other write stays structured fields only, never prose | Review. `settings.dart` writes Asa's own settings file — never a project note. |

## Where things live

| I need to… | It lives in |
|---|---|
| change what the projects list shows, the home screen, or the folder picker | `lib/hubs/product/projects_screen.dart` |
| change what one project's detail screen shows, or its tabs | `lib/hubs/product/project_screen.dart` |
| change what a single decision's detail screen shows, or the accept/reject "Your call" UI | `lib/hubs/product/decision_detail_screen.dart` |
| change which folders count as projects, or the staleness sort and labels | `lib/core/projects_scan.dart` |
| change how frontmatter is parsed, including `parent`/`priority`/`deadline`/`jira`/`links` | `lib/core/project.dart` |
| change how the one-line description is derived from a note's body | `lib/core/project.dart`'s `deriveDescription` |
| change how a project note is found on disk | `lib/core/project_reader.dart` |
| change what git is asked, or how failures read | `lib/core/git_state.dart` |
| change how one decision (an ADR file, or one log section) is parsed | `lib/core/decision.dart` |
| change how decisions are found on disk, their merge and sort order, or the "Needs a look" / "Settled" trial grouping | `lib/core/decisions_reader.dart` |
| change how `sketches\APPROVED.md`'s three tables (approved, trial, rejected) become decisions beside the ADRs | `lib/core/decisions_reader.dart`'s `SketchApprovalsSource` |
| change where or how Asa's own settings are read or written | `lib/core/settings.dart` |
| change how a verdict is appended to a decision file, or re-read afterward | `lib/core/decision_writer.dart` |
| change how a project's `## Tasks` section is checked off, marked all done, captured into, or moved between files | `lib/core/task_writer.dart` |
| change how a project's five whitelisted frontmatter fields are written | `lib/core/project_writer.dart` |
| change what gets logged for a write, or where the write log lives | `lib/core/write_log.dart` |
| change how the inbox — `HOME.md`'s own unfiled `## Tasks` — is read | `lib/core/inbox.dart` |
| change the quick-capture box or the unfiled list on the front page | `lib/hubs/product/inbox_panel.dart` |
| change how a project's `## Roadmap` is parsed into milestones (Rounds), the derived "current milestone", or how `###` headings group milestones into phases | `lib/core/roadmap.dart` |
| change the segmented progress bar itself (its look, its fill logic) | `lib/hubs/product/phase_bar.dart` |
| change how a project's plan (`PLAN.md` plus `plan\*.md`, ADR 0021) is read, its headings split into sections, or its derived `[[wikilink]]`/ADR/Round links found | `lib/core/plan.dart` |
| change how any `##`/`###` heading is split into a heading-plus-body pair for a file whose headings are not known by name in advance | `lib/core/markdown.dart`'s `parseSections` |
| change what the Plan tab shows — "what changed," the collapsible outline, the Strategy pointer | `lib/hubs/product/plan_view.dart` |
| change how a project's Tasks group sorts first when reached from its own project screen | `lib/hubs/product/tasks_view.dart`'s `pinnedProjectName` |
| add a hub | `lib/hubs/<name>/`, and one line in `main.dart` |

## Where a new thing goes

| Kind | Goes in |
|---|---|
| A new hub | `lib/hubs/<name>/` |
| Logic with rules in it | `lib/core/`, with a test |
| Anything that reads the outside world | `lib/core/`, returning a result object that carries the error and the raw output |
| A new decision format | A new `DecisionSource` implementation in `lib/core/decisions_reader.dart` — neither `AdrFolderSource` nor `DecisionLogSource` needs to change |

## What deliberately does not exist

| Not here | Why | What would change it |
|---|---|---|
| A state-management package | Every screen has its own `setState`. A folder path or a `Decision` passes down through a constructor; nothing is shared any other way. | State that two screens both write |
| A YAML package | The frontmatter is a flat list of strings, plus one small hand-rolled reader for `links`' nested list (`project.dart`'s `parseLinks`). Ten lines of code beats a specification to learn. | Frontmatter nesting beyond one list |
| A folder-picker package | `projects_screen.dart`'s "Choose folder…" reuses the existing path `TextField` rather than a native OS dialog — the acceptance criterion is "choose a folder without editing source," not "browse for one." | If pasting a path proves too rough for the teamlead's first run |
| Editing, correcting or reformatting anything already in a decision file | ADR 0011 allows *appending* one verdict section — never touching a byte that was already there. The stale `**Status:** proposed` header is deliberately never corrected; `Decision.displayStatus` overrides it for display instead. | Reported as a real, recurring point of confusion, per ADR 0011's own "what would change this" — its own separate ADR, not a quiet widening of this one |
| A database | The markdown files are the database | Nothing foreseeable |

## Known differences between this map and reality

**Corrected 2026-09-13.** The row above used to read "Writing anything at all to a project's own
notes (not its decisions) — ADR 0007 is proposed and not accepted." ADR 0007 was accepted
2026-09-01, and `task_writer.dart` has written checkbox lines to project notes since 2026-09-07 —
this page simply was not updated in that commit. Found while adding `captureTask`/`moveTask` for
the inbox; fixed here rather than left for whoever notices next.

**Resolved 2026-09-13 (Round 19):** the line above flagged that ADR 0007's guardrail 3 — "every
write is logged" — had no implementation. `write_log.dart` now exists and every writer in
`task_writer.dart` and `project_writer.dart` calls it. The Log tab itself (the guardrail's other
half, "shown on a Log tab") is still unbuilt — that is Round 21, deliberately sequenced after this
one, not part of it.

**Corrected 2026-09-13, second time this round: `roadmap.dart` had no row on this page at all**,
since whichever commit added it (2026-09-07/08) never updated this file either — the same class of
drift as the ADR 0007 row above, just a different file. Added its row now.

**Found and fixed 2026-09-13 while building phases:** `markdown.dart`'s shared section reader
stopped a `##` section at the next heading of **any** level, `#` through `######`. Harmless while
nothing nested a `###` inside a `##` section — no real decision file did — but it silently broke
the moment `roadmap.dart` needed `### Foundation`-style phase headings living inside `## Roadmap`:
the `###` was read as ending the roadmap section, not as part of it. Fixed to stop only at a
heading of the same level or shallower; checked every existing test fixture across the repo first
and confirmed none relied on the old, incorrect boundary.

**Found 2026-09-13, Round 20:** the spec for making the five ADR-0007 fields editable said all
five were "already shown" on `project_screen.dart`. Checked the actual file first: only `status`
was — `parent`, `priority`, `deadline` and `jira` render on `ProjectsView`'s row instead, and
`parent` was not displayed anywhere at all. Asked Nico directly rather than guess past it; his
answer was to add the missing four to `project_screen.dart`'s Details tab as plain rows, then make
all five editable there. That is what got built — this page's own "where things live" row for
`project_screen.dart` did not need a change, since "what one project's detail screen shows" already
covered the addition.
