# Kit log

What the process itself got wrong, session by session. Written with the `kit-feedback` skill.

**One entry changes nothing. A pattern changes the kit.** Wait until something appears twice
before editing the package — otherwise it churns after every bad day and never settles.

> ### This log is one of two. Check which before writing.
>
> | Goes here | Goes to the operating layer's log |
> |---|---|
> | **How we build** — a step that failed, a skill that did not fire, a check that measured the wrong thing, a command that stranded someone | **How the work is remembered** — something rebuilt that already existed, a decision re-argued, a stale fact read as current, a parked idea whose trigger fired and never came back, two numbers disagreeing |
>
> **The test:** *could a change to the build process have prevented this?* Yes → here. **No, because
> the information already existed and nothing looked at it** → the other one.
>
> *Added 2026-08-31. Until then everything landed here, **including findings about deciding and
> remembering — which were recorded and never acted on**, because this kit has no step that could act
> on them. Named by the first outside tester: "the second kind gets recorded as a note about the kit,
> where it does not belong." Same error as a product skill defaulting into the kit, one level up.*

---

## What the process prevented

**Added 2026-08-25, because this file recorded only failures.** A log of pure failure makes the kit
look worse than it is, and — the practical reason — **a retirement decision needs both columns.**
Whether `sketch-the-product` earns its place cannot be judged from a file that lists only its
misses.

Estimates are stated as estimates. What is not an estimate is that each of these took minutes.

| Date | What was about to be built | What stopped it | Cost avoided *(est.)* |
|---|---|---|---|
| 2026-08-25 | A tablet that wakes as you walk past, shows weather, plays music | **Step 1 · research** — Echo Show 8 does all three, presence detection included, ~€80. Two no-code alternatives as well. | weeks |
| 2026-08-25 | A twelve-screen German writing app | **Stage 0 · sketch** — drawn in one message, rejected in one message. *"I dont like it."* | ~6 rounds |
| 2026-08-25 | A chat-plus-flashcards language app | **Step 1 · research** — Langua and LingoStar already combine conversation, correction and spaced repetition. €13–29/month, or a free tier. | ~12 sessions |
| 2026-08-25 | The surviving idea, as first scoped | Two rounds of simplification, each driven by the Boss | 12 sessions → **5** |

**Reading:** on the day the kit first ran end to end on a real product, its most valuable output
was three decisions **not** to build. Stage 0 and step 1 are the two cheapest things in the package
and they carried the entire session.

**Also worth recording as a win:** the rule agreed that morning — *the kit changes only as a
by-product of building something else* — held on its first day. All five changes made on 2026-08-25
came from friction encountered while building. Zero speculative additions, against the 4-of-5
dormancy rate of the scaling skills added by argument on 2026-08-23.

---

### 2026-08-22 — the kit itself — building and first use

- **Slowed me down:** nothing in the process. The *volume* was the problem — 60 files produced in
  one day, and Nico said plainly: *"I am a bit lost in the details right now."*
- **Skipped:** the five session stages were never run on the kit's own work. It was built without
  using itself.
- **Missing:** (1) a door — one entry point per project, now `templates/PROJECT-HOME.md`.
  (2) a promotion trigger — seven generic things were invented inside one project and had to be
  moved back by hand. (3) this log.
- **Skills that fired:** `discovery` · `roadmap` · `stack-choice` · `research` · `toolchain-map` ·
  `process-audit` · `obsidian-docs` · `persona-check` (as a check, not run) · `explain-as-we-go`
- **Worked well:** `process-audit` found nine real defects on its first run, including one — the
  reviewer agent's instructions duplicated and already drifted — that was the exact failure the
  kit warns about, inside the kit.

**Counted honestly: 23 skills exist. 8 have ever fired. 3 agents exist. 0 have ever run.**

---

### 2026-08-23 — Asa — Round 0, the shell

- **Slowed me down:** nothing. Five stages on a setup round took minutes, which is the right cost.
- **Skipped:** **the evidence rule, twice.** Acceptance criteria asked for pasted command output;
  Nico replied "done" and "it works". Round 0 is recorded as *reported, not evidenced*.
- **Missing:** nothing new.
- **Skills that fired:** `roadmap` · `kit-feedback` · `explain-as-we-go`
- **Worked well:** naming five hubs and building none of them. The scope stayed at one round.

---

### 2026-08-24 — Asa — Round 1, one project's state

- **Slowed me down:** nothing. Writing acceptance criteria before the code took two minutes and
  criterion 4 ("the raw data is visible on screen") shaped the design of three files.
- **Skipped:** the evidence rule again — third time. See Pattern 1, now revised.
- **Missing:** nothing new. `first-test` earned its place: "test the logic with rules in it"
  pointed straight at the parser, and the parser is where the one real bug was.
- **Skills that fired:** `architecture-map` · `first-test` · `explain-as-we-go` · `kit-feedback`
- **Worked well:** **§7 rule 5 caught a bug before it ran.** "Show the raw data at every
  boundary" made me write the frontmatter into the UI, which made me look at the value I had just
  written into `asa.md` — a Windows path with doubled backslashes the parser would not unescape.
  A design rule found a defect with no code executed.

---

### 2026-08-24 — Asa — Round 2, every project on one screen

- **Slowed me down:** nothing in the process. **Delivery** was the problem: the round's code was
  sent as a zip that was never extracted, so two exchanges were spent debugging an app that had
  never received the new files. Fixed by sending a script that writes the files itself.
- **Skipped:** the round was never verified against its criteria — Nico stopped it, correctly, to
  ask a bigger question.
- **Missing — the real finding.** Nico: *"we should show me the big idea, big picture UI at the
  end, something roughly. So we both understand each other, and not spending so much time
  building small features, but at the end the big picture isnt what I want."*

  He is right, and the gap is structural. **The five stages all run inside one feature.** Nothing
  in the kit ever asked what the finished product looks like. Two rounds were built against a
  roadmap that had an order but no destination. New skill `sketch-the-product`, and a new
  **stage 0** in `PLAYBOOK.md` §3.

  Note *who* found this: the Boss, not the process. `process-audit` reads the documents against
  each other, so it cannot see something absent from all of them. A missing stage is invisible to
  an audit of the stages that exist.
- **Skills that fired:** `debugging` · `persona-check` (on the sketch) · `kit-feedback` ·
  `explain-as-we-go` · `sketch-the-product` (its own first run)
- **Worked well:** `debugging`'s written hypothesis. *"If I'm right, `projects_scan.dart` will be
  missing from `lib\core\"* — one directory listing settled it in one exchange, instead of
  guessing at hot reload.
- **Second, smaller finding — a real defect with a real cause.** The mockup's em dashes rendered
  as `â€"`. Cause: Windows PowerShell 5.1 reads a `.ps1` file as Windows-1252 unless the file
  begins with a UTF-8 byte order mark. Mine had none. Fix: write installer scripts with a BOM.
  Filed as a verified finding, not a mystery.

**Counted honestly: 24 skills exist. 9 have ever fired. 3 agents exist. 0 have ever run.**

---

### 2026-08-24 — the kit — v1.0 released

- **Slowed me down:** nothing. The session produced a release rather than more files, which is the
  first time that has happened.
- **Skipped:** Asa round 2 was never verified against its criteria and is still uncommitted. It was
  overtaken by a bigger question and left open rather than closed. **Named, not hidden.**
- **Missing — found by the Boss again, twice in one day.** (1) *"Where can I see the features
  created from ideas, and the ranking waiting for the roadmap?"* — a whole stage of the pipeline had
  no screen. (2) *"Where is it that the boss say yes? Where is the self-improvement when the boss
  demands things the product isn't capable of yet?"* — the approval loop and the learning loop were
  both absent from a mockup of the whole product.

  **Pattern forming (see Pattern 2).** Every structural gap this week was found by the person using
  the kit, never by the kit. Twice is now three times.
- **Skills that fired:** `persona-check` (verdict: **block**) · `sketch-the-product` · `dataviz` ·
  `kit-feedback` · `explain-as-we-go`
- **Worked well:** `persona-check` refused to run without a persona, so `PERSONA.md` for Asa got
  written from dated quotes — and the review then found that **six of Asa's eight screens rebuild
  Obsidian**, reversing the project's own founding decision (ADR 0001). A skill blocked work I had
  already designed. That is the check earning its place.
- **A rule this project wrote, and I broke.** `gate` was retired in playbook v4 for being confusing.
  It came back six times in a new screen design. Now §7 rule 11: **a retired term is a banned term.**

**Counted honestly: 24 skills exist. 14 have fired (the old count of 9 was stale). 3 agents exist.
0 have ever run — across four rounds.**

---

### 2026-08-24 — Asa — the hooks round, complete

- **Slowed me down:** nothing. Claude Code ran the whole thing — committed the hooks, wrote
  `CLAUDE.md`, tested the gate by breaking a line, undid it, and re-armed the gate by re-running
  the check. **The Boss approved once at the start.** First time that has happened.
- **Skipped:** nothing.
- **All four criteria evidenced.** Criterion 4 — the gate blocks *after* a code change — is the one
  that proves the gate tracks current state rather than "a test ran once".
- **Found while verifying:** the blocked message printed an absolute path. Reported honestly as
  *"I can't confirm without re-instrumenting, and I'd rather not guess in a commit message."*
  That is the evidence rule working without anyone enforcing it.
- **Worked well:** §7 rule 5 again. The gate prints the raw path, a human read it, and a defect
  surfaced. Three finds this week from one design rule.

**Counted honestly: 24 skills exist. 14 have fired. 3 agents exist. 0 have ever run — five rounds.**

---

## Patterns — updated at each retrospective

### PATTERN 1 — the evidence rule is too broad *(seen twice: 2026-08-21, 2026-08-23)*

Asking for pasted output for *everything* gets ignored. `kit-feedback` says the fix is never to
restate a rule more firmly, so the rule is narrowed instead:

