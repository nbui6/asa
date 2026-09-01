# Start here

**A kit for building real software with an AI assistant, without ending up with something that
works and nobody understands.**

You do not need to be a developer. You do need to be willing to run commands and look at the
results yourself.

---

## The one rule

> **You run the code. You look at the result. A summary from the assistant is not evidence.**

Everything else in this kit exists to support that. If you only take one thing, take this: the
moment you start accepting "it works" without seeing it work, you own a black box, and a black
box cannot be changed, fixed, or handed to anyone.

---

## What you need before you start

| | |
|---|---|
| **Claude Code or the Claude desktop app** | Where the assistant runs |
| **Git** | Save points. Non-negotiable — it is what makes mistakes cheap. |
| **A terminal you are willing to open** | PowerShell on Windows, Terminal |
| **Roughly an hour** for your first session | Later sessions can be 30 minutes |

You do **not** need to know a programming language, a framework, or what a compiler is. You will
pick up the vocabulary as you go — `GLOSSARY.md` has every term in one line each.

---

## Your first 30 minutes

Do these in order. Do not skip 0 or 1.

**0. Write `BOSS.md`** from `templates/BOSS.md` — five minutes, half of it guessed. It is what
stops every explanation being generic, and it grows from your own corrections. Lives once, next to
your projects, not per project.

**0b. Install the skills** so the assistant can actually load them:

```
powershell -NoProfile -ExecutionPolicy Bypass -File install-skills.ps1
```

Then restart Claude Code and run `/skills` to confirm. **This is not optional and it is easy to
skip** — the kit ran for three days with 24 skills that nothing could read.

**1. Read `PLAYBOOK.md` §1 and §3.** Two pages. It tells you what the five stages of a session
are and how to know where you are. Everything else in the playbook can wait until you need it.

**2. Start a session and say this:**

> I want to build something. Use the `discovery` skill to interview me, then write
> `CHARTER.md` from my answers. Don't write any code yet.

The assistant will ask you questions — what problem, for whom, what happens if you don't build
it, what the smallest useful version is. **Answer honestly, including "I don't know".** An
"I don't know" written down as an open question is worth more than a confident guess.

**3. If you have more ideas than one project, before choosing anything:**

> Use the `roadmap` skill. Here is my list of ideas — group them, rank them, and give me a
> Now/Next/Later plan.

Scattered ideas are usually features of one product rather than competing projects. Ranking them
keeps the map; picking one throws it away.

**4. Then:**

> Now use the `stack-choice` skill. Recommend a technology for this, and tell me what it costs
> me in setup time and in things I will have to learn.

**5. Then:**

> Cut this into milestones with checkpoints. Then set up day one from `PLAYBOOK.md` §2, and
> write `ARCHITECTURE.md` using the `architecture-map` skill — even three lines.

The architecture map takes twenty minutes now and days later, and it is what keeps the project
navigable by a human, and by an assistant, once it is bigger than one screen.

At the end you have a repo, a charter, a project memory file, a backlog, a README, a persona,
and one command that says pass or fail. **That is the foundation. Nothing after this is as
important.**

**6. Make your project hub** — copy `templates/PROJECT-HUB.md` into your notes and fill in three lines:
what you are working on, what is waiting on you, and links to your projects. It is a note, not an
app. **This is the file you open first, every time.** One line changes per session; that is the
only maintenance it gets.

**7. If it will have more than two screens, see the whole thing before building any of it:**

> Use the `sketch-the-product` skill. Draw every screen this product would have as one
> clickable mockup with fake data. Label each screen: exists today, designed, or named only.

You get a picture you can argue with. **Say no to it if it is wrong** — that is the entire
purpose, and it is the last moment saying no is free.

**8. Then run your first real session** using the five stages. `PLAYBOOK.md` Appendix A has the
exact sentence to paste at the start.

---

## What is in this kit

| File | What it is for | When you read it |
|---|---|---|
| `START-HERE.md` | This | First |
| `CHANGELOG.md` | What each version changed, and what is **not** tested yet | Before trusting anything |
| `SKILLS.md` | All 24 skills, and which have ever actually fired | When a skill you expected did not fire |
| `install-skills.ps1` | Puts the skills where Claude Code loads them | Once, and after every kit version |
| `ROADMAP.md` | The 13 steps analysed, and every gap ranked Now / Next / Later | When deciding what to do next |
| `PLAYBOOK.md` | The session process, the code rules, the agent team | §1 and §3 now, the rest as needed |
| `GLOSSARY.md` | Every term, one plain line | Whenever a word stops you |
| `SCALING.md` | How to build it so it can grow — structure now, features later | Day one, then at checkpoints |
| `templates/` | Files you copy into your project and fill in — **project hub**, **round**, project home, charter, roadmap, toolchain, architecture, ADR, business case, persona, README, backlog, CLAUDE, **BOSS** | Day one |
| `skills/` | Instructions the assistant loads for specific jobs | The assistant picks them up automatically |
| `skills/_installable/` | The same skills, packaged. Save one from a file card to keep it permanently. | When you want a skill available in every session |
| `agents/` | Separate reviewers with their own context | Copy into `.claude/agents/` |
| `KIT-LOG.md` | What the process got wrong, session by session | At retrospectives |

### The skills, and when each fires

