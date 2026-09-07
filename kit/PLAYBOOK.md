# Vibe Coding Playbook

**Works for any project, any language, any size.** Part of the Vibe Coding Kit — if you have
not read `START-HERE.md`, start there.
Two jobs: **you always know where you are**, and **nothing in the result is a black box.**

Every term in this document is a term real developers use. Where no standard term exists, it
says so.

---

## What changed in v5

**One stage added, before the five: sketch the product.**

The five stages all run *inside one feature*. Nothing in v4 ever asked what the finished product
looks like — so it was possible to run the process perfectly, ship several features, and only
then discover the shape was wrong. That happened on a real project, at round 2, and it is the
gap this version closes. New skill: `sketch-the-product`. See §3, stage 0.

---

## What changed in v4

The vocabulary. v3 used invented names — Point, Promise, Prove, Park, the gate, Adversary.
They were memorable and useless: they only worked inside this document.

| Was | Now | Why |
|---|---|---|
| Point · Promise · Build · Prove · Park | **Goal · Acceptance criteria · Build · Test · Commit** | Standard terms. Searchable, and usable in a conversation with a developer. |
| the gate | **handover check** | Plain description of what it is |
| the three-layer block | **status** | Same |
| Adversary agent | **reviewer** — the activity is *code review* | A real practice with real literature |
| Scribe agent | **note-taker** | Plain |
| Ledger agent | **stack review** | Plain |
| the ladder | **skill checklist** | Plain |
| full gear / quick gear | **big change / small change** | Plain |
| one turn of the wheel | **the loop** | Plain |

Kept because they are real terms worth owning: *blast radius, retrospective, backlog, commit,
linting, static analysis, acceptance criteria, definition of done.*

---

## 1. Status — where am I?

At any moment you are at one point on each of three levels.

```
PROJECT   Session 7 · Milestone 2 of 4 · next checkpoint: first real user test
   │
   └─ SESSION   stage 2 of 5: acceptance criteria
        │
        └─ LOOP    change → run → check → commit    (turn 1)
```

Write that at the top of every session. When you feel lost, one of the three lines is unknown
— find out which.

| Level | Answers | Lives in |
|---|---|---|
| **Project** | Which milestone, how far to the next checkpoint | `CHARTER.md` |
| **Session** | Which of the five stages we are in | this file, §3 |
| **Loop** | Which small change is currently unverified | your screen |

---

## 2. Day one of any project — 30 minutes, once

**Five things on day one. Five more when they are actually needed.** Ten decisions at once is a
wall; five is a start.

### Mandatory — day one

| # | Do | Why |
|---|---|---|
| 1 | `git init`, first commit | Rollback is the cheapest safety net that exists |
| 2 | `CHARTER.md` — one page: what, for whom, what it is *not* | The "not" list is what stops scope creep in week three |
| 3 | `CLAUDE.md` — the operational file, read every session | Chat history disappears. This is the project's memory. |
| 4 | A persona — five minutes, §6 | You cannot check "is this right for the user" against nobody |
| 5 | **One command that says pass or fail** — even if it only prints "hello" | Everything in §5 hangs on this. Far easier on day one than in month two. |

### Triggered — each appears the moment it is needed

| Do | Appears when |
|---|---|
| **The workshop — `MACHINE.md` and `BOSS.md`, beside the kit** | **The first project on a new machine, or with a new person.** Once, then every project reads it. Templates for both. **Skipped, its contents end up scattered through whichever project happened to be open** — see §14, *Three homes*. |
| `PROJECT-HOME.md` — the one note that links to everything else | The second document exists. This is the **door** — see `START-HERE.md`. |
| **The whole-product sketch** — `sketch-the-product` | The product will have more than two screens. Runs **before the first feature**, once per product. |
| **A round note** &mdash; `templates/ROUND.md` | The first feature starts. **Acceptance criteria need a home**, or they are agreed in a chat that later does not exist. |
| `BACKLOG.md` | The first idea you decide not to do yet |
| **`CONFLICTS.md`** — things in this product that fight each other | **The first time something turns out to be structurally impossible.** One line, in the product's own words. **The cheapest thing in this kit**: plain text the assistant already reads, so it fires without being invoked. |
| **`HANDOVER.md`** — `templates/SESSION-HANDOVER.md` | The work splits across two assistant sessions — one that decides, one that builds. §15. |
| **`PRODUCT-CHANGELOG.md`** — what changed, for the owner | The first round that a non-developer owner will want to understand. Which is round one. |
| `TOOLCHAIN.md` — what each tool owns and must not do | The second tool joins. An unnamed boundary is how you rebuild what an adopted tool already does. |
| `ARCHITECTURE.md` | The second source file. Twenty minutes then, days later. |
| `README.md` | The first runnable code |
| Checkpoints | There is a milestone to check |

**The `README.md` gets updated in the same commit as any change to the run command.** Not later
— a README rots silently, because nothing fails when it is wrong. The `onboarding-docs` skill
covers what goes in it and how to review one.

---

## 3. The session — five stages, and one before them

**Goal · Acceptance criteria · Build · Test · Commit.**

These are the standard names for the stages of any piece of software work. One note: to a
developer, "build" on its own often means *compiling*. Here it means writing the code — the
formal word for that stage is **implementation**, and either is fine to say.

### Stage 0 — sketch the product *(once per product, not per session)*

The five stages run **inside one feature**. None of them asks what the finished product looks
like, which makes it possible to run the process perfectly and still build the wrong thing.

So before the first feature of any product with more than two screens: **draw every screen as a
clickable mockup with fake data.** Skill: `sketch-the-product`.

| | What it produces | Not allowed | Done when |
|---|---|---|---|
| **0** | A clickable mockup of every screen, fake data, no working code | Reading real data · exact spacing and copy · building any of it · **sending a mockup nobody has opened** | It has been **rendered and every screen clicked by whoever made it**, and then the human has answered three questions: is this the right product · which screen next · what is missing |

> **A mockup is code, and code that has not been run is a claim.** On 2026-08-25 a sketch was
> delivered with one stray quote in a JavaScript string. The whole script died, the phone rendered
> blank, and it was published, described screen by screen, and offered for signature — none of
> which required anyone to have looked at it.
>
> The kit's oldest rule says *you run it and look; a summary is not evidence.* It had only ever
> been pointed at the human running code. **It applies to whoever produces the artefact**, and a
> mockup, a diagram and a dashboard are all artefacts that run.

Three rules keep it from becoming a project of its own:

1. **Fake data only.** The moment a mockup reads something real it needs error handling, empty
   states and a test — all of which belong to a later round.
2. **Every screen is labelled** *exists today* / *designed, not built* / *named only*. Unlabelled,
   a mockup is read as a promise, including by the person who drew it four weeks later.
3. **Once per product.** Redraw only when "is this still the shape?" is answered *no* at a
   retrospective.

> This is not the persona check. Stage 0 asks *is this the right set of screens*; `persona-check`
> asks *can this person do this job on this screen*. Run stage 0 first — checking the fit of a
> screen that should not exist wastes the check.

### Stage 0b — the plan, confirmed *(once per product, and again when the shape changes)*

The sketch shows *what* it is. The plan says *what gets built, in what order, at what cost* — and
it carries the only thing in this kit that a human must type themselves:

```
Confirmed by: <name>, <date>
```

**No round note may be written until that line is filled.** Not the goal, not the criteria, not a
file list. A round note written against an unconfirmed plan is the assistant deciding what to
build and asking permission afterwards, which is not the same thing as approval.

| | What it produces | Not allowed | Done when |
|---|---|---|---|
| **0b** | `PLAN.md` — the shape, what is excluded, the rounds in order, the checkpoint, the cost | Writing a round note · naming files · any code · **asking for confirmation while the sketch and the plan disagree** | The sketch matches the plan, **and** the `Confirmed by` line has a name and a date in it |

**The plan is confirmed from the picture, not from the prose.** If the sketch shows a screen the
plan cut, redraw the sketch *before* asking — do not note the difference and ask anyway. That was
tried on 2026-08-25 and the answer was *"written is not enough."*

> ### Approval needs something to look at — always, not only for screens
>
> Stated by the Boss on 2026-08-25: **"I can only approve things after seeing mockup."**
>
> Treat that as a condition on approval, not a preference. The same day produced something close to
> a controlled test: one idea, presented twice.
>
> | Format | Answer given |
> |---|---|
> | A well-organised written proposal, with tables | *"I think so, let's try that"* |
> | A working demo they could press | *"I am very happy with this"* |
>
> And in reverse: a twelve-screen product survived several messages of **description** and was
> rejected in four words the moment it was **drawn**.
>
> **So never ask for approval on a description.** Build the smallest thing that can be looked at:
>
> - **Has a UI** → a mockup, rendered and opened before it is sent
> - **No UI** → the concrete equivalent — real sample output, a worked example with actual values,
>   a before-and-after diff. Never a description of what the output would be like.
> - **Too big to mock** → mock the one screen, or the one output, that the decision actually turns on
>
> **This is cheap, which is the part that surprises people.** The demo above took one pass and
> replaced an argument that had already gone wrong once. The mockup that killed the twelve-screen
> product took one message and saved an estimated six rounds.

Text and a picture are not two formats of the same thing. **People agree with prose and argue with
screens** — which is why stage 0 exists at all, and why confirming from prose alone throws away the
check while keeping the paperwork.

