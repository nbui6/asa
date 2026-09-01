---
name: inherit-codebase
description: Take over a codebase you did not write — understand it safely, find out what it actually does, and make a first change without breaking something invisible. Use this when starting work on an existing project, when picking up someone else's code, when returning to your own project after months away, when asked to add a feature to a system nobody can explain, or when a repo has no documentation. Also use before any refactor or rewrite of existing code, and when deciding whether to extend something or replace it.
---

# Inheriting a codebase

Most of this kit assumes you are starting from nothing. **Most real work is not.** You inherit
something: a colleague's script, a system whose author left, or your own project from four months
ago — which is somebody else's code with your name on the commits.

The failure to avoid is the same in every case: **changing something whose consequences you
cannot see.**

---

## The order that keeps you safe

Do not read the code first. Read it fourth.

### 1. Make it run

Before understanding anything, get it running and get **one command that says pass or fail** —
even if that command only starts the thing and checks it did not crash.

Without this you have no way to know whether your change broke something, and every later step is
guesswork. If it cannot be made to run, that is the finding, and it is the whole first session.

### 2. Find the seams from the outside

Not the code — the edges:

- **What does it read and write?** Files, databases, APIs, queues. This is the real shape.
- **How is it started?** A command, a schedule, a button, another system.
- **Who or what depends on it?** The thing most likely to break invisibly.
- **What does `git log` say?** Which files change often (the live parts) and which never change
  (the frozen parts, and the risky ones — nobody remembers how they work).

### 3. Ask the people, before the code

If the author or a user is reachable, thirty minutes with them beats a day of reading:

- What is it *for*? What decision does it support?
- What part are you afraid of?
- What broke last time, and what did you do?
- What did you always mean to fix?

**"What are you afraid of"** is the highest-yield question in this whole skill. Write the answer
down verbatim.

### 4. Now read — narrowly

Follow **one** real path end to end: one input, through the system, to one output. Not the whole
codebase. One path tells you the conventions, the layering and the style, and it gives you a
place to stand.

Write the map as you go — `ARCHITECTURE.md`, the honest version: what is actually there, not what
should be. See `architecture-map`.

### 5. Make one tiny change

Something trivially safe — a label, a log line, a comment. Then run the check and commit.

The point is not the change. It is proving that **you can change this system and know whether it
still works.** Until that loop exists, nothing bigger is safe.

---

## Write down what you find, as you find it

An inherited codebase teaches you things once and then you forget them. Capture in `CLAUDE.md`:

- **Verified findings** — what you *measured*: how to run it, how long it takes, what the real
  data looks like, which config it needs. Date each one.
- **Landmines** — anything that surprised you or that a person warned you about. Verbatim.
- **Questions you could not answer.** A named unknown is safe. An unnamed one is a landmine.

This file is the difference between the next person taking three days or three weeks — and the
next person is often you.

---

## Extend, or replace?

The question arrives early and the instinct is almost always "replace". Resist it long enough to
answer three things honestly:

| Ask | Why it matters |
|---|---|
| **Does it work today, for real users?** | Working software contains years of undocumented fixes for problems you have not met yet |
| **Do you understand *why* it is built that way?** | If not, a rewrite will rediscover every reason the hard way |
| **What is the actual cost of the current design?** | In hours per month, measured. "It is ugly" is not a cost. |

**A rewrite is a bet that you understand the problem better than the people who lived it.**
Sometimes true. Usually not on day three.

The safer middle: keep it running, wrap the part that hurts, replace behind the wrapper. And
write it up as an ADR either way — this is exactly the decision someone will question in a year.

---

## Working with an assistant on inherited code

Two specific dangers:

**It will confidently explain code it half-read.** Ask for the file and line for any claim about
how something works. An explanation that cannot be pointed at is a guess.

**It will suggest a rewrite, because generating new code is easier than understanding old code.**
That bias is real. Weigh the suggestion against the three questions above, not against how clean
the proposed version looks.

And the useful direction: an assistant is genuinely good at **summarising a file you point it
at**, **tracing one path**, and **finding every place something is used**. Use it for that, in
small pieces, and check the answers against the running system.

---

## The finish line for session one

You have inherited it properly when:

1. It runs on your machine
2. One command says pass or fail
3. You can name what it reads and writes
4. You have made one tiny change, verified it, and committed it
5. `CLAUDE.md` has your verified findings and the landmines

That is a full session, it produces almost no visible progress, and skipping it is how people
break systems they were asked to improve.
