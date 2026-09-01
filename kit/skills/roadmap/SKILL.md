---
name: roadmap
description: Take a pile of unsorted ideas, group them, rank them, and turn them into an ordered Now/Next/Later plan with a status view — then re-rank it as things are learned. Use this whenever someone has more ideas than they can build, when several scattered ideas might belong to one product, when deciding what to build next, when a project has many features and nobody can say where each one stands, and at every checkpoint. Also use when someone asks how to prioritise, what to build first, or how to keep track of a big multi-feature project.
---

# Roadmap

Two jobs:

1. Turn a pile of ideas into an **ordered plan** — because you can hold many ideas but build one at a time.
2. Be the **one place that shows where everything stands**, so nobody has to ask.

**The mistake to avoid at the start:** when someone brings ten scattered ideas, do not make them
choose one. Scattered ideas are usually **features of the same product for the same people**, and
picking one throws away the map. Take them all in, then order them.

---

## Step 1 — intake, with no filtering

Ask for the raw list. Problems, not solutions: *"I can't see which accounts renew soon without
opening two systems."*

Do not judge, rank or improve anything during intake. Judging while collecting stops the
collecting — people self-censor the half-formed idea, which is often the good one.

Ask twice. The second pass always produces two or three more.

---

## Step 2 — group into themes

Ten ideas are rarely ten things. Group by **who has the problem and what they are trying to
decide**, not by what technology they would use.

Each theme is a candidate **module** — a part of one product that could be built and reviewed on
its own. If the themes share the same users and the same data, that is the signal for one
connected product rather than several tools.

Read the grouping back and let them move things. They know which two ideas are secretly the same
one.

---

## Step 3 — rank

Three questions per item. Keep it this crude; elaborate scoring systems produce false precision
and get abandoned.

| Ask | Scale |
|---|---|
| **How many people hit this, how often?** | daily / weekly / rarely |
| **How bad is it today?** | blocks work / annoying / mildly untidy |
| **How much work?** | S / M / L |

Then one tiebreaker that overrides the rest: **does anything else depend on it?** Foundations go
early even when their own value is low. A login screen is boring and everything waits on it.

This is a simplified value-versus-effort prioritisation. It is not scientific, and it is not
supposed to be — its value is that the reasoning is visible and can be argued with.

---

## Step 4 — Now / Next / Later

Ordered, **never dated**. Dates on a project with a few hours a week are fiction, and a missed
date poisons a plan that was otherwise fine.

| Band | Means | Size |
|---|---|---|
| **Now** | Being built, or next up | One item. Two at most. |
| **Next** | Agreed, specified enough to start | Three to five |
| **Later** | Real, wanted, not yet thought through | As long as you like |

**"Now" holding one item is the whole discipline.** A "Now" column with six things in it is a
wish list wearing a plan's clothes.

---

## Step 5 — the status view

The same file answers "where does everything stand". One row per item:

| Item | Theme | Band | Status | Who | Notes |
|---|---|---|---|---|---|

Status is one of: **idea · specified · building · shipped · dropped**.

"Dropped" stays visible, with the reason. A dropped item that disappears comes back as a new
idea in four months, and the reasoning has to be rebuilt from nothing.

---

## Step 6 — re-rank, on purpose

**At every checkpoint**, and only then. Mid-milestone re-ranking is how nothing gets finished.

What legitimately changes the order:

- A real user hit a wall you did not know about
- Something turned out much smaller or much bigger than estimated
- A dependency landed, unblocking something
- The reason for an item disappeared — drop it and say why

What must **not** change the order: enthusiasm, whoever spoke last, or how much has already been
invested in something that is not working. Sunk cost is not a ranking criterion.

Expect the order to change. A roadmap that never gets re-ranked is not being used.

---

## Two files, two jobs

| File | Holds | Ordered? |
|---|---|---|
| `ROADMAP.md` | The features that make up the product — the plan | **Yes** |
| `BACKLOG.md` | Things deliberately not being done, with a trigger | No |

An idea that is part of the product goes in the roadmap, even in "Later". An idea that is *out
of scope* goes in the backlog. If everything ends up in the roadmap, scope has not been decided
yet — go back to the charter.

---

## Traps

**Everything is "Now".** Then nothing is. Force the ranking; three questions is enough.

**Ranking by who asked.** The loudest colleague is not the most common case. Ask how many people
have the problem, not how strongly one person put it.

**Never dropping anything.** A roadmap where nothing is ever removed stops being read, because it
is obviously not real.

**Estimating in hours.** S/M/L is honest at this level. Hours invite a promise nobody can keep.

**Confusing a long list with an ambitious plan.** The list can be as long as you like. The build
order is what makes it a plan, and "Now" holds one item.
