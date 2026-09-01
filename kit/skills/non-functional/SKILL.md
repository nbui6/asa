---
name: non-functional
description: Cover the requirements that are invisible until they fail — accounts and permissions, audit trails, data migration, backups, monitoring, error handling, rate limits, accessibility and cost. Use this before the first real user who is not the builder, before any project handles money or other people's data, when planning a system that a team or organisation will depend on, when asked what a project is missing before it is "real", and at each checkpoint of a growing product. Also use when someone asks why a working prototype is not production-ready.
---

# The invisible requirements

Features are what you decide to build. **Non-functional requirements** are what everyone assumes
is already there. They are invisible while things work and are the whole story when they do not.

They are also the difference between "it works" and "a team can depend on it", which is exactly
the gap between a prototype and a product.

---

## How to use this

Not all at once. Each row has a **trigger** — the moment it stops being optional. Before that,
name it and leave it. After that, it is not a nice-to-have.

Write the list into `CHARTER.md` early even if every row says "not yet". Naming a gap is what
stops it being a surprise.

---

## The checklist

### Identity and permissions

| Question | Trigger |
|---|---|
| Who can use this at all? | The second user |
| Can two people see different things? | Any data one user should not see |
| Who can change things versus only read them? | Any write action that matters |
| What happens when someone leaves the organisation? | Any organisational tool |

**Read-only first.** A tool that cannot change anything is a much smaller conversation. Make
write access a deliberate, later decision with someone senior signing for it.

### Auditability

| Question | Trigger |
|---|---|
| Can you answer "who did this, and when"? | Anything that changes shared data |
| Can you answer "where did this number come from"? | Any figure a human will act on |
| Are errors recorded somewhere you would actually look? | The first user who is not you |

Every number on a screen needs a traceable source. A dashboard nobody can reconcile is distrusted
once and ignored forever.

### Data over time

| Question | Trigger |
|---|---|
| What happens to existing data when the structure changes? | The first change to the data model after real data exists |
| Is there a backup, and **have you restored from it**? | Any data you would be upset to lose |
| Can a person's data be deleted on request? | Any personal data at all |
| How long is data kept? | Any personal data at all |

An untested backup is not a backup. Restore it once, on purpose, and write the date in
`CLAUDE.md`.

Data migration is the most commonly forgotten item on this list and one of the most expensive.
The first schema change against real data is where prototypes die.

### When things go wrong

| Question | Trigger |
|---|---|
| What does the user see when it fails? | The first user who is not you |
| What happens with no network, or a slow one? | Anything that calls out to a service |
| What happens when an external service is down or rate-limits you? | Any external API |
| Would you find out it was broken, or would they tell you? | Anyone depends on it |

"It crashed" and "we could not reach the server, your work is saved" are the same failure and
completely different products.

### Accessibility

| Question | Trigger |
|---|---|
| Does it work by keyboard alone? | Any tool used at work |
| Is text contrast sufficient, and text resizable? | Any screen |
| Do images and controls have labels a screen reader can use? | Any screen |
| Is meaning carried by something other than colour alone? | Any status indicator |

Colleagues include people with low vision, colour blindness and RSI. This is also a legal
requirement for many organisational tools in the EU — check for your case rather than assuming.
Cheap during design, expensive as a retrofit.

### Cost and operations

| Question | Trigger |
|---|---|
| What does this cost per month today? | Any paid service |
| What does it cost at 10× the usage? | Before anyone else adopts it |
| What has to be renewed, updated or paid for to keep working? | Day one |
| Who fixes it when it breaks, and when? | Anyone depends on it |

A project nobody is able to maintain should not be given to people who will rely on it. Decide
that before there are users, not after.

---

## The honest conversation

Most of this list will say "not yet" for a long time, and that is correct. The failure is not
having gaps — it is having gaps nobody wrote down, discovered by a user.

Two sentences worth saying plainly to whoever owns the project:

> "Here is what this does not do yet, and here is the moment each one becomes mandatory."

And, for anything involving money, employees, health or customers of a real business: there must
be a **named human** accountable for it inside the organisation. That is not something an
assistant, or a document, can carry.
