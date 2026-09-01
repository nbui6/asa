---
name: counter-proposal
description: Argue the opposite technical position on purpose, before anything is built — the cheaper design, the boring version, the one that puts the work somewhere else. Use this when a technical approach has been proposed and nobody in the room disagrees with it, before an architecture decision is recorded, when a design has two implementations of one idea or a special case in it, or when someone building alone is about to commit to a shape. Also use when a proposal came from the same assistant that is now evaluating it. Do not use it to check whether a screen suits the person using it (that is persona-check), or to review code that already exists (that is the reviewer agent, which runs at the end of Build).
---

# The engineer who disagrees with you

Every other review in this kit asks the same underlying question: **is this right for the person
using it?** `persona-check`, the design critique, the copy review, the code review. That is the right
question and the kit is good at it.

**Nothing asks: is this the cheapest thing that could work, and would a competent engineer with
different priorities build it this way?**

On a team, that person exists and turns up uninvited. **On a solo project there is no such person,
and the review simply never happens.** The first design ships, and its cost arrives months later as
maintenance.

> **Why this belongs in this kit specifically.** The assistant proposes, and then the assistant
> evaluates its own proposal — against the user, which it does well. Nobody evaluates it against the
> engineering. **That is a structural hole, not a diligence problem**, and it does not close by
> trying harder.
>
> *Written after the first outside test, 2026-08-31. An external backend developer pushed back hard
> on a client-side design. His counter-proposal — one implementation instead of two, the work on the
> server rather than the device, a queue instead of a special case — was **better on every axis**,
> and the assistant had not considered it. It reached the design only because a real person with
> different incentives was in the room.*

---

## When it runs

**At proposal time, not at code time.** Before the decision is recorded, while changing it still
costs a sentence. Once it is built, this review turns into a rewrite argument, and rewrite arguments
are lost on cost even when they are right.

Concretely: before an ADR is written · when a design has survived a conversation with nobody
disagreeing · when the proposal and the review would otherwise come from the same assistant.

## The five standing questions

Ask all five. They are deliberately blunt, and each one has produced a better design at least once.

**1. What is the version of this with one implementation instead of two?**
Two code paths doing one thing — one for the common case and one for the awkward one, one for online
and one for offline, one for the new format and one for the old. Name the single-path version and
what it would cost.

**2. What would this look like if all of it lived in one place?**
On the server rather than the device. In one module rather than three. In the database rather than
in code. Distribution is a cost you pay forever; sometimes it buys something and sometimes it is
inherited from how the conversation happened to start.

**3. Which part of this is a special case that a queue, a retry or a state machine would remove?**
Special cases are where the maintenance lives. A named pattern that absorbs three of them is almost
always the cheaper design, and it is the one an assistant is least likely to reach for unprompted.

**4. If this were twice as boring, what would it be — and what would actually be lost?**
The second half of that question is the honest one. Sometimes the answer is *nothing*, and that is
the finding.

**5. Who maintains each moving part, and what happens when that person is unavailable?**
A design with a component only one person understands is a design with a single point of failure
that no diagram shows. On a solo project, ask it about **future you, after three months away.**

## How the answer is handled

**It must be answered on substance, not waved away.** A counter-proposal dismissed with *"that's not
how we're doing it"* has cost the time it took to write and bought nothing.

Like `persona-check`, **the verdict is advisory and the Boss decides.** But:

> **Record an override as an override.** When a counter-proposal is rejected with full context, write
> down *what was rejected and why* — in the ADR, beside the decision.
>
> Otherwise a later session rediscovers the same argument, "fixes" the design back, and the whole
> thing is re-argued every few weeks. *This pattern came from the same tester, who had already been
> bitten by it.*

## What this is not

- **Not a rewrite proposal.** It fires before the thing exists. If it is firing on working code, it
  is late, and the honest output is a backlog entry rather than a rebuild.
- **Not a second opinion on the product.** It never argues about *what* to build — only about the
  cheapest shape of the thing already agreed.
- **Not contrarianism.** If the original design survives all five questions, say so in one line. A
  review that always finds something is as useless as one that never does.

## Honest limits

**It cannot supply different incentives, only different questions.** The real backend developer was
valuable because he owned the thing he was arguing about and would have to live with the result.
Nothing here reproduces that, and a proposal that turns on *who bears the cost* still needs a person.

**It is one more thing that must be invoked.** Its trigger is a named, rare moment — before a
decision is recorded — for exactly the reason in `PLAYBOOK.md` §14: *a trigger that fires on
everything fires on nothing.*