**Why this is its own stage and not a habit.** On 2026-08-25 the assistant offered to start
building **three times in one conversation** before any plan existed — a round note, a skill, and
a two-tier build option. Each offer was reasonable on its own. None of them should have been made.

The failure is not eagerness, it is that **approval had no artefact**. Everyone agreed the Boss
approves; nothing recorded that they had. `PLAN.md` is where that fact lives, and the
`Confirmed by` line is the whole mechanism.

> **The plan is not the roadmap.** `ROADMAP.md` ranks everything across all projects.
> `PLAN.md` is one product, agreed once, and it stops being edited the moment it is confirmed —
> a change after that is a re-confirmation with a new date, not a quiet edit.

### The five stages

| # | Stage | What happens | Not allowed | Done when |
|---|---|---|---|---|
| 1 | **Goal** | Read `CLAUDE.md` §"Where we are". Say the *one* goal out loud. **If you cannot say which files change, explore first** — read-only, no edits, until you can. | More than one goal | You can name the goal and the files in one sentence |
| 2 | **Acceptance criteria** | Write what "done" looks like (§5). If it touches a screen, run the persona check. | Writing code | The criteria are written, with a machine line where possible |
| 3 | **Build** | Code gets written, one small change at a time (§4), in the style of §7. Then the `reviewer` agent reads the diff. | New ideas — those go to `BACKLOG.md` | It compiles, the machine check passes, and the review is clear |
| 4 | **Test** | **You** run it against the criteria. Your eyes, not a summary. | Being told it works | Criteria met, or a specific error to report |
| 5 | **Commit** | **Show the result. Ask whether it is right. Fix what comes back.** Then update `CLAUDE.md`, write the next step, `git commit`. | Ending mid-refactor · **committing before the Boss has said yes** | He said yes, it is committed, and future-you could resume cold |

**Two sizes.** A process with one speed gets dropped the first time it is overkill.

| Size | Use when | Stages |
|---|---|---|
| **Big change** | New feature, anything touching data, architecture or a screen | All five |
| **Small change** | A one-file change you can describe in a single sentence | One-line criteria → Build → Test → Commit |

If unsure which, treat it as big. Ten minutes of overhead on a small task is cheaper than
skipping the criteria on a big one.

**A session that runs out of time stops at the end of a stage, never inside one.** If Build is
half done with ten minutes left, revert and commit what worked. An unfinished Build is worth
less than nothing — next time you inherit a broken state you no longer remember.

---

## 4. The loop

Inside Build and Test, this repeats:

```
change one small thing  →  run it  →  check it did what you expected  →  commit
```

**Rule 1: never two unverified changes at once.** If two things changed and it broke, you do
not know which one broke it, and now you debug both. The term for this is **blast radius** —
keep each change small enough that when it fails, the search space is one file.

**Rule 2: the two-strike rule.** After **two** failed attempts at the same problem, stop
correcting. Clear the context and start again with a fresh prompt containing what you learned
from the two failures.

A third correction almost never works, because the two failed attempts are still sitting in
the context steering toward the same wrong answer. Two strikes and you rewrite the question.
This one rule is the difference between a 90-minute session and a 90-minute session that
produced nothing.

A commit is a save point in a game. Free to make. A bad turn costs one turn.

---

## 5. Acceptance criteria — two checks, not one

**Acceptance criteria** are the conditions that have to be true for this specific piece of work
to count as done. Standard term, used on every agile team.

They must be **observable, in a fixed number of steps, and not a judgement call.** Write two
versions.

```
ACCEPTANCE CRITERIA
  Human:    open the app → wrong password → red message within 2s →
            right password → home screen
  Machine:  pytest tests/test_login.py      →  passes
```

**Why both.** The human line answers *did it do the thing*. The machine line answers *did it
break the other thing*, and it keeps answering that for free every week from now on. At a few
hours a week, any check that needs your eyes is a check that mostly does not happen.

Not everything can have a machine line. Write `Machine: none, because <reason>`. Naming the
absence is the point; an unstated gap is the one that surprises you.

> This also answers the strongest published criticism of writing specs for AI: **prose specs
> drift, because they cannot fail.** A test is a spec that fails when it stops being true.

**Test the human line:** could someone who has never seen the code run it and reach the same
yes/no as you? If not, it is not a criterion yet.

**Test the machine line too — by breaking the thing it checks.** After writing a test, make the
code wrong on purpose and watch the test fail. Then undo it.

> A test that has never been seen to fail is a claim, not a check.

**Run it both ways, as two commands.** Keep the fix and run the suite; restore the bug and run it
again. **The failure has to appear.** If it does not, the test is not testing the thing — and that
has happened three times on this project, once within an hour of this rule being written.

This is not pedantry. It happened three times in one day on this project: a widget test asserted a
*mangled* string and passed while the screen was visibly wrong; a hook test mocked a field name
that does not exist and passed while the hook could never fire. In both cases the test and the code
were written from the same wrong assumption at the same moment, so no amount of care *inside* that
assumption would have caught it. Only running it against reality does.

**Scope rule:** if it is not in the criteria, it is not in this session.

**`[NEEDS DECISION: …]`** — when something must be decided and the answer is not in the charter
or the persona, the assistant writes that marker and **stops**, rather than choosing something
plausible. A guess made silently at this stage becomes an assumption baked into the
architecture.

### Related term: definition of done

**Acceptance criteria** change with every piece of work. The **definition of done** is the same
for *everything* in the project — it is the standing bar. Yours:

> Criteria met · handover check written · reviewed · `CLAUDE.md` updated · **a line in the
> plain-language changelog** · **a screenshot, if a screen changed** · **the result shown to the
> Boss and a yes back** · committed.

**The last two before the commit are in that order on purpose.** Shown, then approved, then
committed — see §8's fifth line and §14, *Done is not delivered*.

Write it once in `CLAUDE.md` and stop restating it per session.

### The last two, and why they were added

*From the first outside test, 2026-08-31 — an item its author called the most important in the
package.*

> **When the person who owns the product cannot read its code, the build is not documented until
> there is a version they can read.**

The kit's documentation guidance was developer-to-developer. **Its actual audience is not a
developer** — that is the whole premise of the package, and the definition of done had not noticed.

| Added | Why a diff cannot do it |
|---|---|
| **A line in `PRODUCT-CHANGELOG.md`**, in the same commit as the work | It says what a person **can now do that they could not before**. Not file names, not "refactored the view model". Readable by the owner, a future developer, or an investor doing diligence. **In the same commit**, because a changelog updated afterwards stops being updated in week three. |
| **A screenshot from the real device**, for any round that changes a screen | They review visually and are often the only tester. A diff cannot show a layout — and a screenshot dates itself, which a claim does not. |

Template and the rules for writing an entry: `templates/PRODUCT-CHANGELOG.md`.

**And the git split, which is where it actually failed:** a session that can run git **commits its
own round with a message naming it**; a session reaching the repo across a bridge **must not run git
at all** — it leaves a lock it cannot delete. The kit said *"push before calling it done"* and
stopped there. *Who* pushes, and *what the message says*, is the part that broke.

---

## 6. The persona, in five minutes

You cannot check whether something fits the user without writing down who the user is. It does
not need to be long — it needs to be **disagreeable**, meaning you could argue with it.

The block to fill in is `templates/PERSONA.md` — five lines. Two rules matter more than the
format:

**Write `Quits when` first.** Written after you have seen the design, it will conveniently
describe something the design already avoids. An invented persona becomes a mirror.

If the user is you, the trap is worse — you will describe who you wish you were. Anchor it in
evidence: which similar tools did you actually abandon, in which week, and what were you doing
when you stopped opening them.

---

## 7. Code you can check — no black boxes

The process being inspectable is not enough. **The code itself has to be written so a human can
check it**, or you have a working system nobody understands, which is a system you cannot
change.

This is not a style preference. It is the countermeasure to a measured effect: assisted
codebases show rising duplication and collapsing refactoring — code accumulates faster than
anyone reorganises it. The only defence is that each piece stays readable on its own.

**1. Boring beats clever.** The scarce resource is the reader's attention, not the CPU's. No
metaprogramming, no dynamic dispatch where a plain `if` works, no one-liner that needs a
comment to explain it. If the assistant produces something clever, ask for the boring version
and compare.

**2. A diff you can read in one sitting.** If understanding a change means scrolling back and
forth, it is two changes. Split it.

**3. Names say what, not how.** `days_until_renewal()` can be checked without being read.
`process()` cannot.

**4. No action at a distance.** If calling a function also writes to the database, sends an
email, or changes something the caller owns, that must be visible in its name or its signature.
Hidden **side effects** are the hardest thing for a human to catch by reading.

**5. Show the raw data at every boundary.** Anywhere the code talks to the outside — an API, a
database, a file — there must be a way to see exactly what came back, unprocessed. One flag,
one log line, one debug screen. Almost every "I don't understand why it does that" ends here.

**6. No silent failure.** An error either surfaces or is logged with what was being attempted
and what came back. A swallowed exception is a black box by construction — the code is now
lying to you about its own state.

**7. Every number a user sees has a traceable source.** You can point at any figure on any
screen and say which query, file or API produced it. A dashboard nobody can reconcile gets
distrusted once and then ignored forever.

**8. Comments explain *why*, not *what*.** The code already says what. Future-you needs to know
why this and not the obvious alternative — especially the alternative that was tried and
failed.

**9. No dependency that cannot be explained in two sentences.** Every library is something you
must understand, update and eventually debug.

