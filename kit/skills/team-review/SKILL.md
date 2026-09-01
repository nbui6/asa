---
name: team-review
description: Set up how more than one person works on the same project — branches and pull requests, who reviews what, code ownership, keeping shared project files from conflicting, and getting a new person productive in an hour. Use this when a second person joins a repo, when planning to hand work over or split it between people, when two people's changes keep colliding, when deciding what a human must review versus what an agent can check, or when onboarding someone onto an existing project. Also use when a solo project is preparing to become a team one.
---

# Working as more than one

The kit's core rule is that a human checks the work. With two or more people that rule does not
get weaker — it gets **distributed**, and it needs a shape so nothing falls between the two of
you.

Set this up when the second person arrives. Not before; the ceremony is real and pointless alone.

---

## The flow

The smallest thing that works, and it is enough for a long time:

1. **One branch per piece of work**, named after the work, short-lived — a day or two, not a
   month. Long branches are where painful merges come from.
2. **A pull request** for every change into the main branch, however small. The PR is where the
   diff becomes reviewable; without it, review has no natural moment.
3. **The machine check is green before review starts.** Reviewing a change whose tests fail wastes the
   reviewer.
4. **One human approves.** Not as a formality — see below.
5. **Merge, and delete the branch.**

The main branch is always in a state you could ship. That is what makes it safe for two people
to work at once.

---

## What the agent reviews, and what a human must

Both. They catch different things, and confusing them is the main way review becomes theatre.

| The `reviewer` agent is good at | A human is needed for |
|---|---|
| Does it break, and with what input | Is this the right thing to build |
| Claimed but unverified | Does it fit the user (`persona-check`) |
| Mocks, hard-coded values, swallowed errors | Does it belong here architecturally |
| Duplication of code already in the repo | Is the trade-off acceptable |
| Rule and boundary violations | Will we regret this in six months |

**Run the agent first, then the human.** The agent clears the mechanical findings so the human's
attention goes to judgement, which is the scarce resource.

**A human must look at every change that touches** money, permissions, personal data, the data
model, or a public interface. No exceptions, no matter how small the diff.

---

## Making review cheap

Review bandwidth is the real limit on how fast a team can grow. Everything here is about lowering
the cost per change rather than reviewing less.

- **Small pull requests.** A diff that takes an hour to read gets approved without being read.
  Under roughly 400 changed lines is a reasonable target; smaller is better.
- **The PR says what and why**, and names the acceptance criteria it satisfies. A reviewer who
  has to reconstruct the intent is guessing.
- **One concern per PR.** A refactor mixed with a feature is unreviewable — the reader cannot
  tell which lines are the change.
- **The architecture map is current**, so the reviewer knows where the change belongs.
- **Review within a day.** A PR waiting three days gets a rubber stamp, and the author has moved
  on and forgotten it.

Two people who both use an assistant can generate far more diff than they can read. **The
constraint is review, not production** — plan the work against reviewer time, not typing time.

---

## Ownership

Write it down, even for two people. Ambiguous ownership means either both touch it or neither
maintains it.

| Area | Owner | Who reviews changes to it |
|---|---|---|

The owner is not the only one who may change it — they are the one who must be asked, and who
notices when it rots.

---

## Shared files, and how they conflict

`CLAUDE.md`, the architecture map and the backlog are edited every session by everyone. That is
exactly the recipe for merge conflicts.

- **Append, do not rewrite.** Session log entries and decisions are added at the end.
- **One decision per file** in a `decisions/` folder rather than one big document — two people
  adding two decisions then never collide.
- **The note-taker agent updates `CLAUDE.md` at the end of a session**, in the same commit as the
  work, so the change is small and easy to merge.

---

## Onboarding a new person

The target is: **useful within an hour, without interrupting anyone.** Test it with the next
person who joins and fix whatever they had to ask.

Their first hour:

1. `README.md` — clone, install, run, and the pass/fail command. It must work exactly as written.
2. `ARCHITECTURE.md` — where things live and what may depend on what.
3. `CLAUDE.md` — where we are, what is decided, what already failed.
4. `PLAYBOOK.md` §1 and §3 — how a session runs here.
5. A small, real, already-scoped first task, with its acceptance criteria written for them.

Whatever they had to ask a person for is the gap in the documents. Add that answer, and nothing
else — see the `onboarding-docs` skill.

---

## When the team grows past two or three

You are now doing normal software engineering, and this kit stops being the whole answer. The
things that start to matter: a shared definition of done that is enforced rather than remembered,
continuous integration on a server, environments that are not someone's laptop, a release
process, and someone accountable when it breaks at night.

Say that out loud when it happens, rather than stretching a solo process until it snaps.
