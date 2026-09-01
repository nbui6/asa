# Charter — <project name>

**Owner:** <name> · **Date:** <yyyy-mm-dd> · **Status:** draft / agreed
**Time budget:** <hours per week> · **Target:** <phone / web / desktop / internal tool>

> Fill this in with the `discovery` skill, not alone at a blank page. One page. If it runs to
> three, the project is too big for its first version.

---

## 1. The problem

<Who has it, how often, and what they do today instead. Concrete, with an example.>

**What happens if this is never built:** <the honest answer. If it is "nothing much", say so —
that is useful information, not a failure.>

## 2. Who it is for

<One sentence. Then point at the persona file: `PERSONA.md`.>

**Not for:** <the people this deliberately does not serve. This line prevents half of all scope
creep.>

## 3. The core loop

<The main thing a user does, as a sequence. Three to six steps. If you cannot write it as a
loop, the product is not defined yet.>

```
step → step → step → step
```

## 4. What "working" looks like

<How you will know this succeeded, in observable terms. Not "users like it" —
"<name> used it three times in the first week without being reminded".>

## 5. Scope

**In, for version 1:**
1. <…>
2. <…>
3. <…>

**Explicitly out, and why:**

| Deferred | Why |
|---|---|
| <…> | <…> |

**Scope rule:** anything not on the loop in §3 goes to `BACKLOG.md` and does not get built.

## 6. Shape

<How the pieces fit together. A diagram in text is fine. Name any boundary that must not be
crossed — those are the decisions that are expensive to reverse.>

## 7. Stack

| Layer | Choice | Why |
|---|---|---|
| <…> | <…> | <…> |

**Deliberately not using:** <things you considered and rejected, with the reason. Prevents
re-litigating them in week three.>

## 8. Where AI is used, and where it is not

> Use AI only where the task needs understanding of text or input the system has never seen
> before. Everything else is code — faster, cheaper, offline, and the same answer twice.

| Job | AI? | Why |
|---|---|---|
| <…> | yes / no | <…> |

## 9. Data and privacy

- **What personal data does this touch?** <or "none", which is the best answer>
- **Where does it live?** <device / server / third party>
- **What leaves the machine, and to whom?**
- **What must never be stored here?**

<If the answer to the first question is not "none", run the `data-and-secrets` skill before
writing code.>

## 10. Cost

| Item | Cost |
|---|---|
| Services and hosting | <…> |
| API usage | <…> |
| **Your time** | <sessions × hours — usually the real cost> |

## 11. Milestones

| # | Outcome | Checkpoint |
|---|---|---|
| 0 | It runs, and one command says pass or fail | — |
| 1 | <…> | <what you stop and look at> |
| 2 | <…> | <…> |

**Every milestone ends with something that runs and something you can check.**

## 12. Open decisions

| # | Decision | Who decides | Still open? |
|---|---|---|---|
| 1 | <…> | <…> | yes |

---

*Nothing gets built until the owner has pushed back on this document at least once.*
