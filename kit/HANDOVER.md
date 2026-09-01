# For the tester — read this one page, then start

You have been given a **Vibe Coding Kit**: a process, plus a few scripts, for building software with
an AI assistant. The version is in the `VERSION` file. It has been used on exactly one real project, by one person.
**You are the first outside test.** Everything in it is meant to be argued with.

**The two promises it is trying to keep:** you always know where you are, and nothing in the result
is a black box to you.

---

## Before you start — 5 minutes

| | |
|---|---|
| **What you need** | **Windows**, Claude Code, git, PowerShell. The four scripts are Windows-only and this version is not trying to be anything else. |
| **What to build** | Something small and real that you actually want. **Not work data** — pick a personal project. One or two screens is plenty. |
| **How long** | One sitting of 1–3 hours gets you through the first round. |

**Install the skills and agents** — this puts them where Claude Code can load them:

Unzip it somewhere sensible, **open PowerShell in that folder** (Shift+right-click → *Open PowerShell
window here*), and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File install-skills.ps1 -Core
```

Then restart Claude Code. `-Core` installs the 14 skills that have fired on real work and **names the
10 it leaves out**. Drop `-Core` to install everything.

### Then give your assistant this, as its first message

The kit expects a **workshop** to exist: two files, beside the kit, that describe *your machine* and
*you* — as opposed to the kit (how anyone builds) or a project (what one thing is). It does not exist
yet on your computer, and nothing will create it unless somebody asks.

```
Read HANDOVER.md, then START-HERE.md, then PLAYBOOK.md section 3 and section 14.

Then create the workshop for me: a folder next to the kit holding MACHINE.md and
BOSS.md, from templates/MACHINE.md and templates/BOSS.md.

Fill in MACHINE.md by actually checking this machine - OS, shell, what is and is
not installed, versions with today's date. Do not copy anything from documentation:
if you have not run it, it does not go in.

Fill in BOSS.md with what you already know about me - from your memory, from
anything I have set up in Claude Code, from how we have worked before. Do not
leave it empty and do not invent.

Mark every line with where it came from: [known] for something you have actually
seen me do or say, [guess] for anything you are inferring. I will delete the
wrong ones - that is faster for me than writing it from scratch, and a marked
guess is safe because it can be checked.

Then ask me at most three questions, about the things you could not mark either
way. Then tell me what you found, and we will start.
```

**Why this matters more than it looks.** Without the workshop, facts like *"no admin rights on this
laptop"* or *"this shell has no `??` operator"* land inside whichever project happens to be open, and
the next project re-learns them from scratch. **If your assistant proposes an install that fails
because of something it should already have known, that is a workshop that was never written.**

**Optional, in a git repo you are working in** — the hooks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File hooks\install-hooks.ps1 -Project .
```

---

## Then read exactly two files

1. **`START-HERE.md`** — the map. Ten minutes.
2. **`PLAYBOOK.md` §3** — the five stages of a session, and the two before them. That is the process.

**Do not read the rest.** `SKILLS.md`, `KIT-LOG.md` *(kept by the kit author, not shipped)*, `GLOSSARY.md` and the rest are reference — you
look things up in them when something does not work. If you find yourself reading the whole kit before
building anything, **that is a finding**, and it goes in the feedback.

---

## What we actually want to know

Not whether you liked it. **Where it got in your way, and where you ignored it.**

The three most valuable things you can report, in order:

| | |
|---|---|
| 1 | **A step you skipped**, and why. Skipped steps are the strongest signal in the whole test — a step that gets skipped is either wrong, badly placed, or badly explained. |
| 2 | **A moment you were stuck or lost.** What you were trying to do, and what you tried. |
| 3 | **A sentence you did not understand.** Quote it. The kit is written for someone who is not a professional developer; if a sentence assumes otherwise, that is a defect. |

**Fill in `FEEDBACK.md`** — it is a form, it takes ten minutes, and it is designed so that vague
answers are hard to give. Send it back with the file.

---

## Two things worth knowing before they surprise you

**The kit will tell you to do things that feel like overhead.** Writing acceptance criteria before
code, sketching screens before building them, getting a plan signed. Some of that will be worth it
and some will not — **and the whole point of you testing it is to find out which.** Follow it as
written the first time, including the parts you disagree with, and write down the disagreement rather
than quietly skipping it. Then skip it the second time if you still think it is wrong.

**It is opinionated and some of the opinions are wrong.** They were formed on one project, on Windows,
building a Flutter app, by one person with one working style. If something is obviously wrong for how
you work, say so plainly. *"This is written for someone who is not me"* is a completely valid finding.

---

## Known limits — read before you hit them

**These are the things we already know are missing or weak.** Listed so you do not spend an hour
proving one of them.

