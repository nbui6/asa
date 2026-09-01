---
name: onboarding-docs
description: Write or review the documentation that lets another person pick up a project — README, CONTRIBUTING, and handover notes. Use this whenever someone wants to share a project with a colleague or teammate, hand work over, onboard a new contributor, make a repo understandable to someone else, write or fix a README, explain "how do I run this", or asks what a collaborator needs to know. Also use when reviewing existing project docs for drift, overclaiming, or missing setup steps. Not for end-user manuals, API reference documentation, or marketing pages. Do not use it to package, host, deploy or distribute the thing itself (that is ship-it).
---

# Onboarding documentation

The job is narrow and testable:

> **Could a competent person, on a different machine, with no access to your chat history, get
> this running and make a correct change — without asking you a single question?**

Everything below serves that sentence. If a section does not, cut it.

---

## 1. Which file, and when

Do not write all of these. Write the one the situation calls for.

| File | Answers | Write it when |
|---|---|---|
| `README.md` | What is this, what works today, how do I run it | Always. From day one, even alone — future-you is the first collaborator. |
| `CONTRIBUTING.md` | How do we work, what gets rejected | A second person actually joins. Not before. |
| `CLAUDE.md` / `AGENTS.md` | Current state, decisions, what already failed | Any project worked on with an AI assistant |
| Handover note | Where I stopped, what is half-done, what I would do next | Someone else continues the work, or you return after a long gap |

Writing `CONTRIBUTING.md` for a team of one is a common and pointless ritual. So is a README
for a repo that has no way to run yet — in that case say so in one line and stop.

---

## 2. The status section is the one that matters

The commonest failure is a README that describes the **intended** project rather than the
**actual** one. It reads as a lie the moment someone tries it, and it destroys trust in
everything else on the page.

So: a **Status** section near the top, and it must be able to embarrass you.

> ❌ "A modular assistant app with spaced-repetition German practice."
> ✅ "Session 1 of ~11. There is no feature yet — this is the Flutter starter app plus a working
> toolchain. It builds, runs in Chrome, and `flutter test` passes."

A two-column table of **works today / not built yet** does this well and takes a minute.

If the project is practice rather than production, **say so in the first line**. People worry
that a learning repo makes them look bad; one honest label removes the problem entirely, and
hiding it is what would actually look bad.

---

## 3. Every command must have been run

No `should work`, no invented flags, no half-remembered menu paths. If a command has not been
executed on a real machine, it does not go in — or it goes in explicitly marked untested.

For each command, give the **expected output**, especially when success looks strange:

- something that takes 30+ seconds and looks stuck
- a terminal that does not return the prompt (a watcher, a dev server)
- an error that is expected and fine (a missing optional toolchain)
- success that looks like nothing happening

That last category is where new people give up, and it costs nothing to prevent.

---

## 4. Point, do not duplicate

Every fact repeated in two files will disagree within a month, and the reader will not know
which one is stale. The README **links** to the charter, the decision log, the backlog. It does
not restate them.

The one thing worth duplicating is the **single next step**, because that is what a returning
person needs in the first ten seconds.

---

## 5. For a collaborator, constraints beat features

A new contributor's expensive mistakes are not "did not know a feature existed". They are
"rebuilt something that was already there", "used the approach we rejected in week two", and
"put a secret in a committed file".

So include, briefly:

- the handful of rules that do not get traded away
- what is deliberately out of scope, and where new ideas go instead
- what was tried and rejected, **with the reason** — otherwise it gets retried
- where secrets live, and where they must never live

This is usually the section that makes the document actually worth reading.

---

## 6. Template

Adapt, do not fill in mechanically. A section with nothing real to say gets deleted, not padded.

```markdown
# <Project>

**<One line: what it is. If it is practice, say so here.>**

<One paragraph: what it does and who for. Plain language, no pitch.>

## Status
<What works today | What is not built yet — a table works well.>

## Run it
<Prerequisites, with versions that were actually used.>
<Commands, in order, each with its expected output.>

## How this project is worked on
<The process, in a few lines. Link to the full version.>

## Rules that do not get traded away
<The short list. Constraints, secrets, architecture boundaries.>

## Where things are written down
<Table: question → file.>

## Open questions
<Decisions that are genuinely undecided. Naming them prevents someone deciding by accident.>
```

---

## 7. Keeping it true

A README rots silently, because nothing fails when it is wrong. Bind it to moments that happen
anyway:

- **The run command changes** → update the README in the same commit. Not later.
- **At each retrospective or milestone** → re-read the Status section and ask whether it is
  still honest.
- **Someone new actually uses it** → whatever they had to ask you is the exact gap. Add that
  answer and nothing else.

That last one is the highest-value edit available and it only happens if you ask them what they
got stuck on.

---

## 8. Reviewing an existing README

Check in this order, and report what fails rather than rewriting silently:

1. Does the Status section exist, and is it honest about what does *not* work?
2. Has every command been run? Any that cannot be verified — say so.
3. Can someone get from clone to running without outside knowledge?
4. What does it duplicate from another file, and do the two already disagree?
5. Are the constraints and rejected approaches written down anywhere findable?
6. Is the single next step visible in the first ten seconds?
