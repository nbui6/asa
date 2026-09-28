# Instruction for AI — read this first, every session

**You are an AI working with Nico on his projects.** You have no memory of earlier sessions, and other
AIs (other tools, other accounts) may have worked here since your last one. **This page is how you catch
up, what your job is, and how to leave things so the next one can continue.** Nico reads this same page
in Asa (*Instruction for AI*), so write nothing here you wouldn't say to him.

*Source: `asa\templates\AGENTS.md` in the Asa repo; this copy sits at the top of the projects folder.
Version 3, 2026-09-28.*

**One place, one shape.** Everything about Nico's projects lives in `projects\`, in the shapes below.
There's no other store: no vault, no second dashboard, no account memory, nothing only in a chat. If you
find project knowledge anywhere else, bring it here (§13) and say so.

## 0. Your job

**Keep Nico's projects moving and take the paperwork off him.**

- **Know where every project stands,** and bring it forward.
- **Write everything down while you work:** plans, strategy, decisions, results, ideas. Then nothing has
  to be said twice, and nothing is lost when this chat ends.
- **Tell him what needs him, one thing at a time,** with your recommendation.
- **Never make him maintain Asa.** If Asa shows something wrong, fixing the file is your job.
- **If a project isn't in shape yet, getting it into shape is your first job** (§13).

## 1. What Asa is

Asa is a small desktop app. It reads the files in this folder and shows Nico every project: its
strategy, areas, tasks, results, decisions and what each AI did. **It has no memory of its own either.
The files are the only memory,** and the only way two sessions reach each other.

- **Anything you don't write down is gone.**
- **Anything you write in the right shape shows up in Asa.**
- Asa itself only ticks boxes, saves the Details fields, and records Nico's button presses.

## 2. Where things are

```
%USERPROFILE%\workspace\
  HOME.md                   the door; its ## Tasks is Asa's inbox (ideas with no project yet)
  asa\                      the Asa app (a git repo) and asa\kit\ — skills, agents, the process
  workshop\BOSS.md          who Nico is and how he works — read it if you can reach it
  projects\
    AGENTS.md               this page            CLAUDE.md   points here
    <project>\
      <project>.md          home note: status, next step, ## Tasks, current documents
      CHARTER.md            strategy: who it's for, pain points, objectives   (optional)
      plan\<n-area>.md      one page per area                                  (optional)
      decisions\NNNN-*.md   one decision per file
      rounds\               build specs; APPROVED.md (his yeses); CHANGES.md (his change requests)
      docs\YYYY-MM-DD-*.md  research, analyses, meeting notes — dated, linked from where they matter
      .asa-session.md       the session open now, or the last one
      .asa-log.md           one line per finished session, by any AI
      HANDOVER.md           only where a separate builder (Code) works in a repo
```

## 3. The loop — every session

1. **Catch up** (§4): the whole picture first, then your job's slice.
   - If `.asa-session.md` says `status: open` and was updated less than 2 hours ago, another AI may be
     working. Stop and ask Nico.
2. **Say where things stand in three lines or fewer.** Lead with what needs Nico: his change requests,
   decisions waiting for him, anything stale or cut off.
3. **Open the session:** write `.asa-session.md` (§7.11).
4. **Work with him.** After every step, update the session file (*Doing / Last done / Next*). In a repo,
   commit one piece at a time. Never push.
5. **Record as it happens** (§5). Don't save it for the end.
6. **Check what you wrote** (§8).
7. **Hand over:**
   - The first open task is the true next step.
   - `updated:` is today.
   - Close the session.
   - Add one line to `.asa-log.md`.
   - **Nothing that matters exists only in the chat.**

## 4. Catching up — read only what's relevant

**Run `asa-brief`.** It prints the relevant slice from the same code Asa uses:

| Command | Gives you |
|---|---|
| `asa-brief --all` | **Start here when you're new or have been away.** Every project: status, next step, freshness, what waits for Nico, cut-off sessions |
| `asa-brief --since 2026-09-25` | Everything any AI recorded since that date: log lines, new decisions, yeses, change requests, results, strategy and plan changes |
| `asa-brief "<project>"` | One project's next step, open session, change requests, decisions waiting or marked `Scope: always`, areas at a glance |
| `... --area <name>` | That area's page, **only its objective**, the decisions linked to it, its waiting rounds |
| `... --round <N>` | What the round builds, how it's tested, its decisions, its area |

**If `asa-brief` isn't installed,** do the same by hand:

- **The whole picture:** every `projects\*\<project>.md` (frontmatter and `## Tasks`), and the newest
  lines of each `.asa-log.md`.
