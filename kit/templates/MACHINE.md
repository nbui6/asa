# MACHINE.md — <this machine>

**What is true of this computer, measured on it, with a date.** Not the kit — none of it would be true
on anyone else's machine. Not any one product — all of it is true of every project you build here.

This file and `BOSS.md` are **the workshop**: the third home. `PLAYBOOK.md` §14, *Three homes*.

> **Where it lives: beside the kit, not inside it.** One copy per machine, read by every project.
> A `CLAUDE.md` in a project points at it; the kit itself never contains it, which is what lets the
> kit be handed to someone else without editing a single file.

> **The docs are a claim. The running system is the fact.** Nothing goes in here that was taken from
> documentation. Everything is dated, so it can be re-checked when it starts to look wrong.

---

## The machine

| | |
|---|---|
| OS and version | |
| **Admin rights?** | *If not, say so — it rules out half of most install instructions* |
| Default shell | *and whether it is the one the scripts assume* |
| **Not installed** | *The languages and runtimes that are NOT here. Saves an assistant proposing a Python script on a machine with no Python.* |

## Shell traps

<Every quirk that has cost you time once. Quoting, encodings, a flag that behaves differently, a
window that has to be reopened after a PATH change. **One line each, with the date.** These are the
cheapest entries in the file and the ones that save the most, because they are invisible and they
repeat.>

## Toolchain — measured, with dates

| Tool | Version | Measured |
|---|---|---|
| | | |

<And for each: anything the tool *claims* that turned out to be wrong on this machine. A self-check
that lies once will lie again, and nobody remembers which one it was.>

## Where things live

| | |
|---|---|
| The kit | |
| The workshop | *this file* |
| Installed skills and agents | |
| Repos | |

## Rules this machine imposes

> **Careful here — this section is a trap.** A *fact* about the machine lives in this file. A **rule
> that binds how anyone may act in a project** has to be repeated in that project's `CLAUDE.md`,
> because that is the file people and agents are told to read.
>
> Learned on 2026-08-26: a rule was moved here, correctly by the letter of *Three homes*, and four
> hours later a subagent that had been told to *"read `CLAUDE.md` for the hard rules"* broke it, and
> blocked a commit. **The measurement travels. The instruction stays where the reader is pointed.**

| The rule | The measurement behind it |
|---|---|
| | |

---

## Maintaining it

| Moment | What happens |
|---|---|
| A tool version changes | The row changes, with a new date |
| A machine fact is found while building | It goes **here**, not into the product's `CLAUDE.md` |
| A product's `CLAUDE.md` grows a machine fact anyway | Move it here, leave a pointer. Two copies drift. |
| At a retrospective | Re-read the dates. A two-month-old version number is a claim again. |
