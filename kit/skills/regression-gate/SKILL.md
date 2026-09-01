---
name: regression-gate
description: Turn the project's pass/fail command into a blocking gate that grows with every bug — what must be in it, how to keep it fast, how to make it run automatically, and what to do when it goes red. Use this when a bug comes back, when a change breaks something unrelated, when the test suite has become slow or is being skipped, when setting up continuous integration or a pre-commit hook, or when a project has more features than one person can re-check by hand. Also use when deciding whether a check should block or only warn. Do not use it to create a project's first pass/fail command where none exists yet (that is first-test).
---

# The regression gate

> Not to be confused with the **handover check** (`PLAYBOOK.md` §8), which is the three lines
> that accompany every handover. This is the automated pass/fail run.

A **regression** is something that used to work and stopped. It is the failure mode that grows
with the project: at one feature you notice immediately, at twenty you find out from a user.

The regression gate is the same pass/fail command from day one, promoted from a habit to a rule: **nothing
merges while it is red.**

---

## What goes in the regression gate

What is worth testing — and what is not — is the `first-test` skill's job. This is what changes
once the gate **blocks**, in value order. The first item matters more than the rest combined.

**1. A test for every bug that was ever fixed.** Written when the bug is found, ideally before
the fix so you watch it fail and then pass. This is what makes the gate grow in exactly the
places your project actually breaks — no guessing about what to test.

**2. The core loop, end to end.** One slow test that walks the main path a user takes. Catches
wiring failures that no unit test sees.

**3. Logic with rules, and the boundaries.** See `first-test` for what qualifies.

**4. The architecture rule.** The dependency-direction lint belongs in it too — a broken
boundary is a regression, just a structural one.

Not in it: layout and appearance (a human looks at those), and anything you would delete
next week.

---

## Blocking or warning?

Make it explicit for each check, and keep the blocking list short.

| Blocks | Warns |
|---|---|
| Tests fail | Style and formatting |
| The build fails | Coverage moved |
| A secret is detected | A dependency is out of date |
| The dependency rule is violated | A slow test got slower |

**A blocking check that people routinely override is worse than a warning**, because it teaches
everyone to override checks. If something is being overridden every week, either fix it or demote
it honestly.

---

## Keep it fast, or it stops running

Speed is not a nicety — it decides whether the gate is used.

- **Under a minute locally.** Past a few minutes people stop running it before committing, and
  it moves from prevention to archaeology.
- **Split it** when it grows: a fast set on every commit, the slow set before merge or nightly.
- **A flaky test is worse than no test.** It trains everyone to re-run and ignore. Fix it or
  delete it the same day — never leave it failing intermittently.

---

## Make it run without being remembered

Instructions are advisory. Escalate as the project grows:

1. **In the acceptance criteria.** Every session's machine line names the command.
2. **A pre-commit hook.** Runs the fast set before a commit is created.
3. **An agent hook.** Blocks the assistant from ending a turn until the command passes.
4. **Continuous integration.** The gate runs on a server for every change, so it cannot be
   skipped by a tired human at 23:00.

Add these in that order, when the previous one starts being skipped. Do not start at 4.

---

## When it goes red

**Red means stop.** Not "carry on and fix it later" — a gate that stays red for a day stops being
a gate, and everything committed while it was red is now unverified.

1. **Is the test wrong, or the code?** Sometimes the behaviour changed on purpose and the test
   is out of date. Say which one it is out loud — silently editing a test to pass is how a suite
   becomes decoration.
2. **What changed?** `git diff` against the last green state. This is why small commits pay.
3. **One hypothesis at a time.** See the `debugging` skill, and the two-strike rule.
4. **Revert if the fix is not quick.** Getting back to green is more important than being right
   tonight. A revert is one commit, and the branch keeps your work.

---

## What the regression gate cannot tell you

It proves the things you thought of still work. It cannot tell you the feature is wrong, badly
designed, or unwanted — that is the human line of the acceptance criteria and `persona-check`.

Green tests and no users is still failure. It protects what you have; it does not tell you
whether what you have is worth protecting.


---

## Turning "strict analysis, a formatter, tests" into actual commands

*Added after the first outside test, 2026-08-30. A founder told to "run static analysis at the
strictest level, plus a formatter, plus tests" **cannot act on that** — it is advice in a language
they do not speak. The mapping is a few lines per stack, it is stable, and every project needs it.*

| Stack | Strict analysis | Formatter | Tests |
|---|---|---|---|
| **Dart / Flutter** | `dart analyze --fatal-infos --fatal-warnings`, plus a strict `analysis_options.yaml` | `dart format --set-exit-if-changed .` | `flutter test` |
| **TypeScript / Node** | `tsc --noEmit` with `"strict": true`, plus `eslint . --max-warnings 0` | `prettier --check .` | `npm test` |
| **Python** | `ruff check .` and `mypy --strict` | `ruff format --check .` | `pytest -q` |
| **Go** | `go vet ./...` (and `staticcheck ./...`) | `gofmt -l .` — any output is a failure | `go test ./...` |
| **Rust** | `cargo clippy -- -D warnings` | `cargo fmt --check` | `cargo test` |
| **C#** | `dotnet build -warnaserror` | `dotnet format --verify-no-changes` | `dotnet test` |

**Two things this exposes, both worth the five minutes:**

1. **A framework's starter config is the baseline, not a strict standard.** On the project this came
   from, the linting config was the framework's default and had been treated as equivalent to strict
   for months. **Check which one you have before believing you are covered.**
2. **`--max-warnings 0` and `--set-exit-if-changed` are the whole point.** A check that prints
   warnings and exits 0 is not a gate; it is a newsletter.

## Continuous integration — the same discipline, minus the remembering

A hook lives on **one laptop**. It does not survive a different machine, a collaborator, or a pull
request — and **the person working alone with an assistant is exactly the person who most needs a
check that does not depend on remembering.** The hook and CI are the same discipline: one is
skippable and one is not.

The minimum is three commands on every push — **analysis, formatting, tests** — in that order,
because a compile error makes every test result meaningless.

### But the checks worth the most are usually not the standard three

**Ask what fails silently in this project, and gate that.** From the same test, two examples that a
generic CI template catches neither of:

- **Generated code gone stale** — a source file edited without re-running its generator. The
  analyser cannot see it; it surfaces as a dozen compile errors in someone's hands.
- **A key missing from one language file** — invisible while testing in the language you speak, and
  it appears as untranslated text in front of the person who cannot read it.

Both had already cost real time. Neither is exotic; both are one line in a pipeline **once somebody
asks the question.** So the guidance is not *"add CI"* — it is:

> **What breaks here without anyone noticing? Gate that first, then add the standard three.**
