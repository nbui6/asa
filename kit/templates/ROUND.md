# Round <n> — <the feature, in five words>

**Date started:** <yyyy-mm-dd> · **Status:** criteria agreed / building / testing / done
**Size:** big change / small change
**Plan:** <link to `PLAN.md`> · **confirmed by** <name> on <yyyy-mm-dd>
**Sketch:** <link to the stage-0 sketch> — or **"not needed, because …"**
**Cost:** started <yyyy-mm-dd hh:mm> · finished <hh:mm> · elapsed <h m> · round-trips to the Boss <n> · **kit changes during this round <n>** · running cost <€…/month, or €0>
**Kit freeze:** yes, kit v<n> — observations go to `KIT-LOG.md` tagged `[FROZEN]`, nothing changes until Commit / or **no, because …**

> **Fill the Cost line. It has been empty for four rounds.** *"Less costly"* is the first word of this
> kit's goal and the only one with no instrument. Elapsed time, round-trips and kit changes are all
> measurable from inside the session; **token spend is not — leave it out rather than estimating it.**
> A number invented for a field is worse than an empty field, because the field then looks answered.
>
> **Kit changes during the round is the one people forget**, and it is where a round quietly triples.
> On 2026-08-26 a round of one session's product work carried **seven kit versions**, each justified,
> none counted. See `PLAYBOOK.md` §14, *The freeze*.

> **If the Plan line has no confirmation date, stop.** This note should not exist yet —
> `PLAYBOOK.md` §3, stage 0b. Delete it, write the plan, and get the line signed.

> **The Sketch line is not optional and not decorative.** On 2026-08-25 a round note was written
> for a twelve-screen product that had never been sketched. The skill existed, its trigger
> matched, and nothing consulted it — a skill only fires if something asks. A blank line in a
> template does ask. Fill it or write the excuse; both are answers, an empty line is not.

> **Why this file exists.** On 2026-08-24 a round was found to have **no written acceptance
> criteria anywhere** — not in the repo, not in the project notes, not in the roadmap. They had
> been agreed in a chat that no longer existed, so "is it done?" could not be answered without
> reconstructing them from a commit message.
>
> Criteria written down are the difference between finishing and stopping.

---

## Goal

<One sentence. If it needs two, it is two rounds.>

**Files that change:** <name them. If you cannot, explore first — read-only — until you can.>

## Acceptance criteria

Observable, in a fixed number of steps, not a judgement call. Fill the **Result** column during
Test — not before.

| # | Human — could someone else run this and reach the same yes/no? | Result |
|---|---|---|
| 1 | <step → step → what you should see> | |
| 2 | | |
| 3 | | |

| Machine | Result |
|---|---|
| `<the pass/fail command>` passes | |

<If there can be no machine line, write **"Machine: none, because …"**. Naming the absence is the
point; an unstated gap is the one that surprises you.>

**Result uses exactly three words:**

| Word | Means |
|---|---|
| **evidenced** | You saw it, or a command printed it |
| **reported** | Someone said so |
| **not run** | Nobody looked |

## Decisions needed

`[NEEDS DECISION: …]` — anything that must be settled and is not in the charter or the persona.
Written here and **stopped on**, rather than guessed. A guess at this stage becomes an assumption
baked into the architecture.

- <none yet>

## Terms introduced

Every word that got explained in conversation during this round. **One line each, and then it goes
into `GLOSSARY.md`** — with the plain explanation, *why it mattered here*, and an analogy where a
plain sentence does not land on its own.

> **Why this field exists.** On 2026-08-25 a round explained the NDK, API levels, the share sheet,
> line endings, `index.lock` and mandatory parameters. **Not one reached the glossary.** The round
> note would have said `NDK 28.2.13676358` in four months' time with no way back to what that was.
>
> An explanation given in a conversation is gone. Capture it while it is fresh or lose it — and the
> tooltip, the hub and the log are all worthless over an empty glossary.

| Term | Went into the glossary? |
|---|---|
| | |

**Rule for the analogies:** an analogy may *illustrate* a conclusion, never *be* one — and no
analogy is better than a forced one. A near-fitting analogy misleads, because the parts that do not
correspond are invisible.

## Not in this round

<The ideas that came up and were pushed away. Naming them is what stops them creeping back in
during Build.>

- <…>

---

## After: what actually happened

<Filled in at Commit. Two or three lines.>

**The gate — nothing below this table gets filled in until all three lines are green.**

| # | | State |
|---|---|---|
| 1 | The result was **shown** — the screen itself, or the command and its real output | |
| 2 | The Boss was **asked** whether it is right | |
| 3 | He said **yes** — or named a fix, which was made and shown again | |

**No round is finished before line 3, and the commit comes after it, never before.** *Added
2026-09-02: a session reported a version done having shown nothing and committed nothing. See
`PLAYBOOK.md` §14, "Done is not delivered".*

- **Commit:** <hash>
- **Defects found while verifying:** <the ones you did not expect — these are the valuable ones>
- **Anything the process itself got in the way of:** → one line into `KIT-LOG.md`
