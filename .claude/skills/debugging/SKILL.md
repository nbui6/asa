---
name: debugging
description: Find the cause of a bug systematically instead of guessing — reproduce it, bisect from the last working state, test one written hypothesis at a time, and turn the fix into a test. Use this whenever something breaks, an error appears, output is wrong, a feature stopped working, a build or test fails, or the second attempt at a fix did not work. Also use when someone is stuck, says they have tried several things already, or is about to change more than one thing at once to see what happens.
---

# Debugging

Debugging is where sessions die. It is the most expensive activity in time and in tokens, and it
is the one place where guessing feels like progress.

**The whole method:** stop changing things, get a reliable reproduction, narrow the search space
by half, and write down each hypothesis before testing it.

---

## Before anything: stop and read

The strongest instinct — the assistant's and the human's — is to immediately propose a fix. A fix
proposed before the cause is known is a guess, and a guess that happens to work is worse than one
that fails, because now the real bug is hidden.

**Read the actual error, in full.** Not a summary of it. In a stack trace, read from the bottom
up: the top frames are usually library code, and the useful line is the last one that belongs to
this project.

---

## The five steps

### 1. Reproduce it

**No reliable reproduction, no fix** — because without one you cannot know it is fixed. Write
down the exact steps, the exact input, and the exact wrong output.

If it only happens sometimes, that is itself the most important clue: intermittent points at
timing, ordering, caching, network, or leftover state.

### 2. Ask what changed

> **What is the last state where this worked?**

The highest-yield question in debugging, and the most often skipped.

```bash
git diff HEAD~1        # what changed in the last commit
git log --oneline      # find the last commit you know was good
```

If the last known-good state is many commits back, bisect: check the middle commit. Working →
the bug is in the newer half. Broken → the older half. Repeat. Twenty commits become five checks.

This is why small commits are worth making: they make the search space small.

### 3. One hypothesis, written down, before testing it

Write it in this shape, every time:

> **I think** the date is parsed as US format
> **because** the failing values are all days 1–12
> **if I'm right,** printing the parsed value for `03/04` will show 4 March, not 3 April

Then test only that.

Why write it down: it stops **shotgun debugging** — changing five things at once and then not
knowing which one mattered. It also makes a wrong hypothesis useful, because a prediction that
failed eliminates a whole branch. Guessing without predicting eliminates nothing.

**Never have two unverified changes at once.** If two things changed and it still breaks, you now
have to debug both.

### 4. Look at the real data at the boundary

Most "I don't understand why it does that" ends here. Print the raw value where the code meets
the outside world — the API response before parsing, the row as it came from the database, the
file's actual bytes, the parameter as received.

Nine times out of ten the data is not what everyone assumed: a string where a number was
expected, an empty list, a null, an encoding, a timezone, a trailing space.

### 5. Name the category

Once found, name the *kind* of problem, not just the fix. Categories transfer to the next bug;
fixes do not.

> off-by-one · null or missing value · type mismatch · timezone · encoding · race condition ·
> stale cache · wrong environment · PATH · permissions · version mismatch · state left over from
> a previous run

Then explain why the symptom looked the way it did. That is the part that makes the next bug
faster.

---

## The two-strike rule

**After two failed attempts at the same problem, stop.** Do not try a third variation.

Clear the context and start again with a fresh prompt containing what the two failures ruled out.
A third attempt rarely works, because the failed attempts are still in the context steering
toward the same wrong answer.

Correcting in circles is the single most common way a session produces nothing.

---

## Close the loop

A bug that is fixed and not written down comes back.

1. **Write the test that would have caught it.** This is the highest-value test in the project —
   see the `first-test` skill. Best done before the fix, so you watch it fail and then pass.
2. **One line in `CLAUDE.md`** under verified findings: the symptom, the cause, the date.
3. **If it happened twice, it becomes a rule** in the hard rules, written as what *to do*.

---

## Things that are not debugging

- Rewriting the whole thing because it is easier than understanding it. Sometimes correct — but
  say it out loud and decide deliberately, do not drift into it.
- Adding a `try/catch` that swallows the error. That is not a fix; it is hiding the evidence and
  making the code lie about its own state.
- Upgrading a dependency and hoping. Reversible, so it is a legitimate *experiment* — but say
  that is what it is, and revert it if it does not help.

---

## Honest limit

The assistant usually cannot run your program, see your screen, or reach your device. It is
working from what you paste. **Paste the whole error, not a summary of it** — and when it asks
for the output of a command, that output is the evidence the whole method runs on.
