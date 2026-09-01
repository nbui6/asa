---
name: research
description: Find out what is actually true before deciding — what already exists, what the current best approach is, what real users do, and whether a widely repeated claim holds up. Use this before choosing a technology, before building something that may already exist, when comparing competitors or alternatives, when a decision rests on a number or a claim, when someone says "I read that…", and before writing a business case. Also use when an answer must be current rather than remembered, such as versions, prices, limits or whether a tool is still maintained. Do not use it to make the technology decision itself or weigh its trade-offs (that is stack-choice) - this skill supplies the facts that decision rests on.
---

# Research

Two failures this prevents. **Building something that already exists**, and **deciding on a number
nobody checked.** Both are cheap to avoid and expensive to discover afterwards.

The third failure is researching instead of deciding, so start at the end.

---

## Start from the decision

Before searching anything, write down two lines:

> **The decision:** <what you will do differently depending on the answer>
> **What would change my mind:** <the finding that flips it>

If nothing would change your mind, you are not researching, you are looking for support. Say so
and skip it — a decision already made is allowed, it just should not be dressed as evidence.

Then **timebox it.** Thirty minutes for a small technology question, two hours for a competitor
landscape. Research expands to fill whatever time exists, and it feels like progress the whole
way.

---

## Three kinds, three methods

### 1. Does it already exist?

Ask before building anything of size. The order matters:

1. **Your own codebase and organisation first.** Grep the repo; ask a colleague. The most
   expensive thing you can build is the thing your company already bought.
2. Then open source, then commercial products.
3. For each real candidate: what does it do, what does it cost, what does it refuse to do, could
   you stand on it instead of competing with it?

**A product's pricing page tells you who it is really for**, faster than its marketing does. And
what a tool deliberately does *not* do is usually the most informative thing about it.

Adopting or building on something is a legitimate and usually better outcome than building. Say
that plainly when it is true.

### 2. What is the current best approach?

For technology questions the answer decays, so anything remembered is suspect.

- **Primary sources**: official documentation, the project's own repository, release notes,
  the changelog. Not a blog summarising them from two years ago.
- **Check it is alive**: last release, open issues, whether the maintainers still respond.
- **Version and date everything.** "Works with version X, checked on <date>" is a fact. "Works"
  is a hope.
- Two or three good sources beat ten. Search results are full of confident, stale, SEO-written
  articles that copy each other.

### 3. What do real people do?

The only one that cannot be searched. Three conversations beat any amount of reading — see
`discovery` for the questions and `ship-it` for watching someone use the thing.

Beware of research that only ever confirms. If nothing you found surprised you, you probably
searched for your own opinion.

---

## Checking a claim that a decision rests on

Anything that will appear in a charter, a business case or a management conversation gets traced
to its source. Numbers travel further than their evidence.

Ask in this order:

1. **Who produced it, and what do they sell?** A code-review vendor measuring the quality of code
   with its own product is data, not evidence.
2. **What was the method, and the sample?**
3. **When?** Two-year-old numbers about AI tooling are archaeology.
4. **Has it been superseded — including by its own authors?** Good research groups publish
   corrections, and the correction never travels as far as the original.
5. **Is anything contradicting it?** If nothing does, look harder.

Then grade it out loud: peer-reviewed · independent benchmark · vendor with stated method ·
vendor marketing · untraceable. **Report the grade next to the number**, every time.

A widely quoted figure that turns out to be a blog's rounding of a vendor press release is a
genuinely useful finding. Say it plainly — it is more valuable than the number was.

---

## Working efficiently

- **Fan out, then read deep.** Several parallel searches for breadth, then read the two or three
  primary sources properly. Skimming twenty results produces a confident average of other
  people's summaries.
- **Use subagents for breadth** when available: each searches one angle and returns a short
  answer, so the main conversation stays clean.
- **Never assert a version number, price, limit or menu path from memory.** These change, and a
  confidently wrong one costs more than an admitted gap. Look it up, and give the URL.
- If a search does not answer the question, **say so**. A named gap is useful; a filled one is
  a hazard.

---

## Where findings go

Research that lives only in a conversation is research you will pay for twice.

| Finding | Where |
|---|---|
| A measured fact about your setup | `CLAUDE.md` → verified findings, **with the date** |
| Something considered and rejected | `CLAUDE.md` → rejected approaches, **with the reason** |
| A choice that shaped the system | An ADR — context, options, why, what would change it |
| Competitor or market findings | The vault, linked from the charter |
| A number for management | The business case, **with its source and grade** |

Every citable claim keeps its URL. In six months "I read somewhere that…" is worth nothing.

---

## Stop when

- You can state the decision and the reason in two sentences, or
- Two or three independent sources agree and nothing credible contradicts them, or
- The timebox ran out — then write down what you found, what you did not, and decide anyway with
  the uncertainty named

**A decision made with named uncertainty is fine. A decision made with hidden uncertainty is
what goes wrong later.**
