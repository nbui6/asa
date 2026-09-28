---
name: module-contract
description: Define the seam between parts of a system so each feature can be built, reviewed and replaced on its own — what a module offers, what it may import, and how parts talk to each other. Use this when adding a second module or major feature, when a file or folder has grown too big to hold in one head, when two features need to share something, when planning how a system will be split before writing it, or when a change in one place keeps breaking another. Also use before adding a plugin or extension point. Do not use it to write or maintain the whole-project map of where everything lives (that is architecture-map).
---

# Module contracts

A **module** is a part of the system that can be understood, changed and reviewed without
reading the rest. That property is the whole point — it is what keeps review possible as the
project grows, and review is the thing that stops it becoming a black box.

The seam costs about one session to put in. Retrofitting it is a rewrite. Put it in before the
second module, not after the fifth.

---

## What a module declares

Keep this list short. Four or five items, the same for every module in the project, written in
the architecture map so nobody has to guess.

A useful default:

| A module declares | Meaning |
|---|---|
| **What it offers** | The functions, screens or events other parts may use — its public surface |
| **What it owns** | Its data: tables, files, keys. Nobody else writes to these. |
| **What it needs** | The shared services it depends on, named explicitly |
| **Its settings** | What a user can configure about it |

**Everything not on the list is private.** That is what makes a module safe to change: if it is
not declared, nothing outside can be relying on it.

---

## The three rules

**1. Dependencies go one direction.** Features may use shared services. Shared services never
reach up into features, and features never import each other directly. A cycle means both parts
must now be understood together, which is exactly what a module was for.

**2. One owner per piece of data.** Two modules writing the same table is the most reliable way
to produce a bug nobody can reproduce. If two need it, it belongs in the shared layer, owned
there.

**3. Talk through the declared surface.** Reaching into another module's internals works fine
until that module changes, and then it fails somewhere unrelated to the change.

Where the language allows it, enforce all three with a lint or a check in the machine check.
A rule enforced by memory is already broken somewhere.

---

## When two modules need to talk

In order of preference. Go down the list only when the one above genuinely does not work.

1. **They don't.** Most cases. Check whether the shared thing belongs in the shared layer.
2. **Through the shared layer.** One owns the data, the other reads it via a shared service.
3. **A declared call.** Module A calls B's public surface, and the architecture map records that
   A depends on B.
4. **An event.** A announces something happened; anyone interested reacts. Good for one-to-many
   and for keeping A ignorant of who is listening. **Costly to debug** — the call chain is no
   longer visible by reading, so use it deliberately and log it, or you have built exactly the
   action-at-a-distance the code rules warn about.

---

## Sizing a module

**Too small** if you can never change one without changing another — the boundary is in the wrong
place.

**Too big** if you cannot say what it does in one sentence, or a newcomer cannot find their way
inside it in ten minutes.

Split when there are two clear sentences instead of one. Do not split by guessing about the
future; split when the seam has already appeared on its own.

---

## The empty template module

Worth creating once, early: a `_template/` module with the folder layout, the declaration file,
one stub of each kind of thing, and a passing test.

It makes the structure obvious rather than documented, and copying it is faster than reading a
description. It is also the clearest possible instruction to an assistant about where a new
feature goes.

---

## Writing it down

In `ARCHITECTURE.md`: the list of what every module declares, and the dependency rule with its
enforcement.

In each module: a short `README.md` — what it does in one sentence, what it offers, what it owns,
what it needs.

In `decisions/`: an ADR for the seam itself, because it is one of the few decisions that is
genuinely expensive to reverse, and in a year someone will ask why it is like this.
