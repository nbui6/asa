---
name: discovery
description: Interview someone about a software idea and turn it into a written charter, persona and milestone plan before any code exists. Use this at the very start of any project — when someone says they want to build an app, tool, script or feature, when a project has no CHARTER.md, when the requirements are vague or exist only in someone's head, or when they ask "where do I start". Also use when an existing project has drifted and nobody can say in one sentence what it is for. Do not use it to choose the technology (that is stack-choice), to plan a single session (that is the playbook), to write or check the persona for a specific screen (that is persona-check), or to rank a list of ideas you already have (that is roadmap).
---

# Discovery

Turn "I have an idea" into a charter someone could hand to a stranger.

**Why this exists.** Specification-driven work is an *execution* tool, not a *discovery* tool —
it will faithfully amplify a wrong assumption across dozens of files. Discovery is the only
place the assumption gets checked, and it costs a conversation instead of a rewrite.

---

## How to run it

**Interview. Do not design.** The strong pull is to start proposing features. Resist it until
the questions are answered — a proposal changes the answers you get afterwards.

**One question at a time.** A numbered list of twelve questions gets three answered.

**"I don't know" is a valid answer** and often the most valuable one. Write it into the charter
as an open decision with a name against it. A guess written as a fact is the expensive outcome.

**Ask for one real name.** "Busy professionals" is not a user. "Anja, team lead, twelve people,
survived two CRM migrations" is. If they cannot name one real person who has this problem, that
is the finding — surface it before anything gets built.

---

## The questions, in order

The order matters. Each one is chosen to defuse a specific failure.

**1. Describe what you want, in one sentence.**
They will describe a solution. That is fine and expected.

**2. So what is the problem underneath that?**
This is the actual first question. Solutions are cheap to change; problems are not.

**3. Who has this problem? Name one real person.**
Then: what is their job, and what else is competing for their attention at the moment they'd
use this?

**4. What do they do today instead?**
Spreadsheet, three browser tabs, a colleague on Teams, nothing. **This is the real competitor** —
not another product. If today's workaround is fine, the project may not be worth it.

**5. How often does this happen?**
Daily beats monthly by an enormous margin. A monthly task rarely justifies software.

**6. What happens if this is never built?**
If the honest answer is "not much", say so plainly. That is a useful result, not a failed
interview. Better to learn it now than after fifteen sessions.

**7. What is the smallest version one real person would actually use once?**
Not "a worse version of everything". One complete path from start to value.

**8. What would make them stop using it?**
The failure modes that end usage. This becomes the persona's `Quits when` line, and it must be
written before any design exists.

**9. What does success look like four weeks after launch — something you could observe?**
Push until it is observable. "They like it" is not; "she opened it three times in the first week
without being reminded" is.

**10. What data does this touch? Any information about a person?**
Names, emails, anything identifying. If the answer is not "none", the `data-and-secrets`
skill runs before code.

**11. How much time per week do you actually have?**
This sets the scope more than ambition does. Two hours a week is roughly one small feature a
month, and pretending otherwise is how side projects die.

**12. What already exists that does part of this?**
Buy, adapt, or build. Building something that exists is the most expensive possible outcome and
the easiest to avoid.

**13. What must this never do?**
Constraints are cheaper to honour from day one than to retrofit. Usually about data, cost, or
who can see what.

---

## Then derive, and read it back

From the answers, draft — and read each back for correction rather than presenting it as final:

**The core loop.** Three to six steps, the main thing a user does. If you cannot write it as a
loop, the product is not defined yet — go back to questions 2 and 7.

**In scope / out of scope.** The out-of-scope list with reasons prevents half of all scope creep.
Anything that is not on the core loop is out, by default.

**Milestones with checkpoints.** Milestone 0 is always the same: *it runs, and one command says
pass or fail.* After that, each milestone ends with something that runs and something the owner
can look at. Size them against the answer to question 11, not against enthusiasm.

**Open decisions.** Every "I don't know", with who decides it and by when.

---

## Traps

**They describe the solution they already imagined.** Ask what it would do for the person in
question 3, on the day in question 5. The solution usually shrinks.

**"It's for everyone."** Then it is for no one. Ask for the one person who would be upset if it
disappeared.

**The feature list arrives before the problem.** Write it into the backlog, unbuilt, and return
to question 2.

**Enthusiasm sets the scope.** Multiply the honest time budget by the number of sessions and say
the number out loud. "That is nine months at two hours a week" ends more bad scopes than any
argument.

**The owner is also the user.** Hardest case — they will describe who they wish they were. Anchor
on evidence: which similar tools have they abandoned, in which week, and what were they doing
when they stopped?

---

## Output

Three files, written from the answers, each read back before it is treated as agreed:

- `CHARTER.md` — from the template
- `PERSONA.md` — the five-minute version is enough to start
- Milestones, into the charter

Then stop. **Do not choose the technology** — that is `stack-choice`, and it is a separate
conversation with different trade-offs. **Do not write code.**

End with: *"Nothing gets built until you have pushed back on this at least once."* A charter
nobody argued with has not been read.
