# ADR <nnn> — <the decision, as a short statement>

**Date:** <yyyy-mm-dd> · **Status:** proposed / accepted / superseded by ADR <nnn>
**Decided by:** <name>

> An **architecture decision record** is one page explaining why a significant choice was made.
> Real term, widely used. File it as `decisions/0001-<slug>.md` — one decision per file, so two
> people adding two decisions never collide, and nothing has to be rewritten later.
>
> Write one when a decision is **expensive to reverse**: the platform, the data model, a module
> boundary, where data lives, an external service you will depend on, a security or privacy
> choice. Small decisions belong in the `CLAUDE.md` decisions table instead — an ADR for every
> choice is how the folder stops being read.

---

## Context

<What situation forced a decision? What was true at the time — constraints, time budget, skills
available, what already existed? Someone reading this in a year has none of that context, and
without it the decision will look arbitrary or stupid.>

## Options considered

| Option | Upside | Downside |
|---|---|---|
| <A> | | |
| <B> | | |
| <C> — do nothing | | |

<"Do nothing" belongs on the list more often than people put it there.>

## Decision

<What was chosen. One or two sentences, stated plainly.>

## Why

<The reasoning, including what was traded away. The honest version — "we did not have time to
evaluate B properly" is a legitimate and useful reason, and far more helpful later than an
invented technical justification.>

## Consequences

**We now get:** <…>

**We now accept:** <…>

**This becomes hard:** <what this decision makes expensive later. The most valuable section — it
is what a future reader needs before they hit the wall.>

## What would change this

<The trigger that should make someone revisit it. "If we ever need X." Without this, a decision
quietly becomes permanent architecture, which is how a first working answer turns into a
constraint nobody chose.>

---

*Never delete an ADR. When a decision is replaced, set this one to superseded and link forward.
The record of what was tried and abandoned is worth as much as the record of what was kept.*