**10. The complexity log.** Anything clever that survives gets one line in `CLAUDE.md`: what it
is, and why the boring version was not enough. Not a ban — a receipt. Most cleverness quietly
does not survive having to justify itself in writing.

**The test:** can you explain this change to someone else, one week from now, without
re-reading it? If not, that is not your failure — the explanation or the code is wrong. Ask for
it in different words, or ask for a simpler version.


**11. A retired term is a banned term.** When this project renames something — in code, in a
document, or on a screen — the old word does not come back. Keep the list of retirements where it
can be checked (the v4 table in this file is one), and check it before naming anything.

*Why this is a rule and not a preference:* a word that gets renamed and then reappears is worse
than a word that was never fixed. It means the rename never held, so nobody can trust that any
name means what it says. This rule exists because it was broken: `gate` was retired in v4 for
being confusing, and reappeared six times in a screen design on 2026-08-24.
---

## 8. The handover check — five lines

Every time the assistant hands you anything, these five lines come with it, containing the
**actual command and the actual output**.

```
Exists?    — grep -r "parseDate" src/   →  0 hits, so this is new code
Checked?   — npm test                   →  14 passed, 0 failed
Honest?    — the API response is a hard-coded sample; the real call is untested
Reachable? — Home → Settings → Practice; the button is on Settings as of this change
Approved?  — shown 14:10, asked, yes at 14:18  →  and only now, commit
```

- **Exists?** — assistants are biased toward writing new code rather than finding code already
  there. This catches it, and it is the direct counter to the duplication problem in §7.
- **Checked?** — a review step only helps if it ran. Naming that it was *skipped* is as useful
  as naming that it ran.
- **Reachable?** — **is there a path to it?** Name the route a person takes, tap by tap, and say
  which part of it this change added. *Added after the first outside test, 2026-08-31: three times in
  one day, work that was correct, tested and reviewed was **unreachable** — a screen inside an app
  whose navigation still matched the old design, multi-page handling behind a capture step that could
  only produce one page, and plumbing behind an API field the backend does not fill. The other three
  lines would have passed on all three.*
- **Honest?** — mocks, guessed versions and untested paths get named **at handover**, not
  discovered an hour later. Anything fake must be visibly labelled *in the product* too — a
  mock that looks real gets tested as if it were real, and that costs a session.
- **Approved?** — **the last line, and the only one that is not about the code.** The result was
  **shown**, the question *"is this right?"* was actually **asked**, and the answer came back. The
  order is the rule: **show → ask → fix or commit.**
  **If the round touched a screen, the approved drawing goes next to the screenshot before the
  question is asked** — not afterwards, and not as a link. *Added 2026-09-04: a screen was rejected
  twice for not matching a drawing nobody had put beside it. Two images in one message is the
  cheapest gate in this kit.* If the answer names a fix, the fix is made
  and shown again — this line goes green only on a yes. *Added 2026-09-02, after a session
  reported a version done having shown nothing and committed nothing. §14, "Done is not
  delivered".*

**A claim you cannot re-run is not evidence.** If a line has no command in it, ask for one.

**Scope it, or it gets ignored.** Ask for pasted output only when you will **reason from it** —
an error message, a version, a device list. For everything else ask for **one line or one word**,
never "the output": selecting and copying a terminal is real work, and a rule with a real cost
gets skipped.

**And record which is which.** In the session log, mark each criterion **evidenced** (you saw the
output) or **reported** (you were told). That keeps the record honest without needing anyone's
cooperation — which is the only kind of rule that survives contact with a tired human.

---

## 9. The files that survive the session

Chat history disappears. These four are the project's memory.

| File | Answers | Updated |
|---|---|---|
| `CHARTER.md` | What are we building, and why this way? | rarely — at checkpoints |
| `CLAUDE.md` | Where are we, what is decided, what already failed? | **every session** |
| `BACKLOG.md` | What did we deliberately not do? | whenever an idea appears |
| `PLAYBOOK.md` | How do we work? | at retrospectives only |

`CLAUDE.md` sections that work: Goal · Shape · Hard rules · Definition of done · Decisions ·
Verified findings · Rejected approaches · Complexity log · Vocabulary · Deferred · Where we
are · Session log.

- **Verified findings** — what you *measured*, not what the documentation claims. The docs are
  a claim; your running system is the fact.
- **Rejected approaches** — with the reason, or you retry them in three weeks.

**Size discipline.** `CLAUDE.md` is re-read at the start of every session, so every line is
paid for repeatedly. The test for each line: **would removing it cause a mistake?** If not, cut
it. Reasoning and history live in `CHARTER.md` and the session log.

---

## 10. The agent team

**An agent earns its place only when it needs a context the main session cannot have.**
Otherwise it is the same work at double the cost, because every agent reads the project from
scratch.

| | Role | Runs at | Why separate |
|---|---|---|---|
| Agent | **reviewer** | end of Build, before you test | Reads the diff *without* knowing the reasoning behind it. Nobody reviews their own work well — they already believe it is right. Highest value by a distance. The practice is called **code review**. |
| Agent | **note-taker** | Commit | Mechanical: update `CLAUDE.md`, write the session log, draft the commit message. Cheap model. Removes the end-of-session tiredness that makes people skip the note. |
| Agent | **stack review** | monthly, or at a checkpoint | Re-checks the libraries: still maintained? something better now? Needs to search the web, not the repo. |
| Skill | **persona-check** | Acceptance criteria, and again before you test | Asks what code review never asks: *can this person do this job on this screen?* |
| Skill | **onboarding-docs** | day one, and when the run command changes | Writing for someone with none of your context is a different job from writing code. Covers `README.md`, `CONTRIBUTING.md` and handover notes. |
| Skill | **explain-as-we-go** | always | Governs how things get explained, so you end up able to reason about your own project. |

Skills that fire earlier or later than a session: **discovery** (before anything exists),
**stack-choice** (choosing or questioning the technology), **data-and-secrets** (before the
first commit, and any time personal data appears), **first-test** (day one, and when you need a
machine check), **debugging** (when the second attempt failed), **ship-it** (when someone else
needs it). Scaling skills — **architecture-map**, **module-contract**, **regression-gate**,
**non-functional**, **team-review** — are described in `SCALING.md`, with the moment each starts.

See `START-HERE.md` for the full map.

**Not an agent: a planner.** Planning is the acceptance-criteria stage, done with you. Handing
your thinking to a subagent is how you end up managing a project you do not understand.

### The hiring rule

> **A new agent needs a written answer to: *what does it need to not know?***
> If there is no answer, it is a skill.

The second reason to hire is volume — a job that would flood your conversation with detail
(searching the web, reading thirty files) belongs in a separate context whatever it knows.

Nothing else justifies an agent. Grouping skills into departments is useful for **navigation and
focus**, not for headcount: an org chart makes you hire, and every agent costs tokens and re-reads
the project from scratch.

### Wiring an agent

In Claude Code, agents are markdown files under `.claude/agents/`:

```markdown
---
name: reviewer
description: Code review of a diff against the session's acceptance criteria. Runs before the human tests anything.
tools: Read, Grep, Glob, Bash
---
<instructions>
```

**Do not retype the instructions here, and do not copy the file by hand either.**
`install-skills.ps1` puts every `agents/*.md` into `.claude/agents` and prints each one by name. An
agent defined in two places drifts, and the copy that drifts is always the one you read.

> **The installer did not always do this.** Until 2026-08-26 it deliberately skipped the agents
> folder, on the recorded grounds that no agent had ever run and the decision *"hook them or delete
> them"* was still open. `.claude/agents` therefore did not exist, in any scope, and **an
> uninstalled subagent cannot be invoked** — so the zero was measuring the installer.
>
> Three rounds passed with two competing theories written down about the trigger, neither of them
> checked against the filesystem. See `KIT-LOG.md`, same date.

⚠️ Folder layout and frontmatter fields change between versions. Create one, run it once,
confirm it fires — before building process around it. **"Installed" and "fired" are two separate
facts and both need evidence**: the installer printing a name proves the first only.

### Brief an agent with the constraints, not only the task

**An agent inherits your instructions. It does not inherit what you happen to know.**

On 2026-08-26 a reviewer was dispatched into a real repo with the path, the files and the criteria —
and not the project's rule that **`git` must never be run through the file bridge**. Its own
instructions told it to read `CLAUDE.md` for the hard rules; the rule had been moved out of that file
four hours earlier. It ran git, left a lock file it could not delete, and **blocked the commit of the
round it had just reviewed.**

So every dispatch carries three things beyond the task:

| | |
|---|---|
| **What it may not do** | the destructive or environment-specific actions — named, not implied. "Read only" is not the same as "do not run git here". |
| **What it cannot do, and must say so** | *"you cannot run the machine check; say that plainly rather than implying you did"*. Both reviewers here did, and their verdicts were worth more for it. |
| **Where the rules live** | not just the repo path. If a rule that binds it sits in a second file, name that file — an agent reads what it is pointed at and nothing else. |

**The failure is silent by construction**: the agent does the sensible thing, and the damage shows up
later somewhere else. Nothing in its report will mention it, because from inside, nothing went wrong.

---

## 11. Triggers — why any of this happens

A rule with no trigger is an intention. Each piece is bound to a moment that occurs anyway.

