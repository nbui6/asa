# Roadmap — the Vibe Coding Kit

**Ordered, not dated.** Re-ranked at checkpoints, and only then.
Last re-ranked: 2026-08-24, from a step-by-step analysis of the whole process.

**Effort is in sessions, not t-shirt sizes.** One session ≈ 1–3 hours, which is what actually
exists. "Medium" hides the fact that three sessions is a month.

---

## Part 1 — the process, step by step

Thirteen steps across three phases. For each: what it produces, who is needed, what the kit has,
what is missing, and **how you know it is done** — that last column is also exactly what Asa
displays, so this analysis is the screen's data model as well as the gap list.

### Phase 1 · Decide — is it worth building?

| Step | Produces | Who | Kit today | Missing | Proof it is done |
|---|---|---|---|---|---|
| 1 · Research | Findings with sources and dates | Claude alone | `research` — fired 3× | Findings scatter into whatever document was open | A dated file with sources |
| 2 · Who it is for | `PERSONA.md` | Claude drafts, **Boss corrects** | `persona-check` — fired, blocked a real design | — | File exists; *quits when* written **before** the design |
| 3 · Evidence | One thing someone said or did | **Only the Boss** can observe it | **nothing** | A skill, a field, and a rule | A quote or a behaviour, dated |
| 4 · Cost | Sessions to build · cost per month to run | Claude estimates, **Boss accepts** | `stack-choice` — setup time only · **`business-case` — cost, savings and risk, and it was never referenced here until 2026-08-25** | A *measurement*, not an estimate. Nothing has ever recorded what a round actually cost. | Both numbers, with the assumption behind each |
| 5 · Roadmap | `ROADMAP.md`, ordered | Claude proposes, **Boss approves the order** | `roadmap` — fired | Nothing connects it to steps 3 and 4 | The file, with exactly one item in Now |

**Steps 3 and 4 are the whole weakness of Decide**, and they are the two that decide whether you
build the *wrong thing*. Everything downstream can be perfect and still wasted.

*On step 3:* `discovery` asks "what happens if you don't build it?" once, informally. Then nothing.
Later, `value: high` is typed into a roadmap table — and **a table makes an opinion look measured.**
That is the mechanism by which a thing nobody wants gets built well.

### Phase 2 · Design — what is it?

| Step | Produces | Who | Kit today | Missing | Proof it is done |
|---|---|---|---|---|---|
| 6 · Sketch every screen | A clickable mockup, fake data, labelled | **Claude makes it visible, the Boss makes it right** — he redirects and it is redrawn, repeatedly. Not a yes/no gate. | `sketch-the-product` — new, fired once, cut 8 screens to 2 | Nothing structural. It is the newest skill and has one run behind it. | The mockup exists and the Boss has answered three questions |
| 7 · Pick the stack | An ADR | Claude recommends, **Boss decides** — often one-way | `stack-choice` — fired · ADR template | **Running cost**, same gap as step 4 | An ADR with options considered and what was traded away |
| 8 · Map the architecture | `ARCHITECTURE.md` | Claude alone | `architecture-map` — fired | The one-way import rule is enforced *by review*. A lint is the written trigger at the second module and has not been reached. | The file exists and matches the folder tree |

**Design is the healthiest phase.** All three have fired, and step 6 changed a real decision the day
it was added.

### Phase 3 · Build — make it, prove it, fix it, ship it

Repeats per feature. Steps 9–13 are one round; the three below them fire when their moment arrives.

