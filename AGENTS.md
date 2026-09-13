# AGENTS.md — Asa

Read this first, in any tool, on any machine. It is the one file that does not assume Claude
Code. If you are `CLAUDE.md`, a Claude Code hook, or a skill, you point here for the reasoning;
this file is what stays true if the tool changes.

**Asa is the desk for Nico's vibe-coding projects.** It shows where every project stands, catches
ideas fast, and hands off to Claude with the context already in place. **Asa does not think.**
Claude reasons; Asa shows, routes, and queues. Full design reasoning: `ARCHITECTURE.md`.

**Why Asa exists, in Nico's own words:** so a session — this one, or the next fresh one on
another machine — does not have to hold everything in memory. The record is the point. If you
are reading this because you are a new session, that is exactly the situation this file exists
for.

---

## Find the workspace by shape, not by path

There is one workspace root, structured the same way on every machine:

| Folder | What it holds | In git? |
|---|---|---|
| `asa\` | This repo — the app and the kit. Shared. | Yes |
| `projects\` | Every project's own record: charter, plan, decisions, round notes. Nico's real work. | **Never** |
| `workshop\` | Scratch space. | **Never** |

A fresh session finds the root by this shape, not by a hard-coded path (ADR 0006, in
`projects\asa\decisions\`) — `%USERPROFILE%\workspace\` on Windows, wherever `workspace\` with
these three folders turns up elsewhere. If you cannot find this shape, say so rather than
guessing a path or creating a new one.

**The real record lives in `projects\asa\`**, not in this repo: `CHARTER.md` (why), `PLAN.md`
(what's next and why, appended to, not rewritten), `asa.md` (the project's own note — the
Roadmap and its checklist of Rounds), `ASA-LOG.md` (dated findings), `HANDOVER.md` (the spec
channel — every round's build instructions), and `decisions\` (one file per ADR, append-only —
see below). **The portable process tooling lives in `kit\`**, inside this repo: `PLAYBOOK.md`
(how sessions work), `KIT-LOG.md`, and `kit\skills\` (see "The doorman," below).

## Three roles, one rule

Three fixed roles, always:

- **The deciding session** — writes specs, decisions, and records. Never runs `git`, `flutter`,
  or a shell.
- **The building session ("Code")** — writes Dart/PowerShell, runs the machine check, commits
  only after Nico's yes. Never pushes.
- **Nico** — reviews, says yes or no. The only one who runs `git push`.

If you are a fresh session and unsure which role you're in, the tools available to you are the
answer: if you can run `flutter`/`git`, you are Code; if you cannot, you are the deciding session.

**The one rule that overrides urgency: no round ends until Nico has seen the result and said
yes.** Show → Ask → Commit, in that order. A commit before Nico has looked is a rule break, not a
shortcut — the one narrow exception is Nico explicitly pre-authorizing a commit before looking,
which gets logged as exactly that, not disguised as a normal yes.

## Gate 1 — the second-developer fork is one-way

If a second developer's fork exists (ADR 0010, `projects\asa\decisions\`): never fetch, pull, or
merge from her fork. Nothing of hers enters this repo. `lib/local/` stays empty here.
`lib/core/`'s public surface is a contract — treat it as one, don't break it to make her fork's
life easier.

## Gate 2 — no work data, ever

No VERBI systems, no company infrastructure, no colleague details, no customer or partner data —
in any file or conversation about Asa, ever. This extends to screenshots of the running app and
to real project `.md` files under `projects\`: don't read Nico's real project notes yourself to
verify a question if a throwaway/invented file can answer it instead. When a round needs to
"show" something working, use throwaway demo data, never real content, and delete the throwaway
folder after.

The API key (when Asa has one) never enters a committed file — entered on device, stored via
secure OS storage.

## The doorman

`kit\skills\doorman\SKILL.md` is meant to fire automatically, before any session reasons about a
project: it reads the project's own note, rows marked "open, needing a decision," `BACKLOG.md`
triggers, and sweeps `decisions\` for anything accepted but never built. **It only works if it is
actually installed** — a skill sitting in `kit\skills\` as a markdown file does not auto-fire; it
has to be copied into `.claude\skills\` (project scope, so it travels with `git clone`, and/or
user scope) via `kit\install-skills.ps1`. If something the doorman should have caught was missed,
check installation before theorising about the trigger — this exact bug has happened three times
in this kit's history (skills, then agents, then the doorman itself).

**When reading a decision file, read the appended verdict, never just the header.** ADRs are
append-only (ADR 0011): the `**Status:**` line at the top is written once and never updated: the
real, current call lives in a `## Your call` section appended below it. A decision can say
"proposed" at the top and be accepted for weeks — check the bottom.

## Feedback from another session

Feedback from another Claude session, another machine, or another tester goes to **GitHub issues
on this repository**. That channel already exists; no new mechanism is needed. A project's own
`FEEDBACK.md`, aggregated by `kit\collect-feedback.ps1` into `kit\FEEDBACK.md`, is the
project-local equivalent for issues found while working a specific project.

## Bringing a real, existing project into Asa

A folder under `projects\` that predates Asa — no note shaped like `asa.md`'s own frontmatter —
does not get a mechanical stub. **Asa does not think, so Asa does not write one.** This is Claude's
job, done with judgment, the same way this file and every decision in `projects\asa\` were
written: read what is actually there (a `CLAUDE.md`, a `README`, whatever notes already exist),
form an honest read of where the project really stands, and write a proper `<folder-name>.md`
next to it — real `project`/`status`/`priority`/`parent`/`deadline`/`jira` values where you can
honestly say them, `(not set)` left alone where you can't guess, a `## Tasks` section if real open
items are worth tracking. **Never invent a status you have not actually formed an opinion on**,
and never touch or delete anything already in the folder — this is one new file, added, not a
rewrite of what's there. Decided 2026-09-13, after a first pass proposed the opposite (Asa's own
UI creating a bare three-field stub) and Nico said no: *"how about let claude works on the notes
and make it into Asa properly there?"*

## Before you touch anything

Read the repo before proposing work for it — check `projects\asa\asa.md`'s Roadmap and
`HANDOVER.md`'s most recent entries for what round is already in flight before assuming day one.
Asa writes only structured fields, never prose (ADR 0007) — if you are Code and asked to make Asa
write something, check that ADR's whitelist first. That rule is about Asa's own code; it does not
apply to you reading and writing a project's own note directly, which is ordinary file editing,
same as the section above.
