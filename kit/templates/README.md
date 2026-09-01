# <Project>

**<One line: what it is. If it is a learning project, say so here, in the first line.>**

<One paragraph: what it does and who for. Plain language, no pitch.>

---

## Status — honest version

<The commonest README failure is describing the *intended* project rather than the actual one.
It reads as a lie the moment someone tries it.>

| Works today | Not built yet |
|---|---|
| <…> | <…> |

---

## Run it

**You need:** <tools, with the versions actually used>

```bash
git clone <repo>
cd <project>
<install command>
```

Check the environment:

```bash
<doctor / version / status command>
```

<Expected output. Say which warnings are expected and fine.>

Run the checks — this is the project's pass/fail command:

```bash
<test command>
```

<Expected output.>

Run it:

```bash
<run command>
```

<What you should see. Say if the first run is slow, if the terminal will not return the prompt,
or if success looks like nothing happening.>

---

## How this project is worked on

Every session runs five stages: **Goal → Acceptance criteria → Build → Test → Commit.**

Two rules the whole approach depends on:

1. Acceptance criteria are written before any code — a human line and a machine line.
2. A human runs the code and looks at the result.

Full process: `PLAYBOOK.md`.

---

## Rules that do not get traded away

<The short list. Secrets, architecture boundaries, where AI is and is not used, what must never
be stored. For a collaborator these matter more than the feature list — the expensive mistakes
are rebuilding what exists and reusing a rejected approach.>

1. <…>

---

## Where things are written down

| Question | File |
|---|---|
| What are we building, and why this way? | `CHARTER.md` |
| Where are we, what is decided, what already failed? | `CLAUDE.md` |
| What did we deliberately not do? | `BACKLOG.md` |
| How do we work? | `PLAYBOOK.md` |

If you are picking this up cold, read `CLAUDE.md` first — it ends with "Where we are" and the
single next step.

---

## Open questions

<Decisions that are genuinely undecided. Naming them stops someone deciding by accident.>