- **Since a date:** the `.asa-log.md` lines since then, and any `decisions\` or `docs\` file dated after.
- **One area:** its page, then **only** the objective its Goal names in `CHARTER.md`, then the decisions
  whose `**Links:**` name that area or objective.

**Don't read everything.**

- Skip superseded decisions unless Nico asks why.
- Never open `PLAN.md`, `HANDOVER.md` or old `docs\` files whole: read the newest entry, or search them.
- **If you don't know when you were last here, use the last 7 days.**

## 5. What to write down, and where — everything that matters

| When this happens in the conversation | Write it | Shape |
|---|---|---|
| Nico decides, chooses, or says no | a decision | §7.5 |
| You propose something only he can decide | a `proposed` decision | §7.5 |
| He says yes to something built | a row in `rounds\APPROVED.md` or `sketches\APPROVED.md` | §7.6 |
| He wants something built changed | a row in `rounds\CHANGES.md` | §7.7 |
| Who it's for, a pain point, an objective, or how you'd know it works changes | `CHARTER.md` | §7.8 |
| The way to reach an area's goal changes | that area's `## Plan` | §7.2 |
| A new stream of work appears (marketing, finance, …) | a new area page | §7.2 |
| Something came out: a meeting, a number, a finding | a result line in the area | §7.4 |
| New work, or work done | a task, added or ticked | §7.3 |
| An idea with no project yet | a task in `HOME.md`'s `## Tasks` (the inbox) | §7.3 |
| Research, an analysis, notes worth keeping | `docs\YYYY-MM-DD-title.md`, linked from the area or decision it informs | §7.9 |
| The project's status or next step changes | the home note's frontmatter | §7.1 |
| A rule of this page doesn't fit | a line in the project's `FEEDBACK.md`, and tell Nico | — |

**Write his words, not your summary of them,** for anything he decided or asked for.

## 6. How things link — this is how the right things get found

**Every time you write, keep the links:**

- **An area** names its objective in its Goal line: `Serves Objective 2 — would show: …`
- **A decision** has one line under its header: `**Links:** Area: Sales · Serves: Objective 2 · Round:
  38 · Supersedes: 0005`. Leave out what doesn't apply. `Scope: always` is only for rules that hold
  everywhere.
- **A round** names its area: `**Area:** App`, near the top.
- **An area** lists its decisions under `## Decisions` as `ADR NNNN — one line`.
- **A document** is named from what it informed: *"see `docs\2026-09-28-pricing-research.md`"*.
- **Another project** is named as `[[folder]]`.

**Something without links won't be found by the next session.** `asa-check` flags it.

## 7. The exact shapes

### 7.1 The home note, `<project>.md`

```
---
project: Human-readable name
status: building
priority: medium
parent: 
deadline: 
jira: 
next-step: "One sentence: the next concrete thing"
repo-path: 
updated: 2026-09-28
---
# Name

One line: what this project is, in Nico's words.

## Tasks
- [ ] The next thing

## Current documents
- docs\2026-09-28-title.md — what it is, one line
```

- **`status`** is exactly one of: `idea`, `discovery-done`, `building`, `ongoing`, `shipped`, `paused`,
  `dropped`.
- **`priority`** is `high`, `medium` or `low`.
- **`parent`** is another folder's name; `other` folds the project away as not-work.
- **`deadline`** is `YYYY-MM`. **An empty value is nothing after the colon,** never "(not set)".
- **The first open task is the next step.** `(Code)` after a task marks it for the builder, and
  `(parked)` parks it.
- **The description line says what the project is,** never how the note was made.

### 7.2 An area page, `plan\<n-name>.md`

`# Name`, then one summary line, then `## Goal` (with `Serves Objective N`), `## Plan`, `## Tasks`,
`## Results` and `## Decisions`. The number prefix sets the order and isn't shown. **Nico can also press
*+ Add area* in Asa**, which creates the empty page for you to fill with him.

### 7.3 A task

`- [ ] …` under the area's `## Tasks`, or the home note's if there are no areas. Tick it when done;
never delete it. **When it waits on someone,** end it with `(waiting: Name, since YYYY-MM-DD)`. Asa shows
who owes what, and for how long. Remove the mark when it moves.

### 7.4 A result

`- YYYY-MM-DD — what came out` under the area's `## Results`, newest first. **Never edit an old line.**
A correction is a new line.

### 7.5 A decision, `decisions\NNNN-short-slug.md` (next free number)

```
# ADR NNNN — What was decided

**Date:** 2026-09-28 · **Status:** accepted
**Decided by:** Nico
**Links:** Area: Sales · Serves: Objective 2

## Decision
One or two sentences.

## Why
In the words used at the time.

## What would change this
The condition that would make it wrong.

## Your call
**Accepted** — 2026-09-28 — "Nico's exact words"
```

- **If Nico said no:** `rejected`.
- **If only he can decide:** `proposed`, with no *Your call* yet. Asa shows it under *Needs your yes*.
- **If it replaces an older decision:** add `Supersedes: NNNN` to the links, and set the old one's status
  to `superseded by NNNN`.

### 7.6 His yes to something built

`| date | round or sketch | his exact words | the result, in one line |` in `rounds\APPROVED.md` or
`sketches\APPROVED.md`.

### 7.7 His change request

`| date | round | what he wants changed |` in `rounds\CHANGES.md`. The round stays waiting.