> **Paste output when the assistant will reason from it** — test results, error messages, version
> numbers, device lists. **The human's word is enough for "did you see it"** — a window that did
> not open is not something a person misses.

Applied to `PLAYBOOK.md` §5 and §8 on 2026-08-23. **It did not hold** — third occurrence
2026-08-24, where the test result was reported as "all good, passed" rather than pasted.

**Revised again, 2026-08-24.** The cost is the copying, not the rule. So:

1. **Ask for one line or one word, never "the output".** "Did it say `All tests passed`?" is a
   one-word answer; selecting and copying a terminal is not.
2. **Record which criteria were evidenced and which were reported**, in `CLAUDE.md`. This makes
   the honesty visible without needing the Boss to do anything — which is the only kind of rule
   that survives.

The second half is the real fix. A rule that depends on someone's cooperation every single time
has a cost problem; a rule that records the truth either way does not.

*(Earlier note — assistant message length — has not recurred since messages were shortened. Not
yet a pattern.)*

### PATTERN 2 — the kit cannot find its own missing pieces *(seen three times: 2026-08-24 ×3)*

Every structural gap so far was found by the Boss using the kit, never by the kit reviewing itself:

| Gap | Found by |
|---|---|
| No stage asked what the finished product looks like | *"we should show me the big picture at the end"* |
| The candidate-features stage had no screen | *"where can I see the features created from ideas?"* |
| Neither the approval loop nor the learning loop existed | *"where is it that the boss say yes?"* |

**Why `process-audit` cannot catch these:** it reads the documents against each other, so it finds
contradictions, dead references and drift — it found nine. **Absence is not written in any
document**, so there is nothing for it to compare.

**Acted on, 2026-08-24:** `PLAYBOOK.md` §14 states this limit in the kit itself, and the
session-closing question is phrased *"did anything about the process get in the way"* rather than
*"did any rule fail"* — the first can surface an absence, the second cannot.

**Not solved.** This is a mitigation. The kit is **improvable with a human as the trigger**, not
self-improving, and v1.0 says so out loud rather than implying otherwise.

### PATTERN 3 — tests get written against what the author believes *(seen three times: 2026-08-24)*

| Where | The test asserted | Result |
|---|---|---|
| `widget_test.dart` | the mangled title | passed while the screen was wrong |
| `test-hooks.ps1` | an invented field name | passed while the hook never fired |
| `test-hooks.ps1`, again | a message check that could not see the bug | passed against the buggy code |

The third happened **one message after** `PLAYBOOK.md` §5 gained the rule that prevents it. The
rule was followed only because it was applied deliberately, not because it had been written.

**What actually works:** run the check *both ways*. Keep the fix, run the suite; restore the bug,
run it again; the failure must appear. Two commands, and it is the only thing that has ever caught
this.

**Not solved.** There is no trigger that forces it. A `PostToolUse` hook on a test file could ask
the question, and that is the next candidate after the agent decision.


---

### 2026-08-25 — stage 0 was skipped on the first real product

**What happened.** Nico said "continue" on the assistant app. The assistant went straight to
round 2 — goal, ten files, four acceptance criteria — for a product that had **never been
sketched**. He stopped it: *"I dont know how it should look like, what is the plan, roadmap ect.
I need to know the big picture before I say go."*

The sketch then took one message and he rejected the product outright. **That is the stage
working; the failure is that he had to ask for it.**

**Why it was skipped.** Not a missing step — `sketch-the-product` exists, and its description
already contains the exact trigger that applied: *"a roadmap of features exists but no picture of
the destination does."* The trigger was correct. **Nothing consulted it.**

That is the materials finding from the same day, arriving as a real defect: a skill is a
*conditional* connector. It fires only if something asks the question at the right moment, and at
the Goal stage nothing did.

**Acted on immediately, 2026-08-25** — a structural fix, so §14's "wait for the second
occurrence" does not apply; a rule that nothing checks is an absence, not a rule that worked badly:

- `templates/ROUND.md` gains a **`Sketch:`** line at the top — a link, or the words
  "not needed, because …". A visible blank asks to be filled; a description in a folder does not.
- The same edit adds the **`Cost:`** line agreed earlier the same day.

**Not yet done.** `orient.ps1` should print one line at session start when a project has code
under `lib/` or `src/` and no sketch file anywhere. That moves the check from a strong material
(template) to the strongest one (hook). Estimated half a session, and it needs the 25-assertion
suite re-run.

**The general lesson, and it now has two instances:** when a rule is skipped, do not reword the
rule. Ask what material it is made of, and move it up one level — playbook rule → template field →
hook. The evidence rule went rule → hook and stopped being skipped. This one has gone
description → template field.

---

### 2026-08-25 — the plan had no gate, and the assistant kept reaching for the keyboard

**What happened.** Across one conversation the assistant offered to start building **three
times** before any plan existed: a round note with ten files, a Claude skill, and a two-tier
build option. Nico stopped all three. The last time he named the actual defect:

> *"you need to build this in our kit, the plan needed to be confirmed before building anything"*

**Why it kept happening.** Each offer was locally reasonable — research was done, the shape was
discussed, the next step was obvious. **But approval had no artefact.** The 13-step analysis on
2026-08-24 already found this: the Boss is required at ten of sixteen steps and not one of them
records that it is waiting. This is that finding arriving as behaviour rather than as a table.

The three offers were not impatience. They were the absence of a place where "he said go" could
be written down — so it was inferred from the conversation going well, which is not the same
thing and never will be.

**Acted on immediately, 2026-08-25** — structural, so the "wait for the second occurrence" brake
does not apply. And it is the third instance today of the same class, after the stage-0 skip:

- **`PLAYBOOK.md` §3 gains stage 0b — "the plan, confirmed."** Between the sketch and the five
  stages. Its only output is `PLAN.md` and its only completion condition is a filled-in
  `Confirmed by: <name>, <date>` line.
- **`templates/PLAN.md`** — new. Shape · who it is for · **deliberately not in it** · the rounds ·
  the riskiest unknown · the checkpoint where stopping is allowed · cost · open questions, each
  naming the round it blocks.
- **`templates/ROUND.md` gains a `Plan:` line** carrying the confirmation date, and an instruction
  to delete the round note if that date is missing.

**It worked on its first use, against the assistant.** The plan drafted for the German memory
layer **cannot be confirmed** — open question 1 (share sheet versus the app owning the chat)
blocks round 2, which is the first round to be built. Under the old process a round note would
already have been written for a round whose shape is undecided.

**The pattern, now with three instances and a rule:**

| Skipped | Was made of | Moved to |
|---|---|---|
| The evidence rule *(3× before 24 Aug)* | a playbook rule | a hook — never skipped since |
| Stage 0, the sketch *(25 Aug)* | a skill description | a template field |
| Plan approval *(3× in one conversation, 25 Aug)* | nobody's job | a stage + a template + a signature line |

**When a rule is skipped, do not reword it.** Ask what material it is made of and move it up one
level. Rewording has never once worked; changing the material has worked every time.

---

### 2026-08-25 — the plan was delivered with a sketch that contradicted it

**What happened.** One hour after stage 0b was added, a plan was written for the German memory
layer and handed over for signature. Its sketch still showed **two screens the plan had cut**. The
assistant noticed, wrote the contradiction into the plan as a parenthetical, and asked for
confirmation anyway. Nico:

> *"give me the sketch pls, written is not enough"*

**Why it happened.** Stage 0b required a `Sketch:` link. It did not require the sketch to still be
**true**. A link is cheap to satisfy and says nothing about whether the picture and the plan
describe the same product.

Worse than a missing field: the drift was *seen and documented*. Writing down a problem felt like
handling it. It is not — a footnote admitting the sketch is wrong still asks someone to approve
from prose, which is exactly the check stage 0 exists to prevent.

**Acted on, 2026-08-25:**

- **`templates/PLAN.md`** — the Sketch line becomes `<link> — matches this plan as of <date>`, and
  a rule: **a plan whose sketch contradicts it cannot be confirmed. Redraw first.**
- **`PLAYBOOK.md` §3, stage 0b** — "Not allowed" now includes *asking for confirmation while the
  sketch and the plan disagree*; "Done when" now requires the sketch to match **before** the
  signature.

**The reusable sentence:** *people agree with prose and argue with screens.* That is the whole
value of stage 0, and it is thrown away the moment approval is sought from text — however honest
the text is about its own gaps.

**Fourth instance today of the same class**, and the pattern now holds without exception:

| Skipped | Was made of | Moved to |
|---|---|---|
| The evidence rule *(3× before 24 Aug)* | a playbook rule | a hook |
| Stage 0, the sketch | a skill description | a template field |
| Plan approval *(3× in one conversation)* | nobody's job | a stage + a signature line |
| **The sketch being current** | **a link** | **a link plus a date, and a condition on confirming** |

A field that can be satisfied without being true is not yet a check. Each of these was fixed by
changing what the rule is *made of*, never by restating it.

---

### 2026-08-25 — the mockup was published blank

**What happened.** The third sketch was written, published, described screen by screen in chat,
and offered for signature. Nico opened it:

> *"I see nothing in the mockup screen."*

One stray character. The first screen's name was written `n:"„Mach Karten draus""` — an ASCII `"`
used as the German closing quote „ … “. That ended the string early, the file stopped being valid
JavaScript, and **every screen was blank.**

**The uncomfortable part is not the typo.** It is that nothing between writing the file and asking
for a signature required anyone to look at it. The page was described in detail — three screens
recommended by name, one called "the actual product" — entirely from the source, none of it from
the rendered result.

**This is the kit's oldest rule, pointed the wrong way.** `START-HERE.md`: *"You run the code. You
look at the result. A summary from the assistant is not evidence."* That rule has always been
aimed at the human running code. It was never aimed at **the assistant producing an artefact** —
and a mockup, a diagram, a dashboard and a report are all artefacts that run.

