# CLAUDE.md — <project name>

Operational file. The assistant reads this at the start of every session. Reasoning lives in
`CHARTER.md`; process lives in `PLAYBOOK.md`.

> **Size rule:** every line here is paid for again in every session. For each line ask *would
> removing this cause a mistake?* If not, cut it. History and reasoning belong elsewhere.

---

## Goal

<Two or three lines. What this is and what the core loop is. Point at `CHARTER.md` for why.>

## How we work

`PLAYBOOK.md`. Five stages per session: **Goal → Acceptance criteria → Build → Test → Commit.**
The owner runs all code; a result they have not seen is not a result.

## Hard rules

<Keep under ~20. When you add one, ask which one retires. Write each as what *to do*.>

1. <…>
2. <…>

## At the end of every session

<Only if the work is split across two assistant sessions — one that decides, one that builds.>

**Append to `HANDOVER.md`, upstream half:** what was built · **what was decided that the spec did
not cover** · what could not be done · **anything changed by hand that the agreed design still shows
the old way.** `templates/SESSION-HANDOVER.md`, and `PLAYBOOK.md` §15.

This line exists because that half is the one that gets skipped, and it is the one carrying the
reasoning no diff contains.

## Who runs what

**Three roles. Fill this in on day one, before the first command is handed to anyone.**

| | Does | Never |
|---|---|---|
| **The deciding session** | decisions, sketches, specs, records | writes the product's code |
| **The building session** | writes the code, **and runs the checks on it** | pushes anything outward |
| **<your name>** | **looks at the result and says yes or no.** Runs whatever leaves the machine | carries text between the two sessions |

| Command | Who |
|---|---|
| The machine check and everything in it | **the building session, itself** |
| Running the app | the session launches it; **you look** |
| Stage and commit | the building session, **after you have said yes** |
| Push, deploy, send — anything that leaves the machine | **you** |

> **Write a prohibition as the mechanism, never as the category of actor.** *"Never through the
> device bridge"* stays true forever. *"Assistants never run commands"* costs you a copy-paste on
> every round and was never what any incident showed. `PLAYBOOK.md` section 14.

## Definition of done

Acceptance criteria met · handover check written · reviewed · `CLAUDE.md` updated ·
**a line in `PRODUCT-CHANGELOG.md` saying what you can now do** · **a screenshot from the real
device if a screen changed** · **the result shown to the Boss and a yes back** · committed, by a
session that is allowed to run git, with a message naming the round.

**Shown, then approved, then committed — in that order.** `PLAYBOOK.md` §8's fifth line.

## Commands

| Job | Command |
|---|---|
| Machine check (pass/fail) | <…> |
| Run it | <…> |
| Install dependencies | <…> |

## Decisions

| Date | Decision | Why |
|---|---|---|
| | | |

## Verified findings

<What was **measured on this machine**, with a date. Not what the documentation claims. The docs
are a claim; the running system is the fact.>

- <…>

## Rejected approaches

<With the reason, or it gets retried in three weeks.>

- <…>

## Complexity log

<Anything clever that survived: what it is, and why the boring version was not enough. Not a
ban — a receipt.>

*(empty)*

## Vocabulary

<Terms specific to this project, agreed with the owner. Prevents two words for one thing.>

## Deferred

See `BACKLOG.md`.

## Where we are

**<Milestone N — status.>**

Next session: <the single next step, specific enough to start cold.>

## Session log

### Session <n> — <date> — <one-word topic>

- **Goal:** <…>
- **Acceptance criteria:** <each one> — met / not met / not attempted
- **Built:** <…>
- **Deferred:** <…>