| Moment | What happens |
|---|---|
| A product with more than two screens, before its first feature | `sketch-the-product` — every screen, fake data, three labels (§3 stage 0) |
| Three features built and no whole-product sketch exists | Run stage 0 now. Late beats never. |
| Session starts | Read `CLAUDE.md`, write the status block, name the one goal |
| You cannot say which files change | Explore first, read-only, before writing criteria |
| Before any code | Acceptance criteria written — human line **and** machine line |
| The session touches a screen | `persona-check` on the *described* screen, before it exists |
| Two failed attempts at the same problem | Clear the context, rewrite the prompt |
| A decision is needed that is not in the charter | `[NEEDS DECISION: …]`, and stop |
| Any handover to you | The handover check, with commands |
| Build is finished, before you test | The `reviewer` agent reads the diff — see §10 |
| It compiles | The machine check runs, then **you** run it |
| Session ends | `CLAUDE.md` updated, commit, and **one question**: did anything about the process get in the way? One line into `KIT-LOG.md` — §14 |
| Something is renamed | The old word is now banned. §7 rule 11 |
| Checkpoint | Retrospective (§12) |

If you write a rule and cannot name the moment it fires, it will not fire.

**When a trigger keeps getting skipped, stop trusting instructions and make it mechanical.**
Most agent tools support **hooks** — scripts that run automatically at a fixed moment and can
block until they pass. Instructions are advisory; a hook is not.

---

## 12. The retrospective — at checkpoints, not on a calendar

A **retrospective** is the standard agile meeting where a team looks back at a period of work
and changes how it works. Twenty minutes at each checkpoint:

1. **Walk every acceptance criterion since the last one**: met / not met / not attempted. An
   unmet criterion recorded as met makes this whole system worthless.
2. **Any trap that happened twice becomes a rule** in `CLAUDE.md`, written as what *to do*, not
   what to avoid. Once is bad luck; twice is a pattern.
3. **Read the complexity log.** Anything that no longer earns its place gets simplified.
4. **Run the stack review**, and `process-audit` if the process documents have grown.
5. **Read `KIT-LOG.md`.** Anything that appears twice is a real finding; act on those and nothing else.
6. **Ask whether the sketch is still the shape.** Look at the stage 0 mockup next to what is
   actually built. Same product? If not, redraw it or delete it — a stale sketch still linked as
   "the plan" is worse than none. This is the *only* moment stage 0 re-runs.
7. **Promote what was invented here.** Anything general that was worked out on this project —
   a convention, a template, a rule — goes back into the kit. Without this trigger, every project
   quietly reinvents what the last one already solved.
8. **Name the next milestone's one outcome.**

Rule cap: keep `CLAUDE.md` hard rules under ~20. When you add one, ask which one retires.

**Change the process only at retrospectives.** Changing it mid-milestone means you never find
out whether it worked.

---

## 13. Skill checklist — proof it is not a black box

The point of all of this is that you can reason about what you built, not just that it runs.

**The test: can you explain the change you accepted to someone else, one week later?**
If not, the explanation failed — go back and get it explained differently. That is the
assistant's failure, not yours.

In order, for any project:

1. Run it, and read the error when it fails
2. Commit and roll back without help
3. Follow one piece of data from the screen to storage and back
4. Read a stack trace and name the file to look in
5. Add a small feature alone

You do not need all five on day one. You should be able to name which step you are on.

---

## 14. The improvement loop — how the kit improves itself

The kit has to get better from being used, or it is a document that ages. Three things make that
mechanical rather than hopeful.

### One question at the end of every session

Not a review, not a retrospective. **One question, asked by the assistant, answered in a
sentence:**

> **"Did anything about the process itself get in the way today?"**

Whatever comes back goes into `KIT-LOG.md` as one line. That is the whole ritual. It fires at the
same moment as the commit, so it costs nothing extra to remember.

**Why one question and not a form:** the previous version asked for five fields and got skipped.
A loop that depends on effort at the end of a session, when the session is already over, has to
be one sentence long.

### When the product exists to test the kit, say so — and let it change decisions

Some projects are built **to exercise the process**, not to ship. When that is true it is not a
footnote; it reorders things:

| | Ordinary project | A project built to test the kit |
|---|---|---|
| Scarce resource | sessions | **the Boss's engagement.** Session count stops being the objection. |
| A round is worth more when | it delivers more | **it exercises a part of the process that has never run** |
| Two equally good designs | pick the cheaper | **pick the one that touches more of the kit** |
| "Good enough to ship" | the goal | not the goal. Process coverage is. |

**Write it into the plan** — *"Why this is being built at all"* — and then **give the rounds table a
column for what each round exercises.** Without that column the priority is a sentence nobody acts
on; with it, an untested skill is a visible reason to order one round before another.

> Stated by the Boss, 2026-08-25: *"Remember to always prioritize improving the kit, as we do this
> project to improve the kit only."* Every cost table produced that day had led with a session
> count — which was never the constraint.

### When the kit may change, and when it must stop

Two rules, agreed 2026-08-25 and **written down 2026-08-25 after being agreed only in conversation
for a full session** — which is itself the finding immediately below this one.

**1. The kit changes only as a by-product of building something else.**

Evidence, measured: five scaling skills were added on 2026-08-23 from an argument about the kit —
**four are still dormant.** The three hooks and stage 0 were added from friction met while
building — **all four fire.** Speculative additions ran at an 80% failure rate; friction-driven
ones at 0%.

> **The exception, and it matters more than the rule:** an item **already ranked** in `ROADMAP.md`
> from a measured finding does **not** need new friction to justify it. It needs a slot.
>
> Without this clause the rule blocks the very work it was meant to prioritise. That happened on
> its first day: the skill-boundary edits were ranked, evidence-backed and undone, and the
> collision they described then cost a real miss eight hours later.

**2. The kit is done enough when one product ships without needing a kit change mid-round.**

A package with no stopping condition grows until the person maintaining it stops. That is the
condition; it is testable, and reaching it is a better outcome than another version.

### Nothing agreed is finished until it is in a file something reads

The failure this rule exists for, dated 2026-08-25: a session produced a skill-to-step mapping, six
named collision clusters, a ranked list, a rule about when the kit may change, and a stopping
condition. **Two of those five reached a file. The rule and the stopping condition reached
nothing** — they lived in the conversation, were agreed, and evaporated. One of the ranked items
then went undone and cost a real defect the same day.

So the closing move of any analysis is mechanical, not optional:

| Conclusion type | Goes to |
|---|---|
| A rule about how work is done | `PLAYBOOK.md` |
| A ranked item of work | `ROADMAP.md`, in `Now` / `Next` / `Later` |
| A fact measured on the machine | `CLAUDE.md` → Verified findings |
| A decision with alternatives considered | an ADR |
| Anything deliberately not being done | `BACKLOG.md` |

> **An agreement in a conversation is not an artefact.** This is the same defect as approval having
> no home — one level up. It is the reason `PLAN.md` has a signature line, and the reason this
> table exists.

**Widened 2026-08-25, the same day it was written, because its first scope was too narrow.** It said
*analysis*, and the next failure was **conversational design**: ten decisions agreed after a plan
was signed — a new home screen, a new data type, a rewritten architecture, five sessions becoming
eight — none of it written anywhere but a mockup.

So the rule is **any agreement**, not any analysis. And a signed plan is the most dangerous place
for this, because **it looks finished**: nobody expects to edit it, so decisions pile up beside it
instead of in it. `templates/PLAN.md` now carries a *Decided since the last confirmation* table for
exactly that, and it must be empty before the plan can be signed again.

> Ask at the end of any design conversation, not only after an analysis: **what did we just agree,
> and which file does it live in now?**

### Where a demand goes when the kit cannot meet it

Every "it should also do X" is one of three things, and they have three different destinations.
Sorting it wrong is how a process gap gets built as a feature.

| Kind | Goes to | Changes | Speed |
|---|---|---|---|
| **Missing feature** — the product should do more | `BACKLOG.md`, then the roadmap | The product | A round |
| **Missing process** — the kit had no step for this | `KIT-LOG.md` | The kit, at the next version | **Only after it happens twice** |
| **Missing capability** — needs money, a person, or a tool that does not exist | `business-case` skill | Nothing yet | Recorded as blocked, with the reason |
| **Missing know-how** — nobody has written down how this product's own thing works | **the product's `.claude/skills/`** | The product | Same session — see *Two libraries* below |

### Three homes: the kit, the workshop, the product

**Everything written down belongs to exactly one of three homes.** Until 2026-08-26 the kit had one,
which is why a product skill walked straight into it — and why one laptop's facts were living inside
one product, where the next product cannot read them.

| Home | Answers | Lives in | Changes when | Holds |
|---|---|---|---|---|
| **Kit** | *how do we build **anything**?* | the kit folder · `skills/` installed to `~/.claude/skills` | a version is cut | the playbook, the templates, the hooks, the general skills |
| **Workshop** | *what is true of **this machine** and **this Boss**?* | `MACHINE.md` and `BOSS.md`, **once**, beside the kit | the laptop or the person changes | versions installed, admin rights, shell quirks, measured build times, how the Boss decides and learns |
| **Product** | *how does **this thing** work?* | the repo — `CLAUDE.md`, `decisions/`, `.claude/skills/` | every commit | the schema, the seams, the domain rules, this product's persona |

**Two questions, in order, and they settle it:**

> **1. Would this still be true in a project that has nothing to do with this product?**
> No → **product.**
>
> **2. Would it still be true on someone else's machine, for someone else?**
> Yes → **kit.** Otherwise → **workshop.**

