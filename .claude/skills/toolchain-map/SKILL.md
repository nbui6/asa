---
name: toolchain-map
description: Name the set of tools a project actually runs on — what is built, what is adopted, what each one owns and must not do — and select which parts of this kit apply to this specific project. Use this on day one after the stack is chosen, whenever a new tool joins the setup, when work is duplicated because two tools do the same job, when nobody can say which tool is responsible for something, and at each checkpoint. Also use when adapting a generic process package to one project, or when someone asks what to call the combination of tools they are using. Do not use it to choose a technology that has not been chosen yet (that is stack-choice) - this skill names and divides what is already in use.
---

# Toolchain map

Almost no project is one program. It is **a set of tools working together**, and usually only one
of them is being built. The others are adopted: an editor, an assistant, a notes app, version
control, a hosting service.

Nothing else in this kit names that set. `stack-choice` picks what the *product* is made of.
This names the whole working system and, critically, **draws the boundaries between the parts**.

Two real terms worth using:

- **Toolchain** — the set of tools used to build and run the work
- **System context** — the picture of what you build, with everything it touches around it. From
  the C4 model; a standard, searchable term.

---

## Why it matters more than it sounds

Three specific failures, all of them expensive and all of them caused by an unnamed boundary:

1. **Building what an adopted tool already does.** The most common and the most wasteful. If the
   notes app already renders a table, building a table view is a month spent going backwards.
2. **Two tools owning the same thing.** Two homes for one fact means drift, and drift means
   nobody trusts either.
3. **Nobody owns the adopted tools.** They update, they break, they get abandoned. An adopted
   tool is a dependency with no `package.json` line — invisible until it fails.

---

## Part 1 — map the tools

One row per tool. The **"must not"** column is the one that does the work.

| Tool | Built or adopted | Owns | Must not | Replaceable? |
|---|---|---|---|---|
| | built / adopted / bought | the one job it is responsible for | the jobs that belong to another tool | how hard, and with what |

Rules for filling it in:

**Every job has exactly one owner.** If two tools could do something, decide which one does, and
write the other one's "must not". This single line prevents most future duplication.

**The "must not" is a boundary, not a criticism.** *"The tool never becomes a text editor —
prose is written in the assistant"* is what stops a two-week detour in month three.

**Adopted tools are dependencies.** Give each one a review date and put it in the same list the
`stack-review` agent reads. A community plugin nobody maintains is exactly as risky as an
abandoned library, and much easier to forget.

**Name what you build.** The built part needs a real name because you will refer to it a hundred
times. The toolchain as a whole does not — it is a description, not a brand.

---

## Part 2 — the system context

A small diagram. Text is fine; the arrows matter more than the boxes.

```
        [person]
            │ uses
            ▼
   ┌──────────────────┐  reads/writes   ┌────────────────┐
   │  the thing you   │ ───────────────▶│  shared files  │
   │      build       │                 └────────────────┘
   └──────────────────┘                        ▲
            │ hands off to                     │ also reads/writes
            ▼                                  │
     [adopted tool]  ───────────────────────────
```

What it must show: who uses it, what you build, what you adopted, and **what data passes between
them**. Anything reached by two tools is where drift will start — mark it.

Keep it to one screen. A context diagram that needs scrolling has become an architecture diagram,
which is a different picture with a different job.

---

## Part 3 — adapt this kit to the project

A generic package used generically is a package nobody follows. State plainly, in the project's
own words:

| | |
|---|---|
| **Skills that apply** | And any project-specific rule they take on here |
| **Skills on standby** | **Not "does not apply"** — every skill is on the team, some are waiting for a trigger. Write the trigger. The difference matters: "inapplicable" is a dead end, "standby, waiting for X" is a state a dashboard can show and a person can act on. |
| **Skills that need a trigger set** | e.g. *"`data-and-secrets` runs before any real customer data touches this"* |
| **What this project adds** | Conventions this project needs that the kit does not have |

The result is short — half a page — and it is what makes the kit feel written for this project
rather than borrowed.

**If the project has more than a handful of skills and agents, make it a roster**: one row each,
with *what it serves*, *status* (active / standby / never ran) and *the trigger*. That table is
readable by a person and by a tool, so it doubles as the data behind any "who is on the team"
view you later build.

---

## Part 4 — the roster, grouped as departments

Once a project has more than a handful of skills and agents, group the roster the way a company
groups functions. It gives you two things a flat list cannot:

- **Navigation** — "which skills are in the room for product work?"
- **Focus** — one session, one department. Jumping between product, engineering and compliance in
  a single sitting is the most expensive way to work.

A useful default: **Strategy & product · Engineering · Risk & compliance · Records & operations ·
People & research.**

| Skill or agent | Department | Status | Fires when |
|---|---|---|---|
| | | active / standby / never ran | the written trigger |

Departments are a **map, not a hiring plan.** A department does not justify an agent — the hiring
rule does (`PLAYBOOK.md` §10).

### Who reports to whom

```
   OWNER  ── decides
     │
   the tool / desk  ── shows state, routes, queues
     │
  ┌──┴──┬──────────┐
ASSISTANT AGENTS  STANDING CHECKS
  └─────┴──────────┘
        │ all pick up
      SKILLS  ── policies, not staff
```

**Skills are policies, not staff.** Nobody reports to a skill; whoever is doing a job picks up the
relevant one. That is why a roster says *fires when*, not *reports to*.

---

## Part 5 — one queue for decisions

Every project accumulates things waiting on a human, and they scatter: a `[NEEDS DECISION]`
marker in one file, an audit finding in another, an ADR marked *proposed* in a third.

**Collect them in one list**, in the project home note:

| What | Where | Since |
|---|---|---|

**An item leaves only by a decision that gets written down.** A queue that empties by ageing out
is theatre — and the scattered version is worse, because you cannot even see what you are
ignoring.

---

## Keeping it true

| Moment | What happens |
|---|---|
| Day one, after `stack-choice` | Write `TOOLCHAIN.md` |
| A tool joins or leaves | Update it in the same session. A tool nobody wrote down is a tool nobody maintains. |
| Work turns out to be duplicated | A boundary was missing. Add the "must not" line, then fix the duplication. |
| Checkpoint | Re-read it. Is every adopted tool still maintained? Has any boundary quietly moved? |

---

## Traps

**Adopting a tool without naming what it owns.** It slowly grows into everything, or into
nothing.

**Forgetting the assistant is part of the toolchain.** Claude, Copilot or whatever else is doing
real work with real boundaries — it owns prose, reasoning and code generation, and it must not
own the things a human has to verify. Write that row like any other.

**Treating adopted tools as free.** They cost attention, they break, and some of them are
maintained by one person who has moved on.

**Mapping tools you might use.** Only what is actually in the setup. A wish list here is
indistinguishable from a decision, and someone will read it as one.
