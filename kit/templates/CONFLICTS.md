# CONFLICTS.md — things that fight each other in this product

**One line per known conflict. Grow it deliberately.**

> **The best value-per-line artefact in the first outside test, and it was not in the kit.** The
> tester's verdict: *"one sentence, recorded from a past failure, applied to a new one. If any part
> of the kit deserves deliberate growth, it is that list."*
>
> The line that earned it: *"a zoomable image inside a scrolling list loses the gesture fight."* It
> settled a design decision **before any code existed**, and prevented a build that would have failed
> on the device.

**Why this works when skills do not:** it is plain text in a file the assistant already reads. **It
fires without being invoked** — no trigger to remember, no moment to notice. It costs one line, it
works in any environment, and it is the only mechanism that reliably carried knowledge from one
problem to an unrelated one.

---

## The list

| The conflict | What happens | What to do instead | Learned |
|---|---|---|---|
| *e.g. a zoomable image inside a scrolling list* | *the two gestures compete; one of them always loses, usually the one the user wanted* | *full-screen viewer on tap, or lock the scroll while zooming* | *yyyy-mm-dd* |

---

## What belongs here

**Two things that cannot both be true, or two mechanisms that cannot both work**, where the failure
is invisible until it is built. Not bugs — bugs get a test. Not preferences.

| Belongs | Does not |
|---|---|
| Two gestures competing for the same input | "This looks better in blue" |
| A cache and a live value both claiming to be authoritative | A one-off bug, now fixed |
| A generated file and a hand-edited one, same target | A style preference |
| A library that assumes it owns the main thread, in an app that does not | Anything with a test that catches it |

## How to write a line

**In one sentence, in the vocabulary of the product, describing the collision and not the incident.**

> *A zoomable image inside a scrolling list loses the gesture fight.*

Not: *"On 14 March the photo viewer in the feed didn't work properly on Android."* That is a bug
report. It will never match a future problem, and matching a future problem is this file's only job.

## When it grows

**Every time something turns out to be impossible for a structural reason** — not because of a
mistake, but because two things were always going to fight. That is the moment; write the line then,
while you still have the reason in your head.

**And when the assistant proposes something this file already forbids, it should say so and stop.**
That is the return on the whole file.
