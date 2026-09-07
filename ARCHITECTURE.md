# Architecture — Asa

One page. Updated in the same commit as any change that adds, moves or removes a part.
Last checked against the folder tree: 2026-09-04.

---

## In one sentence

A Windows desktop app that reads project state out of plain markdown files and out of git, and
shows it. It writes only structured fields, never prose.

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
| Asa writes only structured fields, never prose | Review. `settings.dart` is the one thing that writes, and it writes Asa's own settings file — never a project note. |

## Where things live

| I need to… | It lives in |
|---|---|
| change what the projects list shows, the home screen, or the folder picker | `lib/hubs/product/projects_screen.dart` |
| change what one project's detail screen shows, or its tabs | `lib/hubs/product/project_screen.dart` |
| change what a single decision's detail screen shows | `lib/hubs/product/decision_detail_screen.dart` |
| change which folders count as projects, or the staleness sort and labels | `lib/core/projects_scan.dart` |
| change how frontmatter is parsed, including `parent`/`priority`/`deadline`/`jira`/`links` | `lib/core/project.dart` |
| change how the one-line description is derived from a note's body | `lib/core/project.dart`'s `deriveDescription` |
| change how a project note is found on disk | `lib/core/project_reader.dart` |
| change what git is asked, or how failures read | `lib/core/git_state.dart` |
| change how one decision (an ADR file, or one log section) is parsed | `lib/core/decision.dart` |
| change how decisions are found on disk, or their merge and sort order | `lib/core/decisions_reader.dart` |
| change where or how Asa's own settings are read or written | `lib/core/settings.dart` |
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
| Writing to any project note | `settings.dart` writes Asa's own settings file. `projects\` is never written to. ADR 0007, which would allow writing structured fields into a project note, is proposed and not accepted. | ADR 0007 being accepted |
| A database | The markdown files are the database | Nothing foreseeable |

## Known differences between this map and reality

*(none — this map was updated in the same commit as v0.1)*
