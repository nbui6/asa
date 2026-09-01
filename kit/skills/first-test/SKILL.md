---
name: first-test
description: Set up the one command that says pass or fail for a project, and decide what is worth testing when you are not a developer. Use this on day one of any project, whenever someone needs a machine check for their acceptance criteria, when they ask what to test or how to write a test, or when a project has no automated checks at all. Also use when someone asks whether they need tests, or says testing feels like extra work with no payoff. Do not use it to turn an existing check into a blocking gate, or to add a test for a bug that came back (that is regression-gate).
---

# The first test

Every project needs **one command that says pass or fail**. Not a test suite. One command.

```
<test command>  →  passed / failed
```

That command is what lets a machine check your work while you sleep, and it is the thing that
makes "did I break something else?" answerable in two seconds instead of an hour.

---

## Day one, before there is anything to test

Set the command up while the project is empty. It takes five minutes then and an hour later.

Most tools ship a starter test that passes immediately — `flutter test`, `pytest`, `npm test`,
`go test ./...`. **A passing starter test is not pointless.** The point is not the assertion; the
point is that the command exists, runs, and reports. Everything else gets added to it.

Write the command into `CLAUDE.md` under Commands, and into the `README.md` run section.

### On a compiled language, one command is not enough

**The test command compiles only what the tests import.** A file no test touches is never looked at
by the compiler, so it can contain an outright syntax or type error while every test passes.

> On 2026-08-26 a project ran `flutter test` — **24 passed** — and then failed to build on the
> device, on a one-word error in a file no test imported. The green number was real and it was
> measuring the wrong thing. **Tested and compiled are two separate facts.**

So the machine check is **the whole-build check first, then the tests**:

| | Whole-build check |
|---|---|
| Flutter / Dart | `flutter analyze` |
| TypeScript | `tsc --noEmit` |
| Python | `mypy` or `pyright` — the nearest equivalent |
| Go | `go vet ./...` (and `go build ./...`) |
| Rust | `cargo check` |
| C# | `dotnet build` |

**The exact commands per stack — strict analysis, formatter, tests — are a table in
`regression-gate`.** Written out there rather than here because the same table is what a CI pipeline
needs, and two copies would drift.

**Run it before the tests, not after.** A compile error anywhere makes every test result meaningless,
and finding that out first saves reading a green run that proves nothing.

The cheap partial fix, worth knowing: **a test that merely names a constant from a file compiles that
file.** Useful for a file with nothing worth testing yet. It is not a substitute for the check above —
it covers one file, by hand, and only if somebody remembers.

---

## What is worth testing

You are not aiming for coverage. You are aiming for **the checks that would have caught the
mistakes you would actually make.** Roughly in order of value:

**1. Anything that got broken once.** Highest value in the whole list. When a bug is fixed, write
the test that would have caught it, *before* fixing it if you can. That bug can now never come
back silently, and your check gets stronger every time something goes wrong.

**2. Logic with rules in it.** Dates, money, tax, scheduling, sorting, anything with an edge.
These are wrong quietly rather than loudly.

**3. The boundaries.** Empty input, one item, a very large number, a missing field, a wrong type,
no network. Real users find these on day one and generated code rarely handles them.

**4. The core loop, end to end, once.** One test that walks the main path a user takes. Slow,
worth it, catches the wiring problems that unit tests miss.

### What is not worth testing

- That a library does what its documentation says
- Layout and visual appearance — a human looks at those
- Getters, setters, and code with no decision in it
- Anything you would delete next week

A test you do not trust is worse than no test, because a failing check people ignore trains
everyone to ignore checks.

---

## Writing the first real test

Describe the behaviour in one sentence, then let the assistant write it, then read it. The
sentence is the part you must get right:

> "If the input is empty, the function returns zero and does not crash."

Three rules for tests you can actually check by reading:

1. **The name says what it checks**, not what it calls. `returnsZeroForEmptyInput` beats
   `testCalculate`.
2. **One behaviour per test.** A test that checks four things tells you nothing useful when it
   fails.
3. **Real values, not clever setup.** A test full of helpers and fixtures needs its own tests.

---

## Make it run without being remembered

A check nobody runs is decoration. Bind it to a moment:

- The acceptance criteria of every session carry a **machine line** — the command, and what
  passing looks like
- The `reviewer` agent is told to run it and report the actual output
- When you keep forgetting anyway, make it mechanical: a git pre-commit hook or an agent hook
  that runs the command and blocks until it passes. Instructions are advisory; a hook is not.

---

## Honest limits, worth saying to the owner

**Tests prove the thing you thought of still works.** They cannot tell you the feature is wrong,
ugly, or unwanted. That is what the human line of the acceptance criteria and `persona-check` are
for. A project with green tests and no users has failed.

**Do not chase a coverage number.** Coverage measures lines executed, not risks covered, and
optimising it produces a lot of tests that assert nothing.

**Generated tests can be circular.** An assistant asked to write tests for code it just wrote
will happily test that the code does what it does, bug included. The defence is that *you* say
the sentence in plain language first, and that the failing test is seen failing before the fix
makes it pass.