**How it was found and fixed, both ways:**

```
node --check  ->  SyntaxError: Unexpected string   (the bug, located, not guessed)
fix, re-check ->  SYNTAX OK
reintroduce   ->  SyntaxError again                (§5: the check can fail)
render        ->  7 screens, 164-348 chars of content each, 0 page errors
look          ->  two screenshots opened and read
```

**Acted on, 2026-08-25** — `PLAYBOOK.md` §3 stage 0: "Not allowed" gains *sending a mockup nobody
has opened*; "Done when" now requires it to have been **rendered and every screen clicked by
whoever made it**, before the three questions.

**Fifth instance today of one pattern, and the sharpest version of it:**

| Skipped | Was made of | Moved to |
|---|---|---|
| The evidence rule *(3× before 24 Aug)* | a playbook rule | a hook |
| Stage 0, the sketch | a skill description | a template field |
| Plan approval *(3× in one conversation)* | nobody's job | a stage + a signature line |
| The sketch being current | a link | a link plus a date, and a condition on confirming |
| **Looking at the artefact** | **a rule aimed only at the human** | **a completion condition on whoever makes it** |

**The general sentence, and it is the one to keep:** every rule in this kit that says "verify"
silently assumes the verifier is Nico. Wherever the assistant produces something that runs, the
same rule binds the assistant — and there is no reason it should have taken five instances in one
day to notice.

---

### 2026-08-25 — retrospective: the whole route, run once, on a real product

The first session in which the kit was used end to end on something that was not itself.

- **Worked:** step 1 and stage 0 killed three products in minutes each — see *What the process
  prevented* at the top of this file. `debugging` held twice: the empty `$dest` and the licence
  contradiction were both settled by one measurement block, not by retrying.
- **Slowed us down:** nothing in the process. What cost time was **instructions written from
  documentation instead of from the machine** — an obsolete `--android-licenses` step, and the NDK
  called optional when Flutter 3.47 pins an exact version. One failed 10-minute build.
- **Skipped:** stage 0 (recovered when Nico asked for it), and plan approval three times.
- **Skills that fired:** `research` ×3 · `sketch-the-product` ×3 · `roadmap` · `debugging` ·
  `explain-as-we-go` continuously · `kit-feedback`.
- **Never fired and should have:** `persona-check`. Six screens were designed and the fit check was
  never run — the `sketch-the-product` skill's own §6 says to run it immediately afterwards, and
  that instruction was read and not followed. **Log line, not a change: first occurrence.**

**One change from this retrospective, and it is a criteria rule:**

> On a **toolchain** round — a new platform, a new SDK, a new device — write every acceptance
> criterion as something **the product does**, never as something **a tool reports about the
> setup**.

Round 2 proved it in one table. Criterion 1 was *"`flutter doctor` shows a tick"* and **failed**,
while criteria 3 and 4 — *"the counter increments on the phone"*, *"unplug the cable and it still
opens"* — passed and were the truth. `flutter doctor` is now wrong twice on that project. A
criterion that checks a tool's opinion of itself inherits every one of that tool's bugs.

**Also added:** `PLAYBOOK.md` §14, *"When a rule gets skipped, check its scope before writing a new
one"* — the five-row table that explains every failure of this session, and the two corollaries.

**Still open, carried forward, none of it blocking:** the `awaiting:` field · cost actually being
*measured* rather than merely having a line in the template · the eleven skill-boundary edits ·
`persona-check` against the signed sketch before round 3 builds any screen.

---

### 2026-08-25 — why the analysis was not acted on

Nico, after `persona-check` failed to fire on three sketches: *"why we had the analysis but didnt
act on it?"*

**Two causes, both structural, neither of them anyone's memory.**

**1. A rule written that morning blocked the work it was written to prioritise.** *"The kit changes
only as a by-product of building something else"* is a good brake on speculative additions — the
evidence is 4 of 5 argued-in scaling skills dormant against 4 of 4 friction-driven ones firing. But
it conflated two different things:

| | Needs |
|---|---|
| A **new idea** about the kit | friction, to justify it |
| An item **already ranked** from a measured finding | a slot, nothing more |

With no exception clause, the ranked skill-boundary edits could never be started — every session
belonged to the product. **The collision they described then caused a real miss eight hours later.**
Fixed: the rule now carries the exception, in `PLAYBOOK.md` §14.

**2. Three of the session's five conclusions never reached a file at all.** The mapping and the
ranked list went into `ROADMAP.md`. The kit-change rule and the stopping condition went **nowhere** —
agreed in conversation, and a grep for either found only a passing mention inside a log entry
written hours later.

That is the approval defect one level up. **An agreement in a conversation is not an artefact.**
Fixed: `PLAYBOOK.md` §14 now has *"An analysis is not finished until its conclusions are in a file
something reads"*, with a five-row table naming the destination for each type of conclusion.

**3. And nothing ever read the file that did get written.** `ROADMAP.md` held the ranked item all
day. The orient hook injects `CLAUDE.md` → *Where we are*, and nothing else. **A ranked item in a
file nobody opens is indistinguishable from an item nobody ranked.**

Fixed mechanically, which is the only fix that has ever held: `orient.ps1` now injects
`ROADMAP.md` → `Now` at session start, and flags a `PLAN.md` whose `Confirmed by` line is unsigned.
**30 assertions, 0 failures, and all five new ones verified to fail against the old code.**

**Two of the five new assertions passed vacuously on the first attempt** — negative checks that are
trivially true when nothing is printed at all. Paired with the positive signal and re-verified.
That is the fourth appearance of Pattern 3 this week, caught this time by doing what §5 says
instead of trusting it.

**Everything else the analysis predicted, closed the same session:** 13 boundary lines · the
duplicate clause · `install-skills.ps1 -Core` (14 installed, 10 named, tested both ways) ·
`business-case` wired into step 4 · the agents placed and recorded · the roadmap re-ranked with a
`Done` section so this cannot happen silently again.

**The sentence worth keeping:** *an analysis produces two artefacts — the finding, and the place
the finding will be read from.* Only the second one changes anything.

---

### 2026-08-25 — the assistant sent the Boss to look for a download button

A folder on his machine — `Documents\Claude\Vibe Coding` — was **connected to the session the whole
time.** The assistant wrote the kit changes to its own workspace, zipped them, told him to click a
download button, and gave him two commands to unpack it. The zip was not where the instructions
assumed. Both commands failed. He said:

> *"if you could put things directly somewhere, dont make me do things you can actually do it
> yourself. Please put that in the kit"*

**The capability was available and unused for a whole session**, including while he was pasting
terminal output by hand.

**Acted on, 2026-08-25** — `PLAYBOOK.md` **§15, who does what.** `START-HERE.md` had always stated
the human's half — *you run the code and you look at the result* — and the assistant's half had
never been written down:

> **If the assistant can do it, the assistant does it. Handing the human a task the assistant is
> capable of performing is a defect, not politeness.**

With the test to apply before every instruction — *can I do this myself with a tool I have?* — and a
short list of what genuinely stays with the human. Every item on that list is there because **the
human's involvement is the point** (running the check and looking, approving the plan, physical
hardware, credentials, judgement, anything legal), never because the work is fiddly. Fiddly is what
the assistant is for.

**Same root as the whole session.** Five failures at the *read-it-back* link, and this one is the
sixth at a link nobody had drawn at all: **the assistant never checked what it could already do.**
Not a missing capability — an unread one. `get_device_info` would have answered it in one call, at
any point in eleven hours.

**The measurable difference, immediately:** the same delivery, done properly, took two tool calls and
zero instructions to him. The previous attempt took a zip, two failed commands and an apology.

---

### 2026-08-25 — "do it yourself" is not "do the tool's job by hand"