**When something is genuinely two of them, it is two entries** — the general rule in the kit, the
instance in the workshop or the product, and a pointer between them. Never one entry hedged to cover
both, which is how a general package acquires a paragraph nobody else can use.

> **Why the workshop is the one people miss.** *"No admin rights on this laptop", "PowerShell 5.1 has
> no `??`", "the first build took ten minutes"* — none of that is general enough for the kit and none
> of it belongs to any one product. With only two homes it lands in whichever product was open at the
> time, and **product number two either re-learns it or copies it, and then there are two copies that
> drift.** On 2026-08-26 an app's `CLAUDE.md` held fourteen such facts.

> **How this rule was earned.** On 2026-08-26 a skill called `content-pack` was written into the
> kit: how to choose a file format for reference content that ships inside a product, and how to
> validate it. It was good, it fired the same day, and it was **in the wrong library** — the Boss
> said so in one sentence:
>
> > *"This skill is for the product the kit produces. But the kit should be able to support this
> > skills systems or ideas to make the product possible."*
>
> Which is the distinction exactly. The kit does not need to know what a German gender pack is. It
> needs to **make a product able to have one** — a place to put the skill, a rule for when a decision
> is an ADR, and a habit of asking whether content belongs in code.
>
> **Why it defaulted into the kit:** the kit had a path *upward* — a promotion trigger, written after
> seven generic things were invented inside one project on 2026-08-22 and had to be moved back by
> hand — and **no path downward, and no home at the bottom.** With one library and a rule pointing
> only into it, everything invented anywhere ends up in the kit. That is how a general package
> quietly turns into one project's notes.

**What the kit provides instead, and it is enough:**

1. **The slot.** A product's own skills live in its repo and are read from there. `install-skills.ps1`
   leaves them alone and prints them by name, so the libraries never overwrite each other.
2. **`templates/PRODUCT-SKILL.md`** — the shape of one, and the four things it must carry.
3. **The ADR habit** — a format, a schema or a seam is a *decision with a date*, not a skill.
   `templates/ADR.md`, and `architecture-map` asks the question that finds them.
4. **A rule that binds behaviour stays in the operational file, even when its evidence moves.**
   *Learned four hours after this section was written, on 2026-08-26.* The rule *"never run git
   through the device bridge"* was moved into `MACHINE.md` with the other machine facts — correct by
   the letter of the table above. A subagent was then told, by its own instructions, to *"read
   `CLAUDE.md` for the project's hard rules"*. The rule was no longer there. It ran git through the
   bridge and left a lock file that blocked the round's commit.

   > **Split the fact from the rule.** *"Git through the bridge has no `core.autocrlf` and reports
   > 4,742 phantom changes"* is a **workshop** measurement. *"`git` runs in PowerShell, never through
   > the bridge"* is a **product** operating rule, and it belongs in the file everyone working in that
   > repo is pointed at. Moving the evidence out is right; moving the instruction out is how a rule
   > stops binding anyone.

   And the general form, worth more than the instance: **a rule only binds the people who are told to
   read the file it lives in.** Before relocating one, ask who currently reads its home and who reads
   the new one.

5. **The bounce, in every direction.** A kit skill that turns out to be about one product moves down;
   a machine fact found in a product moves sideways into the workshop; a product skill written twice
   in two repos moves up. Record the move in `KIT-LOG.md` either way — **the movement is the
   interesting data**, not the destination.

**And a rule is not a system.** `check-boundaries.ps1` scans the kit for product names and exits 1 on
a hit, with a soft count for one-ecosystem technology, which is legitimate as an example. Run it at
every retrospective and before cutting a version.

> **Its own first run is the argument for having it.** It found two real leaks — and **four false
> positives**, because a substring match read "r*anki*ng" as the flashcard app four times. A check
> whose first output is mostly noise is a check that gets switched off, so it now matches whole words
> and has a self-test (`-SelfTest`) that plants a leak, proves the scan catches it, and proves
> "ranking" is not caught.
>
> It also drew a line the rule had not: **somebody else's product is not a leak.** Naming Anki,
> Obsidian or git as an example is what a kit is *for*. The list is of the products **we** build.

### When a rule gets skipped, check its scope before writing a new one

**The most reliable diagnostic in this kit, and the cheapest.** On 2026-08-25 five separate
failures happened in one session. Every one was a rule that already existed, failing just outside
the scope it had been given:

| The rule | What it actually bound | Where it failed |
|---|---|---|
| *You run it and look; a summary is not evidence* | the human, running code | **the assistant**, publishing a mockup it had never opened |
| *Measured on this machine, not taken from documentation* | findings in `CLAUDE.md` | **instructions** — a round note full of steps copied from docs, two of them obsolete |
| *The Boss approves before work starts* | everyone agreed it was true | nothing **recorded** that they had, so approval was inferred |
| Stage 0 requires a `Sketch:` link | a link being present | the link was **stale, and still satisfied the field** |
| Stage 0 fires above two screens | the skill's description | **nothing consulted the description** at the moment it applied |
| *Nothing agreed is finished until it is in a file something reads* | **new** agreements | the **old** contents of that file. `CLAUDE.md` still described a twelve-screen product that had been rejected, through two re-confirmations of the plan that replaced it. Every decision since was written down; nothing looked back at what they contradicted. *2026-08-26.* |
| *0 runs, so it has not earned its place* | skills, which the installer installs | **agents, which it did not.** The dormancy count was measuring the plumbing. *2026-08-26 — see below.* |

Not one of these needed a new rule. Each needed the existing one pointed one step wider.

> **So the first question at a retrospective is not "what rule is missing?" It is:
> who or what does the existing rule actually bind — and who was standing just outside it?**

Two corollaries worth holding:

- **A field that can be satisfied without being true is not yet a check.** A link, a tick, a
  filename. Add the condition that makes it true, not a second field.
- **Rules that say "verify" almost always bind the human by default.** Wherever the assistant
  produces something that runs — a mockup, a diagram, a script, a dashboard — the same rule binds
  the assistant, and nobody will have written that down.

### The drawing and the spec are two encodings of one screen, and nobody compares them

**A visual round has three documents: a drawing, a prose spec, and code.** The drawing is approved.
The spec is then written from it, by hand, usually by the same person — and **prose cannot carry
layout.** Flat list against cards, a pill against a line of grey text, `today` against
`2026-09-02`, where the date sits on the row: none of that survives being written down unless
someone writes it down on purpose, and nothing measures what was lost.

Then the code is built from the spec, and **judged against the drawing.**

*2026-09-04.* A screen was built twice and rejected twice. The spec said:

> *"Each row — title, status, date… **the provenance block stays below both, unchanged.**"*

The approved drawing showed pills, hairlines, humanised dates, and **no provenance block at all.**
Of eight reported differences, **zero were the building session disobeying an instruction.** Seven
were the spec being silent about form. **The eighth was the build obeying the spec, and the review
calling that a defect.**

> **When a drawing and a spec describe the same screen, one of them is a copy — and nobody has
> compared them.** Compare them, on purpose, **before either is handed to anyone**, and write down
> every disagreement and how it was resolved.

**This is the only fix in that incident that prevents rather than detects.** Filing the drawing,
checking the path resolves, putting the image next to the screenshot — all good, all make the
failure visible sooner. **Only the reconciliation stops it happening**, because it attacks the
lossy step itself.

**Two rules that fall out of it:**

- **Declare which document wins, per class of question.** *Prose owns data, behaviour and scope.
  The image owns form.* Where they disagree about form, the image wins; where they disagree about
  data, the prose wins **and the image gets redrawn before the round starts.** A builder who has to
  guess this will follow the document addressed to them, every time, and be right to.
- **Never let one person draw the sketch, write the spec, and judge the result.** That chain had
  five roles and one actor, with no independent step. The kit has a reviewer for code and a persona
  check for screens; **it has nothing that checks a spec against the design it came from** — the
  most error-prone translation in a visual round.

### And its mirror: when a rule IS followed, check that it binds the right actor

**The scope diagnostic above catches a rule that failed by being too narrow. This is the other
direction, and it is harder to see, because nothing fails.** A rule that is obeyed exactly as
written, by someone it was never about, looks like the process working.

*2026-09-03.* A rule read:

> *"Nico runs every `git` and `flutter` command himself, in Windows PowerShell. Never through an
> assistant's device bridge — one left a stale `.git/index.lock` on 2026-08-26."*

One sentence, two claims, and the second is the stated reason for the first. **The incident was the
deciding session, reaching the machine through a bridge that cannot delete a file it creates.** The
**building session** runs in a real shell and has no such limitation — and it had been quoting this
rule for a morning as the reason it could not run a test, handing every `flutter test` back to the
Boss to type. On a test-iteration loop.

> **When a rule names an incident as its reason, check that the actor it constrains is the actor
> from the incident.** A rule written as *"assistants must not X"* after **one** assistant hit a
> **mechanism-specific** problem over-applies to every assistant, forever — and the
> over-application is invisible, because the rule still reads as prudent.

**The tell, and it is worth memorising: a rule whose cost is paid by someone the rule does not
mention.** That one constrained two assistants, cited one incident, and **billed the human** — on
every check of every round.

**Two corollaries:**

- **A prohibition should name the mechanism, not the category of actor.** *"Never through the device
  bridge"* is correct and stays true forever. *"Assistants never run commands"* was never what the
  incident showed.
