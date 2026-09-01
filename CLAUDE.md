# CLAUDE.md - Asa

**Asa is the desk for my vibe-coding projects.** It shows where every project stands, catches
ideas fast, and hands off to Claude and VS Code with the context already in place.

**Asa does not think.** Claude reasons; Asa shows, routes and queues.

One product, several hubs. Only the Product Hub exists. The others are named so the shell is
built to accept them, and naming them is the entire investment.

`ARCHITECTURE.md` is the map of the code. Read it before adding a file, and update it in the
same commit as the part it describes.

This file is ASCII only. The orient hook prints the section below into the session's opening
context, and Windows PowerShell 5.1 mangles anything else.

---

## Where we are

**Round 2 is committed and verified.** Commit `0fd717c`, 2026-08-24. Every project in the
projects folder appears on one screen, most stale first, unknown git state last and labelled.
A row opens the Round 1 detail screen.

**Verified with:** `flutter analyze` clean, `flutter test` 26 passing, and one scan against the
real projects folder (2 projects, correct order, `_to_delete` ignored, no read errors).

**Two things are open, and both are named rather than hidden:**

1. **Round 2's human line was never checked.** Nobody has looked at the running window. To
   close it: `flutter run -d windows`, expect two rows, staleness on the right, click `Asa`.
2. **Round 2's acceptance criteria were never written down.** The verification above ran
   against criteria reconstructed from `ROADMAP.md`. Rule 1 exists because of this.

**Next:** Round 3, the handoff - open the project in VS Code and put a session opener with the
current state on the clipboard. Before any code: write the criteria (rule 1).

**Last moved:** 2026-08-24

---

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

> Criteria met - handover check written - reviewed - `CLAUDE.md` updated - committed.

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
    **Two checks always run — a machine path and an email address — and the name list starts
    empty.** The repository is private and shared with people who already know the project names,
    so nothing there is secret from them; add a name only if that changes. Same shape as
    `kit/check-boundaries.ps1`, including the `-SelfTest` that proves it still catches things.
    *Two more elaborate versions were written and thrown away first — one with a hand-maintained
    list, one that derived the list from folder names, git and the private notes. Both solved a
    problem this project does not have. The second was written while the proven checker sat
    unread in the folder it had just been copied into.*

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

## At the end of every session

**Append to `HANDOVER.md`, upstream half:** what was built · **what was decided that the spec did
not cover** · what could not be done · anything changed by hand that the agreed design still shows
the old way.

That half carries the reasoning no diff contains, and it is the half that gets skipped. This line is
why it will not be.

## Where the process lives

The playbook, the roadmap and the retrospective log are outside this repo, in the Obsidian
vault: `Vibe Coding/PLAYBOOK.md`, `Vibe Coding/projects/asa/`, and `vibe-coding-kit/KIT-LOG.md`.
`asa.md` in that vault is the project's own note, and Asa reads it like any other project.
