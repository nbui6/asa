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

## Where the process lives

The playbook, the roadmap and the retrospective log are outside this repo, in the Obsidian
vault: `Vibe Coding/PLAYBOOK.md`, `Vibe Coding/projects/asa/`, and `vibe-coding-kit/KIT-LOG.md`.
`asa.md` in that vault is the project's own note, and Asa reads it like any other project.
