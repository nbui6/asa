# <Title> — for someone outside this project

**Written for:** <the developer, the funder, the adviser, the collaborator>
**By:** <name> · **Date:** <yyyy-mm-dd>

> **Fill the first four sections before you write any structure.** They are not throat-clearing.
> A document written from inside a project is *always* missing them, and its author cannot feel the
> gap — everyone inside shares context invisibly.
>
> *From the first outside test, 2026-08-31. A structural document was written for an external
> developer twice and rejected twice with the same two words: **"context is missing."** Both drafts
> opened with the architecture. From inside it read as complete; from outside it read as a set of
> assertions arriving from nowhere. The third version worked, and **the difference was entirely in
> what came first.***
>
> **This is a position problem, not a writing-skill problem.** More effort on the prose does not fix
> it; a checklist does.

---

## 1. The problem, with real evidence

<Not a summary of the problem — **the actual evidence**, quoted. The research, the numbers, the
thing a user said, the log line. Without it every design choice below looks arbitrary, and a reader
who thinks your choices are arbitrary is not reading, they are waiting to disagree.>

## 2. Vocabulary

<One table. Each term defined once, here, and then used consistently.>

| Term | In this document it means |
|---|---|
| | |

> **Most disagreement between two competent people is one word used two ways.** This table is the
> cheapest section to write and the one that prevents the longest arguments.

## 3. The sceptic's question, answered first

<The objection a competent reader raises in the first thirty seconds. Write it in their words, as
sharply as they would put it — then answer it.>

**"<the objection>"**

<The answer.>

> **Unanswered, it discredits everything after it.** The reader spends the rest of the document
> composing that objection instead of following your argument. Answering it early is not defensive;
> it is what earns the next five pages.

## 4. One worked example, end to end

<One concrete trace: a real input, every step it passes through, the real output. Not a diagram, not
a representative case — one actual instance, followed all the way.>

> **One trace explains more than any diagram.** After it, the structure explains itself, because the
> reader already has something to hang it on.

## 5. The structure

<Now it lands. Stores, tables, services, the field that carries state, the boundaries — whatever the
document is actually about.>

## 6. What is deliberately not decided yet

<And what would settle each one. An external reader who spots a gap you have not named assumes you
missed it; one you have named is an invitation to help.>

| Open | Why | What would settle it |
|---|---|---|

---

## Before sending

- [ ] Sections 1–4 come before any structure
- [ ] Every term in the vocabulary table is used the same way throughout
- [ ] The sceptic's question is one a competent reader would actually ask, not a soft one
- [ ] The worked example is a **real** instance, followed end to end
- [ ] **Every premise the argument rests on has been re-checked today.** Before re-using an argument
      written earlier — even your own, even from two days ago — restate its premises and check each
      is still true. *A proposal was argued on a constraint that a different decision had quietly
      invalidated the day before. It still read as sound, because its own text was never edited.*
