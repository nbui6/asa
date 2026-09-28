---
name: doorman
description: Reads a project's own record before work on it continues, so a session never guesses something the file already answers. Fires automatically at the start of project work under workspace\projects\ — opening a project, being asked its status or next step, being asked to change one of its files, or picking one up after any gap — not on a fixed trigger word, the same way a person would glance at the file before saying anything. Surfaces the project's own note (status, next-step, where it stands), everything in "Open, needing a decision", the task list, and any BACKLOG.md parked item whose trigger has fired. Never opens or quotes a *.local.md file — existence only (ADR 0018). Scoped only to workspace\projects\ and workspace\asa\ — never the Verbi Vault or any other system; that stays chief-of-staff's, untouched. Read-only: never edits, audits, scores, or writes anything back.
---

# Doorman

**The one job:** stand between "a session starts talking about a project" and "the session says
anything" — and put the record in front of it first.

**Why this exists.** ADR 0004 found the same failure six separate times: the right information
existed in a file, and nothing forced a look at it before someone (human or session) acted from
memory instead. ADR 0012 named the fix a doorman rather than a rebuild of Asa itself — the
deposit end already existed for the Vault (`chief-of-staff`'s DEPOSIT mode); **the read-first end
did not exist anywhere.** This is that end, built for `workspace\projects\` specifically, not
the Vault.

**A live example of the failure this must actually catch, not just a hypothetical (2026-09-08):**
a session was asked whether Asa was ready to hand a round to Code, and answered from memory. The
true answer sat in `asa\CLAUDE.md`'s own "Where we are" section — which was itself five days
stale, still saying "nothing is committed" after two rounds had shipped and pushed. Reading a
stale file and repeating it faithfully is not read-first working — it's read-first failing
quietly, with more confidence. **Surfacing a record is only useful if the record's own currency
gets a second's thought**, which is why the freshness check below exists and isn't optional.

**What this is not.** It does not audit, does not compare against yesterday, does not notice
drift or propose changes, and does not write anything — including a deposit at the end of a
session. Those are a different job (the "Asa HR" line of work, ADR 0019, not yet built). Doorman
only reads and surfaces, once, at the start.

---

## When it fires

Not a trigger word — a moment. Fire before continuing whenever any of these is about to happen,
and it hasn't already fired this conversation for that project:

- A project under `workspace\projects\<name>\` is named, opened, or asked about.
- A session is about to answer a question about a project's status, next step, or history.
- A session is about to edit any file inside a project's folder.
- A conversation picks a project back up after a gap, even mid-conversation.
- **Anything doorman would read for this project has changed since it last fired in this
  conversation** — including a change the session itself just made. A long working session on one
  project is not one moment, it's many, and a doorman that only checks the record once at the
  start goes stale by the same mechanism it exists to catch.

**Not "once per conversation" — once per conversation *or again on change*, whichever is more
often.** For a short conversation touching a project once, that's the same thing: fire once. For a
long, continuous session actively editing a project's own files — this kind of session — it means
firing again each time the record moves, because the whole point is a briefing that's actually
current, not a briefing that was current when it first ran. Re-firing on a message that changed
nothing is still noise; re-firing because something real changed is the job.

## What it reads

Only inside `workspace\projects\<name>\` and, for cross-references, `workspace\asa\`:

1. **The project's own note**, `<name>\<name>.md` — the frontmatter (`status`, `priority`,
   `deadline`, `milestone`, `next-step`, `updated`) and whatever prose sections the file actually
   has. Don't assume a fixed section list — `## Where it stands`, `## Tasks`,
   `## Open, needing a decision`, `## Parked`, `## Decisions`, and `## Roadmap` where one exists
   (ADR 0014) are today's shape, but a file's real sections win over this list if they differ.
2. **Every row in `## Open, needing a decision`.** If a row names an ADR, glance at that ADR's
   own `**Status:**` line and any `## Your call` section — say plainly if a decision the project
   is waiting on has actually been settled since the project note was last touched.
3. **`workspace\asa\BACKLOG.md`**, filtered to parked items whose trigger condition, read
   plainly, has now fired for this project.
4. **Existence only** of any `*.local.md` sibling file next to the project note (ADR 0018) — to
   say "an owner is set" or "no owner set yet," never to open it.
5. **When the project is `asa` itself** (or any session is about to reason about Asa the product
   or repo, not just Asa the project note) — **also read `asa\CLAUDE.md`'s own "Where we are"
   section.** It is the one file most likely to be trusted verbatim and least likely to be
   current, exactly because it describes the thing doing the describing. This is the specific gap
   that let the 2026-09-08 failure above happen, and it does not get to happen the same way twice.
6. **`decisions\`, swept for accepted decisions with no work behind them.** Read each file's
   **current verdict** only — not the whole decision. **The header `**Status:**` line is not the
   verdict and must not be read as one:** ADR 0011 made verdicts *append-only*, so a decision that
   was accepted still carries `proposed` in its header and records the real answer in an appended
   `## Your call` section below. **The last appended verdict wins; the header is only the answer
   when no verdict has been appended at all.** For every decision whose current verdict is
   **accepted**, check
   whether the project's own `## Roadmap` names a Round for it, or the decision's own file records
   that it shipped. **An accepted decision with neither is the highest-value thing in that folder
   and the easiest thing in the whole record to miss.**

   **Added 2026-09-13, for a failure this skill did not catch and should have.** `ADR 0007` —
   *Asa writes structured fields* — was accepted 2026-09-01 and found unbuilt twelve days later,
   by accident, because a session happened to notice its filename looked relevant before writing a
   duplicate decision on the same subject. **Item 2 above only looks at an ADR when a row in
   "Open, needing a decision" names it — so the moment a decision is accepted, it leaves that
   section and this skill stops looking at it entirely.** That is the blind spot: not a decision
   nobody recorded, a decision recorded, displayed, accepted, and then invisible. An accepted ADR
   reads as finished work at a glance, which is what makes it worse than an open one.

   **Corrected the same day this was added, on its very first real run.** The instruction first
   written here said to read the `**Status:**` header line. **Run against the real folder it
   produced three false positives immediately** — ADRs 0012, 0014 and 0015 all still say `proposed
   — needs the Boss's decision` in their headers and were all accepted on 2026-09-08 by appended
   verdicts, exactly as ADR 0011 specifies. A check that reads the header would have reported the
   doorman's own founding ADR as undecided. **Read the appended verdict.**

   **Bounded deliberately, because this edges toward the audit this skill is not.** Verdicts only.
   Name it and move on — never open the decision to summarise it, never chase whether the work was
   done *well*, never compare across projects. If that bound ever needs loosening, this has become
   the audit job and belongs to a different skill.

**The freshness check, every time, not just for `asa\CLAUDE.md`:** before repeating anything read
above as current fact, compare its own claimed date (an `updated:` field, a "Last updated" line, a
dated section heading) against harder evidence sitting right next to it — the most recent file
`mtime` in the same folder, the newest date in `decisions\`, the newest task checked off. **A claim
whose own date is older than evidence sitting beside it gets flagged, not repeated** — *"this file
says X, dated N days ago, but Y (dated more recently) suggests otherwise — worth a look before
trusting it."* This is still reading and surfacing, not auditing: doorman says what it found and
how much to trust it, it does not go looking for drift across files the way a full audit would.

**Never reads:** anything under `workspace\projects\<other-name>\` unless that project's own note
links to it directly (a `[[wikilink]]` or a named cross-project task), the Verbi Vault, any
`*.local.md` file's contents, or anything outside `workspace\`.

## What it surfaces, and in what order

Short. This is a briefing, not a report — if it's long enough to skim past, it has failed at
its one job.

1. **Status in one line** — `status`, `next-step`, and days since `updated`, humanised
   ("3 days ago," not a date subtraction).
2. **Anything in "Open, needing a decision"** — each row, and whether its linked ADR (if any) has
   actually been settled since the note was last touched. This is the single highest-value thing
   doorman can say, because it's the exact shape of failure ADR 0004 found: an answer sitting one
   file away from the question.
3. **Open tasks**, count only, not the full list — *"6 open, 2 completed"* — unless asked to show
   them.
4. **A fired parked item**, if any — named, with its trigger condition quoted back.
5. **An accepted decision with no work behind it**, if the sweep found one — the ADR's number and
   title, and the plain fact that nothing in the roadmap carries it. One line each, no summary of
   what the decision said. **Not optional when it fires**, for the same reason as the freshness
   flag below: this is the failure that already happened once, for twelve days.
6. **A freshness flag**, if the check above found one — the claim, its date, and the more recent
   evidence that contradicts it. This is not optional when it fires; a doorman that finds a stale
   claim and stays quiet about it is the exact failure this skill exists to end.

If none of the above has anything to say — a quiet, current project — say that in one line and
stop. **A doorman that pads a quiet project with filler trains the person to stop reading it.**

## The other end of a session

**Round 32/F.3.** Doorman only covers the start — nothing here fires at the end, and nothing
should. **The end has its own step, and it already exists: `HOW-ASA-WORKS.md`'s own "Before you
finish" section, in the project's own folder.** Point a session there rather than repeating it
here — doorman does not re-fire to check it, does not remind, and does not write anything at
close, same as everywhere else in this file (see "What this is not," above).

## Rules

- **Read-only, always.** If something looks wrong while reading (a stale date, a settled decision
  the note doesn't reflect) — say so as part of the briefing. Don't fix it. That's a different
  job, on purpose (see "What this is not," above).
- **Silence is a valid finding.** A project with nothing open and nothing stale gets a one-line
  "nothing open, last touched 2 days ago" — not padded to look thorough.
- **No hardcoded path — find the root by structure, not by memorising one.** `workspace\` is a
  shape, not an address (ADR 0006): a directory holding exactly three siblings named `asa`,
  `projects`, and `workshop`. Locate it fresh each time from wherever the session is actually
  working — walk upward from the current or connected folder until that three-sibling shape is
  found. **If that search finds zero matches, or more than one, stop and ask which folder is the
  real root rather than guess** — same rule `chief-of-staff` already uses ("ask when ambiguous. A
  wrong archive costs more than a question"). This is what makes the skill itself portable: a
  colleague running the same kit on a different machine, a different username, even a different
  drive letter, gets the same behaviour with nothing edited, because nothing in this file assumes
  where `workspace\` sits — only what it looks like once found.
- **Done when** (ADR 0012's own bar): it fires unprompted — whether in a fresh conversation
  or, for a session that never starts a fresh one, on its own inside a continuing one — and at
  least once catches one real stale or settled thing a session would otherwise have missed or
  assumed. **Corrected 2026-09-09:** "a fresh conversation" assumed a usage pattern that
  turned out not to be the Boss's real one — see `projects\asa\HOW-ASA-WORKS.md` and
  `ASA-LOG.md`, same date, for the mechanism that makes "unprompted, inside a continuing
  session" actually possible.