| Skill | Fires when |
|---|---|
| `discovery` | Before anything exists. Interview → charter. |
| `research` | Before deciding anything that rests on a fact — does it already exist, what is current, is that number real |
| `stack-choice` | Choosing the technology, or questioning one already chosen |
| `toolchain-map` | Naming which tools the project runs on, what each owns, and which kit skills apply |
| `persona-check` | Any screen, before it is built and again after |
| `data-and-secrets` | Any API key, any personal data, before the first commit, before sharing or selling |
| `first-test` | You need a command that says pass or fail and don't know how |
| `debugging` | Something breaks and the second attempt failed |
| `roadmap` | You have more ideas than you can build, or need to know where everything stands |
| `design-system` | More than two or three screens, so features look like one product |
| `business-case` | You need management to say yes — budget, time, or a developer |
| `obsidian-docs` | Deciding where project documents live, and stopping them drifting |
| `ship-it` | The thing works on your machine and someone else needs it |
| `onboarding-docs` | Someone else has to read or run your project |
| `process-audit` | Your skills and process documents have grown, or two of them disagree |
| `kit-feedback` | End of any session — what the process itself got wrong |
| `inherit-codebase` | Taking over code you did not write, including your own after months away |
| `sketch-the-product` | **Before the first feature** of any product with more than two screens — stage 0 |
| `explain-as-we-go` | Always on, if you want to understand what you are building. **Reads `BOSS.md`** — who is being taught. |

**Scaling skills** — see `SCALING.md` for when each one starts:

| Skill | Fires when |
|---|---|
| `architecture-map` | Day one, and whenever a new part is added |
| `module-contract` | Adding the second module, or splitting a growing one |
| `regression-gate` | The first bug that comes back |
| `non-functional` | Before the first real user, and before money is involved |
| `team-review` | A second person joins the repo |

### The agents

Copy `agents/*.md` into `.claude/agents/` in your project.

| Agent | Runs |
|---|---|
| `reviewer` | End of every build, before you test. The highest-value one by a distance. |
| `note-taker` | End of every session |
| `stack-review` | Monthly, or at a checkpoint |

---

## If it ever feels heavy — the three doors

The kit has many parts on purpose. **You never hold them all.** Think of a car: thousands of
parts, three controls.

| Door | You open it when | What it is |
|---|---|---|
| **The session** | You sit down to work | One sentence you paste — Appendix A of `PLAYBOOK.md`. **You never choose a skill**; triggers do that. |
| **The project** | You want to know where one project stands | `templates/PROJECT-HOME.md` — one note, links to everything else |
| **The system** | You want to see all projects | One dashboard note, or a Bases view over the project notes |

The skill list exists so you can **audit** the team, not so you can operate it.

**The distinction worth knowing** — from Fred Brooks, *No Silver Bullet*:

- **Essential complexity** is in the problem. Removing it loses something. Keep it.
- **Accidental complexity** is bad arrangement. Cut it.
- **Essential but hideable** — genuinely complex, but nobody should hold it. **Put a door in
  front of it.**

> If the system feels heavy, the fault is a missing door — not too many pieces.

---

## What this is not

**Not a replacement for thinking.** The assistant is fast at producing code and has no opinion
about whether the code should exist. That judgement stays with you, which is why discovery comes
before the stack and the stack comes before the code.

**Not a guarantee.** Published research finds AI-generated code carries more security
vulnerabilities and more duplication than human-written code, and that teams adopting it see
higher delivery instability. This kit is built around those findings — the reviewer agent, the
`data-and-secrets` skill, the handover check and the machine check all exist because of them.
It reduces the risk. It does not remove it.

**Not the only approach.** GitHub's **spec-kit** covers similar ground for the
specification-to-code path and is worth knowing about. What this kit adds: the human-verification
discipline, a user-fit check that no mainstream framework has, the teaching layer, and the phases
before and after the code — discovery at the front, shipping at the back.

---

## When you are stuck

| Symptom | Go to |
|---|---|
| "I don't know what I'm building" | `skills/discovery` |
| "I don't know which technology" | `skills/stack-choice` |
| "Which tools are part of this, and who does what?" | `skills/toolchain-map` |
| "Does this already exist? Is that claim true?" | `skills/research` |
| "I don't understand a word" | `GLOSSARY.md` |
| "I don't know where I am" | `PLAYBOOK.md` §1 |
| "It broke and I tried twice" | `skills/debugging`, and read the two-strike rule in `PLAYBOOK.md` §4 |
| "Will this still work when it's ten times bigger?" | `SCALING.md` |
| "I have twenty ideas and don't know what to build first" | `skills/roadmap` |
| "Am I allowed to do this with company data?" | `skills/data-and-secrets` |
| "Management needs to approve this" | `skills/business-case` |
| "It works but I don't understand it" | Say so. That is the assistant's failure, not yours. Ask for it explained differently, or for a simpler version. |


---

## Sharing this kit

**It has now been shared once**, so this is a procedure rather than a plan. `package-for-tester.ps1`
does the mechanical half: it excludes the author's own files, replaces names, blanks the product list
in `check-boundaries.ps1`, packs, and then **reads every text file back out of the archive** and
refuses to ship if anything private survived. It deletes the zip on failure so it cannot be sent by
accident.

| # | Do | Why |
|---|---|---|
| 1 | Run `package-for-tester.ps1` | The sweep that reads the *folder* is not the check. What ships is the *archive*. |
| 2 | Send `HANDOVER.md` as page one | Which two files to read, which not to, and the known limits — so nobody spends an hour proving something already known |
| 3 | Give them **one file to send back**, not a request for feedback | Nobody writes a kit log unprompted. That is what `FEEDBACK.md` is. |
| 4 | Say what is untested, and do not say what is planned | Limits stop wasted time. Plans stop honest findings — a tester who knows the roadmap stops reporting what is missing. |
| 5 | **Answer the ownership question first** | Whether work built at your job is company property is an **HR and contract question**. Do not guess it in either direction, and do not let an assistant guess it for you. |

Row 5 is not a formality. It is the only one that can go wrong in a way that matters, and the only one
you cannot delegate.
