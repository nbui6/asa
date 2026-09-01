---
project:    <Name>                     # display name
status:     idea                       # idea | discovery-done | building | paused | shipped | dropped
milestone:  "<0 — nothing built yet>"  # short, free text
next-step:  "<the ONE next action>"    # always current — this is the field you will actually use
repo-path:  ""                         # absolute path to the code, or empty if none yet
updated:    <yyyy-mm-dd>               # the date a human last touched this note
---

# <Project>

**<One line: what it is.>**

<One or two sentences: what it does and for whom. If it is a learning project, say so here.>

> **This note is the door.** One screen. Everything else is behind a link. If it grows past a
> screen it has stopped being a door and become another document to read.
>
> `updated` is typed by a human — when you last *thought* about this.
> "Last moved" is read from git — when the code last *changed*. Different facts; keep both.

---

## Where I am

> **<Current state in one or two lines. Honest — "nothing is built" is a valid answer.>**

**Next step:** <the single next action, specific enough to start from cold>

**Last moved:** <date>

---

## Needs my decision

<Everything waiting on a human yes or no, from anywhere: `[NEEDS DECISION]` markers, audit
findings, proposed rules from a retrospective, ADRs marked *proposed*, a roadmap re-rank.>

| What | Where | Since |
|---|---|---|
| | | |

*Nothing leaves this list except by a decision that gets written down. A queue that empties by
ageing out is theatre.*

---

## The documents

| | |
|---|---|
| [[CHARTER]] | What it is, who for, what it is not |
| [[ROADMAP]] | Now / Next / Later |
| [[TOOLCHAIN]] | The tools, what each owns, which skills apply |
| [[BACKLOG]] | Deliberately not doing yet |
| `CLAUDE.md` | In the repo — state, decisions, verified findings |
| `decisions/` | |

<List only what exists. Name the rest as "not yet written — appears at its trigger", so a gap
reads as a plan rather than an omission.>

---

## What's next to build

**Now:** <one item>
**Then:** <two or three>

Full list and reasoning: [[ROADMAP]]

---

## Verified, on this machine

<What was measured, with dates. Versions, the run command, the pass/fail command. The thing you
will otherwise re-derive every time you come back.>

- Machine check: `<command>` → `<expected output>`
- Run it: `<command>`

---

## Rules I keep forgetting

<Three at most. The ones this project actually breaks — not a copy of the playbook.>
