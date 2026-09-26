# What Asa is, and how to work with it from here

**Read this if you are an assistant session working on this project.** It is self-contained — you
do not need access to any other folder.

**Rewritten 2026-09-25.** The earlier version never said what Asa actually reads, so sessions did
real work that the overview never showed. The two new sections, "What Asa shows" and "Before you
finish", are the reason for the rewrite.

> **Before anything else, whenever project work resumes — a new conversation, or this one after
> a gap:** open `asa\kit\skills\doorman\SKILL.md` and do its job against whatever project you're
> about to work on — read its own note, its next-step, any open decision, any fired backlog
> trigger, and the freshness check against evidence sitting next to the claim.
>
> **Corrected 2026-09-09.** "Every conversation" was the wrong unit — Nico stays in one continuous
> conversation and does not start new ones, so a rule that only fires at conversation start would
> never fire again after the first time. **A cloud/Cowork session has no hook and no automatic
> skill loading** (checked 2026-09-08; see `ASA-LOG.md`) — still true, still no fix for that
> specific gap. **What does work, proven the same day it was doubted:** a `send_later` reminder,
> which wakes this exact session — not a new one — and delivers as a normal message. Used as a
> self-perpetuating check-in: each time it fires, actually run the doorman's job, report what it
> found, then schedule the next one. This is the real mechanism now, not a placeholder — see
> `ASA-LOG.md`, 2026-09-09.

---

## Asa is not an agent. It is a program that reads these folders.

There is **no session to message, no schedule, no daemon, no API.** Asa is a small Windows desktop
app. When someone opens it, it reads the project folders on disk and shows what it finds. That is
all it does.

**So "telling Asa" means one thing: writing a file in this folder.** Nothing else reaches it.

**For Asa's own project, how those files connect into one loop — a Round opening, running, and
closing, and when to re-rank — is written down in `PROCESS.md`, not left implicit.** Read it
after this file if the work is on Asa itself.

**Sessions cannot message each other either.** Two assistants working on the same project at the
same time are invisible to one another. **The folder is the only shared channel.**

## What Asa shows, and exactly where it reads it from

Asa reads **one file per project: `<folder>\<folder>.md`**, the project's home note. On the overview,
every project is one row: its name, status, priority, deadline, a Jira chip, how fresh it is, and
its **next step**. If the home note is out of date, the row is wrong, and Nico acts on a wrong row.

**The frontmatter, at the very top of the file, exactly this shape:**

```
---
project: Human-readable name
status: building
priority: medium
parent: 
deadline: 
jira: 
next-step: "One sentence: the next concrete thing to do"
repo-path: 
updated: 2026-09-25
---
```

| Field | Rule |
|---|---|
| `status` | **Exactly one of:** `idea` · `discovery-done` · `building` · `ongoing` · `shipped` · `paused` · `dropped` (ADR 0017). Nothing else, no sentence. A longer explanation goes in the body |
| `priority` | `high` · `medium` · `low`, or empty |
| `parent` | Another project's **folder name**, or empty. `other` folds a project away as not-work |
| `deadline` | `YYYY-MM`, or empty |
| `jira` | The full Jira URL, or empty |
| `next-step` | One sentence. **The same thing as the first open task below** |
| `repo-path` | Absolute path to a git repository this project's code lives in, or empty |
| `updated` | Today's date whenever you change the note |

**One `key: value` per line. An empty value is nothing after the colon**, never `(not set)`, never
a comment. Asa reads `(not set)` as a real value.

**Then the body:**

- `# Name`, then **the first plain paragraph is the one-line description** shown under the name.
- **`## Tasks`** — exactly that heading, nothing added to it. One checkbox per line:
  `- [ ] Do the thing` or `- [x] Did the thing`. A trailing `(Code)` marks a task for the building
  session. A trailing `(parked)` parks it. `[[other-folder]]` names another project. **The first
  open task is the project's next step.**
- **`## Roadmap`** (optional) — `- [ ] **Milestone name**` lines. `### Phase name` headings inside
  it become the segments of the progress bar on the overview.
- Decisions — see below.

Anything else in the note is yours to shape however the project needs. Asa just doesn't read it.

## Before you finish — every session, not only big ones

**This is what keeps the overview true without Nico maintaining it.** Before the session ends, or
before a long pause in the same conversation:

1. **Tick** the tasks that got done. **Add** the ones you discovered — anything more than a couple of
   minutes of work.
2. **`status:`** — still true? If not, change it.
3. **`next-step:`** — make it the first open task, in one sentence.
4. **`updated:`** — today's date.

That's all. **Don't rewrite the rest of the note to tidy it.** Changing someone's text in passing is
how a decision silently disappears.

## Bringing a new project in

Make a folder `projects\<folder-name>\`, lowercase with dashes. Put the home note in it as
`<folder-name>.md`, with the frontmatter above. Copy this file in next to it. That's all Asa needs to
show it.

## Where things live

```
%USERPROFILE%\workspace\
  asa\        the app, and asa\kit\ — the written process. A git repository.
  projects\   this folder's parent. One folder per project. Never in git.
  workshop\   facts about this machine and its owner. Never in git.
```

**You may well not have access to `asa\`.** That is normal and nothing here depends on it. Older
notes may point at `dev\asa\kit\...` — **that path is stale**, everything moved on 2026-09-01.

## How to give feedback about the *way of working*

**`FEEDBACK.md`, in this folder.** One dated line per finding. It exists because feedback written
anywhere else does not get found. On 2026-09-01 a session wrote a good structural decision at the
bottom of a project note, and an hour later a second session recommended the opposite, never
having seen it.

**Mandatory case:** if a convention you were given does not fit and you change it, **write the
line**. An unrecorded change forks the convention silently, per project, forever.

## How to record a decision

Either shape is read. **Pick one per project, and do not convert an existing project from one to
the other.**

**A folder of files** — `decisions/0001-short-slug.md`, one per decision:

```markdown
# ADR 0001 - The thing that was decided

**Date:** 2026-09-01 - **Status:** accepted
**Decided by:** <name>

## Decision
<One or two sentences.>

## Why
<The reasoning, in the words used at the time. Not a summary.>

## What would change this
<The conditions that would make this wrong.>
```

**Or one log** — `decisions.md`, a `## 0001 - Title` section per decision, same fields inline.
Better for a small project, where a file per decision is more overhead than it's worth.

**Four things the reader depends on:**

| | |
|---|---|
| **A number** | So supersession can point at something |
| **A status** | `accepted` · `proposed` · `superseded by 0008` · `accepted (supersedes 0005)` · or *waiting on <someone>* when it needs an approval you do not have |
| **Why**, in the original words | The *what* is recoverable from the system itself. The *why* is not, and it is the only reason this record exists. |
| **What would change this** | The expiry condition. **Three of these once fired unnoticed on another project for ten days.** It is the most valuable field and the most often left out. |

## The one rule about content

**No customer data, no partner data, no personal data about any individual — ever, in any file
here.** Structures, decisions and reasoning: yes. Data about people: no.
