# HANDOVER.md — between the session that decides and the session that builds

**Lives in the project repo, at the root.** Both sessions read it; **neither writes in the other's
half.**

> **Why this exists.** Two assistant sessions on one repository — one that can decide, design and
> research, one that can compile, run and see the result — turn the human into a **message bus**.
> They explain in session B what was decided in session A, then explain back. Nobody else can,
> because neither session sees the other's conversation.
>
> **Most of that work is unnecessary: the two sessions already share the repository.** Anything
> written to a file is visible to both. What does not survive the boundary is not the *what* — that
> is readable in the diff — but the **why**.
>
> *From the first outside test, 2026-08-30. The failure it prevents was observed: a layout the owner
> fixed by hand in the building session was never written back to the agreed design. The next round
> built from the design and handed her the exact thing she had already rejected. One full rebuild,
> against a one-line note.*

---

## ⬇ Downstream — written by the deciding session, read before building

**Gate — read this before anything else.**

| Check | State |
|---|---|
| Does this work change the structure of a screen? | yes / no |
| If yes, has the sketch of that screen been **seen and approved by the Boss**? | approved on `<date>` / **not yet — do not start** |

<Link the sketch. A review of the sketch, or a persona verdict on it, is not an approval.>

> *Added 2026-09-01. A deciding session rendered a sketch, reviewed it, put its one decision to the
> Boss and offered to hand the build over — without ever showing him the picture. `PLAYBOOK.md` §14,
> "Rendered is not seen".*

**What to build.**

<One paragraph. Point at the round note for the criteria rather than repeating them.>

**What must keep working.**

<The things that are easy to break from here and expensive to notice. Name them.>

**Still undecided — do not build around these.**

| Open | Why it is open | What would settle it |
|---|---|---|
| | | |

**Deliberately not in this piece of work.**

<The ideas that came up and were pushed away. Naming them is what stops them creeping back in
during Build — including by an assistant being helpful.>

---

## ⬆ Upstream — appended by the building session at the end of every session

**This is the half that does the work, and the half that gets skipped.** Put a line in the
project's `CLAUDE.md` so the building session writes it at session end without being asked, the way
the commit happens without being asked.

**Gate — the session does not end, and nothing is committed, until all three are true.**

| # | | State |
|---|---|---|
| 1 | The result was **shown** to the Boss — the screen, or the command and its real output | |
| 2 | He was **asked** whether it is right | |
| 3 | He said **yes**, or named a fix that was then made and shown again | |

> *Added 2026-09-02. A building session wrote a complete and honest note here and reported the
> round done — with nothing shown and nothing committed. **This note is not the delivery.**
> `PLAYBOOK.md` §8 and §14, "Done is not delivered".*

### <yyyy-mm-dd> — <what the session was>

**Built:** <one or two lines. The diff has the detail; this is the index.>

**Decided, that the downstream half did not cover:**

| Decision | Why | What would reopen it |
|---|---|---|
| | | |

> **This table is the single most valuable thing in the file.** It carries *reasoning*, and no diff
> ever contains reasoning. A decision made here and not written down is one the deciding session
> will contradict next week, in good faith, using the design document that is now wrong.

**Could not be done, and why:** <blocked, out of scope, needs a decision, needs the device.>

**Changed by hand and not yet reflected upstream:** <the most dangerous line in the file. Anything
adjusted directly here that the agreed design still shows the old way.>

---

## What does not cross this boundary — say it out loud

Do not let a shared file imply more than it delivers:

| | |
|---|---|
| **Live questions** | A building session that hits an ambiguity mid-task cannot ask the deciding session. It still routes through the human — **which is the argument for spending more effort on the downstream half before the session starts**, not less. |
| **Anything only a human can see** | A result on a real device. Whether it looks right. Whether it feels slow. |
| **Approval** | Neither session settles product direction alone, and a shared file makes it slightly too easy to pretend otherwise. |
