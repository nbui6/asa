# Project Hub

**The one note you open first.** Everything else is reachable from here in one click, and nothing
else needs to be remembered.

Copy this into your vault, fill it in, and pin it. It is a note, not an app — so it works today,
costs nothing to change, and cannot break.

> **Why a note and not a screen.** Notes first; code only for the gap a note cannot fill.
> Navigation is not that gap — links are what a notes app is *for*. The two things that genuinely
> need code are reading `git log` and launching another program in a folder.
>
> *(If you build a hub app later, it renders this note. It does not replace it — one measurement,
> two readers.)*

---

```markdown
---
updated: 2026-01-01
---

# Project Hub

## Where I am

```
PROJECT   <which thing, which milestone>
SESSION   <which of the five stages, and whether it is finished>
LOOP      <the one change that is not yet verified>
```

This is the **status block** from `PLAYBOOK.md` §1. It is the only part of this note that
changes every session.

> **A blank line is the finding.** It names which level you are lost at, and each level has a
> different fix: the project line lives in `CHARTER.md`, the session line in the playbook, the
> loop line on your screen.

## Waiting on me

Only decisions. Not tasks, not ideas — the things where nothing moves until I answer.

| # | Question | Blocks | Open since |
|---|---|---|---|
| 1 | <question> | <what stops> | <date> |

**Empty is the goal.** A long list here means I am the bottleneck, and that is worth seeing.

## Projects

| Project | Status | Next step | Note |
|---|---|---|---|
| <name> | building / idea / dormant / in use | <one line> | [[<project note>]] |

## The kit

- Version: **v1.0** — see `CHANGELOG.md`
- Skills map: `SKILLS.md`
- What the process got wrong lately: `KIT-LOG.md`
- Anything seen **twice** in that log becomes a change. Once is just a line.

## Doors

- [[PLAYBOOK]] — the five stages, and stage 0
- [[BOSS]] — how I want to be worked with
- [[BACKLOG]] — everything deliberately not being done
- <path to code> — the repo
```

---

## The shape: one small page, everything else folded

**The front page is the status block and what is blocking you. Nothing else.** In Obsidian, a
callout written `> [!question]- Title` is **folded by default** — one click opens it. Use that for
every other section.

Why it matters: a front page you cannot hold in your head is a front page you stop reading. Term:
**progressive disclosure**. Analogy: a car dashboard — three dials always visible, the manual in
the glovebox.

### The section people forget to include: *why does each piece exist?*

Systems get forgotten from the inside. In a few weeks you will remember that `CHARTER.md` exists
and not what it is **for**, and a file whose purpose you cannot recall is a file you stop
maintaining.

So keep a folded section with **one line per piece, saying why it exists** — not what it contains.

```markdown
> [!question]- Why does each piece exist?
> | Piece | Exists because |
> |---|---|
> | `CHARTER.md` | Says what it is **not**. That list stops scope creep in week three. |
> | `CLAUDE.md` | The project's memory. Chat history disappears; this does not. |
> | `BACKLOG.md` | Ideas I decided not to do, so they stop nagging me. |
```

**If a piece cannot earn one line, delete the piece.** That is the second job this section does.

Keep a second folded section for **the rules you keep forgetting** — the five stages, the
two-strike rule, the twice rule, one line each. The logic goes stale faster than the file list,
and nowhere else in the kit holds it in a form you can scan in thirty seconds.

---

## Why this note exists

**Not to look organised. To answer "where was I?" after a gap.**

At a few hours a week you will forget between sessions — that is the normal condition, not a
failing, and it is the constraint this whole note is designed around. A person who worked on
something every day would not need it.

The `PLAYBOOK.md` §1 status block is the answer to that question. This note is that block, made
durable: written down somewhere that survives closing the laptop and clearing the chat.

**Everything below the block is a pointer.** The block is the only part that has to be right.

## The three rules that keep it alive

**1. One block changes per session, not the whole note.** Update *Where I am* at the end of every
session and nothing else. A note that needs ten minutes of maintenance gets abandoned; a note that
needs three lines survives.

**2. Stale is information, not failure.** If *Where I am* describes something you stopped doing
three weeks ago, that is the note doing its job. Rewrite it, or move the project to `dormant` and
stop pretending.

**3. Nothing lives here twice.** Every table above either holds a *pointer* or holds the *only*
copy. Duplicated status is the thing that rots — two places disagreeing is worse than one place
being empty.

---

## When to graduate a section into code

Only when it needs something a note cannot do. Two examples that qualify, and they are the same
two as always:

| Section | Stays a note because | Would need code if |
|---|---|---|
| Where I am | You type it; nothing can measure it | Never |
| Waiting on me | You type it | Never |
| Projects | A table of links | You want **days since the code last moved** — that needs `git log` |
| Doors | Links | You want a button that **launches** the editor in the right folder |

Everything else that feels like it wants a screen probably wants a better note.