Minutes after §15 was written, the assistant applied it badly. Having gained write access to the
repo, it copied the hook scripts into `.claude\hooks\` **by hand** instead of letting
`install-hooks.ps1` place them. Nico then ran the installer — from that folder — and it died:

```
Copy-Item : Cannot overwrite the item ...\.claude\hooks\orient.ps1 with itself.
```

**It died before registering anything**, so `settings.json` was never written. The visible symptom
was a copy error; the actual damage was that no hook was installed and nothing said so.

**Two distinct defects, both fixed:**

- **The script.** Running an installer from its own destination is not a user error worth an
  exception — it is what happens the first time anyone re-runs the installed copy. It now detects
  the same folder, skips the copy, and **carries on to the registration step, which is the part
  that matters.** Proved both ways: the old code throws on that path, the new code completes.
- **The rule.** §15 says *if the assistant can do it, the assistant does it.* That is about **work**,
  not about **bypassing tools**. Doing a tool's job by hand leaves the system in a state the tool
  does not expect — and the tool is the thing with the guards, the ordering and the registration
  step in it.

> **Use the tool. Do not reimplement the tool.** If a tool exists for the job, run it — the
> capability to write files is not permission to skip the thing that knows the order.

Second install defect the same hour: `-Project` was a mandatory parameter, so PowerShell prompted
with a bare `Project:` and Nico read it — reasonably — as a request for a project *name*. Now it
defaults to the current folder, prints the resolved path before acting, and refuses outright if the
folder is not a git repo.

**Both were found by a human running it, not by the suite.** The hook suite tests the three hooks and
has never tested the installer, which is the one script a new user runs first. Logged, not fixed:
first occurrence.

---

### 2026-08-25 — the same idea, twice, and only one version got a real answer

Close to a controlled test, by accident. Explain mode was proposed twice on the same evening.

| Format | What came back |
|---|---|
| A written proposal — two mechanisms, a coverage rule, a comparison table, all of it organised | *"I think so, let's try that"* |
| A working demo with a toggle he could press | *"I am very happy with this"* |

And the reverse the same day: a twelve-screen product survived several messages of **description**
and was rejected in four words the moment it was **drawn**.

Then he named it himself:

> *"I also appreciate that you show me the mockup. I see now, I can only approve things after seeing
> mockup."*

**This is a condition on approval, not a preference**, and treating it as a preference is how a
whole plan gets signed on "I think so".

**Acted on 2026-08-25:**

- **`BOSS.md`** — new section, *"He approves what he can see, not what he reads"*, with the two
  results above as the evidence.
- **`PLAYBOOK.md` §3 stage 0b** — approval needs something to look at, **always, not only for
  screens.** With the non-UI equivalents named: real sample output, a worked example with actual
  values, a before-and-after. Never a description of what the output would be like.

**The trap this closes.** Stage 0b already required a *current sketch* — but only for products with
screens. Everything else could still be approved from prose, which is most of what this kit produces:
process changes, rules, plans, scripts. **The gap was that "mockup" was read as a UI word.** It is
not; it is a word about being able to see the thing before agreeing to it.

**And the cost objection does not survive the numbers.** The demo took one pass and replaced an
argument that had already gone wrong once. The sketch that killed the twelve-screen product took one
message against an estimated six rounds. **Building the thing to look at has been cheaper than
arguing about it every single time it has been tried.**

Third instance of one pattern, now with a name: *people agree with prose and argue with screens.*

---

### 2026-08-25 — "screenshot above" when nothing had been sent

**Twice in a row**, Nico said *"I dont see it."* Both times the assistant guessed at a cause and
fixed something — a marker that was too small, then the same marker again. **Both diagnoses were
wrong.**

The actual cause: the assistant **rendered screenshots, opened them to check its own work, and then
wrote "screenshots above"** — while never sending them. Viewing a file is not delivering it. From
Nico's side there was nothing above.

**Two separate defects, and the second is the worse one.**

1. **A claim of delivery that was never checked.** The message asserted an artefact was in front of
   him. Nothing verified that. This is §15's rule failing in the other direction: the assistant did
   the work and then did not hand it over.
2. **Guessing twice at the same symptom.** `PLAYBOOK.md` §4's two-strike rule exists for exactly
   this: after the second attempt fails, stop and diagnose. Instead the same guess was made twice
   with a smaller font size. **The first "I dont see it" should have produced a question, not a fix.**

**The rule, and it generalises past screenshots:**

> **Never say "above", "attached" or "delivered" about something you have not actually sent in that
> message.** If it matters enough to mention, send it. Rendering it, reading it, and describing it
> are all things that happen on the assistant's side only.

**And the diagnostic habit this should have triggered:** when someone says they cannot see
something, the first hypothesis is *it was never sent*, not *it was too small*.

---

### 2026-08-25 — ten decisions agreed after signing, none of them written down

Nico, cutting off a design conversation that was running away:

> *"let's not build the details now, park that in the process... we are testing the vibe kit now,
> dont get distracted, focus on the goal. Did the process document things we agree on in the
> process?"*

**Checked rather than claimed, and the answer was no.** `PLAN.md` still described the five-screen
version. Ten decisions since signing existed only in a mockup and in the conversation: the dashboard
becoming the home screen · a grammar inventory · mastery from production rather than cards · the
word counter · articles as a rate · **patterns as a third data type** · **the three-layer
architecture** · no streak, no backlog · English chrome · button-not-typing. Cost had gone from five
sessions to eight. `BACKLOG.md` and `decisions/` did not exist in the repo at all.

**Why the rule written that morning did not catch it.** §14 said *"an analysis is not finished until
its conclusions are in a file something reads."* This was not an analysis — it was **conversational
design**, and the rule's scope excluded it. **Third time in one day that a correct rule failed just
outside its own boundary.**

**And the signed plan made it worse, not better.** A signed document *looks finished*. Nobody
expects to edit it, so agreements pile up beside it rather than in it. The confirmation gate only
fires at confirmation time; between confirmations nothing watches for drift.

**Acted on 2026-08-25:**

- **`PLAYBOOK.md` §14** — the rule is now *"Nothing agreed is finished until it is in a file
  something reads"*, with the closing question widened: **ask at the end of any design conversation,
  not only after an analysis.**
- **`templates/PLAN.md`** — a **"Decided since the last confirmation"** table. Anything agreed after
  signing lands there immediately, and **it must be empty before the plan can be signed again.**
  A non-empty list at confirmation time means the plan is out of date.
- The product's own files caught up: ten decisions recorded, `BACKLOG.md` created with eight parked
  items and their triggers, `decisions/0001-three-layers.md` written.

**Who found it, again: the Boss.** Pattern 2 in this log says the kit cannot find its own gaps, and
this is another instance — but a sharper one, because **the gap was in a rule written eight hours
earlier to prevent exactly this.**

---

### 2026-08-25 — round 2 retrospective: four things, and three of them are about who does what

**1. Scope grew 60% one good decision at a time, and nothing was counting.**

The plan went from 5 sessions to 8 across about fifteen exchanges. **Every single addition was an
improvement and the Boss was right every time** — the dashboard as home, the grammar inventory,
covering A1, static reference data, patterns over words. No bad decision was made. The drift was
invisible because it arrived as a series of small yeses.

The previous entry fixed *decisions not being written down*. This is a different gap: **written down
is not the same as added up.**

> **Acted on:** `templates/PLAN.md`'s running record gains a **cost column and a running total.**
> Scope does not grow by bad decisions; it grows one good decision at a time, so it needs a number
> rather than a feeling.

**2. Naming a problem as hard got it solved. Twice.**

The assistant declared two things unsolvable-as-designed: *"practice for grammar you avoid has
nowhere to come from"* and *"card count cannot map to a CEFR level"*. Nico removed both in one
sentence each — prebuilt drills generated at **build time**, and counting words he *used* rather
than words that got carded.

> **The habit worth keeping: state the hard problem out loud, in plain words.** A constraint is
> usually only hard given assumptions the Boss does not share, and he cannot remove an assumption
> he has not been shown. Both fixes were better than anything the assistant had.

**3. Every design idea in this round came from the Boss. Not one came from the kit.**

Counted: dashboard-as-home · grammar as a finite inventory · cover A1 not just C1 · prebuilt static
data · patterns rather than single words · Explain mode · show the reference table · show it as a
chart. **Eight, all his.**

What the kit contributed instead: research that killed three products, the honest caveats, the
persona check, and the arithmetic.

> **Corrected by Nico immediately, and he is right:** *"You did propose a mockup, which helped me
> think and give feedback for improvement."*
>
> **The mockup is not a design proposal. It is the instrument the design is done with.** Eight ideas
> came from him, and not one of them would have arrived without something concrete to argue with —
> the twelve-screen version was rejected *by being drawn*, the dashboard became the home screen
> *because a dashboard existed to look at*, and Explain mode only got a real answer once it could be
> pressed.
>
> So neither of the two obvious framings is right. Not *"Claude proposes, Boss approves"* — the
> proposals were his. Not *"Boss proposes, Claude checks"* either — he had nothing to propose from
> until something was on screen.
>
> **Claude makes it visible. The Boss makes it right.** That is the actual division of labour, and
> it explains why *"I can only approve things after seeing mockup"* is not a preference about
> presentation: **it is a statement about where his thinking happens.**

`ROADMAP.md`'s design rows say *"Claude draws, Boss says yes or no"* — which understates it. He does
not say yes or no; he redirects, repeatedly, and the drawing is redone. Corrected below.

**4. `research` is not a phase-1 step, and drawing it as one is wrong.**

It fired three times *during design* — CEFR vocabulary figures, the German grammar inventory,
gender predictability (~80%, Durrell/Donaldson) — and **each time it changed a design decision.**
The 13-step route puts Research at step 1, inside Decide. It belongs with the standing rules, like
`explain-as-we-go`: it fires whenever a decision rests on a fact, at any step.

**Log line, not a change: first occurrence.** But it is the same shape as the loop-and-edges
finding — a step that turns out not to be only a step.

**What the process prevented, this round:** `persona-check`'s *"evidence that is missing — ask, do
not invent"* section produced the two best findings of the day. Two of its three questions were
answered in one message: Anki had already worked (risk down sharply) and the on-off cycle is long
(kill the streak, never show a backlog). **Neither would have been guessed.**

---

### 2026-08-26 — the reviewer agent had never run because it was never installed

- **Skipped:** nothing this session. This entry is about a check that had been skipped for three
  rounds without anybody noticing there was a check to skip.
- **Found by:** starting round 3, whose acceptance criteria include *"the `reviewer` agent runs"* —
  which forced the question *can it?* before the question *did it?*

**The fact.** `.claude/agents` did not exist. Not in the project, not in the user profile.
`install-skills.ps1` refused to create it, and stated the reason in a comment: *0 of 3 agents have
run, and the open decision is hook them or delete them.* **The non-installation was producing the
evidence used to justify the non-installation.**

**Why it survived.** `SKILLS.md` had recorded two candidate explanations for the silence — the
trigger is unenforced, or the work already happens inline — and named the next retrospective as the
place to choose between them. Both are interesting. Both are about intent. **Neither was checked
against the filesystem, and the filesystem answered in one `ls`.**

**And this is a repeat.** The installer exists *because of this exact bug*: its header has said
since 2026-08-24 that the kit had twenty-four skills in a notes folder and Claude Code had none. The
fix was applied to `skills/` and not to the `agents/` folder sitting beside it. **A fix that is not
applied to the whole class of thing it fixes is half a fix**, and the half left behind looks
identical to a decision.

**Changed:**

| | |
|---|---|
| `install-skills.ps1` | copies `agents/*.md` into `.claude/agents`, prints each by name, counts them in `.kit-version`. `-Core` does not apply — there are three, and omitting any is what produced the zero. |
| `SKILLS.md` | *Reading 0* recorded, above the two theories it displaces |
| `PLAYBOOK.md` §14 | new rule: **when something has never fired, check that it is installed before theorising about its trigger** |

**Verified:** 14 skills + 3 agents into a clean folder; all three agents listed by name; the stamp
file records the count. Not verified yet: that Claude Code offers `reviewer` by name in a real
session. That is a round 3 criterion and it is on the phone-and-laptop side of the fence.

**The uncomfortable part.** Two dormancy entries in this log, the `-Core` switch, and a retirement
rule in `SKILLS.md` all reason about which parts of the kit have earned their place. **Every one of
those arguments assumed the part was reachable.** The retirement rules now need a precondition, or
the kit will one day delete something for never firing from a folder nothing reads.

- **Skills that fired:** `process-audit` in effect, `kit-feedback` for this entry
- **Cost:** one `ls`, against three rounds of a wrong open question

---

### 2026-08-26 — a decision was put to the Boss without its explanation attached

- **Slowed him down:** two decisions were asked as multiple choice, each option one sentence of
  trade-off. Both came back the same way: *"I dont understand to decide this, need to explain
  please"* and *"I cant decide when I dont understand."*
- **The rule that already exists:** `explain-as-we-go` fires **always** — it is one of the standing
  rules, not a stage. It had fired all session, in prose, while explaining what was being built.
- **Where it failed:** at the exact moment of a decision. The explaining had been attached to the
  *work*, and not to the *question*.

**Why this is the expensive version of the same mistake.** §15 says there are exactly two reasons to
ask the Boss for anything, and the first is *a decision or an approval*. It says nothing about what
must travel with the question. So the kit had a rule about **when** to ask and none about **what an
askable question looks like**.

A one-way-door decision — the pack format — was reduced to three labels and a sentence of trade-off
each. That is enough for someone who already knows what a serialisation format is. It is a **stop**
for the person the kit is written for, and the stop is worse than a slow answer: an unexplained
decision either blocks the round or gets waved through, and *waved through* is how a one-way door
gets chosen by accident.

**The shape of the fix**, for v1.7 — this belongs in §15, beside the two reasons to ask:

> **A decision put to the Boss travels with its explanation: plain terms, an analogy where a plain
> sentence does not land, and — where the options are formats, shapes or structures — the same thing
> written both ways so the difference can be seen rather than imagined.**
>
> And the question under the question: **name the one fact that decides it.** "JSON or YAML" is not
> answerable. *"Will you ever hand-edit a pack yourself?"* is, and it settles it.

**Not fixed in v1.6.** v1.6 was cut and mirrored before this happened, and a released version stops
being editable — which is the rule working, and also a note about my own timing: **the version was
stamped mid-session, on the assumption the session's learning was finished.** It was not. Cut the
version at the end.

- **Skills that fired:** `explain-as-we-go` — late, and only when asked twice
- **Cost:** one round trip, and it is the second time this week the Boss has had to say *explain it
  again* before he could act

---

### 2026-08-26 — a product skill was written into the kit, and the kit had no way to say no

- **What happened:** a new skill, `content-pack`, was added to the kit — how to choose a file format
  for reference content that ships inside a product, how to validate it, how to fail loudly. It was
  written, packaged, mirrored, and released in v1.7. It fired the same day.
- **Caught by:** the Boss, in one sentence, an hour later.

> *"This new content management skill shouldnt be in the kit. This skill is for the product the kit
> produces. But the kit should be able to support this skills systems or ideas to make the product
> possible."*

**The distinction, which the kit did not have written down anywhere.** A kit skill answers *how do we
build things?* A product skill answers *how does **this** thing work?* The kit does not need to know
what a German gender pack is. It needs a product to be **able** to have one — a place to put that
knowledge, a rule for when a decision is an ADR instead, and the habit of asking whether content
belongs in code at all.

**Why it defaulted into the kit, and this is the part worth keeping.** The kit had a path *upward*:
a promotion trigger, written on 2026-08-22 after seven generic things were invented inside one
project and had to be moved back by hand. It had **no path downward, and no home at the bottom.**

> **With one library and a rule that only points into it, everything invented anywhere ends up in
> the kit.** That is the mechanism by which a general package turns into one project's notes — and it
> is invisible, because every individual addition is useful. `content-pack` is a good skill. It was
> good in the wrong place.

**Changed:**

| | |
|---|---|
| `PLAYBOOK.md` §14 | **Two libraries** — the table, the one-question test (*would this still make sense in a project with nothing to do with this product?*), and the bounce in both directions |
| §14 destination table | a fourth row: **missing know-how → the product's `.claude/skills/`**, same session |
| `templates/PRODUCT-SKILL.md` | new — the shape of a product skill, the four things it must carry, and the three it must not do |
| `skills/architecture-map` | asks the one generic question that remains the kit's business: *is any of this content rather than code?* Three lines for the map, then it hands the schema itself to the product |
| `install-skills.ps1` | the "not from this kit" notice now names those as **the project's own skills** rather than reporting them like a wart. The behaviour was already right; it read like an accident. |
| `skills/content-pack` | **deleted from the kit.** Rewritten as the product's own, in the app repo, concrete: real schema, real paths, the validation command, and the non-obvious rules — starting with *a rule id is permanent, because the review history is keyed on it.* |

**The version consequence, and it is embarrassing in a useful way.** v1.7 was cut an hour before
this, and its headline addition was the skill that has now been removed. **Two versions in one
session, one of them wrong** — which is exactly what the *"cut the version at the end of the
session"* note in the previous entry was warning about, written by me, one hour earlier, and not
followed.

**What the process got right:** the skill was written, installed, and fired on real work within the
hour, which is what made the misplacement visible immediately rather than in November. A skill
sitting unfired in a folder would have been judged on its description, and its description reads like
a kit skill.

- **Skills that fired:** `kit-feedback`
- **Cost:** one skill rewritten, one version wasted, one rule the kit should have had from the start

---

### 2026-08-26 — a heading that was printed over the wrong list

- **Found by:** the Boss running the installer, one hour after I changed it. First real-machine run.

The installer's last report was reworded from *"already there, not from this kit — left alone"* to
*"the project's own skills"*, to name the two-libraries mechanism instead of making it look like a
wart. On his machine it then printed **the ten dormant kit skills** under that heading — leftovers
from an earlier full install, which `-Core` does not copy. They are not the project's own anything.

**The bug is one line of set arithmetic:** the "foreign" list was *everything in the target that this
run did not install*, which lumps together two unrelated things — a kit skill from a previous run, and
a skill the kit has never heard of. That was survivable while the heading was vague. **Rewording it
to something specific made it false**, which is the more interesting half:

> **A vague label hides a wrong set. Naming the set precisely is what exposes it.** The set was
> already wrong; the old wording was just too loose to contradict. This is the fourth instance of
> §14's *"a field that can be satisfied without being true is not yet a check"* — and the first where
> the improvement is what surfaced the defect.

**Fixed:** compare against **every skill name the kit has**, not against what this run copied. Two
separate reports now — *kit skills present but not installed this run* (leftovers, never deleted) and
*not from this kit* (the product's own). Verified in his exact sequence: full install → add a project
skill → `-Core`, and each list contains exactly what its heading says.

**And the process note.** The wording change shipped in v1.8 with the line *"Verified: installer clean
at 14 core + 3 agents"* — which was true and did not cover this. **I verified the path I had changed
and not the path the change affected.** The clean-folder test could never have caught it: it needs a
folder with a *previous* install in it, which is the normal case for every user and the one case the
test did not have.

- **Skills that fired:** `debugging`, `kit-feedback`
- **Cost:** one wrong line of output on the Boss's screen, and the honest version of a "verified" claim

---

### 2026-08-26 — the boundary audit: five leaks, and a missing third home

- **Asked by the Boss:** *"Do we have a system to separate what belongs to the products the kit
  produces, vs what belongs to the kit itself?"*
- **Honest answer at the time: no.** One rule, for one artefact type, added an hour earlier.

**What the audit found**, by grepping the kit for product names and one-ecosystem technology:

| Leak | Size |
|---|---|
| `GLOSSARY.md` | **67 of 276 lines** were one product's build log — an exact NDK version, `flutter doctor` "on this project", *"the German memory layer"* |
| `START-HERE.md` step 6 · `obsidian-docs` · `templates/ASA-HUB.md` | the kit told **every** reader to build a product they have never heard of |
| `hooks/install-hooks.ps1` | wrote `"command": "flutter test"` into every new `check.json` — one product's command as the kit's default |
| **the product's `CLAUDE.md`** | **fourteen machine facts** — no admin rights, PowerShell 5.1's traps, no Python or Node, the device-bridge git rule |
| `PLAYBOOK.md` §v5 · `ROADMAP.md` | a product named in the version history and in a milestone |
| person's name in kit prose | 4 lines, now *"the Boss"* |

**The finding that mattered: two homes are not enough.** *"No admin rights on this laptop"* is not
general enough for the kit and does not belong to any one product. With only two buckets it lands in
whichever product happens to be open, and **product number two either re-learns it or copies it, and
then there are two copies that drift.**

> **Three homes: kit · workshop · product.** The workshop — `MACHINE.md` and `BOSS.md`, once, beside
> the kit — is the one nobody thinks of, and it was already half-written: `templates/BOSS.md` had
> existed unused for days, homeless.

**Two questions settle every case:** would this still be true in a project that has nothing to do with
this product? *No → product.* Would it still be true on someone else's machine, for someone else?
*Yes → kit. Otherwise → workshop.*

**And a rule is not a system.** `check-boundaries.ps1` scans the kit, exits 1 on a product name, and
counts one-ecosystem technology as a soft warning because *"flutter test, pytest, npm test"* teaches
better than an abstraction. It has a `-SelfTest` that plants a leak and proves the scan catches it.

**Its own first run is the argument for having it, twice over:**

1. It found **two real leaks** nothing else had.
2. It produced **four false positives** — a substring match read "r*anki*ng" as the flashcard app. A
   check whose first output is mostly noise is a check people switch off. Now whole-word, with an
   assertion for exactly that case.
3. It drew a line the rule had not: **somebody else's product is not a leak.** Naming Anki, Obsidian
   or git as an example is what a kit is *for*. The hard list is only the products **we** build.

**Also changed, and this one is a class-sweep rather than a single fix:** `check.json` is now
**detected** from the repo — `pubspec.yaml` → `flutter test`, `package.json` → `npm test`,
`pyproject.toml` → `pytest -q`, `go.mod`, `Cargo.toml` — and an unrecognised project gets an **empty**
command and is told so loudly, which leaves the commit gate inactive rather than wrong. Four
assertions added to `test-hooks.ps1` (30 → 34), and **all four were verified to fail against the old
hard-coded version** — one of them vacuously, which is worth saying: the Flutter assertion passes
either way, because the old default happened to be right for Flutter.

- **Skills that fired:** `process-audit`, `kit-feedback`, `debugging`
- **What the process prevented:** the audit was ten minutes of grepping and it stopped the kit
  becoming a Flutter kit with a German glossary. **Nothing else was going to notice** — every leak was
  added by someone being helpful.

---

### 2026-08-26 — 24 tests passed and the app would not build

- **Found by:** the Boss, running the app on his phone, one command after a green test run.
- **The error:** a mutable field on a class with a `const` constructor. Dart requires every field to
  be final for that. One word.

**The interesting part is not the mistake. It is that the machine check said nothing.**

`flutter test` compiles **only what the tests import**. `pack_repository.dart` was imported by no
test — the reviewer had said so in its own words, *"the largest new code surface has no test"* — so
the compiler never looked at it. **24 tests, all green, over code that could not compile.**

> **Tested and compiled are two different facts, and the kit had been treating one as the other.**
> Exactly the shape of the morning's finding that *installed* and *fired* are two different facts. In
> a compiled language the test command is not the build command, and a green run over a partial
> compile is more dangerous than a red one, because it is evidence of the wrong thing.

**Changed:**

| | |
|---|---|
| `skills/first-test` | **the machine check must cover the whole build, not only what the tests touch.** Named per ecosystem: `flutter analyze`, `tsc --noEmit`, `mypy`/`pyright`, `go vet ./...`, `cargo check` — run *before* the tests, because a compile error makes every test result meaningless |
| the product's `CLAUDE.md` | machine check is now **two** commands, analyze then test |
| the product's test suite | one test that names two constants from the unimported file, purely so the file is compiled. The cheap half of the fix; `analyze` is the real one. |

**What made it visible at all:** the round's criteria put *"open it on the phone"* in the human column
rather than trusting the machine column. A round that had stopped at green tests would have committed
this. **The human line is not ceremony** — it is the only thing that ran the whole build.

**Not fixed:** nothing makes `analyze` run. It is a line in `CLAUDE.md` and a habit. The commit gate
watches for a recorded pass of the *test* command only. Ranked: `ROADMAP.md`.

- **Skills that fired:** `first-test`, `debugging`, `kit-feedback`
- **Cost:** one 32-second Gradle build, and the second time today that a green number turned out to be
  measuring something other than what it claimed

---

### 2026-08-26 — round 3 retrospective: four things found, and none of them by the tests

The first round of this project with real product code. Worth recording as a whole, because the
pattern across the four discoveries is sharper than any of them alone.

| Found by | What it found | Could a test have found it? |
|---|---|---|
| **the `reviewer` agent** | 13 findings — a rule contradicting another rule in the same file, four ending-vs-suffix overclaims, a hard-coded list that made the round's headline claim untrue, an error message that never named the rule it came from | **No.** Content and claims are outside what any assertion reaches |
| **break-it-on-purpose** | that one broken line fails *two* tests, and the second is the one that catches a half-loaded pack | It **was** a test — and only visible because it was watched failing |
| **the phone** | a compile error in a file no test imported | Only by importing it, which is the fix |
| **`flutter analyze`** | a dead import, on its first ever run | No |

**The tests passed at every single stage, including while the app could not build.** That is not an
argument against tests. It is the measured argument for the other three columns, and for the human
line in the acceptance criteria — which is the row that ran the whole build.

**On the reviewer, now that it has actually run.** Six rounds of "should run" produced nothing; one
round of *"its verdict goes in the note or the round is not finished"* produced thirteen findings.
**A condition works where an instruction did not** — the kit has now measured that rather than
asserted it. Two refinements it earned:

1. **Require the run, not the opinion.** The criterion was worded *the verdict is recorded, whatever
   it is* — so a BLOCK satisfies it. Without that the round would have hung on a brand-new agent's
   mood. Generalised: **a criterion about a tool must require evidence that it ran, never a
   particular result from it.** Round 2 made the opposite mistake with `flutter doctor`.
2. **Point it at the claims, not only the code.** Its whole yield was in content and in documents
   that promised more than the code did. That is where an assistant's work is weakest and where no
   machine check reaches.

**Still not proven:** the *installed* `reviewer` agent in Claude Code. Both passes here were a
subagent given `agents/reviewer.md` in a different tool, and neither could run the machine check.
**Installed, fired, and fired-where-it-can-run are three facts, and only the first is now true.**

**Cost, honestly:** round 3 was planned as one session. It took one session of product work wrapped
around **five kit versions** (v1.6–v1.10) — the agents installer, three homes, the boundary checker,
the whole-build check. That is the by-product rule working as designed, and it is also why "sessions"
is still not a useful unit. The `Cost:` line in `templates/ROUND.md` has now been unfilled for four
rounds.

- **Skills that fired:** `content-pack` (the product's own), `architecture-map`, `first-test`,
  `debugging`, `explain-as-we-go`, `kit-feedback`
- **What the process prevented:** committing an app that could not build, and shipping a reference
  pack in which one screen contradicted another.

---

### 2026-08-26 — the reviewer blocked the commit of the round it had just reviewed

- **Symptom:** `git add -A` → *"Unable to create '.git/index.lock': File exists."* The round was
  finished, reviewed twice, tested and running on the phone, and could not be committed.
- **Diagnosed by looking, not guessing:** the lock was **0 bytes, created 15:29**. An empty lock means
  whatever made it died before writing — stale, not live.
- **Cause:** the `reviewer` subagent ran `git` through the Claude device bridge while reading the
  diff. Through the bridge git cannot delete its own lock, so it leaves one behind. This exact failure
  is documented in the project, dated 2026-08-25, in the rule *"`git` and `flutter` run in Windows
  PowerShell, never through the bridge."*

**Two causes, and the second one is mine twice over.**

**1. The rule had been moved out of the file the agent was told to read.** That morning, *Three homes*
sorted machine facts into `MACHINE.md` — the CRLF measurement, the 4,742 phantom changes, the lock.
Correct by the letter of the rule I had just written. But `agents/reviewer.md` says *"read `CLAUDE.md`
for the project's hard rules"*, and by 15:29 the rule was no longer in `CLAUDE.md`. **The relocation
was four hours old and it had already cost a commit.**

> **The correction, now in §14: split the fact from the rule.** *"Git through the bridge reports 4,742
> phantom changes"* is a workshop **measurement**. *"git runs in PowerShell, never through the
> bridge"* is a product **operating rule**, and it belongs where everyone working in that repo is
> pointed. Moving the evidence out is right; moving the instruction out is how a rule stops binding
> anybody.
>
> General form: **a rule only binds the people who are told to read the file it lives in.** Before
> relocating one, ask who reads its current home and who reads the new one.

**2. I briefed the agent with the task and not the constraints.** I gave it the repo path, the files,
the criteria and an explicit instruction about which *tool* to read files with — and never the one
sentence *"do not run git in that repo"*. Now in §10: **an agent inherits your instructions, not what
you happen to know.**

**What worked, and is worth as much as the finding.** The failure was diagnosed in one look because
the fact was written down: a dated rule, and a symptom precise enough to recognise. Second occurrence,
about ninety seconds to fix, versus the original which cost a session. **That is the log paying for
itself** — and it is the first time this project has hit a repeat failure and had the answer waiting.

**The uncomfortable symmetry:** the reviewer's value this round was finding claims that were more
confident than the code. Its own run made a claim of that kind true of me — I moved a rule and assumed
it still bound everyone.

- **Skills that fired:** `debugging`, `kit-feedback`
- **Cost:** one `Remove-Item`, and a rule that had to be written twice in one day

---

### 2026-08-26 — the commit that stalled in vim

- **What happened:** round 3 was finished, tested and reviewed. The commit was handed over as four
  `-m` chunks on one pasted line, with quotes, parentheses and dashes inside them. Part of it was lost
  in the paste, git got no message, and **git opened `vim`.**
- **Where it stopped:** *"# Please enter the commit message for your changes…"* and a cursor. No
  visible way out for someone who has never used it.

**§15 already said the right thing and was pointed at the wrong half.** *"If the assistant can do it,
the assistant does it"* — and running git on that machine genuinely is the Boss's half. **But the
wording of the command was never his half**, and I handed over the fragile form of it.

> **A command handed over is a deliverable.** It gets handed over badly far more often than it is
> wrong. The failure here was not the git command; it was quoting, plus an interactive editor nobody
> named in advance.

**Fixed in two minutes** by writing the message to `.git/round3-msg.txt` — work the assistant can do —
and handing over `git commit -F .git\round3-msg.txt`. No quoting, no editor. `d8042d6`, 37 files.

**Now in §15, *Hand over the safe form of a command*:** long text goes in a file; one command per
line; prefer a command that fails loudly over one that waits for input; say what a normal run prints
so a wall of warnings is not read as failure; and **name the way out of anything interactive before it
opens.**

**Same session, same shape, third instance.** *"Use the tool, do not reimplement the tool"* (2026-08-25),
*"do not send the Boss hunting for a download button"* (2026-08-25), and now *"do not hand over a
command that can strand him"*. All three are the assistant's half of §15, and all three were found by
the Boss getting stuck rather than by anything in the process.

**Worth noting what did not go wrong:** the 49 `LF will be replaced by CRLF` warnings in the same run
were correct, harmless, and *look* exactly like the 85-file phantom diff from the day before. Having
that failure written down and dated is what made the difference between a warning and an alarm.

- **Skills that fired:** `kit-feedback`, `explain-as-we-go`
- **Cost:** one stranded terminal, and the last five minutes of a round that was otherwise finished

---

### 2026-08-26 — the pattern across the whole day, and the decision it produced

Seven entries above, from one round. Read together they are **one shape, five times**:

| The number | What it was actually measuring |
|---|---|
| 3 agents, **0 runs** in six rounds | the installer, which never created `.claude/agents` |
| the installer's *"the project's own skills"* | ten kit leftovers, printed under a heading that had just been made specific enough to be false |
| **25 tests pass** | the subset of files the tests happen to import — the app could not build |
| `exceptionsComplete: true` | a completeness nobody had checked, on four rules |
| *"verified by review"* in an ADR | verified by **reading**. Nothing had been run |

> **A green number always measures something. The question is what — and the kit had no habit of
> asking.** Every one of these was true as written and false as understood.
>
> **The rule that follows, and it is the day's real output: a claim of coverage must name its
> denominator.** *"All tests pass"* → over what? *"Never fired"* → reachable from where? *"All of
> them"* → checked by whom?

**Second pattern, three instances: the right content in the wrong place for its reader.**
A product skill in the kit · a rule moved to a file the agent was not told to read · machine facts
inside one product where the next product cannot see them. All three were tidy by one logic and
broken by the only one that matters — **who reads this file?**

**Third, and the only good news: a condition beat an instruction, measurably.** Six rounds of
*"the reviewer should run"* produced nothing. One round of *"its verdict goes in the note or the round
is not finished"* produced **13 findings, 12 fixed, none of them in the code.**

**The uncomfortable count.** Of the day's findings, the process caught the *content* defects — every
one, through the review. **The Boss caught the process defects**: the stale skill, the missing
boundary system, the lock file, the editor. Four of the six kit changes came from him getting stuck.
A process that only improves when the Boss gets stuck is charging him for its own development.

**Decided, 2026-08-26** — *"yes do what needed to have a good kit"*:

**Round 4 runs frozen.** No kit changes during the round. Friction is logged `[FROZEN]` and fixed
afterwards. Cost is recorded for the first time: elapsed time, round-trips, kit changes. The
prediction worth writing down before it can be adjusted: **round 3 would have scored seven.**

- **Skills that fired:** `process-audit`, `kit-feedback`

---

### 2026-08-26 — the personal-data sweep skipped the two files most likely to be dirty

- **Claimed, in writing, an hour earlier:** *"Verified before it left your machine: no personal data
  anywhere in the kit. No names, no email, no paths."*
- **Actually true:** `KIT-LOG.md` contained the Boss's first name **18 times**, his products 10 times,
  and his mistakes in detail. `ROADMAP.md` contained his plans.
- **Why the sweep said clean:** it excluded `KIT-LOG.md` and `CHANGELOG.md` from the grep — on the
  reasoning that those files *legitimately* name products. Which is true of **product names** and has
  nothing to do with **a person's name**.

> **The exclusion was written for one kind of match and then applied to a different question.** Same
> shape as the day's other five: *a green result that measured something other than what it claimed.*
> This one is the worst of them, because the claim was made **to the Boss, about his own privacy, in a
> sentence congratulating the process for making it easy.**
>
> Caught by the Boss asking a completely different question — *"did you tell her about the Asa UI
> plan?"* — which forced a look at what was actually in the package.

**What shipping requires, now written into `HANDOVER.md` and done for the first version that leaves:**

| | |
|---|---|
| **Not shipped** | `KIT-LOG.md` (names, products, half-finished work) and `ROADMAP.md` (plans — *a tester who knows the plan stops reporting what is missing*) |
| **Sanitised** | the Boss's name → *the Boss*; product names → generic, in 15 files |
| **Blanked** | `check-boundaries.ps1`'s own list of product names, with a comment saying it is a blank to fill in, not a default |
| **Verified after packing, not before** | every `.md` and `.ps1` **inside the zip** read back and grepped. That is the check that would have caught this. |

**And a real bug it surfaced:** blanking the product list broke `check-boundaries.ps1 -SelfTest`, because
the self-test used `$hard` — the live list — instead of its own. **A fresh copy of the kit would have
reported its own checker as broken on first run**, to the first outside user, on day one. Fixed in both
copies: the self-test now carries `acme-widget` and `zebra-app` and no longer depends on the user
having filled anything in.

**The rule this earns, and it is the packaging version of the day's theme: verify the artefact, not the
source.** The sweep read the folder. The thing that ships is the zip.

- **Skills that fired:** `ship-it` — for the first time, and it found this
- **Cost:** nothing, because the Boss asked one more question before sending it

---

### 2026-08-26 — the audit before the first release: DO NOT SHIP

The Boss asked for the package to be checked before he downloaded it. An auditor was given the **zip**,
not the folder, and told to assume it was not ready. **Nine findings. Verdict: DO NOT SHIP.**

**The blocker, and it is the kind nothing else would have caught:** `hooks/install-hooks.ps1` copies
four scripts into a repo's `.claude\hooks` and **does not copy itself** — while `test-hooks.ps1` shells
out to it for four of its assertions. So the suite passes from the kit folder and **fails 4 of 34 from
the folder the installer's own closing message tells you to run it in.**

> **The first machine check a new user ever runs would have printed FAIL**, on a kit whose central
> rule is *you run the code, you look at the result*. She would have looked, seen FAIL, and had no way
> to know it was the harness. One string added to one array.

**The most embarrassing, and the most instructive:** the sanitiser was a blind global find-and-replace.
It welded *"(kept by the kit author, not shipped)"* onto **all 38 mentions** of the two excluded
filenames — including **inside `templates/ROADMAP.md`, the template she copies into her own repo**, and
inside the `roadmap` skill whose entire job is to write that file. Two of them ran twice, leaving
doubled parentheses on page one.

> **A sanitiser is a program, and it was the only program here nobody tested.** Every other script in
> this kit has a self-test. This one was written, run once, and its output shipped — the exact failure
> the kit has a rule against.

**Seven more:** the author's product survived as *"the German app"* five times and as a near-verbatim
quote in a skill's bad example; `PLAYBOOK.md` called the Boss **"he" 17 times** in a package going to a
woman; two sections written for the author told the reader *"nothing here has been used by anyone
else"* and listed what sharing *would* require; `HANDOVER.md` announced v1.13 in a v1.17 package;
`START-HERE.md` told her to install without `-Core`, undoing page one; a machine fact about one laptop
shipped as a constraint on hers.

**Fixed and verified inside the archive** — the hook suite now passes from `.claude\hooks`, no
identifying material, no gendered pronouns, no self-contradicting annotations, no stale version.

**What this buys next time**, and it is the answer to *"how do we ship more easily":*

| | |
|---|---|
| `package-for-tester.ps1` | sanitise, pack, then **read every text file back out of the zip** and refuse on a hit — **and delete the zip**, so a failed package cannot be sent by accident. It caught a false positive on its own first run and was fixed. |
| **An audit by something that has not seen it before** | Nine findings, seven invisible from inside. The person who assembled the package is the worst possible reader of it. |
| **The rule** | **Verify the artefact, not the source.** The sweep read the folder; what ships is the archive. |

**The pattern, seventh instance today:** *the check measured something adjacent to what it claimed.*
The folder was clean. The zip was not the folder.

- **Skills that fired:** `ship-it` — twice now, and it has yet to be wrong
- **Cost:** one round-trip, and the Boss asking one more question before downloading

---

### 2026-08-31 — the first outside feedback, and four of our rules became laws

A second project — different product, different stack, different environment, no contact with this
one — used the kit hard and sent back a filled feedback form, a direction document, and five log
entries of its own. **Its verdict on the writing: *"sentences you did not understand: none"*, checked
for specifically.** Its verdict on everything else is below.

**The kit's brake is *twice, not once*. Four things crossed that line in one delivery:**

| The law | Found here | Found there, independently |
|---|---|---|
| A step that depends on being remembered does not survive a busy week | reviewer: 0 runs in six rounds as an instruction, 13 findings in one round as a condition | an orchestrator skipped three sessions running; `persona-check` skipped twice on its own job |
| **A claim of coverage must name its denominator** | 25 green tests over the files the tests imported, while the app could not build | a stored finding — *"screenshot-tested, no collisions"* — measured at desktop width, false at phone width |
| A fix has to live where the failure happens | a rule moved to `MACHINE.md`; a subagent reading `CLAUDE.md` broke it ninety minutes later | a path corrected in a rules file nobody reads while typing a command; failed again identically |
| **A default that is always accepted is not a default — it is the value** | `check.json` shipped one product's command as everyone's default | a save script's timestamp fallback became **half the project's git history**. Nobody ever chose it. |

**The sharpest new finding, and it is arithmetic rather than opinion:**

> **A trigger that fires on everything fires on nothing.** Their orchestrator claimed to fire before
> every delivery — twenty or thirty times a session — so it settled at zero.

**Our audit of it produced a lesson about audits.** The first count said *twenty of twenty-four
skills have always-shaped triggers*. It had grepped for the word **"whenever"** instead of the
**shape of the moment**. The real number is **two**: `explain-as-we-go` and `persona-check`. Making
the denominator error inside the message announcing the denominator law is not a coincidence — **it
is how cheap that mistake is**, which is the argument for the law rather than against it.

**And `persona-check` is now the only skill to have failed on its own job in two unrelated
projects.** Both failures used the same excuse, which the skill never named: *"the design was checked
earlier, so the build is covered."* A warning that does not name the excuse does not survive a tired
evening. Now written into the skill, with what it cost — *"UI UX is bad, very overwhelmed"*, one
wasted build-and-install cycle on a physical device.

**What the outside test found that we had nothing for at all:**

| Gap | Evidence |
|---|---|
| **Draw the one screen before coding it** | She invented the step herself, mid-session, out of frustration. **This project improvised the same step in the same week.** Two independent inventions of a missing step. |
| **"Can they reach it?"** | Three pieces of correct, tested, reviewed work were unreachable in one day. Our handover check asked *exists · checked · honest* and would have passed all three. |
| **Nothing reviews the engineering** | An external developer's counter-design was better on every axis and the assistant had not considered it. On a solo project that person does not exist. |
| **Which parts need which environment** | Their hooks install, register, and **were watched firing** — and never fire where she actually works. **True of us too**, and unsaid: our hooks have never fired in a single Cowork session, because the files are reached across a bridge. |
| **Installing over an existing copy** | Her skills folder holds skills this kit did not write. Nothing guaranteed they would survive an upgrade, and the safe response to a leap of faith is not upgrading. |

**The brake was deliberately overridden, and that is recorded as an override.** Eleven items from one
project in one week is more than *twice, not once* allows. The Boss chose to take all of them:
*"Everything in her priority list."* Four are twice-witnessed and cheap; the rest are one project's
evidence, however well argued. **If any of them turn out to be about her situation rather than
everyone's, this line is where to look first.**

**What the outside test says not to change**, and it is worth as much as the findings: the writing ·
the frozen-release discipline · `-Core` and `SKILLS.md` · and **the known-conflicts list, which was
never in the kit at all.** It was hers. Her verdict — *"the best value-per-line in the kit… one
sentence, recorded from a past failure, applied to a new one"* — is now `templates/CONFLICTS.md`, and
the reason it beats a skill is that **it fires without being invoked.** In an environment where the
hooks cannot run, that is the only mechanism that works.

- **Skills that fired:** `kit-feedback`, `process-audit`, `ship-it`
- **Cost:** the largest single version this kit has taken. Also the first one where the evidence came
  from somebody who does not work here.

### 2026-09-01 — the sketch was rendered, reviewed and never shown

**Bucket: how we build.** A change to the process prevents this one.

**What happened.** A screen was about to change. The sketch was written, rendered headlessly,
checked for page errors, and the image inspected — every mechanical step of `sketch-the-screen`
completed. The session then ran a persona check *on the sketch*, produced a verdict, reported the
verdict, put the one open decision to the Boss and offered to hand the work to a building session.

**The picture was never sent.** His reply was two clauses and both were findings:

> *"code shouldn't start until I approve the sketch, I don't see new sketch yet."*

and, a minute later, on the sketch once it was looked at again:

> *"the current is overwhelming to me."*

**Two defects, one drawing.**

**1. Rendered is not seen.** The same shape as *installed is not fired* (2026-08-26) and *tested is
not compiled* (2026-08-26). A step whose completion leaves a file behind feels finished; the half
that reaches a human leaves no trace and is the half that got dropped. Three instances now, in three
different parts of the kit, so it is a law rather than a slip: **a step that ends at a person is not
done until it reaches the person.**

**2. A sketch had turned into a document.** Twenty-four kilobytes for one row of one screen — a
six-state reference table, both options drawn in full, three columns of notes, a standing-rules
footer. Every part of it was true. None of it was the thing being decided. It was also **evenhanded
where it should have recommended**: two options laid out for the Boss to weigh, which is the
assistant declining the judgement it was asked for.

The replacement is one page: the row today, the row after, one question, one recommendation with one
reason. It rendered in the same minute and was approved-or-rejected on sight.

**Cost.** One exchange, and a build that would have started against an unapproved drawing. Cheap
because he caught it. Not cheap if he had not.

**Changed** — `PLAYBOOK.md` §14 *Rendered is not seen, and a sketch that needs reading is not a
sketch* · `sketch-the-screen` gains a sixth output rule, a one-page size test, and an explicit gate ·
`SESSION-HANDOVER.md` opens with that gate as a two-row table, so a building session cannot start
against a sketch nobody approved.

**What this does not fix.** Nothing yet forces the send. The gate is written in three places and all
three are read by an assistant that has just demonstrated it can complete a step and skip the
delivery. A hook cannot see whether a picture reached a human. **Standing weakness, recorded rather
than solved.**

### 2026-09-01 — a full discovery re-run, and four findings the kit could not have caught

**Bucket: how we build**, all four.

**What happened.** A product with three committed rounds, 26 tests, four round notes and thirteen
hard rules was found to have **never completed step 1**. Its charter had said *"draft, not agreed"*
for ten days, no `PLAN.md` existed, no `Confirmed by` line existed anywhere, and stage 0 — sketch
the whole product — had never run. The Boss found it, not the kit: *"I think we really need to go
back to step 1 of the kit, and do it properly."*

The interview was re-run in full. It produced a different product from the one being built.

---

**1. The kit has a gate with nothing watching it.**

`PLAYBOOK.md` §3 says *"no round note may be written until the `Confirmed by` line is filled."*
Four round notes were written. **Nothing checked.** The rule is in the playbook, which is prose,
and prose does not fire.

This is the third instance of the same shape — `install-hooks`, the agents' installer, and now
this. **A rule that names a precondition needs something that can see the precondition.** The
cheapest version here is one line in the session-start hook: *if `rounds/` has files and `PLAN.md`
has no name on it, say so.*

**Not built today.** Recorded with its cost: three rounds and one whole product's shape.

---

**2. `Quits when` cannot be asked. It must be derived from tools the person already abandoned.**

The `discovery` skill's question 8 and `persona-check` both require it. Asked directly, the Boss
said: *"i dont really have an answer here until after using it."* **That is the honest answer to
that question and it will be the honest answer most times** — nobody abandons a tool on purpose,
so nobody can predict it.

Derived from tools he actually stopped using, it took four lines and every one had evidence behind
it. **The question to ask is not "what would make you stop" but "what have you stopped using, and
what were you doing when you stopped".**

Both skills to be amended. The measurement date — three weeks of real use — goes in the persona as
an appointment, because the derived list is a hypothesis until then.

---

**3. The rule of two exists in three places and has never been named.**

The Boss invented it independently for a fourth: *"Claude should tell me if I park something in
there again, it means we shouldnt park but really work on it."*

| Where it already lives | Wording |
|---|---|
| `KIT-LOG.md` header | *One entry changes nothing. A pattern changes the kit.* |
| `PLAYBOOK.md` §14 | *The brake: twice, not once.* |
| `PLAYBOOK.md` §14 | *Confirmed twice — four laws, each seen in two unrelated projects.* |
| **New** | *Parked twice is not parked. It is work.* |

**Four independent inventions of one mechanism is the strongest signal this process produces**, and
it is the mechanism the whole kit uses to tell signal from noise. Named in `PLAYBOOK.md` §14 today.

---

**4. The kit assumes every project produces software. Not every project does.**

> *"remember some project like [a process change] or [a system integration] doesnt have any product
> or sketch"*

The kit's shape — stage 0 sketch, rounds, `flutter analyze` then `flutter test`, a commit — is a
**software** shape. A process or integration project has no screens to draw, no rounds, and no
machine check. Under the current kit those steps are not *skipped*, they are **meaningless**, and a
process that reports them as missing is wrong rather than strict.

**The fix is the same principle the product arrived at independently: the steps a project has are
derived from what the project is, and a step that does not apply is absent, not empty.** The kit
currently has one shape and calls deviations from it failures.

**Open.** This is the largest of the four and it is not a one-line fix. It goes to the next
retrospective, not into v1.21.

---

**A conflict, recorded rather than resolved by fiat.** `discovery` question 3 says *"ask for one
real name"*. The standing constraint on this workshop says *no colleague details, ever*. Both are
right. **Resolution used: ask by role, never by name** — the interview recorded *"a teamlead"* and
nothing else, and lost nothing by it. Belongs in `CONFLICTS.md`.

### 2026-09-01 — the machine check was two commands and should have been four

**Bucket: how we build.**

An outside standard arrived for a product built with this kit: *code must follow SOLID where the
stack allows, and there must be tools for code quality, styling, unit tests and feature tests, all
passing completely.* Given in PHP terms — PHPStan level 10, Pint, PHPUnit.

**The kit's machine check has been two commands: static analysis, then unit tests.** Measured
against that standard it is missing two whole categories:

| Category | Kit had it? |
|---|---|
| Static analysis | Yes — but **at default strictness**, which is not the level being asked for |
| Unit tests | Yes |
| **Formatting** | **No.** Never mentioned in `first-test` or the playbook. |
| **Feature / end-to-end tests** | **No.** The kit has never distinguished *does the unit work* from *does the app work when a person uses it* — despite `PLAYBOOK.md` §8 asking "is it reachable?", which is exactly a feature test asked in prose. |

**And the strictness point is the sharper one.** *"Level 10"* has no meaning in a kit that says
"run the analyser". Every language has a dial, the kit never said to turn it up, and the default
is not the top. For Dart the dial is three language modes plus `--fatal-infos`.

**Changes to make:**

1. `first-test` gains **four categories, not two** — format, analyse *at maximum*, unit, feature —
   and says to wrap them in one script so it stays one command.
2. The playbook's machine check becomes that script. **Order is load-bearing**: format, analyse,
   unit, feature. On 2026-08-26 a project had 25 green tests over code that could not compile,
   because only the test step ran.
3. **§8's "is it reachable?" gets a mechanism.** It has been a question a human is asked. A feature
   test is the same question, automated, and it stops depending on someone remembering to ask.
4. `stack-choice` should name **the strictness dial for the chosen stack** at the moment the stack
   is chosen, not leave it at default forever.

**Not yet applied to the kit** — applied first to the product spec that needed it today, so the
shape can be tested once before it becomes a rule. **The kit is not changed on one instance.**
Second occurrence promotes it: `PLAYBOOK.md` §14, the rule of two.