- **The audit question at every retrospective:** *who is actually paying for each rule?* If the
  answer is someone the rule does not name, the rule is pointed at the wrong actor.

### When something has never fired, check that it is installed before theorising about its trigger

**Dormancy has a boring cause and an interesting one. Check the boring one first, because it takes
one `ls`.**

| Order | Question | Cost to answer |
|---|---|---|
| 1 | **Is it in a path the tool actually reads?** | seconds |
| 2 | Does anything consult its description at the moment it applies? | minutes |
| 3 | Is the work already happening inline, making it duplication? | a retrospective |

On 2026-08-26 the kit's three agents had zero runs across six rounds. Two explanations were written
down — unenforced trigger, or duplicated work — and the retrospective was named as the place to
choose between them. **The real answer was that `.claude/agents` did not exist**, because the
installer skipped that folder *on the grounds that the agents had never run.* The measurement was
its own cause.

> **A dormancy count is only evidence if the thing was reachable.** Otherwise it measures the
> plumbing. Any argument that ends in *"it has never fired, so retire it"* needs the reachability
> line above it, or the kit will eventually delete something for never firing from a folder nothing
> reads.

And the wider version, which is the one that generalises: **a fix applied to one folder and not to
its sibling looks exactly like a decision.** The installer was written because twenty-four skills
sat in a folder nothing loaded; `agents/` sat beside it, unfixed, for two days — with a comment
explaining why, which is what made it invisible. **When you fix a class of bug, name the class and
sweep it.**

### Confirmed twice — four laws, each seen in two unrelated projects

**This kit's brake is *twice, not once*.** These four were found here, and then found again
independently by the first outside tester in a different product, a different stack and a different
environment, within the same week. They are no longer observations.

| The law | Here | There |
|---|---|---|
| **A step that depends on being remembered does not survive a busy week** | Six rounds of *"the reviewer should run"* → zero runs. One round of *"its verdict goes in the note"* → thirteen findings. | An orchestrating skill skipped three sessions running; `persona-check` skipped twice on exactly the work it exists for |
| **A claim of coverage must name its denominator** | 25 green tests over the files the tests happened to import, while the app could not build | A stored finding — *"screenshot-tested, no collisions"* — measured at desktop width and false at phone width |
| **A fix has to live where the failure happens** | A rule moved to `MACHINE.md`; a subagent told to read `CLAUDE.md` broke it ninety minutes later | A path corrected in a rules file nobody reads while typing a command. It failed again, identically. The working fix was two lines at the point of failure. |
| **A default that is always accepted is not a default — it is the value** | `check.json` shipped one product's command as every project's default | A save script falling back to a timestamp became **half the project's history**. Nobody ever chose it. |

**The corollary on that last one, and it is the one to keep:** *any convenience script written for a
non-developer must be audited for what it decides on their behalf.* **They cannot evaluate the
default, which is precisely why it was made one.**

**And a measurement needs its conditions.** *"Screenshot-tested, no collisions"* was true — on a
desktop. A measurement recorded without the conditions it was taken under is not a measurement, and
it is worse than nothing, because it will be built on. Wherever findings get written down, write what
they were measured on.

### Which parts of this kit need which environment

*From the first outside test, and it was the correction that made the rest of the feedback usable.
An early draft said the hooks "do not run". They were then watched firing — including a commit
genuinely blocked, naming the file that had changed since the last test pass. **They work.** They
were simply never reachable from the environment the kit was being judged in.*

> **The kit's only enforcement mechanism is available in one environment, and its users spend much
> of their time in another. Nothing in the kit said so.**

| Part | Works where |
|---|---|
| **The playbook, the templates, the skills, `CONFLICTS.md`** | **Anywhere.** Text the assistant reads. No trigger to remember, no shell required. |
| **The hooks** — orient, record-test, gate-commit | **Only** where the assistant is running *in that project folder*, in a terminal, on that machine. Not across a file bridge, not from a cloud session. |
| **The four scripts** | Windows PowerShell, run by a human |
| **The machine check and the build** | A session that can actually compile and run — see §15, *Route the work* |

**Two consequences worth stating plainly.** In a session where the hooks cannot fire, **every check
depends on the assistant choosing to run it** — so the passive parts carry the weight, and that is
the argument for growing `CONFLICTS.md` over adding another skill. And **hooks installed is not
hooks firing**: `install-hooks.ps1` succeeding tells you they are registered, nothing more.

### A trigger that fires on everything fires on nothing

*From the first outside test, 2026-08-31. The sharpest single finding it produced.*

An orchestrating skill in another project claimed to fire **at the start of every build session and
before every single delivery** — every file, build, document or code change. It was skipped **three
sessions running**.

> **In a working session "before delivering something" happens twenty or thirty times. Nobody
> invokes a skill thirty times, so it settles at zero.** A broad trigger feels safe to write and is
> the least likely to run.

**The design fault underneath it: one skill doing two jobs with one trigger.**

| Job | Natural frequency | Needs |
|---|---|---|
| **Orient** — what is in scope, what must not be built | **Once per session** | A single checkable moment |
| **Gate** — has this been checked before a human sees it | **A few times, at real handovers** | Named, rare, high-stakes moments |

Bundled under one "always", **neither fires.**

**So, before writing any trigger, count.** *How many times a session does its moment occur?*

| Times per session | Verdict |
|---|---|
| **Once** — session start, session end, a round opening or closing | Reliable. Chain it to something that already fires. |
| **A few, and nameable** — before a build reaches the device, before anything goes to a third party, before a round is called closed | Reliable if the moments are **named**, not described |
| **Five or more, or "throughout"** | **It will not fire.** Split it, or make it a standing rule in this playbook rather than a skill. |

**Chain the once-per-session ones to something that cannot be forgotten.** The most reliable trigger
in this kit is the session-start hook, because a session cannot start without it. Hang work off that
rather than asking it to be independently remembered.

> **Our own audit, run the day this arrived: two of twenty-four.** `explain-as-we-go` said
> *"throughout any hands-on technical work"* and `persona-check` said *"whenever UI is being
> designed, described, mocked up, wireframed or built"* — which is the twenty-to-thirty case exactly,
> and it is the one skill that has now failed to fire on its own job **in two unrelated projects**.
> Both narrowed to named moments.
>
> **And a caution about the audit itself.** The first count said *twenty of twenty-four*, because it
> searched for the word "whenever" instead of the shape of the moment. Two is the real number. The
> word is not the defect — *"whenever a bug comes back"* is a fine trigger, because bugs do not come
> back thirty times a day.

### The rule of two — the one mechanism this kit uses to tell signal from noise

*Named 2026-09-01, after it turned up for the fourth time. It had been working, unnamed, in three
separate places since v1.0.*

**Once is an incident. Twice is a fact.** Everything in this kit that decides whether something is
real runs on that, and none of it said so:

| Where | The wording it already had |
|---|---|
| `KIT-LOG.md`, first lines | *One entry changes nothing. A pattern changes the kit.* |
| §14, the brake | *Twice, not once.* |
| §14, confirmed twice | *Four laws, each seen in two unrelated projects.* |
| **The Boss, 2026-09-01** | ***Parked twice is not parked. It is work.*** |

The fourth arrived from outside the kit, describing a product feature, and it is the same rule:

> *"this kind of 'let's discuss more about this in the future' should be parked somewhere that I
> see, and Claude should tell me if I park something in there again — it means we shouldn't park,
> but really work on it, or give it a real deadline."*

**Why it works.** A single occurrence is indistinguishable from a bad day, a stray thought or one
person's preference. Acting on it churns the process after every session. A second, independent
occurrence cannot be explained that way — and the cost of waiting for it is one repetition, which
is almost always cheaper than the change.

**Where to apply it, deliberately:**

- **Feedback** — one complaint is noted, two changes the kit
- **A parked idea** — parked twice means it needs a deadline or a place in the roadmap, not a third
  parking
- **A skill that failed to fire** — twice is a broken trigger, once is a busy session
- **A finding from two unrelated projects** — that is a law, and it goes in this file

**Where it does not apply.** Anything that loses data, leaks a secret, or misleads a person: **once
is enough.** The rule of two is for judging patterns, never for tolerating a defect.

**And it does not apply to a stated requirement whose gap you can check directly.** *Added
2026-09-01, the day after the rule was named, because it was almost misapplied.* Outside feedback
arrived asking for formatting, maximum-strictness analysis, unit tests and feature tests. The first
instinct was to wait for a second occurrence — **wrong.** The rule of two exists because a single
*inferred* pattern might be a bad day. A **stated requirement** is not an inference, and the gap it
names can be verified in one look: the kit genuinely had no formatting category and no feature-test
category. **When you can check the claim against the kit itself, the evidence is the check, not the
count.**

### Rendered is not seen — and a sketch that needs reading is not a sketch

*Two failures in one exchange, 2026-09-01, both mine, both on the same drawing.*

**First: the picture was made, rendered, checked — and never sent.** The session then reported a
review *of* the sketch, put a decision to the Boss, and offered to start the build. His reply:
*"code shouldn't start until I approve the sketch, I don't see new sketch yet."*

This is the same shape as *installed is not fired* and *tested is not compiled*:

> **A sketch exists when the person who has to approve it has looked at it. Not when the file is
> written, not when the screenshot renders clean.**

Add it to the row of near-misses this kit keeps tripping on. Each one is a step that was completed
and then not delivered, and each was invisible because the completed part left a trace and the
delivered part did not.

