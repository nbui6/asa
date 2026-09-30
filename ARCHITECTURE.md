# Architecture — Asa

One page. Updated in the same commit as any change that adds, moves or removes a part.
Last checked against the folder tree: 2026-09-29 (Round 42, ADR 0039 — the Tasks view rebuilt
around a new reader, `lib/core/tasks_board.dart`; the old `lib/core/tasks_reader.dart` and its
test are deleted, not just superseded, once nothing imported it any more.
`lib/hubs/product/ui/task_row.dart` grew four optional slots (`leading`, `textChild`, `onTapText`,
`trailing`) so the rebuilt screen's own drag handle, click-to-edit field, and indent buttons could
still go through the one shared checkbox rather than building their own).

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
  product/ui/    ← Round 37, ADR 0029: the only place a colour, text size,
                   spacing value or date format lives, and every small
                   part (pill, chip, panel, row, progress bar) used by more
                   than one page. Every other file under `hubs/product/`
                   composes these and writes none of its own — enforced by
                   `test/one_look_test.dart`.
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
| **An area page's `## Tasks` section may *also* be written to — checkbox state only, `[ ]` ↔ `[x]`, nothing else.** Round 34 F, ADR 0021's 2026-09-26 amendment — `PLAN.md` and `CHARTER.md` still may never be written to. | Reuses `task_writer.dart`'s existing `setTaskDone` unchanged, called against an area's own `sourceFile` instead of a project note's — `project_screen.dart`'s `_toggleAreaOrHomeTask`, `projects_screen.dart`'s `_toggleAreaTask`. Proven against a real temp file: exactly one line changes, the write log gets an entry. |
| **A project note's frontmatter may be written to — five named fields, nothing else.** ADR 0007's own whitelist, in code: `parent`, `status`, `priority`, `deadline`, `jira`. Ten fields re-decides the ADR rather than extending it. | `project_writer.dart`'s `setProjectField` — refuses any other field with a `StateError`; refuses on drift (the frontmatter changed on disk since it was read); a round-trip test per field. |
| **Every write in `core/` is logged — what, when, which file, what it was, what it became.** ADR 0007 guardrail 3, unmet for twelve days after the ADR was accepted. | `write_log.dart`'s `appendWriteLogEntry`, append-only, in `%APPDATA%\Asa\write-log.jsonl` next to `settings.json` — never inside `projects\`. Every function in `task_writer.dart` and `project_writer.dart` calls it after a successful write. |
| Every other write stays structured fields only, never prose | Review. `settings.dart` writes Asa's own settings file — never a project note. |
| **No page file under `lib/hubs/product/` (everything except `ui/` itself) writes its own `Color(0x…)`, `fontSize:`, `Card(`, `.toUpperCase()` or `BoxShadow`.** Round 37, ADR 0029 — one look everywhere, one file of tokens, one set of parts. | `test/one_look_test.dart` — reads every such file as plain text and fails the build the moment one of those patterns reappears outside `ui/`. |

## Where things live

