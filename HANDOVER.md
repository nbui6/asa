# HANDOVER.md — between the deciding session and the building session

**Both sessions read this. Neither writes in the other's half.**
Created 2026-08-31. Template and reasoning: the kit's `templates/SESSION-HANDOVER.md`.

> **Why it exists.** Two assistant sessions on one repository — one that can decide, design and
> research, one that can compile, run and see the result — turn the Boss into a message bus. **They
> already share this repository:** the *what* is readable in the diff. Only the **why** needs
> writing down.

---

## ⬇ Downstream — written by the deciding session, read before building

### Session 2026-08-31 · for Claude Code, running natively on Windows in this repo

**Read these three first, in this order. Hard rule 14.**

1. `CLAUDE.md` — the standing rules, the machine check, and *Where we are*
2. `ARCHITECTURE.md` — the map, and the two import rules it enforces
3. `..\..\Documents\Claude\Vibe Coding\projects\asa\rounds\round-4.md` — **the criteria for this
   round, already agreed on 2026-08-24. Do not rewrite them.**

---

### Job 0 — close round 2, before anything new. Fifteen minutes.

`CLAUDE.md` names two open items and neither is code:

| # | What | How to close it |
|---|---|---|
| 1 | **Round 2's human line was never checked.** Nobody has looked at the running window. | `flutter run -d windows`. Expect two rows, staleness on the right, and clicking `Asa` opens the round 1 detail screen. **Look at it, then write what you saw** into `CLAUDE.md` — evidenced, or the real result if it is not what round 2 claimed. |
| 2 | **Round 2's acceptance criteria were never written down.** The verification ran against criteria reconstructed from the roadmap. | Write them into a `rounds/round-2.md`, **marked as reconstructed after the fact**, with the results as they actually are. A reconstructed criterion is worth having and must not pretend to be a criterion agreed in advance. |

**Do not skip job 0 to get to the code.** Round 2 is the round that would otherwise be remembered as
finished, and it is not.

---

### Job 1 — round 4: the stage, measured not typed

**The criteria, the rule table, the file list and the "not in this round" list are all in
`rounds/round-4.md`.** Nothing is restated here — two copies of a criterion is how they drift.

**What the deciding session is adding, and it is only context:**

**Why this round and not round 3.** `CLAUDE.md` says *"Next: Round 3, the handoff."* The kit's
roadmap ranks **round 4 first**, with round 3 noted as *"was next, overtaken — still the single
highest-value screen element."* **Two sources disagree, and that disagreement is itself a finding**
(`ASA-LOG.md`). Round 4 is specified here because **its criteria are already agreed and round 3's
are not**, and hard rule 1 says criteria before code. *If the Boss says round 3, that overrides
this — say so and stop.*

**What must keep working.** Round 4 touches `projects_scan.dart` and the projects screen, which are
round 2's deliverable and have never been looked at by a human. **If job 0 finds round 2 broken,
stop and report — do not build a stage indicator on top of an unverified list.**

**What is still undecided, and must not be built around:**

| Open | Do not assume |
|---|---|
| Whether the projects screen gets an action row at the top (kit roadmap item 8, six findings from a UI review) | Do not restructure the screen for it. Add the stage to the row as `round-4.md` says, and nothing else. |
| Round 3's handoff buttons | Explicitly out — `round-4.md` says so |

**Three rules from the kit that changed this week.** Two are new and untested; they are flagged so
you can push back rather than absorb them silently:

| | |
|---|---|
| **The handover check is four lines now** — the fourth is **Reachable?** *Name the route a person takes to see this, tap by tap.* | Applies cleanly here: the stage appears on a row that already exists. |
| *(new, one day old)* A round that changes a screen ships **a screenshot from the real window**, in the same commit | **Worth it this round** — criterion 6 is *"the stage is never colour alone"*, and a screenshot is the only thing that settles it. |
| *(new, one day old)* A line in a plain-language changelog, in the same commit | **Not set up in this repo.** Say whether it is worth starting, rather than starting it silently. |

**Who runs git.** You do, natively, in this repo. **The deciding session must not** — it reaches
these files across a bridge, where git has no `core.autocrlf` and leaves an `index.lock` it cannot
delete. Commit round 4 yourself, with a message naming the round.

**Where to stop and ask.** Anything that changes what Asa *is* — a new hub, writing prose into a
note, an editor of any kind (hard rule 13), or a change to the rule table in `round-4.md`. Those are
charter questions, and they belong in the deciding session.

---

## ⬆ Upstream — appended by the building session at the end of every session

**This half is the one that does the work and the one that gets skipped.** Add a line to `CLAUDE.md`
so it happens at session end without being asked.

### <yyyy-mm-dd> — <what the session was>

**Built:** <one or two lines. The diff has the detail; this is the index.>

**Decided, that the downstream half did not cover:**

| Decision | Why | What would reopen it |
|---|---|---|
| | | |

> **The most valuable table in this file.** It carries *reasoning*, and no diff ever contains
> reasoning. A decision made here and not written down is one the deciding session will contradict
> next week, in good faith, using a document that is now wrong.

**Could not be done, and why:** <blocked · out of scope · needs a decision · needs the Boss to look>

**Changed by hand and not reflected upstream:** <the most dangerous line in the file — anything
adjusted here that the agreed design still shows the old way.>

---

## What does not cross this boundary

| | |
|---|---|
| **Live questions** | Hit an ambiguity mid-task and you cannot ask the deciding session. It routes through the Boss — which is the argument for a fuller downstream half, not a thinner one. |
| **Anything only a human can see** | The running window. Whether the stage labels read clearly. Whether it feels slow. |
| **Approval** | Neither session settles what Asa is. A shared file makes it slightly too easy to pretend otherwise. |