| | |
|---|---|
| **Windows only** | The four scripts are PowerShell and assume Windows. Not a limitation being worked around — this version simply targets one platform, and everything they do can also be done by hand. |
| **The agents have run once, in a different tool** | `reviewer`, `note-taker`, `stack-review`. They install, they are wired, and **almost nothing about them is proven.** If yours behaves oddly, that is new information. |
| **The kit is opinionated about one workflow** | Claude Code, git, a laptop, a person who is not a professional developer. The further you are from that, the more of it will be wrong. |
| **The workshop has to be created** | See above. Nothing does it for you. |
| **10 of the 24 skills have never fired on real work** | Named by the installer when you use `-Core`. Their triggers are guesses. |
| **`check-boundaries.ps1` will always say "clean"** | It checks that the kit contains no *product* names, and its list ships empty for you to fill in. Useful once you have a product name to protect; until then it has nothing to look for. |

**What you will not find here is a list of what is planned next, and that is deliberate.** If you knew
what was already on the roadmap you would stop reporting those things — and *"this is missing"*
arriving independently from you is worth far more than a nod at a plan. **Report it even if it seems
obvious.** Especially then.

## When a new version arrives — what to keep, what to replace

You will get a new version after your feedback comes back. **Nothing you have made gets thrown away**,
as long as you keep the line clear between the two:

| Yours — an update never touches it | Ours — replaced wholesale every version |
|---|---|
| **Your project repo.** Code, `CLAUDE.md`, rounds, decisions. | Everything inside the kit folder |
| **Your workshop** — `MACHINE.md`, `BOSS.md`, beside the kit, **not in it** | |
| **Your `FEEDBACK.md`** — copy it out before you replace anything | |
| `check.json` in your repo's `.claude\hooks` — the installer never overwrites it | |

**One thing the manifest cannot help with: files you copied *out* of the kit.** A template copied
into your project, or a rule pasted into your project's `CLAUDE.md`, is now yours — the installer
cannot see it and will not update it. **Every version's changelog carries a section saying which
copied-out files changed**, so you can decide one by one. That section is the one to read first.

**Do not edit the kit's own files.** It is tempting and it is the one thing that makes updating
painful — your change is silently gone at the next version. **If you want something changed, write it
in `FEEDBACK.md` instead.** That way it comes back to you as part of the kit rather than as a patch
you have to reapply. If you already edited something, say which file: otherwise it is lost and neither
of us will know.

### The guarantee

> **The installer never creates, modifies or deletes a file it did not place.**

It can promise that because it writes **`.kit-manifest.json`** — the version, and a SHA256 for every
file it installs. On the next run it compares three things: what the kit has now, what the manifest
says it put there last time, and what is actually on disk. That is what separates *you edited this*
from *the kit changed this* from *this was never ours*.

**So a re-run tells you exactly what it did:**

```
  unchanged        14
  updated           3
  new               2

  YOU EDITED THESE - kept, not overwritten (1):
    debugging/SKILL.md
    Your version is still there. Re-run with -Force to take the kit's,
    or move your change into the kit so it survives the next upgrade.

  no longer part of the kit, left on disk (1):
    ship-it/OLD-EXTRA.md
```

**A file you edited is never silently replaced**, a skill of your own is never touched, and a file
dropped from the kit is **named but not deleted** — it is not the installer's to remove.

**`-DryRun` reports all of that and writes nothing**, including the manifest. Run it first if you
want to see an upgrade before taking it.

**The update, in four steps:**

1. Unzip the new version **beside** the old one, not over it. Keep the old folder until you are happy.
2. Copy your `FEEDBACK.md` across, and keep your workshop where it is.
3. `install-skills.ps1 -Core -DryRun` to see what would change, then the same without `-DryRun`.
   Then **restart Claude Code**.
4. In each repo using the hooks: `hooks\install-hooks.ps1 -Project .` again. Your `check.json`
   survives.

**In the gap while you wait for a version: just keep working with the one you have.** Findings from an
older version still count — and a complaint that survives a version is the strongest kind there is.

## Two files you will not find in here

**`KIT-LOG.md` and `ROADMAP.md` are not shipped.** The log is the kit author's own record of failures,
with names and half-finished products in it; the roadmap is what is planned next, and **a tester who
knows the plan stops reporting what is missing.** The reasoning behind each rule is quoted inside
`PLAYBOOK.md` where the rule lives, so nothing you need is in the files you cannot see.

## What happens to your feedback

It comes back, gets read, and turns into a new version of the kit — with your findings recorded and
dated in `KIT-LOG.md` *(kept by the kit author, not shipped)*. Then you get the new version and we do it again. **Nothing gets changed on the
strength of one comment: the kit's own rule is that a change waits until something has been seen
twice.** So repeating a complaint is not nagging, it is the mechanism.