| I need to… | It lives in |
|---|---|
| change what the projects list shows, the home screen, or the folder picker | `lib/hubs/product/projects_screen.dart` |
| change what one project's detail screen shows, or its tabs | `lib/hubs/product/project_screen.dart` |
| change what a single decision's detail screen shows, or the accept/reject "Your call" UI | `lib/hubs/product/decision_detail_screen.dart` |
| change which folders count as projects, the staleness sort and labels, a project's derived `lastTouched` (git's last commit, else the newest file mtime in its folder), or how its areas are read at scan time | `lib/core/projects_scan.dart` |
| change the right-hand freshness value a row shows (a deadline, or `today`/`1 day`/`N days` since the project was last actually touched) | `lib/core/freshness.dart` |
| change how a project's next step is derived — the home note's first open, unparked task; else the first open task of the first area with one (Round 34/E); else the typed field; else "no next step" (ADR 0020) — or how the status pill's colour bucket is chosen | `lib/core/project_row.dart` |
| change the exact text the "Start → Copy opener" action puts on the clipboard | `lib/core/opener.dart` |
| change how an area (`plan\<area>.md`: goal, plan, tasks, results, decision/objective numbers, progress) is parsed, or how an area's name and sort order come from its filename | `lib/core/area.dart` |
| change how a project's areas are found on disk | `lib/core/area.dart`'s `readAreas` (raw `dart:io`) / `readAreasVia` (through `FileAccess`, for a caller that fakes the disk in its own tests) |
| change the "Start" menu itself (copy opener, open folder, open code in VS Code) shown on a project row or the project screen's header | `lib/hubs/product/start_menu.dart` |
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
| change the segmented progress bar itself (its look, its fill logic) | `lib/hubs/product/ui/phase_bar.dart`, drawing its segments through the shared `lib/hubs/product/ui/progress_bar.dart` |
| change how a project's plan (`PLAN.md` plus `plan\*.md`, ADR 0021) is read, its headings split into sections, or its derived `[[wikilink]]`/ADR/Round links found | `lib/core/plan.dart` |
| change how any `##`/`###` heading is split into a heading-plus-body pair for a file whose headings are not known by name in advance | `lib/core/markdown.dart`'s `parseSections` |
| change how a result names its own task and links to a file/folder/page (`· task: … · [label](target)`), or how a decision's own `**Links:**` line does the same (`Task:`/`File:`) | `lib/core/area.dart`'s `AreaResult`/`ResultLink`/`parseResultsSection`, `lib/core/decision.dart`'s `DecisionLinks.tasks`/`.files` |
| change how a task finds its own result/decision, or a result/decision finds its own task ("derived both ways") | `lib/core/task_links.dart` |
| change how ticking a task writes its own dated result line (Round 43 §A/§B, ADR 0042) | `lib/core/result_writer.dart`'s `writeResult` |
| change how a brand new decision is created — which of the two real shapes (`decisions\NNNN-slug.md` or one `decisions.md` log) it lands in, the next number, the slug | `lib/core/decision_create_writer.dart`'s `createDecision` |
| change the shared name→filename-slug rule an area, a decision or a new project's own folder all use | `lib/core/slug.dart`'s `slugify` |
| change how a project's own home note reads a `## Results` section for an area-less task (ADR 0042) | `lib/core/project_reader.dart`, `Project.results` |
| change what the Plan tab shows — a project with any area: the area list, "Not in an area," "What this project is for," and the folded Overview row; a project with a real `PLAN.md`/`plan\` but none (`asa` today): "what changed," the collapsible outline, the Strategy pointer, unchanged since Round 27, now with the Next line above it; a project with **neither** `PLAN.md` nor `plan\` at all (round 36 cp8 — 12 of 13 real projects): the Next line, "What this project is for" if there's a real Strategy, home tasks under "Not in an area" (open by default, the only row), and a quiet "No areas yet" pointer | `lib/hubs/product/plan_view.dart`'s `build`/`_noPlanBody`/`_legacyBody` |
| change the Tasks view's own left rail (⭐ Next up · 📥 Inbox · every visible project with its own open count), which project opens on arrival, add-anywhere / edit-in-place / drag-to-reorder-or-move, the per-project done-task fold, or the small "Code tasks" filter menu (§B — replaces the old inline `FilterChip`, hides every `(Code)` task everywhere on the screen, on by default) | `lib/hubs/product/tasks_view.dart` — Round 42, ADR 0039, replaces the old flat "every project, all its tasks, nested" view |
| change how one project's own tasks are read for the Tasks view — home note plus every area, even one with zero tasks so far — or how "Next up" picks one task per project | `lib/core/tasks_board.dart`'s `buildProjectTasksSnapshots`/`ProjectTasksSnapshot`, `buildNextUp`/`NextUpItem` |
| change a task's own subtask indent (exactly one level, derived from the line's own leading whitespace) | `lib/core/task.dart`'s `Task.indent`, computed by `parseTasks` |
| change how a task is added, its text edited in place, its indent set, reordered within a file, or moved to another file — each one atomic, one write-log entry (ADR 0039) | `lib/core/task_writer.dart`'s `addTaskAtTop` (bottom reuses the existing `captureTask`), `editTaskText`, `setTaskIndent`, `reorderTasks`, `moveTask`/`moveTaskToTop` |
| change how a project's strategy (`CHARTER.md`'s Origin / Who it's for / Pain points / Objectives) is read | `lib/core/charter.dart` |
| change how a Round's state (planned / in progress / waiting for approval / completed / no approval needed) is derived, or how `rounds\APPROVED.md` is read | `lib/core/round_state.dart`, `lib/core/round_approvals.dart` |
| change what the Strategy tab shows — who it's for, pain points, objectives, the segmented bar, the legend | `lib/hubs/product/strategy_view.dart` |
| change the order or presence of `project_screen.dart`'s tabs (`Plan · Strategy · Decisions · Details`) | `lib/hubs/product/project_screen.dart`'s `_Tab`/`_visibleTabs` — Plan is unconditional now (round 36 cp8, §2 a/§9: every project opens on Plan, with or without plan pages of its own) |
| change the overview's "Next" line's own text, or the closed-area-row "next <task>" label | `lib/hubs/product/plan_view.dart`'s `_nextLineRow`/`_areaNextTaskLabel`; the underlying (text, area) chain is `lib/core/project_row.dart`'s `effectiveNextStepWithArea` |
| change the overview row's own per-area bar segment | `lib/hubs/product/projects_view.dart`'s `_AreaBar` |
| change the overview's own row layout — one bordered panel per bucket (work, then a separate one for "other"), hairlines between rows, not a `Card` each | `lib/hubs/product/projects_view.dart`'s `_rowPanel`/`_card` (round 36 cp8, §9 point 3) |
| change how a project's `## Roadmap` milestone exposes the prose under its own checkbox | `lib/core/roadmap.dart`'s `Milestone.body`/`bodyLines` |
| change what a link that lands on a project carries (which area, "Not in an area", a task to highlight) | `lib/core/project_open_target.dart`'s `ProjectOpenTarget`/`openTarget` — built by `ProjectsView`/`TasksView`, consumed by `ProjectsScreen._openProject`, which passes it to `ProjectScreen`'s `initial*` constructor params (round-36 §3, L1-L9) |
| change the ~2s highlight a landed-on task briefly gets, or an area's own "Objective N" mention (round-36 §3, L3/L9/L12; round-37 §D4 — the mention is the link itself, inline in the Goal sentence, not a separate chip) | `lib/hubs/product/plan_view.dart`'s `_highlightedRawLine`/`_armHighlightTimer`, `_goalField`/`_goalText` |
| change which objective expands when `StrategyView` is asked to open one (round-36 §3, L12) | `lib/hubs/product/strategy_view.dart`'s `objectiveToOpen`/`_objectiveIndex` — keyed by the objective's own list position, not `identityHashCode` |
| change whether an ADR chip (`PlanView`'s area chip, `StrategyView`'s objective chip) opens the real decision detail screen or just the raw file | same file's own `_openDecision`/`_openAdr` — in-app when the decision is already loaded, `openUrl` fallback otherwise |
| change the area chip shown on the decision detail screen itself (round-36 §3, L17) | `lib/hubs/product/decision_detail_screen.dart`'s `areasNaming`/`onOpenArea` |
| change whether a screen's own tab body stays mounted through a reload (a checkbox tick, a manual refresh) | `project_screen.dart`/`projects_screen.dart` gate their body on `read`/`scan` being non-null, never on `_loading` too — the previous read/scan stays on screen until the new one lands, so local UI state (an open area, an expanded group) survives (round 36 cp6) |
| change whether recording a decision's verdict reloads the caller that pushed the detail screen | `decision_detail_screen.dart`'s `_verdictJustRecorded`, popped as the route's own result (`Navigator.pop(_verdictJustRecorded)`, both the back button and the area chip); each of the three pushers (`project_screen.dart`'s decision row, `plan_view.dart`'s `_openDecision`, `strategy_view.dart`'s `_openAdr`) reloads only when it comes back `true` (round 36 cp6) |
| change a colour, text size, spacing value or date format, or a small part shared by more than one page (`AsaPage`, `AsaPanel`, `AsaRow`, `AsaGroup`, `SectionLabel`, `Pill`, `LinkChip`, `AreaChip`, `TaskRow`, `ProgressBar`, `EmptyLine`, `SourceLine`) | `lib/hubs/product/ui/tokens.dart` and one file per part in `lib/hubs/product/ui/` |
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

