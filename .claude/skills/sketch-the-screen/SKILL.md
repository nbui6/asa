---
name: sketch-the-screen
description: Draw one screen as a clickable mockup and get it agreed before writing any of its code — the mid-build sibling of sketching the whole product. Use it when the structure of a single screen is about to change: a new screen, a screen being redesigned, or new elements landing inside an existing one. Also use when a screen has already been built and rejected once, or when the build-and-install loop runs on a physical device and is therefore expensive. Do not use it for copy changes, styling, logic or data work where the layout does not move, and do not use it at project start for the whole product (that is sketch-the-product, once, before the first feature).
---

# Draw the one screen you are about to change

`sketch-the-product` runs **once, at the start**, and asks *is this the right set of screens?*

**Nothing covered "this screen is changing now."** Between the whole-product sketch and the code
there was a gap, and every screen fell through it.

> **This step was invented by the first outside tester, mid-session, out of frustration at repeated
> rebuilds — not proposed by the kit.** The rest of her day got several times cheaper. It is the
> single highest-value change the first outside test produced, and it was **absent, not skipped**.
>
> *Independently, in the same week, the same step was improvised on this kit's own project for the
> same reason. Two independent inventions of a missing step is as strong a signal as this process
> generates.*

## Why it pays, arithmetically

The loop it replaces is **build → install on a device → look → reject**. On a phone that is minutes
per turn, plus the cost of being in the wrong place mentally when the verdict arrives.

The loop it costs is **write some HTML → look → change a line**. Seconds.

**The device round trip is the most expensive loop in a project like this**, and this step removes
most of the turns from it.

## When it fires — and when it does not

**The trigger is structural change**, and it is deliberately narrow, because a trigger that fires on
everything fires on nothing (`PLAYBOOK.md` §14).

| Fires | Does not fire |
|---|---|
| A new screen | Copy or wording changes |
| A screen being redesigned | Colours, spacing, styling |
| **New elements landing inside an existing screen** | Logic or data work behind an unchanged layout |
| A screen that was built once and rejected | A bug fix that moves nothing |

**The third row is the one that gets rationalised away.** *"The design was checked earlier, so the
build is covered"* — it is not. What the person now faces is the old content **plus** the new
content, and nobody has looked at that combination. See `persona-check`, which records exactly this
excuse being used and what it cost.

## What it produces

**A clickable mockup of that one screen, with fake data, and an explicit yes before any code.**

1. **One screen.** Not the flow, not the neighbours. If two screens are changing, that is two
   sketches, and doing them separately is usually faster.
2. **Real content, fake data.** The longest label you actually have, not "Item name" — layout breaks
   on real content and holds on placeholder.
3. **At the width it will really be seen.** *A measurement without its conditions is not a
   measurement.* A layout checked at desktop width and shipped to a phone has been checked at the
   wrong width, and this has already cost one project a false "no collisions" finding.
4. **Every element labelled** *exists today* / *new in this change* / *coming later*. Unlabelled, a
   mockup is read as a promise.
5. **Rendered and opened by whoever made it, and then actually sent.** A mockup is code, and code
   that has not been run is a claim — but a rendered mockup nobody was shown is worse, because it
   leaves a file behind and feels done. **The step completes when the person who approves it has
   seen it**, not when the screenshot comes out clean.
6. **Short enough to take in at a glance.** Before and after, one question, no headings. See the
   size rule below — this is the one that gets violated by being helpful.
7. **Filed in the project's own folder the moment it is approved — the image *and its source*.**
   Render, send, get a yes, **file.** Four steps, and the fourth is the only one that survives the
   conversation.

   > *2026-09-04: an approved sketch lived in a chat and in a temporary cloud workspace, and was
   > cited by path in a gate table, a spec and a drift report for three days. **The path never
   > existed.** A whole round was then built against a recreation of it, drawn from source code a
   > day later, and rejected undiagnosably — because "it doesn't match what we agreed" cannot be
   > answered when the thing agreed no longer exists. **Shown is not saved.***

   **File both formats.** A `.png` can only be redrawn; the source can be re-rendered. And record
   the approval — `sketches/APPROVED.md`, one row: file, date, who, which screen, and the one line
   saying what it must look like. **Approval that lives only in a conversation is not a record.**

Then the question, and it is one question: **is this the screen?** Not "does this look nice."

## Keep it to one page

**A sketch that has to be read is not a sketch.** The failure mode is not laziness, it is
thoroughness: the states get tabulated, both options get drawn in full, the out-of-scope list goes
in, the standing rules go in the footer — and the one row that was actually changing is now on page
two.

| Belongs in the sketch | Belongs in the round file |
|---|---|
| The screen **before** | The full table of states and conditions |
| The screen **after** | What is out of scope this round |
| **One** question, naming what happens on each answer | The acceptance criteria |
| A one-line note on what is real and what is invented | Every alternative that was considered |

**If it needs headings, it has stopped being a sketch.**

**And put the recommendation in it.** Drawing two options side by side and asking which one is
preferred hands the work back. Name the one to build and give the single reason; an override costs
one line and takes ten seconds.

## The gate

**No code for this screen starts until the sketch has an explicit yes.** Not a review of the sketch,
not a verdict from `persona-check` on the sketch — a yes from the person who will use the screen.
When a build is being handed to a second session, the handover file says so in its first lines, or
the second session starts building against an unapproved drawing.

**And three more conditions, each earned the expensive way on 2026-09-04:**

| | |
|---|---|
| **The file exists** | The handover names the image *and* its source, and **both paths are checked, not typed.** `check-refs.ps1` |
| **The prose has been read against the image** | Every disagreement listed and resolved in the handover **before the round starts.** Prose cannot carry layout, so the disagreements are always there |
| **The image goes beside the screenshot** | Before *"is this right?"* is asked. Two pictures in one message, not a link |

## Where it sits in the session

Between **Acceptance criteria** and **Build**. The criteria say what must be true; the sketch shows
what it will look like; the code comes third.

If the answer is no, you have spent minutes. If nobody asked, you find out after the build, on the
device, in the evening.

## Honest limits

**It does not check whether the screen suits the person** — that is `persona-check`, and it runs on
the sketch, which is the cheapest moment it will ever have.

**It does not check that the screen can be reached.** A perfect screen with no route to it is three
of one project's wasted days. That is the *Reachable?* line of the handover check,
`PLAYBOOK.md` §8.

**And it is not a design tool.** The output is throwaway. If a sketch is being polished, it has
stopped being this step and started being the product.