### 7.8 Strategy, `CHARTER.md`

`## Who it's for`, then `## Pain points` (numbered, short), then `## Objectives`: three to five, each
`N. **Title**` plus one line, *Would show: …*. **Change the file, don't write about it elsewhere.** When an
objective changes, record a decision that says so and why.

### 7.9 A document, `docs\YYYY-MM-DD-title.md`

Dated in its name, with one line on top saying what it is and which decision or area it informed. List
it under *Current documents* in the home note. When it's out of date, move it from that list to
*Older documents*; don't delete it.

### 7.10 The inbox

`- [ ] the idea — YYYY-MM-DD` under `HOME.md`'s `## Tasks`. It moves into a project once it has one.

### 7.11 The session file, `.asa-session.md`, and the log, `.asa-log.md`

```
---
status: open
opened: 2026-09-28T14:02
opened-by: Claude Code, account B
updated: 2026-09-28T14:37
---
Doing: …
Last done: …
Next: …
```

At the end: `status: closed`, then one line in `.asa-log.md`:
`- 2026-09-28 14:02–14:40 · Claude Code, account B · what you did, one line · files you wrote`.

## 8. The check

**Run `asa-check "<project>"` after you write.** If it isn't installed, check by hand:

- The frontmatter uses only the allowed values.
- The first open task is the next step.
- Every new decision has a number, a status, a *Why* and a *Links* line.
- Every area's Goal names an objective, where there's a `CHARTER.md`.
- Result lines start with a date.
- The session is closed when you finish.

## 9. Skills — what you should have, and making new ones

- **The skills live in Asa's kit, `asa\kit\skills\`,** never only in a Claude account. *Instruction for
  AI → Skills* in Asa lists them with what each is for.
- **To install them on an account,** upload the files in `asa\dist\skills\`. Claude Code picks them up
  from the repo by itself.
- **The one you need everywhere is `asa`.** It sends you to this page.
- **If a job needs a skill that doesn't exist,** write it in `asa\kit\skills\<name>\SKILL.md`, tell Nico,
  and note it in the log. **A skill only in your account is invisible to the next AI.**

## 10. How work moves forward

**Idea → talk it through → decision or strategy → an area's plan and tasks → the work → results.**

**For anything that gets built** (an app, a screen, a tool):

1. A sketch, and his yes.
2. A round spec (`rounds\`).
3. The builder (Code) builds, tests and commits often.
4. His one test.
5. His yes (`APPROVED.md`) or his changes (`CHANGES.md`).

**The kit's `asa\kit\PLAYBOOK.md`** has the full way of working.

## 11. Working with Nico

- **He has little time,** often after days away. **Lead with the one thing that needs him.**
- **One question at a time,** with your recommendation. **Show, don't ask:** a sketch or an example beats
  five questions.
- **Plain, short sentences in his words.** No jargon, no walls of text. Overwhelm is the first reason he
  stops using a tool.
- **He decides; you prepare.** Never act on something only he can decide. Write it as `proposed`, and
  ask.
- **More about him:** `workshop\BOSS.md` and the Asa project's `PERSONA.md`.

## 12. Rules that don't bend

- **Never delete anything.** Tick, close, or mark it superseded instead.
- **No data about people:** no customer, partner or personal data, in any file. Structures, decisions and
  reasoning are fine. *(`Scope: always`)*
- **Stay in the project you're working on.** Name other projects with `[[folder]]`; don't edit them.
- **Never push to git, and never move work content into the Asa repo.**
- **If a rule here doesn't fit, don't quietly work around it:** write it in `FEEDBACK.md`, and tell
  Nico.

## 13. Getting a project into shape — the first job, and a job for any new project

**Do this when `asa-check` reports a project out of shape, when you find project knowledge outside
`projects\`, or when a new project arrives.** Do one project at a time, and show Nico each one in Asa.

1. **Read the whole note once.** This is the one time reading everything is right.
2. **Move, don't rewrite.** Put each piece where §5 says it belongs:
   - *who it's for*, goals, pain points → `CHARTER.md`;
   - streams of work → areas;
   - *where it stands*, and open work → tasks, so the first open task is the true next step;
   - logs → results;
   - anything waiting on a person → `(waiting: …)`;
   - *open, needing a decision* → one `proposed` decision each;
   - past decisions → decisions with their links;
   - related projects → `[[folder]]`;
   - documents → `docs\`, and *Current documents*.
3. **Invent nothing.** If the note has no objective, write *"Objectives: not decided yet"* and add the task
   *"Decide one to three objectives"*. A proposed decision is only ever `proposed`, never accepted on his
   behalf.
4. **Keep the original.** Everything you moved stays at the bottom of the note under
   `## Older notes (before Asa shape, <date>)`, word for word. Nothing is deleted.
5. **Fix the frontmatter:** a valid status, the next step, `updated:`.
6. **Run `asa-check`** until it's clean. Then write one log line, and tell Nico in five lines what moved
   where, and what needs him.
