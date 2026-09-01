# What changed — <product name>

**Written for the person who owns this product, not for a developer.**
One entry per round, **written in the same commit as the work**.

> **The rule this file exists for:** *when the person who owns the product cannot read its code, the
> build is not documented until there is a version they can read.*
>
> *From the first outside test, 2026-08-31. The owner asked whether the building session had become
> a black box. Half the commit history said things like `Session work 2026-08-31 20:58` — and the
> deeper problem was not the commit messages. **She cannot read the language her product is written
> in.** No amount of git discipline touches that. The kit's documentation guidance was
> developer-to-developer, and its actual audience is not a developer.*

**Written in the same commit is doing real work in that sentence.** A changelog updated afterwards is
a changelog that stops being updated in week three.

---

## How to write an entry

**Say what a person can now do that they could not before.** Not file names. Not *"refactored the
view model"*. Not *"added a service layer"*.

| Write this | Not this |
|---|---|
| "You can now practise the gender rules by tapping, and it tells you which rule explains the answer." | "Added DrillScreen and DrillSession with rule-linked feedback." |
| "Scanning a two-page document works. Before, the second page was silently dropped." | "Fixed multi-page capture pipeline." |
| "Nothing you can see yet — this round only prepared the data so the next one can show it." | *(silence)* |

**That last row matters.** A round that changes nothing visible should say so, in one line. Silence
reads as work that vanished.

## The shape of an entry

```markdown
## Round <n> — <date> — <what you can now do, in five words>

**What you can now do:** <one or two plain sentences.>

**What changed that you cannot see:** <one line, or "nothing".>

**Still not working / not built yet:** <the honest line. What someone would reasonably try and fail
to do.>

**Screenshot:** <required for any round that changes a screen — see below.>

**Commit:** <hash>
```

---

## The screenshot rule

**Any round that changes a screen ships a screenshot from the real device, in the same commit.**

The owner reviews visually and is often the only tester. **A diff cannot show a layout.** The
building session can already drive a real device — it simply was not being asked to.

A screenshot also dates itself, which a description does not: *"the labels do not collide"* was true
when it was measured on a desktop and false at phone width. A picture taken on the device settles it.

## Who writes it, and who commits

| | |
|---|---|
| **A session that can run git** commits its own round, with a message naming what it did | Leaving a pile of changes for the owner to commit later as one blob is how half a history becomes `Session work <timestamp>` |
| **A session that cannot run git** — one reaching the repo across a bridge — **must not run it at all** | It leaves a lock file it cannot delete, and every later commit fails |
| **The message names the round** | `Round 6c: profile weight + reads screen`, not a timestamp |

> **A default that is always accepted is not a default. It is the value.**
>
> Half of one project's history was timestamps because a save script fell back to one when no message
> was given. **Nobody ever chose that message.** Three lines fixed it — prompt, and keep the
> timestamp only if the person presses Enter.
>
> **The general rule is worth more than the fix: any convenience script written for a non-developer
> must be audited for what it decides on their behalf.** They cannot evaluate the default, which is
> precisely why it was made one.
