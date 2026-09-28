# DRAFT — proposed v1.27 — not released

**Nothing has been bumped.** `VERSION` still reads **1.26** and `CHANGELOG.md` is untouched. This
file is a draft written by the daily sweep on 2026-09-22 for the Boss to accept, rewrite or delete.
If it is accepted, its body moves to the top of `CHANGELOG.md` and `VERSION` changes there — not
here.

## Why a version is due — which criterion, and which one does not apply

**b) the rule of two — met.** `PLAYBOOK.md` §14. **A convention was changed in a project note,
with its reason given in passing, in two unrelated projects three weeks apart.** On 2026-09-01 a
decision format was changed and the reason written at the bottom of the note; a second session
recommended the opposite an hour later, unaware. That is the incident `FEEDBACK.md` exists because
of, and it is quoted in that file's own header. On 2026-09-21 a new project note settled how two
overlapping projects divide ownership and gave the reason in one line, inside the note — visible
only to a session that opens that exact file. **Second sighting, unrelated project, same shape.**

**a) three or more findings since the last version entry — met in substance, and the honest
version is worse than the count.** Eight clean findings are sitting in five project folders,
uncollected. **Five of them predate v1.26 and were never in it**, because the channel that carries
them has not run since 2026-09-01. Two further findings were added by today's sweep. Ten in total
are waiting.

**c) something that loses data, leaks something private, or misleads a person — not newly
triggered, and worth saying plainly rather than borrowing.** The one finding of that kind
(a realistic personal name and address written into a project note) was answered the same hour it
was raised, on 2026-09-02, by `check-notes.ps1`. A read-only re-run across every project note today
returns **zero hits**. **Nothing is leaking.** What is true is that nothing ever calls that script
— see below — which is a gap in firing, not an incident.

## Proposed changes — three, and only the third prevents rather than detects

- **The feedback channel gets something that makes it run.** Rule 18 says *run it before a commit*
  and nothing enforces that. `kit\FEEDBACK.md` holds one line, written on the day the channel was
  built; eight more have been publishable and stationary for three weeks. Nothing was ever held
  back — the vetting has never once had to refuse a line. **A channel enforced by memory is a
  channel with one user and no schedule.**

- **`check-notes.ps1` gets a caller.** Written 2026-09-02 with a self-test and an honest header
  about the one thing it cannot detect, and named, three weeks later, in exactly one place in the
  entire workspace: the `FEEDBACK.md` line that records writing it. Not in a hard rule, not in the
  playbook, not in a hook, not in another script. **This is the third time this kit has produced a
  correct artefact that nothing fires** — after `install-skills.ps1`'s `$coreSkills` gap and the
  doorman with no session type that could reach it. *Installed is not fired*, again, one level
  further out.

- **The sweep for unlabelled feedback becomes part of the process, not a thing a reader happens to
  do.** Both of this cycle's best findings were conventions changed in passing inside a project
  note, and **neither was written as feedback by the session that changed it.** The existing rule
  already calls that case mandatory. What is missing is anything that looks. *This is the only one
  of the three that attacks the lossy step: a person deciding something and recording it where the
  decision happens to be, which is never where the next session looks.*

## What is deliberately not in this draft

No re-ranking of `ROADMAP.md`'s existing items, and no new work invented that nobody reported.
Three rows were added — two to `Next`, one to `Later` — each carrying one line saying why it sits
there.
