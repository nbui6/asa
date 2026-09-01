---
name: data-and-secrets
description: Keep API keys and passwords out of code, handle personal data lawfully, and find the legal questions a project raises — .gitignore and environment variables, what to do when a key leaks, GDPR basics, who owns code built at work, open-source licences, accessibility law, and what changes if something is sold. Use this before the first commit of any project, whenever an API key, token, password or connection string appears, whenever the project touches names, emails or anything about a person, before pushing a repo anywhere, before sharing or selling anything built at work, before adding a dependency with an unusual licence, and whenever someone asks whether they are allowed to do something. Also use when a secret has already been committed.
---

# Data, secrets and what you are allowed to do

Two problems that share one property: **both are cheap to prevent and expensive to discover
later.** A leaked key costs money and access. Mishandled personal data costs a fine — in the EU,
a serious one.

Published benchmarks put a large share of AI-generated code as containing a known vulnerability,
flat across model generations. **Assume generated code is not secure by default and check it**,
rather than hoping this time it was.

This is a checklist that finds questions. It is **not legal advice** — the output is a short list
of open items with a name against each.

---

## Part 1 — secrets

### The rule

> **A secret never enters a file that git tracks.** Not once, not temporarily, not "I'll remove
> it before committing."

Git remembers. Deleting a key in a later commit does not remove it from history — anyone who
clones the repo still gets it.

### Where secrets actually go

| Situation | Where the secret lives |
|---|---|
| Script or backend on your machine | A `.env` file, listed in `.gitignore`, read as an **environment variable** |
| A mobile app | The device's secure storage (Keystore, Keychain) — entered by the user, never shipped |
| A web frontend | **Nowhere.** Anything the browser can read, the user can read. Needs a backend, or a key scoped so exposure is harmless. |
| A team | A secret manager, or the CI provider's secret store |

### Before the first commit

1. `.gitignore` exists and contains `.env`, key files, credential files, local config. Start from
   the standard one for your language.
2. Commit a `.env.example` with the variable **names** and no values.
3. Run this before every push — from the command, not from memory:

```bash
git grep -nEi "api[_-]?key|secret|password|token|BEGIN [A-Z ]*PRIVATE KEY" -- . ':!*.example'
```

Anything it finds either moves out, or is a false positive you can explain in one sentence.

### A key that reached a commit

In this order, and do the first step first:

1. **Revoke and rotate the key** at the provider. Immediately. Assume it is already compromised.
2. Remove it from the working files and commit that.
3. Only if the repo was pushed: rewrite history. Disruptive and easy to get wrong — step 1 is
   what actually protects you.
4. Write it into `CLAUDE.md` under verified findings, with the date.

**Do not skip step 1 because the repo was never pushed.** Verify that claim with `git remote -v`
rather than assuming it.

---

## Part 2 — personal data

Applies the moment the software touches information about a person — a name, an email address, an
IP address, a user ID traceable to someone.

### Four questions, answered in the charter

1. **What personal data does this touch?** The best answer is "none", and it is achievable more
   often than people expect.
2. **Why does it need it?** No clear answer → remove the field. Data you do not hold cannot leak,
   cannot be requested, and cannot be misused.
3. **Where does it live, and for how long?**
4. **Who can see it?**

### The principles that do most of the work

**Do not collect it.** Ask what decision the data enables — often a count, a band or a flag does
the same job. "Renews in 43 days" is actionable; the exact contract value usually is not.

**Link, do not copy.** Where a record already lives in another system, link to it. One source of
truth, one place to delete from.

**Aggregate by default, detail on request.** Counts and flags on the main screen; names and
detail behind a click, in the system that owns them.

**Local beats remote.** Data that never leaves the device has no transfer, no hosting and no
breach surface.

**Say what leaves.** The user should see what is sent to a third party — an AI API included —
before it is sent.

### The compliance checklist

Mark each **fine / needs a decision / needs a professional**.

| Question | Fine when |
|---|---|
| Is there a lawful basis for holding it? | Someone in the organisation can name it. Not your call alone. |
| Where is it stored, and in which country? | You know, and it is written down |
| Which third parties see it, including AI providers? | Listed, and users know |
| Can a person's data be found and deleted on request? | You have done it once, deliberately |
| How long is it kept? | There is an answer that is not "forever" |
| Who inside the organisation can see it? | Fewer people than technically could |

**Test data:** invented data is safe. A copy of production data **is** production data, with all
the same obligations, wherever it is sitting.

**Escalate to a professional when** the data concerns employees, health, children, finances or
real customers; when it leaves the EU; or when anyone says "we'll ask forgiveness later".

---

## Part 3 — what you are allowed to do

### Who owns the code

Uncomfortable, and better asked early — especially for something built at work that might be
shared or sold later.

- Built on company time, company laptop, or solving a company problem? In many jurisdictions and
  most employment contracts that points to the employer — but it depends on **the contract and
  local law**, not on which laptop it ran on.
- Building in your own time on your own machine keeps the question simple. Mixing the two is hard
  to unwind later.
- If you might share it outside the organisation, ask **before** building.

**This is an HR and contract question.** An assistant cannot answer it and should not guess in
either direction.

### Open-source licences

Every dependency carries a licence, and it travels with your project.

| Family | Roughly means | Watch for |
|---|---|---|
| MIT, Apache-2.0, BSD | Use freely, keep the notice | Apache-2.0 adds patent terms — normally good |
| LGPL | Usually fine if you only link to it | Modifying it changes things |
| GPL, AGPL | Distributing can require publishing your source. AGPL extends this to software offered over a network. | **Check before adding**, especially for anything you might sell or host |
| "Source available", non-commercial, custom | Not open source. Read the terms. | Commercial use often prohibited |

Generate the dependency-and-licence list — most package managers can — and keep it.

**Also:** AI-generated code can resemble training data. For anything commercial, a similarity or
licence scan is a reasonable precaution.

### Accessibility

For workplace tools this is increasingly a legal requirement in the EU, not only good practice.
Check what applies to your case rather than assuming it does not.

The baseline and its reasoning live in the `non-functional` skill — keyboard operation, contrast,
resizable text, labels, never colour alone.

### If it is shared or sold

Each is a real obligation: terms of use and a privacy notice · liability when it is wrong ·
support and who answers · data separation between organisations · a payment provider, never your
own card handling · sector rules for finance, health, education, public sector.

**A working internal tool is not one step away from being a product.** This list is the distance.
The trade-offs of selling are in the `business-case` skill.

### AI-specific

- What is sent to the provider, and does the user see it before it goes?
- Does the provider train on your inputs? Verify against current terms — and record the date you
  checked.
- If an AI output influences a decision about a person, someone must be able to explain and
  override it.
- Who is accountable when the model is confidently wrong? Always a person.

---

## Output

A short table, not an essay:

| Question | Status | Who owns it | By when |
|---|---|---|---|

Anything marked **needs a professional** gets a named human inside the organisation.

**Write into `CHARTER.md` §9:** what data, where it lives, what leaves, what must never be
stored. **Into `CLAUDE.md` hard rules:** where secrets live, one line.
**Into `README.md`:** how a new person supplies their own credentials.
