---
name: persona-check
description: Check whether a planned or built screen actually fits the person who will use it, and write the user persona file when one is missing. Use it at two named moments and not continuously: **when the acceptance criteria are written for a round that touches a screen**, and **again before a human tests that round** — a screen, a flow, a form, a dashboard, an empty state, a navigation change. Also use it when someone asks "would anyone actually use this", "does this make sense for the user", "is this too complicated", when a feature is being scoped, or when a project has users but no written persona. Do not use it for pure backend, data-model or infrastructure work with no human-facing surface. Do not use it to decide which screens should exist at all (that is sketch-the-product, which runs first) or to define shared colours, spacing and components (that is design-system).
---

# Persona check

Correctness review asks *does this work*. This asks a different question:

> **Can this person do this job, on this screen, in the time and state of mind they
> actually have?**

Software fails this test far more often than it fails the correctness test. The build is fine
and nobody opens it.

---

## First: is there a persona?

Look for a persona file — `PERSONA.md` (template: `templates/PERSONA.md`). With several
personas, `PERSONA-<name>.md`.

**If there is none, stop and write one.** A fit check with no persona is you agreeing with
yourself in a different font. Go to §4.

**If there is one, read it fully before looking at the design.** Order matters — reading the
design first primes you to find reasons it is fine.

---

## 1. What to review, and when

| Moment | What you review | What it costs to fix a finding |
|---|---|---|
| **Before any code** (planning, spec, mockup) | The described screen or flow | One sentence |
| **After it is built, before the human tests it** | The real screen | A rebuild |

Both are worth doing. The first one is where the value is — a screen that is wrong for the
user is wrong at the sentence stage, and everything after that is sunk cost arguing for itself.

**Honest limit at the second moment:** reading UI code tells you the structure, not what it
looks like. Ask for a screenshot. If you cannot get one, say plainly that you reviewed the
code and not the screen, and which findings that makes uncertain.

---

## 2. The seven questions

Answer in writing. Short answers. An uncomfortable answer is the point of the exercise.

**1. The moment.** Where is this person when they open this, and what else is happening?
Standing on a train, one hand, three minutes. Between two meetings with a colleague waiting.
Tired, at 22:00, having already decided to skip it. Design reviewed against an imaginary calm
user at a desk passes every time and predicts nothing.

**2. The first screen.** What can they do without reading anything? If the answer is "nothing,
they read first", it fails for anyone in a hurry — which, per question 1, is usually everyone.

