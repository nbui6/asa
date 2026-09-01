---
name: stack-choice
description: Choose the technology for a project honestly — language, framework, database, hosting — and say what each choice costs in setup time, learning and long-term maintenance. Use this whenever someone asks what to build something with, which framework or language to use, whether they need a backend or a database, where to host it, or whether a library is worth adding. Also use to re-examine a stack that was chosen earlier, or when someone proposes adding a dependency. Especially important for people who are not developers and cannot yet judge the trade-offs themselves. Do not use it to establish the facts a choice rests on, such as current versions, prices or whether a tool is still maintained (that is research, which runs first), or to record and divide up the tools a project already runs on (that is toolchain-map).
---

# Choosing the stack

The first question a beginner asks, the one with the worst available advice online, and the one
where a wrong answer costs a rewrite rather than an afternoon.

**The bias to correct for:** the assistant knows every framework and will produce working code in
all of them, so every option looks equally good from the inside. It is not equally good for a
specific person with a specific time budget on a specific machine.

---

## Decide in this order

Stop at the first line that settles it. Most projects are decided by line 1 or 2.

**1. What does the thing have to run on?**
A phone app, a website, a command-line tool and a spreadsheet macro are different problems. This
eliminates most of the field immediately, and it comes from the charter, not from preference.

**2. What does this person already know?**
A language they can read is worth more than a "better" one they cannot. They have to review the
code — that is the whole approach. Somebody who knows Python and builds their first thing in
Rust has given up the ability to check the work.

**3. What can be installed on this machine?**
Ask before recommending. Admin rights, disk space, and a corporate laptop's restrictions are
real constraints, and finding out after a 12 GB download wastes a session. Prefer things that
install in user space.

**4. What is the smallest thing that could work?**
Static file before a web app. One file before a framework. No database before a database. No
server before a server. **Every layer removed is a whole category of problem that cannot happen.**

**5. Only then: which specific option.**
And when two remain roughly equal, pick the more boring one — the one with more documentation,
more answered questions, and more code in the assistant's training data. Novelty costs you
support.

---

## Say the cost out loud

Never recommend a stack without these four numbers. A recommendation without them is a
preference.

| | Ask |
|---|---|
| **Setup time** | Hours before the first thing runs. Say it honestly: "this eats your first session" is often the true answer. |
| **Disk and install** | Numbers, from the official docs, not from memory. Check before you promise. |
| **What they must learn** | Not "you'll pick it up". Name the concepts: async, types, build steps, package management. |
| **What has to be maintained** | Every server, account, subscription and dependency is a thing that breaks later while they are not looking. |

Then say the *reversal cost*: how expensive is it to change this decision in two months? Cheap
reversals deserve a fast decision. Expensive ones — data model, hosting, the platform itself —
deserve the whole conversation.

---

## Things that are almost always wrong for a first project

Say these plainly rather than letting the person discover them.

- **A backend server, when nobody but the owner uses it yet.** A server is a subsystem, a
  monthly bill and an ops job. The trigger to build one is a real second user who cannot be
  asked to configure anything.
- **A database, before you know the shape of the data.** A file is a database with fewer ways to
  be wrong.
- **A state-management library, a UI kit, a monorepo tool.** Ceremony for one developer.
- **Microservices.** For anything.
- **The framework that trended last month.** Fewer answered questions, more breaking changes.
- **Anything requiring an account, a card, or a cloud build service**, unless the project cannot
  exist without it.

---

## Dependencies

Apply this to every library, one at a time:

> **If it cannot be explained in two sentences, it does not go in.**

And: the owner can veto any dependency without giving a reason. They are the one who will have
to understand it at 22:00 when it breaks.

Before adding one, ask whether the language's standard library already does this. It usually
does, less elegantly, with zero maintenance cost.

---

## How to present the recommendation

Two or three options, never one and never five. For each: what it is in one sentence, the four
costs, and what it rules out.

Then **one clear recommendation with a reason**, phrased so that disagreeing is easy. The person
decides — they are the one living with it.

Write the outcome into `CHARTER.md` §7 **including the rejected options and why**. Otherwise the
same debate happens again in three weeks, and the answer will be different for no good reason.

---

## Re-examining a stack later

Belongs at a checkpoint, not mid-milestone. The routine sweep across every dependency is the
`stack-review` agent's job; use this skill when you are actively reconsidering **one** specific
choice and want the trade-offs argued. Two questions only:

1. Is anything here unmaintained, insecure, or now clearly worse than an alternative?
2. Is anything here **unused** — a dependency that stayed after the reason for it left?

Changing a stack that is merely unfashionable is the most expensive way to feel productive.

---

## Name the strictness dial when you name the stack — added 2026-09-01

Choosing a language chooses an analyser, and **every analyser has a dial that is shipped turned
down.** If nobody sets it at the start, nobody sets it at all — turning it up on a mature codebase
means hundreds of findings at once, which is how it gets turned back down again.

**So when this skill records a stack, it records three more lines with it:**

| | |
|---|---|
| The **formatter** and its checking flag | `dart format --set-exit-if-changed`, `prettier --check`, `gofmt -l` |
| The **analyser and the level** | Not "the analyser" — the setting. `strict-casts` + `--fatal-infos`, PHPStan level 10, `mypy --strict` |
| The **feature-test runner** | The one that drives the real thing, not the unit runner |

**Cost of setting it on day one: minutes. Cost of setting it in month three: a day, or never.**
