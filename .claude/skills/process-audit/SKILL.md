---
name: process-audit
description: Check that a set of skills, templates, agents and process documents still works as one system — broken references, contradictions between files, overlapping skills, rules with no trigger, inconsistent vocabulary, and files nobody uses. Use this whenever a collection of skills or process documents has grown, after adding several new pieces, when two documents seem to disagree, before sharing a process package with anyone else, and at every checkpoint. Also use when a process is not being followed and nobody can say which part is wrong. Reports findings; never silently rewrites.
---

# Process audit

A set of skills and documents rots differently from code: **nothing fails when it is wrong.** A
broken cross-reference, two files giving different advice, a skill nobody's situation ever
triggers — all of it sits there looking fine, and the whole package quietly stops being trusted.

This is the check that makes it visible. Run it at every checkpoint, and always after adding
several pieces at once.

---

## The eight checks

Work through them in order. Report; do not silently fix — a package that gets edited without
its owner noticing is a package they stop trusting.

### 1. References resolve

Every mention of another file, section or skill points at something that exists. Broken
references are the most common defect and the most damaging, because they teach the reader that
the document is stale.

Check: file names, section numbers (`PLAYBOOK.md §7`), skill names, template names, folder paths.

### 2. Nothing contradicts

Two documents giving different advice on the same question is worse than either one alone,
because now the reader has to arbitrate and they came here for an answer.

Look especially where scopes touch: two skills covering neighbouring ground, a rule in a process
doc restated in a template, guidance repeated in an agent's instructions.

### 3. No duplication

Anything stated in two places will disagree within a month. **One home per fact, links
elsewhere.** When two files both explain something, decide which owns it and make the other
point at it.

### 4. No overlap that should be a merge

Two skills whose triggers fire in the same situation will both load, or neither will. Ask: could
a reasonable person not tell which one to use? If so, either merge them or sharpen both
descriptions until the boundary is obvious.

The opposite failure counts too: one skill trying to do two unrelated jobs, which makes it
trigger unreliably for both.

### 5. Every rule has a trigger

The core test: **name the moment this fires.** A rule with no moment is an intention, and
intentions do not survive a deadline.

For each skill, template and rule, find where its firing moment is written down — a trigger
table, a stage in the process, a checklist. Anything with no moment is either dead weight or
needs one adding.

### 6. Vocabulary is consistent

One word per concept, and every term is one professionals actually use.

- Flag any invented name for something that already has a standard term. Invented vocabulary is
  a second thing to learn and it is worth nothing outside the package.
- Flag two words used for one concept, and one word used for two.
- Check the glossary covers every term the documents use, and contains nothing they do not.

### 7. Nothing invented here is trapped here

When a package is used on a real project, general things get worked out inside that project and
never come back — a convention, a template, a rule that would help every future project.

Check the project's own documents for anything **generic** sitting in a project-specific file.
Each one is a promotion the package is missing, and the reason the next project reinvents it.

### 8. Nothing is dead

- Files nothing points at
- Skills that have never been used since they were written
- Rules that are routinely skipped — those are not rules, they are decoration, and pretending
  otherwise trains people to ignore the real ones
- **Growth without use.** A package that keeps growing while never being applied is a warning,
  not an achievement. Say the number out loud: how many pieces exist, how many have actually
  been used.

---

## How to run it efficiently

Read every file — a partial audit that reports "no issues" is worse than none.

For a package of any size, fan out: several parallel readers, each doing a subset of the checks
across all files, each returning findings only. Then merge and de-duplicate.

Verify each finding before reporting it. A false positive in an audit costs more trust than a
missed one, because the next audit gets ignored.

---

## The report

Findings first, worst first. For each:

**what is wrong → where → the smallest fix**

Then a summary table:

| Check | Findings | Worst one |
|---|---|---|

And one honest verdict:

- **Coherent** — the pieces work as one system
- **Coherent with conditions** — usable, and these specific things need fixing
- **Drifting** — the package is no longer trustworthy as a whole; name what to fix first

## After the audit

- Fixes are proposed, then applied with the owner's agreement
- Anything that cannot be fixed now becomes a backlog entry with a trigger
- **If a finding appears in two consecutive audits, the process itself is wrong**, not the
  document. Change the process, not the file, or the same finding returns forever.
