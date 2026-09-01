---
name: business-case
description: Build the argument that gets a project supported — what it costs, what it saves or earns, what the risks are, and the specific decision being asked for. Use this when someone needs to present a project to management, ask for budget, headcount or developer time, justify continuing or expanding something already built, propose an internal tool as a product the company could sell, or answer "why should we spend time on this". Also use to sanity-check whether a project is worth doing at all before building it.
---

# The business case

A working prototype does not get supported. **An argument does.** This is the document that
turns "I built a thing" into "we should invest in this thing", and it is a different skill from
building.

The reader is a decision-maker with fifteen minutes, several competing requests, and a budget.
Write for that person.

---

## The rule that decides whether it works

> **Name the decision you are asking for, on the first page.**

Not "here is what I made". Something specific and answerable:

> *"I am asking for 20 days of a developer's time in Q3, to take this from a working prototype to
> something the support team can use daily."*

A presentation with no ask gets "interesting, thanks" and nothing happens. That outcome is
usually blamed on the audience; it is almost always the document.

---

## Structure

One or two pages. Longer gets skimmed, and the skimmed parts are the ones you needed.

**1. The problem, in their terms.** Not "the tools are disconnected" — *"a support agent opens
three systems to answer one question, roughly N times a day."* Quantify it even roughly, and say
where the number came from.

**2. What it costs today.** Hours × people × frequency, or the deal that was lost, or the mistake
that happened. This is the number the whole case rests on, so be conservative — an inflated one
that gets challenged takes the rest of the document down with it.

**3. What exists now.** Honest status of the prototype: what works, what doesn't, what's faked.
Overstating here is the fastest way to lose the room, because someone will click the thing that
isn't finished.

**4. What it would take.** Time, people, money, and what has to be bought or hosted. Include
running cost, not just build cost — the question after "what does it cost to make" is always
"what does it cost every month".

**5. The risks, named by you.** Every reader is silently listing them. Naming them first is what
makes the rest credible: key-person risk, maintenance, data protection, "what if the person who
built it leaves".

**6. The alternatives, including doing nothing.** Buy an existing product, hire, keep the manual
process. If you have not compared, someone in the room will, out loud.

**7. The ask.** The specific decision, and by when.

---

## Getting the numbers honestly

**Time saved** is the usual currency, and the usual place people lose credibility.

- Count the people, the frequency and the minutes. Show the arithmetic so it can be checked.
- **Halve your first estimate.** Nobody saves the full theoretical amount.
- Say where the number came from: measured, asked three colleagues, or estimated. "Estimated" is
  fine. Presented as measured when it was not is fatal.
- Time saved is not money saved unless the time gets used for something. Say which.

**Other currencies that count**, and sometimes count more: mistakes avoided, faster response to
customers, something previously impossible becoming possible, risk reduced, a job people hate
becoming tolerable.

---

## The "could we sell this?" case

A different and much harder argument. If someone raises it, be plain about what changes:

| Internal tool | Product to sell |
|---|---|
| One organisation's data | Many organisations, kept apart — a data-model decision |
| Colleagues who can be asked | Customers who cannot |
| Broken is annoying | Broken is a refund and a reputation |
| No terms, no billing, no support | All three, plus liability and compliance |
| One person can maintain it | A team, indefinitely |

The honest framing: **a working internal tool is evidence that the problem is real, not evidence
that a product exists.** Selling is a company decision involving legal, support, pricing and
sales — propose it as a question to explore, with the internal version as proof the need is
genuine. Proposing it as a finished plan invites everyone to find the hole, and there are many.

---

## Tone

- **Numbers with their source beats adjectives.** "Roughly 40 minutes a day across four people,
  measured over one week" beats "significantly faster".
- **Say what you don't know.** A named unknown reads as competence; a gap someone finds reads as
  a sales pitch.
- **No jargon from the build.** They do not need the stack. They need cost, benefit, risk, ask.
- **One page they could forward.** Most decisions are made in a meeting you are not in.

---

## Before writing it, check it is worth writing

If the honest answers are "a few people, occasionally, mildly annoying", there is no case, and
finding that out in twenty minutes is a good result. Say so rather than dressing it up — the
credibility you keep is worth more than the one project.