**3. Steps to the thing they came for.** Count them. Then compare against what this persona
has said they will tolerate. Personas usually state this explicitly if the persona is any
good ("I will accept one extra click to reach detail; I will not accept a tool that tells me
nothing until I click").

**4. The bad day.** Check the unhappy paths, because they are the ones a real person hits
first: the very first use with no data at all, no network, they typed something wrong, they
came back after two weeks away. An app is judged on day one and day fourteen, and both are
empty-state days.

**5. What it asks of them.** Every field, every choice, every sentence they must type is a
cost paid by the user so the software can be simpler. Add up the cost of one full pass. Then
ask honestly whether this person, in the moment from question 1, pays it — not once out of
curiosity, but on a Tuesday in week three.

**6. Their words.** Does the screen speak their vocabulary or the developer's? "Sync failed
(err 42)" versus "Not saved — you are offline". "Cardinality" versus "how many". The persona
file should contain actual phrases the person uses; check the screen against those.

**7. Replacement or addition.** Does this replace something they do today, or become one more
thing to open? Tools that are additions get abandoned quietly and nobody files a report.

---

## 3. The verdict

Pick one. Give the reason in one sentence. Then list findings, worst first.

- **APPROVE** — build it as described.
- **APPROVE WITH CONDITION** — build it, and the named condition happens in this session or
  the next one, not "later". "Later" is where conditions go to die.
- **BLOCK** — name the one specific thing that has to change, and what it should become.

Format each finding as: **what the persona hits → why it costs them → the smallest fix.**
A finding with no proposed fix is a complaint.

**Calibration.** A review that always approves is not a review, and a review that always
blocks gets ignored by month two. If three reviews in a row come back APPROVE with no
condition, the questions are being answered too generously — go back to question 5.

Say which questions you could not answer, and what you would need in order to answer them.
An unanswered question named is useful; an unanswered question quietly skipped is how this
becomes theatre.

---

## 4. Writing a persona when there is none

A persona is not a marketing profile. It is **a colleague you can consult without booking a
meeting**. Everything in it must be something you could disagree with.

### The trap, first

**An invented persona becomes a mirror.** Write it after the design and it will conveniently
want what you already built. Three defences:

1. **Base it on a real person wherever possible.** Pointing at a real colleague's actual
   concerns beats an invented composite every time. Name the real person if you can.
2. **Write "what makes them quit" before you look at the design.** That section is the one
   that does the work, and it is the one that gets softened.
3. **Date it and mark what was invented.** Then it can be corrected instead of quietly
   hardening into fact.

### Self-personas are the hardest

When the user of the app is the person building it, the persona will describe who they wish
they were: someone who writes for ten minutes every evening. Anchor it in evidence instead —
which similar apps did they actually abandon, in which week, and what were they doing when
they stopped opening it. Past abandonment predicts future abandonment better than any
intention does.

### The five-minute version

Most of the time this is enough, and a short persona that exists beats a thorough one that does
not. The block is `templates/PERSONA.md` — five lines, and the `Quits when` line is written
**first**, before any design exists.

Five lines is enough to run §2 against. Expand later only if a review keeps hitting a
question the short version cannot answer — that is the signal, not a general wish for rigour.

### The long structure

Use this when the project is long-lived, has several distinct users, or when the persona has
standing positions that would otherwise get re-argued every session.

```markdown
# Persona — <Name>, <role>

**Purpose:** <who consults this and when>
**Real person / invented:** <which, and the date>

## Who they are
One paragraph. Concrete. Include what they have already lived through — the tool
everybody was told to use and nobody used is more informative than a job title.

## The moment
When and where they use this, and what else is competing for that minute.

## What they want
In their words, not in feature terms. What decision are they trying to make?

## What makes them quit
The failure modes that end usage. Write this before you look at the design.

## The trade they will accept
Every design costs the user something. Name what this person will pay and what
they will not. This is the section that settles arguments.

## Their words
Actual phrases they use. Give the screens their vocabulary.

## What they would say yes to immediately
So it reads as a person, not a compliance checklist.

## Standing positions
Things that do not get re-litigated every session.
```

Keep it to one page. A persona nobody rereads is a file, not a colleague.

### Multiple users

Write one file per persona, and say which one this screen is *for*. A screen designed for the
average of two personas usually serves neither. If two personas genuinely conflict on a
screen, that is a finding — surface it, do not average it away.

---

## 5. What this check is not

It does not cover correctness, security, privacy, or data governance. Those are separate
reviews with separate questions, and a reviewer asking about GDPR and button placement in the
same pass does neither well. If the persona file contains governance positions, use them —
but the verdict here is about fit, and a governance concern gets handed to that review rather
than absorbed into this one.


---

## Two ways this check gets skipped, both recorded from real use

**1. "The design was checked earlier, so the build is covered."** It is not. A change that lands
**inside an existing screen** produces a new screen: the thing the person now faces is the old
content plus the new content, and nobody has looked at that combination. **List what is actually
stacked on the screen, top to bottom, and check that.**

> On 2026-08-29 an outside tester skipped this check on exactly that reasoning. What got built was
> the old screen with new buttons bolted on, and the verdict on the phone was *"UI UX is bad, very
> overwhelmed"*. One wasted build-and-install cycle, which on a physical device is the most
> expensive loop in the project.

**2. Checking the screen and not the way in.** The screen can be right and unreachable. Same
tester, same week: a screen was built correctly inside an app whose navigation still matched the
*pre-redesign* shape, so nothing led to it. **Ask where the person is standing when they need this
screen, and whether anything takes them there** — see the handover check in `PLAYBOOK.md` §8.

**Why this section exists rather than a firmer instruction:** the skill already warned that reading
UI code shows structure and not appearance. It did not name the rationalisation people actually use,
and a warning that does not name the excuse does not survive contact with a tired evening.
