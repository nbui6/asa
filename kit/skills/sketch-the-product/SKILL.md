---
name: sketch-the-product
description: Draw the whole finished product as a clickable mockup with fake data, before the first feature gets built — so the shape is agreed while changing it still costs one sentence. Use this at the start of any project that will have more than two screens, when someone says "I don't have the mental picture yet", "what will this actually look like", "show me the big picture", "are we building the right thing", when a roadmap of features exists but no picture of the destination does, when several rounds have shipped and nobody has ever seen the whole thing, or when scattered ideas are being turned into one product. Also use it when a stakeholder needs to see something before approving work. Not for a single-screen tool, a script with no interface, or a change to a product whose shape is already agreed and unchanged. Do not use it to check whether one screen fits the person using it (that is persona-check, which runs immediately after this one) or to define shared styles and components (that is design-system).
---

# Sketch the product

The five session stages — Goal, Acceptance criteria, Build, Test, Commit — all run **inside one
feature**. None of them asks what the finished product looks like. So it is possible to run the
process perfectly, ship six features, and only then find out the shape was wrong.

This skill fills that gap. It runs **once per product**, before the first feature.

> **The whole point:** at the sketch stage, changing the product costs one sentence. After six
> rounds it costs six rounds.

---

## 1. When this fires

| Fires | Does not fire |
|---|---|
| A new product with more than two screens | A one-screen tool, a script, a library |
| A roadmap of features exists, but no picture of the finished thing | The shape is already agreed and unchanged |
| Someone says "I don't have the mental picture yet" | A single feature inside an agreed product |
| Scattered ideas are being merged into one product | A bug fix, a refactor |
| Rounds have shipped and nobody has seen the whole thing | |
| Someone outside the build needs to approve it | |

**The late trigger matters most.** If three or more features are built and no whole-product
sketch exists, run this now rather than deciding it is too late. Finding out in round 3 beats
finding out in round 9.

---

## 2. The three rules

Without these, a sketch becomes a build, and then it has eaten a week and proved nothing.

### Rule 1 — fake data only

No file reading, no database, no API, no real state. Typed-in numbers that look plausible.

The moment a mockup reads something real, it is software: it needs error handling, empty
states, a test. All three belong to a later round.

### Rule 2 — every screen carries an honesty label

Three labels, and each one appears on the screen itself:

| Label | Means |
|---|---|
| **Exists today** | Built, running, you have seen it work |
| **Designed, not built** | This is a proposal. Nothing behind it. |
| **Named only** | A word holding a space open. Not on any roadmap. |

Without these, a mockup is read as a promise. Someone will remember seeing a feature and
believe it was delivered — including the person who built it, four weeks later.

### Rule 3 — one sketch per product, not per feature

Re-run it only when the answer to *"is this still the shape?"* becomes no. Put that question in
the retrospective and nowhere else. A sketch redrawn every session is a design habit, not a
decision.

---

## 3. What to draw

Every screen the finished product would have — including the ones that will never be built,
labelled *named only*. The screens nobody builds are half the information: they show where the
product stops.

For each screen, three things and no more:

1. **Its name**, in the user's words
2. **The one job it does** — one sentence, and if it takes two the screen is two screens
3. **Enough fake content to see the shape** — four or five rows, not one and not forty

**Make it clickable if the tool allows it.** Tabs that switch, cards that open. A static picture
gets a polite "looks good"; something that can be clicked gets a reaction, and the reaction is
the deliverable.

**One file, no dependencies.** A sketch that needs a build step is a project.

**Keep it deletable.** The sketch is not the product's design system and should not be reused as
one — it exists to be argued with and thrown away.

---

## 4. The questions that come after

A sketch that is only admired has failed. End with exactly three questions, in this order:

1. **Is this the right product at all?** — Give them permission to say no. Then add the
   question that actually finds the truth: *which of these screens would you open on a normal
   Tuesday?* If the answer is two out of eight, the product is smaller than everyone has been
   treating it — and that is the most valuable finding this skill produces.

2. **Which screen next?** — Recommend one, with the reason in a single sentence. A menu with no
   recommendation hands the work back.

3. **What is missing that you expected to see?** — The only question that finds an absence.
   Nobody notices a missing screen while looking at eight present ones unless asked directly.

Then write down what the answers were, in the project's decisions file, dated. Otherwise the
sketch is agreed in conversation and forgotten by the next session.

---

## 5. Failure modes

**It becomes the product.** Someone asks to "just make the mockup work". Refuse: mockup code is
built to be thrown away, and turning it into a product means keeping every shortcut. Build the
real screen against the real acceptance criteria instead.

**It gets too detailed.** Exact spacing, real copy, hover states. The sketch answers *is this the
right set of screens* — not *is this the right button*. Detail is the persona check's job and
the design system's job, later.

**It flatters the plan.** A sketch drawn by the person who wrote the roadmap will show the
roadmap. Defence: draw at least one screen nobody has asked for, and one that shows the product
being used by someone other than the builder. If nothing in the sketch surprises the person who
commissioned it, it was a summary, not a sketch.

**It hides what is real.** Every screen looks equally finished, so a built feature and a
one-sentence idea read the same. That is what Rule 2 is for, and it is the rule most likely to
get dropped for looking untidy.

**It never gets revisited.** A sketch that is four months stale and still linked as "the plan"
is worse than none. Date it. When it stops matching the product, either redraw it or delete it.

---

## 6. Then run persona-check on it

The sketch and the persona check are different questions and both are cheap here:

- This skill asks: **is this the right set of screens?**
- `persona-check` asks: **can this person do this job on this screen?**

Run this one first — checking the fit of a screen that should not exist wastes the check. Then
run `persona-check` against the sketch, before any of it is built. That is the cheapest moment
the two checks will ever have.

---

## 7. What this does not replace

The charter still says what the product is for and what it is not. The roadmap still says the
order. Acceptance criteria still say what done means for each feature.

This is the picture those three documents describe, made visible in one place — because a
sentence in a charter and a screen in front of someone are not the same object, and people
disagree with the screen.