**Resolved 2026-09-26, Round 36 cp3.** The row above named a deliberate gap after cp2: the
overview's own `ProjectSummary`/`ProjectNode` carried no area data, so `effectiveNextStep`'s area
fallback and a per-area bar segment only reached `project_screen.dart`, not the overview row. Both
now exist: `projects_scan.dart`'s `scanProjects` reads each project's areas via `readAreas` at scan
time (`ProjectSummary.areas`), carried through `buildProjectForest` onto `ProjectNode.areas`;
`projects_view.dart`'s `_card` reads its own next step with `areas: node.areas` and draws one bar
segment per area (`_AreaBar`) in place of `PhaseBar` once any exist, `PhaseBar` staying the
unchanged fallback for a project with none.

**Found 2026-09-25, Round 32, left alone on purpose:** `projects_scan.dart`'s `daysStale` /
`sortByStaleness` / `stalenessLabel` are fully unit-tested but called from no screen — `repo-path`
staleness was never wired in past its tests. Round 32/A builds `freshness.dart` alongside them
instead of retrofitting this dead code, since consolidating or removing it was outside this round's
own file list. Whoever touches staleness next should read both before choosing one.

**Found 2026-09-13, Round 20:** the spec for making the five ADR-0007 fields editable said all
five were "already shown" on `project_screen.dart`. Checked the actual file first: only `status`
was — `parent`, `priority`, `deadline` and `jira` render on `ProjectsView`'s row instead, and
`parent` was not displayed anywhere at all. Asked Nico directly rather than guess past it; his
answer was to add the missing four to `project_screen.dart`'s Details tab as plain rows, then make
all five editable there. That is what got built — this page's own "where things live" row for
`project_screen.dart` did not need a change, since "what one project's detail screen shows" already
covered the addition.

**Resolved 2026-09-27, Round 37 (ADR 0029).** The row above ("What deliberately does not exist")
had no entry for a shared UI layer, because there wasn't one: 25 private copies of basic parts, 11
font sizes, 29 hard-coded colours, and no shared folder, counted across `lib/hubs/product/` before
this round. `lib/hubs/product/ui/` now holds all of it — `tokens.dart` plus one file per part — and
every other file under `lib/hubs/product/` composes them exclusively, enforced by
`test/one_look_test.dart`. Three real defects were found and fixed in the shared parts themselves
while moving pages onto them (never worked around in a page): `AsaGroup`'s single `InkWell` would
have merged a project's name-tap with its triangle's expand/collapse; the shared `Pill` had lost the
old outlined pill's width clamp and ellipsis; `ProgressBar`'s `Stack` painted a bare `ColoredBox`
with no `Positioned.fill`, so every bar in the app — the overview's area segments, an area's own
progress, Strategy's round bar, `PhaseBar` — rendered at zero size until cp4's own screenshot review
caught it. `phase_bar.dart` moved from `lib/hubs/product/` into `ui/` alongside this same move, its
segment drawing now the shared `ProgressBar`.
