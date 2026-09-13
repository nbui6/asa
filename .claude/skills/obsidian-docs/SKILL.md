---
name: obsidian-docs
description: Organise a project's documents in an Obsidian vault (or any linked markdown notes) and keep them from drifting out of sync with the repository — which file is the single source of truth, what links to what, and the one dashboard note that answers "where are we". Use this when someone keeps project notes in Obsidian, asks where documentation should live, has the same information in two places, runs several projects at once and needs one overview, or wants a home for decisions and research that is not the code repository. Also use when notes and repo files have already diverged.
---

# Project documents in Obsidian

Obsidian is a good home for project documents: plain markdown, links between notes, works
offline, and the files stay yours. The one problem it creates is the one that matters.

---

## The drift problem, and the rule that solves it

Documents live in two places — the **repository** and the **vault** — and within a month they
disagree. Then nobody knows which is true, and both stop being read.

> **One file, one home. Never two copies. Link across, never duplicate.**

Where each file belongs follows from who needs it and when:

| File | Home | Why |
|---|---|---|
| `README.md` | **Repo** | Someone cloning the code needs it there |
| `CLAUDE.md` | **Repo** | The assistant reads it at the start of every session |
| `ARCHITECTURE.md` | **Repo** | It must change in the same commit as the code it describes |
| `decisions/` (ADRs) | **Repo** | Versioned with the change they justify |
| `CHARTER.md` | **Vault** | Product thinking, changes rarely, read by people not code |

| `ROADMAP.md` | **Vault** | Discussed with colleagues, not with a compiler |
| `BACKLOG.md` | **Vault** | Same |
| `PERSONA.md` | **Vault** | Same |
| Research, meeting notes, interviews | **Vault** | Never belonged in a repo |

> `PLAYBOOK.md` §2 says day one creates `CHARTER.md`, `BACKLOG.md` and `CLAUDE.md`. It does not
> say where. **This table is where.** If you keep no vault, they all live in the repo and nothing
> here applies.

The rough rule: **if it must change in the same commit as code, it lives in the repo.** Everything
else lives in the vault, and the repo's README links to it.

Obsidian can open a folder inside a repo, which is tempting and gives you both problems at once —
noisy git history and vault clutter. Prefer the split above.

---

## Vault structure

Flat enough to navigate, deep enough to scale to several projects.

```
Vault/
├── Project Hub.md           ← the one note you open first (templates/PROJECT-HUB.md)
├── Projects/
│   └── <project>/
│       ├── <project>.md      ← the project's home note
│       ├── CHARTER.md
│       ├── ROADMAP.md
│       ├── BACKLOG.md
│       ├── PERSONA-<name>.md
│       └── notes/            ← research, interviews, meetings
├── People/                   ← who asked for what, who decides
└── Reference/                ← things true across projects
```

**Folders for structure, tags for cross-cutting.** A note is in one folder and can carry several
tags — `#waiting-on-someone`, `#decision-needed`, `#idea`. Search by tag; navigate by folder.

---

## The two notes that do the work

**The hub note** — the only note you open first. Built from `templates/PROJECT-HUB.md`; name it
whatever you actually call it, and use **one** name everywhere. Kept short enough to read in
twenty seconds: what you are working on right now, what is waiting on you, and one line per
project with its next step.

> **One name, one note.** Earlier drafts of this kit called it `Dashboard.md` here and
> `PROJECT-HOME.md` elsewhere, which is the duplication this skill exists to prevent. The hub is
> the *vault's* front door; a **project home note** is the front door of *one project*. Two
> different jobs, two names, no overlap.

**The project home note** — the map of one project. Its current state, its single next step, and
links to the charter, roadmap, backlog, personas, the repository, and recent notes. If it is
longer than a screen it has stopped being a map.

Obsidian keeps these current on its own if you use links: search for unlinked mentions
occasionally, and let backlinks show you what refers to a note rather than maintaining lists by
hand.

---

## Linking to the code, and to the assistant

- Link to the repository by **path** in the project home note, and say which branch is current
- Never copy code into the vault. Link to the file. A copy is wrong within a week.
- After a session, the vault gets **the decision and the reasoning**; the repo already has the
  change. `CLAUDE.md` is the state; the vault is the story.

If the assistant can read the vault folder, tell it which notes are the source of truth. If it
cannot, say so — an assistant working from a stale copy of a charter is worse than one working
from none, because it will be confident.

---

## Keeping it honest

Bind the maintenance to moments that already happen:

| Moment | What happens |
|---|---|
| End of a session | Project home note: current state and next step updated |
| A decision is made | Small ones: the `CLAUDE.md` decisions table. Architectural and expensive to reverse: an ADR in the repo. Product decisions: a vault note. **One home each, never two.** |
| A checkpoint | Re-rank the roadmap; re-read the dashboard and remove what is stale |
| Anything appears in two places | Delete one and link to the other. Immediately — this is how drift starts. |

A note nobody reopens is a file, not documentation. If a note has not been read in three months
and nothing would break without it, it belongs in an archive folder.

---

## Any other tool

Nothing here is specific to Obsidian — the same rules apply to plain markdown folders, Notion, or
a wiki. What matters is: **one home per file, links instead of copies, one dashboard, and a moment
that forces the update.** Obsidian happens to make all four easy, and keeps the files as plain
markdown that an assistant can read directly.
