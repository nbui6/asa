---
name: ship-it
description: Get a working project from the builder's machine into someone else's hands, and decide what to watch afterwards — packaging, hosting, distribution, a first-user checklist, cost and maintenance, and when to stop. Use this when a project works locally and someone else needs to use it, when someone asks how to publish, deploy, host, install or share what they built, when planning a first release or a pilot with real users, or when asking what a project costs to keep running. Also use to decide whether a project should be continued, paused or killed. Do not use it to write the README or handover notes another person will read (that is onboarding-docs) - this skill covers packaging, hosting, distribution, cost and what to watch afterwards.
---

# Shipping

"It works on my machine" is not finished. Shipping is a separate skill from building and it is
where most side projects stop, usually because nobody planned for it.

---

## 1. Is it actually ready?

Five questions. A "no" is not a blocker — an *unnamed* no is.

1. **Does it work from a clean start?** New folder, clone, install, run — following only the
   README. If you cannot test that yourself, the README is a guess.
2. **What happens on the worst realistic day?** No network, empty state, wrong input, first-ever
   use. Real people hit these on day one.
3. **Are there secrets in the package?** Run the check from `data-and-secrets` before anything
   leaves your machine.
4. **What personal data does it hold, and can it be deleted?**
5. **What is obviously unfinished?** Write it down and tell the user before they find it. A known
   gap is a limitation; a discovered one is a bug in their eyes.

---

## 2. Pick the smallest distribution that works

The instinct is to reach for an app store or a cloud platform. Almost always premature.

| How many users | What is usually right |
|---|---|
| Just you | Run it locally. This is a legitimate answer, not a failure. |
| One or two people you know | Send them the file, or let them clone the repo and run it |
| A handful inside one organisation | A shared internal location, or a small internal host |
| Strangers | Now you need a store, a domain, a support path — and it is a different project |

**Each step up adds an account, a bill, an approval process and a thing that breaks while you are
not looking.** Take one step, not three.

The trigger for a real hosting setup is a real person who cannot be asked to run a command. Not
before.

---

## 3. Make the release reproducible

Whatever the target, three things must be true:

- **One documented command produces the artefact** — the installer, the bundle, the container.
  Written in the README. If it takes a sequence of remembered steps, it is not repeatable.
- **The release is tagged in git**, so you can get back to exactly what someone is running. When
  they report a bug in two weeks, you need that.
- **The version is visible inside the product**, even as a tiny label. Otherwise every bug report
  begins with a guess about which build they have.

Build from a committed state, never from a working directory with uncommitted changes. What you
shipped must exist in the history.

---

## 4. The first user

The first real user is worth more than the next fifty, and only if you watch properly.

**Watch them use it once, in silence.** Do not explain, do not help, do not narrate. Where they
hesitate is the design problem — and it is almost never where you expected. Ten minutes of this
beats a month of speculation.

**Ask three questions afterwards, in this order:**

1. What did you expect to happen that didn't?
2. Where did you have to stop and think?
3. Would you use it again this week — and if not, what would have to change?

**Then triage honestly.** Not every piece of feedback is a change:

| Feedback | Action |
|---|---|
| They could not complete the core loop | Fix now |
| They completed it but hesitated | Fix soon — this is the highest-value class |
| They want something outside the charter | `BACKLOG.md`, with the trigger being "a second person asks" |
| They dislike something the persona explicitly accepts | Leave it, and say why |

One person's preference is not a requirement. Two people hitting the same wall is.

---

## 5. What it costs to keep alive

Write this into the charter before shipping, not after the first bill.

| | Ask |
|---|---|
| **Money** | Hosting, API usage, subscriptions, domains — per month, and what happens if usage grows 10× |
| **Time** | Dependency updates, breakages, questions from users. A rough hours-per-month. |
| **Attention** | What silently breaks while you are not looking, and how you would find out |

**A project you cannot afford to maintain should not be shipped to people who will rely on it.**
That is a real decision, and it is better made before there are users than after.

---

## 6. When to stop

Almost nobody writes this down, and it is why dead projects consume time for months. Decide the
criteria at a checkpoint, while you are calm:

**Kill or pause when:**
- The core loop has been usable for a while and nobody uses it — including you
- The thing it replaced is still being used instead
- Every session is maintenance and none is progress
- The cost, in money or hours, is no longer worth the value to its actual users

**Pivot rather than kill when** people use one small part of it enthusiastically and ignore the
rest. That part is the product.

Stopping deliberately is a good outcome, and it is very different from drifting away from
something while it silently rots. Write the decision, the date and the reason in `CLAUDE.md` —
a project that ended for a written reason is a lesson; one that faded is just guilt.
