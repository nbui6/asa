# Template — a product's own skill

**Lives in the product repo**, not in the kit:

```
<repo>/.claude/skills/<skill-name>/SKILL.md
```

Committed with the code it describes, so it is versioned with the thing it explains and a colleague
gets it on clone. `install-skills.ps1` leaves this folder alone and prints what it found there.

> **Kit skill or product skill?** One question: *would this still make sense in a project that has
> nothing to do with this product?* Yes → the kit. No → here. `PLAYBOOK.md` §14, **Two libraries**.
>
> A product skill is where **domain knowledge** goes — the shape of this app's content files, the
> grammar of the block it parses, the contract with the service it talks to. The kit does not need
> to know any of that. It needs the product to be *able* to have it.

---

```markdown
---
name: <skill-name>
description: <What it does, in one sentence.> Use when <the concrete moments in THIS product —
name the files, the formats and the folders, because that specificity is the whole point of a
product skill>. Do not use it for <the neighbouring job>, and hand <the generic half> to
<the kit skill that owns it>.
---

# <Name>

<One paragraph: what this part of the product is, and what goes wrong when someone touches it
without knowing.>

## The shape

<The actual schema, format, folder layout or contract. Real, copy-pasteable, from the repo — not
described in prose. This is the section people come here for.>

## The rules that are not obvious from the shape

<Every rule someone would break by accident. Each one with the reason, because a rule without its
reason gets optimised away in three months.>

## How to add one / change one

<The steps, and the command that proves it worked. If there is no such command, say so and say
what a human has to look at instead.>

## What this cannot check

<The limits. A validator checks shape, never truth — say which parts nothing verifies, so the gap
is known rather than discovered.>
```

---

## The four things it must carry

| | | Why |
|---|---|---|
| 1 | **The real shape**, copied from the repo | Prose about a format is a second source of truth, and it drifts the day after it is written |
| 2 | **Where the files live**, by path | A skill that says "the content folder" makes the reader guess |
| 3 | **The command that validates it** | Otherwise the skill is advice, and advice does not fail a build |
| 4 | **What nothing checks** | The honest limit. Every product skill has one, and the ones that pretend otherwise are the dangerous ones |

## And what it must not do

- **Not restate the kit.** No testing philosophy, no process, no five stages. Point at the kit skill
  and stop. Two copies of a rule means one of them is out of date.
- **Not turn into a decision record.** *"We chose JSON because…"* is an **ADR** — `templates/ADR.md`,
  dated, with the rejected options. The skill says *how it works now*; the ADR says *why, and what
  was rejected*. A skill carrying its own history stops being readable.
- **Not describe a feature that does not exist yet.** A skill for a planned thing is a plan.
