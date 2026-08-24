# Architecture — Asa

One page. Updated in the same commit as any change that adds, moves or removes a part.
Last checked against the folder tree: 2026-08-24.

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
```

## Rules, and how each is enforced

| Rule | Enforced by |
|---|---|
| **`core/` never imports Flutter** | The tests. `test/project_test.dart` and `test/projects_scan_test.dart` import `core/` directly — if Flutter leaked in, it would still compile but core would stop being testable without a widget harness. Checked by eye at each checkpoint. |
| `hubs/` may import `core/`. Never the reverse, never each other. | Review, for now. A lint is the trigger at the second hub. |
| Asa writes only structured fields, never prose | Review. There is no writing code yet. |

## Where things live

| I need to… | It lives in |
|---|---|
| change what the projects list shows, or the home screen | `lib/hubs/product/projects_screen.dart` |
| change what one project's detail screen shows | `lib/hubs/product/project_screen.dart` |
| change which folders count as projects, or the staleness sort and labels | `lib/core/projects_scan.dart` |
| change how frontmatter is parsed | `lib/core/project.dart` |
| change how a project note is found on disk | `lib/core/project_reader.dart` |
| change what git is asked, or how failures read | `lib/core/git_state.dart` |
| add a hub | `lib/hubs/<name>/`, and one line in `main.dart` |

## Where a new thing goes

| Kind | Goes in |
|---|---|
| A new hub | `lib/hubs/<name>/` |
| Logic with rules in it | `lib/core/`, with a test |
| Anything that reads the outside world | `lib/core/`, returning a result object that carries the error and the raw output |

## What deliberately does not exist

| Not here | Why | What would change it |
|---|---|---|
| A state-management package | Two screens, each with its own `setState`. The list passes a folder path to the detail screen and shares nothing else. | State that two screens both write |
| A YAML package | The frontmatter is a flat list of strings. Ten lines of code beats a specification to learn. | Nested frontmatter, if it ever appears |
| Any writing to files | Rounds 1 and 2 only read. Writing arrives with quick capture. | Round 4 |
| A database | The markdown files are the database | Nothing foreseeable |

## Known differences between this map and reality

*(none — this map was written with the code)*