| Step | Produces | Who | Kit today | Missing | Proof it is done |
|---|---|---|---|---|---|
| 9 · Goal | One sentence, files named | Claude proposes, Boss agrees | `PLAYBOOK.md` §3 | — | The round note exists |
| 10 · Acceptance criteria | Human lines + a machine line | Claude drafts, **Boss agrees before code** | §5 · `templates/ROUND.md` | Was **homeless until 2026-08-24** — agreed in chats that then vanished. Fixed. | The criteria table is filled in |
| 11 · Build | Code, small steps | Claude alone | §4 loop · §7 code rules · `reviewer` agent | **The reviewer has never run. 0 of 3 agents, across 4 rounds.** | `git status` shows the change |
| 12 · Test | Evidence, not a summary | **Boss runs it and looks** | `first-test` · `record-test` hook | — | The hook's timestamp is newer than the files |
| 13 · Commit | A save point | Claude, once the gate allows | `gate-commit` hook — verified | — | The commit exists |
| — · Debugging | The cause, not a guess | Claude alone | `debugging` — fired, found a bug in one exchange | — | The written hypothesis and what settled it |
| — · Regression check | A test so a fixed bug cannot return | Claude alone | `regression-gate` — never fired | Its trigger is "the first bug that comes back". **That has not happened yet** — dormant for a legitimate reason. | The bug has a test |
| — · Handover | It leaves the machine | Claude prepares, Boss sends | `ship-it` — never fired | Nothing has ever left the machine | Someone else ran it |

**Build is strong from step 12 onward** — the hooks made Test and Commit mechanical today, and
they are the two that used to be skipped. **Step 11 has the loudest unresolved fact in the kit.**

---

## Part 2 — what to do about it

Every gap above, ranked. `Now` holds **one live item**, per the kit's own rule.

**Re-ranked 2026-08-25**, after the first end-to-end run of the kit on a real product.

### Done

| Was # | Do | Outcome |
|---|---|---|
| ~~1~~ | ~~Check whether the skills are installed~~ | **2026-08-24.** They were not — `~/.claude/skills` did not exist. Fixed by `install-skills.ps1`. |
| ~~2~~ | ~~Map the 24 skills onto the 13 steps~~ | **2026-08-25.** All 24 placed. **Six collision clusters** and one near-verbatim duplicate clause found. Steps 3 and 11 confirmed as the only real holes. |
| ~~3~~ | ~~Draw the boundaries the mapping found~~ | **2026-08-25.** **13 descriptions edited** so each names the sibling it hands off to, using the pattern `discovery` already had. Duplicate clause removed from `first-test`; `regression-gate` now owns "a bug came back". Standing cost +150 tokens. |
| ~~4~~ | ~~`install-skills.ps1 -Core`~~ | **2026-08-25.** Installs the 14 that have fired, names the 10 it leaves out. Tested both ways. |
| ~~5~~ | ~~Surface ranked work at session start~~ | **2026-08-25.** `orient.ps1` now injects `ROADMAP.md` → `Now`, and flags an unconfirmed `PLAN.md`. **30 assertions, checked in both directions.** This is the fix for *why the analysis was not acted on*. |

### Now

| # | Do | Why it is first | Sessions |
|---|---|---|---|
| 1 | **Take one small real product from idea to shipped**, whatever it is — currently the German memory layer | **In progress.** Rounds 1–2 of 5 done: toolchain, and the app running on a physical phone. Nothing below this is trustworthy until it has happened once, end to end. | 5 total, 2 spent |

**Before round 3 writes any screen code:** run `persona-check` against the signed sketch and write
the missing `PERSONA.md`. It never fired across three sketches on 2026-08-25 — the collision the
mapping predicted, arriving eight hours later. Cheapest moment it will ever have.

### Next

