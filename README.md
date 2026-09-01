# Asa

**The findable record of what was decided on a project, why, and what came of it.**

Asa is a small Windows desktop app that reads the markdown notes and git state you already have,
and shows them back to you. It does not ask you to fill anything in.

> **Early. Version 0.1 is not finished.** Nothing here is stable, and the shape is still changing
> after each version. If you are reading this because you were invited to try it, see
> **[For testers](#for-testers)** below.

---

## What problem it solves

A decision gets made, it is correct, and it cannot be found again — so the work gets redone, and
you cannot tell in advance which part is a rerun.

Everything Asa shows is derived from files that already exist. **There is no status field to keep
up to date**, because a field that has to be maintained by hand is out of date exactly when you
need it.

## The rules it is built on

1. **Your files are the truth.** Asa is a window onto plain markdown and git. **Delete Asa
   tomorrow and nothing is lost** — everything stays readable in any text editor.
2. **Derived, not typed.** State is worked out from what is on disk.
3. **Show less.** Everything is stored; almost none of it is on screen at once.
4. **Stack-agnostic.** A project can be a Flutter app, a package deployed into someone else's
   system, or a process change with no code at all. Asa never assumes a toolchain.
5. **No AI at runtime.** Reading files, dates and git state is arithmetic. Asa does no reasoning.
6. **Nothing leaves your machine.** No server, no account, no telemetry, no network calls.

## What is in this repository

Two things, and they are shared together because they are one idea.

| | |
|---|---|
| `kit/` | **The Vibe Coding Kit** — the written process: skills, a playbook, templates, hooks and an installer. Usable entirely on its own, by someone who never runs the app. |
| the rest | **Asa** — the Windows app. *(Moving to `app/` once the current version is verified running; two unverified changes at once is how you lose a whole afternoon.)* |

**Asa shows the kit.** The process tab of a project is the kit's own steps made visible: what was
set up once, the round that repeats, what was released and what came back. The kit is not a
dependency Asa borrowed — it is most of what Asa displays.

**The rule that keeps them separable:** *Asa may depend on the kit. The kit must never depend on
Asa.* Take the `kit/` folder on its own and it works.

## Before pushing

```
powershell -NoProfile -ExecutionPolicy Bypass -File check-shareable.ps1
```

Checks every file that would be published for machine paths, email addresses, and a private term
list that is **not** in this repository. See the script's header for why.

## Running it

Requires the Flutter SDK with Windows desktop support (`flutter doctor` green for Windows) and
Visual Studio Build Tools.

```
flutter pub get
flutter run -d windows
```

The machine check, in this order — the second alone is not enough:

```
flutter analyze
flutter test
```

On first run Asa asks you to choose the folder your project notes live in. That choice is stored
in your own Windows app-data folder, never in this repository.

## For testers

**You can read this repository and run the app. You cannot commit to it** — that is deliberate,
not a lack of trust. One person and one assistant do the building, so that the record of why each
thing was decided stays in one place.

**Feedback is wanted and there is no wrong format.** A written note, a list of annoyances, a
screenshot, or a sentence saying you opened it once and never again — that last one is genuinely
useful and is the single most valuable thing you can report.

Three questions worth more than any feature request:

1. What did you expect to see that was not there?
2. What did you have to work out for yourself?
3. Did you open it a second time without being reminded to?

**Send feedback as a file or a message.** It gets recorded, and every version says which feedback
produced it.

## What Asa never holds

**No customer data. No partner data. No personal data about anyone.** Asa reads your own project
notes on your own machine. If a project note would contain any of the above, it does not belong in
a project note either.

## How it is built

Built with an assistant, using a written process: an interview before a charter, a charter before
a sketch, a sketch before a plan, and a signed plan before any code. Every decision has a file
saying why it was made.

- `lib/core/` — reading and parsing. **Imports nothing from Flutter**, so it can be tested without
  a running app, and so it could be ported off Flutter without a rewrite.
- `lib/hubs/` — the screens.
- `ARCHITECTURE.md` — where everything lives and what may depend on what.
- `CLAUDE.md` — the working rules, including the ones that exist because something went wrong.

The plan, the charter, the persona and every decision live outside this repository, in the owner's
notes. **They are the actual product; this is the window.**
