---
name: roadmap
description: Take a pile of unsorted ideas, group them, rank them, and turn them into an ordered set of milestones with tasks underneath — then re-rank it as things are learned. Use this whenever someone has more ideas than they can build, when several scattered ideas might belong to one product, when deciding what to build next, when a project has many features and nobody can say where each one stands, and at every checkpoint. Also use when someone asks how to prioritise, what to build first, or how to keep track of a big multi-feature project.
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

## Step 4 — a milestone is a state, not a to-do

**A milestone is a state the project reaches. A task is a thing you do.** (ADR 0015, Asa —
confirmed against nine real projects with no exceptions: every `milestone:` value ever written was
a noun and a finished state — *"v0.1 - the decisions are findable"* · *"Build spec ready"* — and
every task was a verb — *Test forms* · *Talk to M about design*.)

**The backstop, for anything that can be phrased either way:** a milestone has tasks under it, or
plausibly could. If nothing sits underneath it and nothing ever would, it is a task wearing a noun.

Ranked items from Step 3 become milestones, **one per real state the project passes through** — not
one per idea. Several small ideas often belong under one milestone as its tasks; that is the
grouping doing its job, not a shortcut.

**A shared milestone has one owner.** If a milestone genuinely belongs to more than one project
(ADR 0015, Asa): it lives once, in whichever project owns the underlying work. Every other project
carries a **pointer to it, never a second copy** — a duplicated milestone with two checkboxes is
guaranteed to drift, because one gets ticked and the other doesn't.

---

## Step 5 — where it lives: the project's own note, not a separate file

**`## Roadmap`, in the project's own note — the same file as `## Tasks`, not `ROADMAP.md`.** (ADR
0014, Asa — revised twice before landing here; the first version tried a separate document and a
typed `progress:` field, both rejected: typed data goes stale the moment nobody's looking, and a
second file for one project's plan is the "three homes gain a fourth" mistake with different
words.)

- **One checkbox per milestone, in order.** Order carries priority — Step 3's ranking becomes the
  sequence, not a separate `Now`/`Next`/`Later` label. **The first unfinished milestone is the
  de facto "now"** — nothing else needs to say so.
- **Tasks indent one level under their milestone**, or stand alone in `## Tasks` for things that
  belong to no milestone. Both render together wherever tasks are shown.
- **A count, never a percentage**, if anything renders a bar: *"4 of 11"*, drawn as discrete
  segments. A percentage implies precision counting checkboxes does not have.
- **No `## Roadmap` section → no bar, and that's fine.** Most projects are small enough that
  `## Tasks` alone is the whole plan. A roadmap is earned by having more than one real state to
  pass through, not assumed on day one.
- **Capture never classifies.** One place to type a new item, and it always lands as a task —
  never sorted by guessing whether it "sounds like" a milestone. Turning a task into a milestone
  (or a milestone back into a task) is a **drag**, made once someone actually looks at it, never a
  decision forced at the moment of writing it down. The same goes for assigning an unfiled idea to
  a project, in a workspace with more than one: capture goes to one inbox with no project chosen,
  and moving it to the right project is the same drag, made later, not guessed at typing time.

**Round and Version, if the project ships code to somewhere else.** Once a project has real commits
and a remote, it's worth naming its work in the same two words the commits already use: **Round**
for the unit Code actually works in — matches `git log` more often than you'd expect, since builders
tend to say it out loud whether or not it's written anywhere — and **Version** reserved only for a
Round that was actually pushed for someone outside the building session to use or test. Not every
Round earns a Version; most don't. **A Round's number is permanent once given** — if work jumps
ahead of an unbuilt Round, that Round keeps its number for whenever it's actually built, rather than
being renumbered to look tidy.

**A Round closes in a fixed order, not whenever someone remembers:** tick its checkbox, write its own record file if it earned one (goal, what shipped, the decisions it produced, by number), tag it with a Version if it was pushed for outside testing, log a process lesson if it has one, re-rank, then open the next Round. A project using the Round/Version pattern is expected to write this sequence down for itself once — Asa's own copy is `PROCESS.md` —  rather than relying on someone doing the five steps from memory each time.

**When a milestone (or Round) is substantial enough to need its own record** — goal, acceptance
criteria, the decisions it produced, what actually shipped — give it its own file (a `rounds\`
folder works well) and **point to it from the roadmap line**, never restate its content inline.
The roadmap line is the index; the detail file is where the detail lives, once, so it can't drift
from itself.

---

## Step 6 — re-rank, on purpose

**At every checkpoint**, and only then. Mid-milestone re-ranking is how nothing gets finished.

What legitimately changes the order:

- A real user hit a wall you did not know about
- Something turned out much smaller or much bigger than estimated
- A dependency landed, unblocking something
- The reason for a milestone disappeared — drop it and say why

What must **not** change the order: enthusiasm, whoever spoke last, or how much has already been
invested in something that is not working. Sunk cost is not a ranking criterion.

Expect the order to change. A roadmap that never gets re-ranked is not being used.

---

## Status, and the one enum

The project's own `status:` frontmatter (`idea · discovery-done · building · shipped · ongoing ·
paused · dropped` — ADR 0017, Asa, after three real files disagreed on the words) describes the
*project*. It is typed only when there is no `## Roadmap`; once one exists, the effective milestone
shown anywhere is **derived** — the first unfinished one — not hand-typed, same reasoning as
everywhere else in this kit: a fact two sources can disagree on is not a fact, it's a suggestion.

**Two files, two jobs, unchanged:**

| File | Holds | Ordered? |
|---|---|---|
| The project's own note, `## Roadmap` | The milestones that make up the plan | **Yes** |
| `BACKLOG.md` | Things deliberately not being done, with a trigger | No |

An idea that is part of the plan becomes a milestone, even a distant one. An idea that is *out of
scope* goes in the backlog. If everything ends up in the roadmap, scope has not been decided yet —
go back to the charter.

---

## Traps

**Everything is "the next milestone."** Then nothing is. Force the ranking; three questions is
enough, and order does the rest.

**Ranking by who asked.** The loudest colleague is not the most common case. Ask how many people
have the problem, not how strongly one person put it.

**Never dropping anything.** A roadmap where nothing is ever removed stops being read, because it
is obviously not real.

**Estimating in hours.** S/M/L is honest at this level. Hours invite a promise nobody can keep.

**Confusing a long list with an ambitious plan.** The list can be as long as you like. The order is
what makes it a plan, and the first unfinished milestone is the only one that matters right now.

**Naming every milestone a "round" or every task a "milestone."** A milestone is a state with tasks
under it. A round is a Round only if it's a real, numbered unit of work with its own record — not a
label reached for because it sounds more official than "task."