| # | Do | Why | Sessions |
|---|---|---|---|
| 2 | **The `awaiting:` field** — who, what question, since when, what it blocks — plus the one conformance check that covers it | The queue job has no producer. `PLAN.md` now covers plan approval specifically; this is the general case, for every step that stops at the Boss. **Ship the field with its own check** — a weak-material wire with nothing watching it is how the evidence rule got skipped three times. | 1 |
| 2b | **One measurement, two readers** — the state the orient hook computes gets written to a human-readable `STATUS.md` in the same pass | **The asymmetry created on 2026-08-25:** `orient.ps1` now injects project state into the assistant's context at every session start, and the Boss still has to ask a question to learn the same facts. That is the black box, restated. Nico: *"without it, you will be a blackbox for me, while I want to build a good product that I actually understand."*<br><br>**Design constraint that decides the whole item: it must be generated, never maintained.** His last hub note went stale because a human had to update it. One computation, written twice — once into the assistant's context, once into a file he opens. They cannot disagree, because they come from the same read of the same disk.<br><br>**And this is what Asa should display.** Not a reimplementation of the reading — Asa renders `STATUS.md` and the files behind it. **Confirmed by the Boss on 2026-08-26**, unprompted, at the end of round 3: *"I guess we will see this once we have ASA UI directly from there, what we built for what round ect. They will all connect together to be the full product."* He had just had to ask which screen came from which round, because nothing but the assistant could tell him. Resolves the overlap between Asa round 4 ("the stage, measured not typed") and this. | 1 |
| 3 | **Conformance, the remaining 15 checks** — generalise `gate-commit.ps1` from one proof to sixteen | 11 of the 16 "Proof it is done" entries are computable today with no new writes, and one is already implemented. Computed from artefacts on disk, **never from anything the assistant says about its own work.** | 1–2 |
| 4 | **Decide the agents** — hook them where the wiring map placed them | No longer an open question: `reviewer` → step 11, `note-taker` → the report job, `stack-review` → conformance over Design. All three were unattached, not idle. | 1 |
| 5 | **Cost, measured rather than declared** — sessions spent and rough token spend, recorded per round | `templates/ROUND.md` has a `Cost:` line as of 2026-08-25 and nothing has yet filled it with a measurement. "Less costly" is the first word of the goal and the only one with no instrument. | 1 |
| 6 | **A kit installer** — day-one files, `git init`, the pass/fail command, calling the hooks and skills installers | Three pieces exist; this joins them so starting a project is one command instead of remembering three. | 1 |
| 7 | **The evidence step** — an `evidence:` field, and one rule: nothing reaches `Now` without something observed | Closes the biggest hole in Decide. One field and one gate. Waits behind `awaiting:` because they are the same mechanism twice and the second is cheaper once the first exists. | 1 |

### Then — the checkpoint

**Stop after item 2 and re-rank.** Everything below is guesswork until one real product has gone
through the kit end to end.

### Later

| # | Do | Why it waits | Sessions |
|---|---|---|---|
| 7 | Asa round 4 — the steps, measured not typed | Criteria already written. Waits because **Asa displays the process, so the process should be right first** — otherwise the screen faithfully shows holes. | 1–2 |
| 8 | Asa UI — one visual language, action buttons at the top | Six findings from today's review. Layout only, no new information. | 1 |
| 9 | Asa round 3 — the handoff buttons | Was next, overtaken. Still the single highest-value screen element. | 1 |
| 10 | A home for research findings | Real but small; findings currently land in whatever document was open. | 1 |

### Not scheduled, and why

| Item | Why not |
|---|---|
| `regression-gate` | Its trigger is a bug that comes back. **That has not happened.** Dormant for a good reason — leave it. |
| `ship-it` | Nothing has left the machine. It fires when item 6 does. |
| The five other hubs | **Dropped, 2026-08-24.** If a marketing tool is ever needed, it is a product you build *with* the kit, not a part of it. A direction, never a roadmap. |
| Sharing with a colleague | Deferred. The structure supports it; nothing has been tested by anyone else. |

---

## How this list was made

Not from opinion. Each item is a gap found by walking all thirteen steps and asking three
questions: what does this step produce, who is needed, and **how would you know it was done?**
A step that cannot answer the third question is either missing or unfinished — and that is every
item in `Next`.

**The ordering rule used:** anything that makes other items *meaningless* if it is wrong goes
first. That is why a one-command check is ahead of four real features.