**Second, and worse: the sketch had grown into a document.** Six-state reference table, two full
option variants, three columns of notes, a footer of standing rules — twenty-four kilobytes for one
row of one screen. His words: **"the current is overwhelming to me."**

A sketch is not a specification with pictures in it. The test:

| A sketch | A document pretending to be one |
|---|---|
| One screen | The screen, its states, its rules, and what is out of scope |
| **Before** and **after**, side by side or stacked | Every variant fanned out for comparison |
| **One question**, and it names what happens on each answer | Several open questions, ranked |
| Fits on one page without sections | Has headings, and needs them |

**If it needs headings, it is a document.** Everything that got cut here was true and worth keeping —
it went back into the round file, which is where reference material belongs. The sketch is the part
that gets looked at, and it competes for thirty seconds of attention, not thirty minutes.

**The recommendation goes in the sketch, in one sentence, with its single reason.** Laying out two
options evenhandedly and asking the Boss to weigh them is the assistant declining to do its job. Say
which one and why; being overruled costs one line.

### Done is not delivered — the end-of-round gate

*2026-09-02. The fourth instance of one pattern, and the one that finally got written as a gate
instead of a lesson.*

A building session finished a version and wrote a full, honest handover note — and **reported the
round done without showing the result and without committing.** Nothing was hidden and nothing in
the note was wrong. The work simply stopped one step short of the only person who can say whether
it is right. The instruction that followed, verbatim:

> *"Show me result, ask me if everything is okay, then commit after I approve or fix what I ask to.
> No round is finished before this."*

**The row of near-misses this kit keeps tripping on is now four long:**

| | The completed part left a trace | The delivered part did not |
|---|---|---|
| *installed is not fired* | the agent file was written | nothing installed it, so it never ran |
| *tested is not compiled* | 24 tests passed | the app would not build |
| *rendered is not seen* | the sketch rendered clean | it was never sent |
| **done is not shown** | the code was written, the note was full | the Boss never saw the result |

**Each is a step that was completed and then not delivered**, and each was invisible for the same
reason: **completion leaves an artefact, delivery does not.** So delivery gets a field of its own,
in three places — §8's handover check, the round note's *After* section, and the building
session's half of the handover file. A rule with no field to fill is a rule remembered by whoever
is least tired.

**And the order is the whole rule: show → ask → fix or commit.** Not *commit, then show*, which
turns the Boss into a reviewer of history rather than the person who decides. A question is cheap
to ask; a commit is cheap to make and awkward to unmake.

### The freeze — one round where the kit is not allowed to change

**The stopping condition in §14 says the kit is done enough when one product ships a round without
needing a kit change mid-round. That was never testable, because the kit always changed.** On
2026-08-26 one round of product work carried **seven kit versions**. Every one was justified. Nobody
could say whether the round needed them or whether they were simply available.

**A frozen round is the experiment.** Declared in the round note, before Build:

```
Kit freeze: yes - kit v<n>. Observations go to KIT-LOG tagged [FROZEN]; nothing changes until Commit.
```

| During the round | |
|---|---|
| Process friction happens | **Log it. Do not fix it.** One line in `KIT-LOG.md`, tagged `[FROZEN]`, with what it cost |
| A skill is missing, a template is wrong, a rule is too narrow | Same. Logged, not fixed. |
| **Only one thing breaks a freeze** | Something that makes the round *impossible* — a hook that blocks every commit, an instruction that would destroy work. **Inconvenience never breaks it.** Note the break in the round note, with why. |
| After Commit | Count the observations, rank them, change the kit **then** |

**Reading the result, and this is the whole point:**

| `[FROZEN]` observations | What it means |
|---|---|
| **0** | The kit got out of the way for a whole round. That is the stopping condition, met once. |
| **1–3** | Normal. Fix them after the round and freeze the next one too. |
| **more** | The kit is not finished, and the list says exactly where — which is far more useful than seven versions cut in the moment. |

> **Why fixing it immediately is the trap.** A process improved the instant it chafes is a process
> nobody ever measures. You cannot tell a kit that works from a kit that is being continuously
> repaired, and the repairs hide inside the round's cost, where nothing counts them.
>
> This does not repeal *the by-product rule* — the kit still only changes because of real building. It
> puts a **delay** between the friction and the fix, so that the friction can be counted first.

### Cost, measured with what is actually measurable

`templates/ROUND.md` has had a `Cost:` line since 2026-08-25 and **it has never been filled in.**
*"Less costly"* is the first word of this kit's goal and the only one with no instrument.

Three things can honestly be measured from inside a session, and they are the three the Boss feels:

| | Why this one |
|---|---|
| **Elapsed time**, start and finish | The only unit the Boss's week is actually made of |
| **Round-trips to the Boss** | Every one is an interruption. A round that needed nine is a different animal from one that needed two, even at equal wall-clock. |
| **Kit changes during the round** | Zero is the target under a freeze. Non-zero is the hidden cost that made "one session" mean six hours. |

**Token spend is not measurable from inside the session — say so rather than estimating it.** A number
invented for a field is worse than an empty field, because the field then looks answered.

### The brake: twice, not once

A process that changes every time something goes wrong never settles, and by month three nobody
can say what the process is. **One occurrence gets a log line and nothing else.**

The honest cost: a real problem waits for its second occurrence. Accept it. The alternative was
tried and produced churn.

**The one exception:** a *structural* gap — the process had no step for something, rather than a
step that worked badly — changes the kit immediately. Stage 0 was added on first occurrence for
exactly this reason. An absent step cannot recur, because nothing is there to fail twice.

### What this loop cannot do

**It has no way to notice its own gaps.** `process-audit` reads the documents against each other,
so it finds contradictions and dead references — it found nine. It cannot find something missing
from every document, because absence is not written anywhere.

That job belongs to the person using the kit, and it is the reason the closing question is
phrased as *did anything get in the way* rather than *did any rule fail*. The kit is
**improvable, with a human as the trigger** — not self-improving. Saying otherwise would be the
kind of overclaim this file exists to prevent.

---

## 15. Who does what — and the assistant's half of it

`START-HERE.md` states the human's irreducible job: **you run the code and you look at the result.**
That cannot be delegated, because verification by the thing being verified is not verification.

**This section is the other half, and it was missing until 2026-08-25.**

> **If the assistant can do it, the assistant does it. Handing the human a task the assistant is
> capable of performing is a defect, not politeness.**

The failure that produced this rule, and it is embarrassingly plain: a folder on the user's machine
was connected to the session the entire time. The assistant wrote files to a temporary workspace,
packaged them, told the user to find a download button, and gave them two commands to unpack it. He
found no button, ran two commands that failed, and said:

> *"if you could put things directly somewhere, dont make me do things you can actually do it
> yourself."*

The capability was available and unused for a whole session.

### Three roles, and the one with no name is the one that gets left implicit

**With two assistant sessions and one human there are three roles, not two** — and the human's is
the easiest to leave unwritten, which is why its absence causes the confusion.

| | Does | Never |
|---|---|---|
| **The deciding session** | decisions, sketches, specs, records, boundary checks | writes the product's code |
| **The building session** | writes the code, **and runs the checks on it** | pushes anything outward |
| **The Boss** | **looks at the result and says yes or no.** Runs whatever leaves the machine | is the message bus between the two sessions |

**Two things collapse into each other if this is not written down, and collapsing them makes both
unusable:**

1. **"Hand code work to the building session"** — about *who writes what*.
2. **"Do not make the Boss carry text between sessions"** — about *the channel*. The handover file
   is the channel; a person is not.

**Neither of those says the Boss types the commands.** *2026-09-03: stated as two roles, the
instructions read as a contradiction — "hand code work to Code" against "here is a command for
you" — and the Boss said so: "but that is code work? It is working right now, so I am confused."*
**He was right to read it that way.**

**Who runs what, and the split is deliberate:**

| | Who |
|---|---|
| The machine check and everything inside it — format, analyse, unit tests, feature tests, clean, dependency resolution | **the building session, itself.** It touches no remote and nothing outside the repository |
| Running the app | the session launches it; **the Boss looks.** The looking is the part that cannot be delegated |
| Staging and committing | **the building session, and only after the Boss has said yes.** The approval gate is about approval, not about who types |
| Anything that leaves the machine — a push, a deploy, a send | **the Boss.** One command, one human hand on the last step |

**This is configuration, not weakening.** No check is removed and the gate does not move. What
changes is who types the commands that only ever report.

### There are exactly two reasons to ask the Boss for anything

Not a list of exceptions — two categories, and everything else is a defect.

| # | Ask for | Because |
|---|---|---|
| **1** | **A decision or an approval** — the goal, the plan, the signature, "is this the right product", what is worth building, anything legal or contractual | **So that nothing gets built that they do not know about or does not want.** This is the entire reason for showing progress and getting approval before building. Approval that can be manufactured is not approval. |
| **2** | **Something the assistant genuinely cannot do** — their hardware, their credentials, their admin rights, their eyes on a running program | Physically out of reach. Say *why* when asking. |

**Anything that is neither is a defect.** Copying, pasting, moving a file, creating a folder,
finding a download, unzipping, running a command the assistant could have run — these are not small
courtesies to ask for. As one Boss put it on 2026-08-25:

> *"Imagine coming to the boss asking them to copy and paste something."*

### Route the work before starting it — and stop rather than do it badly here

*From the first outside test, and its highest-value single rule. 2026-08-29.*

