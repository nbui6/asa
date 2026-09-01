# Building it so it can grow

**The principle:** structure is cheap to add on day one and expensive to retrofit. Features are
the opposite. So build the *structure* of a large system from the start, and the *features* of a
small one.

This is not "build big now". It is "do not build a shape that has to be demolished."

---

## What this protects against

A system that works and cannot be navigated has a ceiling, and you hit it without warning. The
symptoms are always the same:

- Nobody can say where a given thing lives, so it gets written a second time
- A change in one place breaks something in another, and nobody predicted it
- A new person takes weeks to become useful, so nobody is added
- The assistant can no longer see enough of the codebase to be accurate
- Every decision gets re-argued, because no one recorded why it was made

Each of those is caused by a missing structure, not by missing effort. And each one is fixed on
day one by a file that takes twenty minutes to write.

---

## The five pieces

| Piece | What it does | Cost on day one | Cost to retrofit |
|---|---|---|---|
| **Architecture map** (`ARCHITECTURE.md`) | One page saying where everything lives and what may depend on what | 20 min | Days, and it will be wrong |
| **Module contracts** | Each part declares what it offers and what it may import | 1 session | A rewrite |
| **Decision records** (`decisions/`) | Why each significant choice was made | 5 min per decision | Impossible — the reasoning is gone |
| **Regression gate** | The machine check becomes blocking, and grows with every bug | Free (you already have the command) | Weeks of writing tests for code you no longer remember |
| **Non-functional checklist** | Auth, permissions, audit, backup, monitoring — named early, built when triggered | 10 min to write the list | Very expensive; some of it is a redesign |

Plus, when a second person arrives: **team review** — the branch and review flow, and who owns
what.

---

## When each one starts

Trigger-based, like everything else in this kit. Do not do all of it in week one.

| Moment | What starts |
|---|---|
| **Day one, always** | `ARCHITECTURE.md` (even three lines), the decisions folder, one pass/fail command |
| **The second module or major feature** | Module contracts, and a lint that enforces the dependency direction |
| **The first bug that comes back** | The regression gate stops being optional |
| **The first real user who is not you** | The non-functional checklist gets a first pass |
| **The second person on the repo** | Team review, ownership, branch flow |
| **Money is involved** | The whole non-functional checklist, properly |

---

## The rule that makes all of it work

> **Any human should be able to open this project and, within an hour, say what it does, where a
> given thing lives, and why it was built that way.**

That is testable. Ask someone to try. Whatever they could not answer is the gap, and it is
usually one missing file, not a missing month.

---

## What still does not scale, honestly

Structure removes most of the ceiling. Two things it does not remove:

**Review bandwidth.** More code needs more reviewers. Structure makes review *cheaper per change*
— small diffs, clear boundaries, an agent pre-reviewing — but it does not make it free. Growing
the team as the product earns it is the answer, and it is the normal one.

**Domain complexity.** Billing, permissions across organisations, data migration and compliance
are hard because the problem is hard, not because the code is badly organised. Budget real time
for them and expect to need someone who has done it before.

Neither is a reason to skip the structure. Both are reasons not to promise a timeline.

---

## The skills

> The full trigger list for every skill lives in `START-HERE.md`. These are the scaling ones.

| Skill | Use when |
|---|---|
| `architecture-map` | Day one, and whenever a new part is added |
| `module-contract` | Adding the second module, or splitting a growing one |
| `regression-gate` | The first returning bug, and every bug after |
| `non-functional` | Before the first real user, and before money is involved |
| `team-review` | A second person joins the repo |
| `design-system` | More than two or three screens — so features look like one product, not ten tools |
| `roadmap` | More ideas than you can build, and a need to see where everything stands |
| `data-and-secrets` | Before real data, before sharing, before selling |
| `business-case` | When growing it needs someone else's budget or time |
| `process-audit` | The kit or your own process documents have grown — check they still agree |

Templates: `templates/ARCHITECTURE.md`, `templates/ADR.md`, `templates/ROADMAP.md`,
`templates/BUSINESS-CASE.md`.
