---
name: kit-feedback
description: Capture what the process itself got wrong during a session, so the kit improves from real use instead of from guessing — what slowed you down, what was skipped, what was missing, and which skills actually fired. Use this at the end of any working session, when a rule felt like paperwork, when something in the process was ignored, when a skill did not fire and should have, when a skill fired and was useless, and at every retrospective. Also use when deciding whether to add or remove something from a process package.
---

# Kit feedback

The retrospective improves the **project**. This improves the **process**.

Without it, a process package only changes when someone happens to notice something in
conversation — which means it changes based on the loudest recent memory rather than on what
actually keeps happening.

**Five minutes at the end of a session. Appends to `KIT-LOG.md` in the kit.**

---

## The four questions

Answer briefly. One line each is enough — the value is in the accumulation, not in any single
entry.

**1. What slowed you down?**
Which part of the process cost more than it returned *today*. Be specific: "writing the machine
line for a one-file change felt like paperwork" beats "too much overhead".

**2. What got skipped, and why?**
A skipped step is data, not a confession. Steps get skipped because they are unclear, too
expensive, or genuinely unnecessary here — and each cause has a different fix.

**3. What was missing?**
Something you needed and had to invent on the spot. This is where new skills come from — and
where they should come from, rather than from imagining what might be useful.

**4. Which skills actually fired?**
List them. Over ten sessions this is the only honest evidence for **growth without use** — a
package that keeps growing while the same four skills do all the work.

Optionally: what worked unexpectedly well. Rare, and worth keeping when it happens.

---

## The rule that makes it useful

> **One entry changes nothing. A pattern changes the kit.**

Do not edit the package after a single complaint. Wait until the same thing appears **twice**,
then act — otherwise the package churns after every bad day and never settles.

When a pattern does appear, the fix is usually one of four:

| Pattern | Usual fix |
|---|---|
| A step is skipped every time | It is too expensive, or it is not needed. Cut it or make it cheaper — do not restate it more firmly. |
| The same thing is invented every project | A new skill or template. This is the honest origin of one. |
| A skill never fires | Its description does not match how people actually ask. Rewrite the description, or remove the skill. |
| A skill fires and gets ignored | It is wrong, too long, or duplicates another. Fix or merge. |

**"Restate the rule more firmly" is never the fix.** A rule people skip is a rule with a cost
problem or a trigger problem, and repeating it louder solves neither.

---

## The entry format

Append to `KIT-LOG.md`. Keep it to a few lines.

```markdown
### <date> — <project> — <what the session was about>

- **Slowed me down:**
- **Skipped:**            <and why>
- **Missing:**
- **Skills that fired:**
- **Worked well:**        <only if something did>
```

---

## Reading the log

At each retrospective, read the last several entries together and ask three things:

1. **What appears twice or more?** Those are the real findings.
2. **Which skills have never appeared in "skills that fired"?** Either the description is wrong
   or the skill should go. Say which, honestly.
3. **Is the same thing being invented on different projects?** That is a promotion waiting to
   happen — see the retrospective's promotion step.

Then make the changes, and note in the log which entries they came from. A change with no traced
cause is how a package accumulates rules nobody remembers agreeing to.

---

## Honest limits

**This measures friction, not value.** A process that never annoys anyone is probably not doing
anything. Some friction is the point — writing acceptance criteria before code will always feel
slower in the moment and be faster over the session.

So when something is reported as slow, ask what it caught. If the answer is "nothing, ever",
that is a cut. If the answer is "it caught the thing that would have cost a day", it stays and
the friction is the price.

**And the honest self-check for any process package:** how many pieces exist, and how many have
actually been used? If the first number keeps growing and the second does not, the package has
become a hobby.


---

## First, check you are writing in the right log

*Added 2026-08-31, from the first outside test.*

**Feedback from real use sorts into two kinds, and only one of them is about the kit.**

| Kind | Example | Where |
|---|---|---|
| **How we build** | a step that failed · a skill that did not fire · a check that measured the wrong thing · a command that stranded someone | `KIT-LOG.md` |
| **How the work is remembered** | something rebuilt that already existed · a decision re-argued · a stale fact read as current · a parked idea whose trigger fired and never came back · two numbers disagreeing | **the operating layer's log**, if this setup has one |

**The test is one question:**

> **Could a change to the build process have prevented this?**
> Yes → the kit's log. **No, because the information already existed and nothing looked at it** →
> the other one.

**Why it matters rather than being tidiness:** a retrieval failure written into the kit's log is
recorded somewhere that **has no step able to act on it.** It reads as captured and is actually lost.
Six of them accumulated that way in one week before anyone noticed the bucket was wrong.

**If there is no operating layer in this project, say so and write it in the kit's log anyway** — but
label it, so it can be moved when one exists. A finding in the wrong place is better than a finding
nowhere.