Some work needs a session that can **compile, run, install and see the result**. Some needs one that
can **research, decide, draw and argue**. When those are two different sessions, **the assistant
always knows which one a task needs before any work starts** — the task's requirements are obvious
from the task.

> **Before starting a task, say which session it belongs in. If it belongs in the other one, say so
> and stop — do not produce a degraded version in the wrong place.**

**The evidence is a full day of it going wrong.** In a session with no compiler, an assistant wrote
code it could not compile, invented an identifier without re-reading a file it had already read, and
had the human paste every error back by hand. **Not one of those was a knowledge failure.** It knew
the work needed a compiler and did a worse version anyway, because nothing said to stop.

**Leaving the routing decision to the Boss puts the choice on the person with the least
information** — usually at the end of a long day.

**One refinement, from the same tester after a day of living with it:** *a fix that can be stated in
one sentence should stay where it is.* The first version of this rule was too eager to send work
back, and bouncing a one-line change between sessions costs more than doing it in the wrong room.
Route the **task**, not every keystroke.

### Two sessions, one repository — the handover file

Routing stops work happening in the wrong place. It does **not** solve what happens at the boundary,
and that is the bigger daily cost: **the human becomes the message bus** between two assistants who
cannot see each other's conversation.

**They already share the repository.** The *what* is readable in the diff. Only the **why** needs
writing down — what was decided when the spec was vague, what was tried and abandoned, what is
deliberately not built yet.

So: **one file, `HANDOVER.md`, two halves, neither session writing in the other's.**
`templates/SESSION-HANDOVER.md`.

| Half | Written by | Contains |
|---|---|---|
| **Downstream** | the deciding session, before building | what to build · what must keep working · what is still undecided and must not be built around |
| **Upstream** | the building session, at the end of every session | what was built · **what was decided that the spec did not cover** · what could not be done · **what was changed by hand and not reflected upstream** |

**The upstream half is the one that does the work and the one that will be skipped**, so it gets the
same treatment as the round note: **a line in the project's `CLAUDE.md`**, which the building session
reads at startup. Then it happens without the Boss asking.

> **The failure it prevents, observed:** a layout the owner fixed by hand in the building session,
> never written back to the agreed design. The next round built from the design and handed her the
> exact thing she had already rejected. **One full rebuild, against a one-line note.**

**And say plainly what does not cross:** live questions mid-task, anything only a human can see on a
device, and approval. A shared file makes it slightly too easy to pretend otherwise.

### A question of category 1 travels with its explanation

Knowing *when* to ask is half of it. **The other half is what an askable question looks like**, and
the kit had nothing written about that until 2026-08-26, when two decisions were put up as multiple
choice with one sentence of trade-off per option and both came back:

> *"I dont understand to decide this, need to explain please"* — *"I cant decide when I dont
> understand."*

One of the two was a **one-way door** (a file format that all later content would be written in).
`explain-as-we-go` had been firing all session — on the *work*. Nothing attached it to the
*question*, which is the one moment where not understanding has a price.

**So a decision put to the Boss carries, in the same message:**

| | |
|---|---|
| **Plain terms** | what the thing *is*, before what the options are |
| **An analogy** | only where a plain sentence does not land. A forced one misleads. |
| **The options shown, not described** | where the choice is between formats, shapes or structures, write the same real example **both ways** and put them side by side. This is stage 0's argument — people agree with prose and argue with pictures — applied to a decision instead of a screen. |
| **The one fact that decides it** | see below |

> **Find the question under the question.** *"JSON or YAML?"* is not answerable by the person who
> has to live with the result. *"Will you ever want to open one of these files and edit it by hand?"*
> is — and it settles the first question completely. **A decision the Boss cannot answer has usually
> been asked at the wrong level, not at the wrong person.**

And the cost of skipping this is not a slow answer. It is a **waved-through** answer: an unexplained
one-way-door decision either blocks the round or gets approved on trust, and approval on trust is how
a door gets chosen by accident.

### The test, applied before every instruction

Before writing *"now run this"* or *"now save this to…"*, classify it:

| If it is | Then |
|---|---|
| A decision or approval | **Ask.** Make it a clean question, not a chore. |
| Something you cannot do | **Ask, and say why.** |
| Anything else | **Do it.** Then say what you did and where it landed. |
| You are not sure whether you can | **Check before asking.** An unchecked assumption about your own capabilities is the cheapest error in this kit to avoid, and it cost a whole session on 2026-08-25. |

### Hand over the safe form of a command, not the clever one

Some commands genuinely have to be run by the Boss — their machine, their credentials, their git. **That
does not make the wording their problem.** A command handed over is a deliverable, and it is handed over
badly more often than it is wrong.

On 2026-08-26 a commit message was handed over as four `-m` chunks on one line, with quotes,
parentheses and dashes inside them. The paste lost part of it, git received no message, and **git
opened `vim`** — an editor with no visible way out, in front of someone who had never seen it. The
round's commit stalled there.

| Do | Instead of |
|---|---|
| **Write long text to a file and pass the file** — `git commit -F .git\msg.txt`. The assistant can write that file. | Long quoted strings in a pasted command |
| **One command per line**, each doing one thing | A chain that half-succeeds and leaves state behind |
| **Prefer a command that fails loudly** over one that drops into an interactive editor or prompt | Anything that can silently wait for input |
| **Say what a normal run prints**, so a wall of warnings is not read as failure | Handing over a command and nothing else |
| **Name the way out** of anything interactive, before it opens | Assuming the tool is familiar |
| **A command in prose is still a handover.** Paste the runnable form — with the `cd`, the interpreter and the flags the project already documents. | Naming a script or a tool in a sentence and leaving the reader to reconstruct the line |

**The general rule: if a command can strand them, it is not ready to hand over.** Rewrite it so that
the worst case is an error message they can read — and where the fragile part is text, move the text
into a file, which is work the assistant can do.

> **The failure this rule keeps having is not a bad command — it is a command written in a
> sentence.** *2026-09-02: an assistant asked for `check-shareable.ps1 -SelfTest`. In PowerShell a
> bare script name is not a command, and the repository's own `CLAUDE.md` already carried the
> runnable form — `powershell -NoProfile -ExecutionPolicy Bypass -File check-shareable.ps1`. The
> safe form existed, was written down, and was abbreviated anyway on the way into a paragraph.*
>
> **So the test is mechanical: could this line be pasted into a cold terminal and work?** If a
> `cd`, an interpreter or a flag has to be remembered, it is prose about a command, not a command.
> **Where a project has already written the runnable form, that form is the only one that gets
> quoted** — reformatting it is not helping.

### When the blocker is access, ask for access once — not for the chore repeatedly

The version of this failure that survives the rule above: the assistant *cannot* write to a folder,
so it asks the human to paste files into it — **every round, forever.** Each individual ask looks
justified under category 2.

It is not. **The right ask is one approval for access**, which is category 1, and after that the
chore disappears permanently.

> Before asking a human to move something by hand for the second time, ask instead for the
> permission that makes the asking unnecessary.

### Verification is not an exception to any of this

The human runs the machine check and **looks** at the result, and that never moves — but it is not a
chore the assistant could have done and declined to. It belongs to category 2 when the code runs on
their machine, and to the evidence rule always: *a summary is not evidence.*

### The related habit, same root

Do not describe a file's contents from the source and then ask for approval — **render it, open it,
and look**, then hand over what you have actually seen. Same rule, pointed at artefacts instead of
tasks. See §3, stage 0.

---

## Appendix A — copy-paste blocks

**Session opener:**

> Read `CLAUDE.md` and `PLAYBOOK.md`. Write the status block. Tell me the one goal for this
> session, and whether it is a big or small change. If you cannot say which files change,
> explore first without editing. Then propose the acceptance criteria — human line and machine
> line. No code until I agree to them.

**Handover check:**

```
Exists?   — <command>  →  <result>
Checked?  — <command>  →  <result>
Honest?   — <what is mocked, guessed or untested>
```

**Session closer:**

> Update `CLAUDE.md`: where we are, decisions made today, anything verified, anything rejected
> and why, anything added to the complexity log. Add a session log entry. Draft a commit
> message. Then ask me the one improvement question (§14) and write my answer into `KIT-LOG.md`.
> Then tell me the single next step so I can start cold next week.

---

## Appendix B — a worked session

Session 1 of a real project, in the five stages. It happens to be a Flutter app; the shape is
the same for a Python script or a web service.

```
GOAL         Session 1 · Milestone 0 (toolchain) · next checkpoint: review loop usable
             Size: big change.  Goal: the default app runs on my phone.

ACCEPTANCE   Human:   plug the phone in → `flutter run` → the counter app appears →
CRITERIA              tap + → the number goes up
             Machine: none yet, because there is no project to test. Creating one
                      is this milestone's real output — see COMMIT.

BUILD        Install the SDK, enable developer mode on the phone. One step at a
             time, I run each command myself.

TEST         I look at my phone. Not at the chat.

COMMIT       git init · first commit · CLAUDE.md created · `flutter test` runs and
             passes on the default test, so every later session has a machine line.
```

The first session of any project is the same shape: **make the smallest possible thing run, end
to end, prove it with one command, and commit it.** Not a feature. Proof that the machinery
works.

---

*Playbook v5, shipped in Kit **v1.0** — 2026-08-24. Stage 0 added: sketch the product before
the first feature. §14 added: the improvement loop, made mechanical. Revised at retrospectives
only, and only into a new kit version — see `CHANGELOG.md`.*
