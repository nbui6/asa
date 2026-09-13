# Skills — all 27, and which ones are real

**27 skills exist. 16 have ever fired.** This file exists so that number is visible instead of
implied, and so the dormant ones can be judged rather than quietly trusted.

*Corrected 2026-09-13: this said 26/15. `doorman`, added 2026-09-08, was never counted here — it
had already fired twice (see below) by the time anyone checked the real folder count against this
file's own header.*

Nothing is deleted here. A skill with a written trigger that has not fired yet is different from
a skill nobody can find a use for — and the difference is what this file records.

> ### Correction, 2026-08-24
>
> **These skills had never been installed anywhere Claude Code could load them.** No
> `~/.claude/skills`, no project `.claude/skills`. Every "fired" below happened in a **Cowork**
> session, where skills come from the conversation rather than from disk.
>
> Fixed by `install-skills.ps1`. The counts are still true — they were just measuring one of the
> two places the kit runs.

> **Read this once, then only when a skill fails to fire.** You do not memorise 27 skills. The
> assistant loads them; you check this file when something you expected did not happen.

---

## The 16 that have fired

These are proven on real work. If you only ever use these, the kit still works.

| Skill | Fires when | Fired on |
|---|---|---|
| `discovery` | An idea exists and nothing is written down | Day one of two projects |
| `roadmap` | More ideas than one project's worth | A pile of scattered ideas |
| `stack-choice` | Technology not chosen yet | Flutter, and the Obsidian-vs-build decision |
| `research` | A claim would otherwise be a guess | Vibe-coding practice, Obsidian plugin state |
| `architecture-map` | The second source file exists | Asa's three layers |
| `first-test` | New logic with rules in it | Found the parser bug |
| `debugging` | Something behaves wrongly twice | Located a missing file in one exchange |
| `persona-check` | Round criteria touch a screen, and again before a human tests | Asa's UX review — verdict: block |
| `sketch-the-product` | A product with more than two screens | This kit's newest stage |
| `kit-feedback` | Every session ends | Every entry in `KIT-LOG.md` |
| `explain-as-we-go` | Session start, and at the named moments | Continuously |
| `obsidian-docs` | Documents live in a vault | The vault layout |
| `toolchain-map` | The second tool joins | Obsidian / VS Code / Claude Code / Asa |
| `process-audit` | Process documents have grown | Found nine real defects |
| `ship-it` | Something leaves the builder's machine | The first packaged copy, 2026-08-26. Found that the package had not been checked the way it claimed. |
| `doorman` | Before any session reasons about a project — reads its note, `BACKLOG.md`, and sweeps `decisions\` for accepted-but-unbuilt | Caught ADR 0007 (accepted 2026-09-01, unbuilt for twelve days) via its own decisions-sweep, 2026-09-13; then caught a bug in its own header-vs-verdict check on that same sweep's first run |

Sixteen rows, not nine — `kit-feedback`, `explain-as-we-go`, `obsidian-docs`, `toolchain-map` and
`process-audit` fired after the count of 9 was taken, `ship-it` fired on 2026-08-26, and `doorman`
fired twice on 2026-09-13, the day it was finally installed somewhere Claude Code could load it
from (see the correction note at the top of this file).
**The honest count today is 16 of 27.**

### Two added 2026-08-31, from the first outside test

| Skill | Fires when | Why it exists |
|---|---|---|
| **`sketch-the-screen`** | One screen's **structure** is about to change — mid-build, not at project start | The gap between `sketch-the-product` (once, at the start) and the code. **The tester invented it herself out of frustration; this project improvised the same step in the same week.** Two independent inventions of a missing step. |
| **`counter-proposal`** | A technical approach has been proposed and **nobody disagrees with it** | Every other review here asks *is this right for the user*. **None asks whether a competent engineer with different priorities would build it cheaper.** On a team that person turns up uninvited; on a solo project the review never happens. |

**Both have narrow, named triggers on purpose** — see `PLAYBOOK.md` §14, *a trigger that fires on
everything fires on nothing*.

### Triggers narrowed the same day

Two skills claimed unbounded triggers, and one of them is the only skill that has now **failed to
fire on its own job in two unrelated projects**:

| Skill | Was | Now |
|---|---|---|
| `persona-check` | *"whenever UI or UX is being designed, described, mocked up, wireframed or built"* — twenty or thirty moments a session | **Two named moments**: when the round's acceptance criteria are written, and again before a human tests it |
| `explain-as-we-go` | *"throughout any hands-on technical work"* | Session start, plus named moments: the overload phrases, a decision being put to the Boss, handing over code they will maintain |

**The first count of this audit said twenty of twenty-four.** It had searched for the word
*"whenever"* rather than the shape of the moment. **Two is the real number** — *"whenever a bug comes
back"* is a fine trigger, because bugs do not come back thirty times a day.

> ### A 25th skill was added on 2026-08-26 and removed the same day
>
> `content-pack` — how to design the file format for reference content that ships inside a product.
> Useful, fired immediately, and **the wrong library.** It is knowledge about *a product's content
> system*, not about *how to build products*, and the Boss caught it in one sentence:
>
> > *"This skill is for the product the kit produces. But the kit should be able to support this
> > skills systems or ideas to make the product possible."*
>
> It now lives in the product's own repo, at `.claude/skills/content-pack/`, where it is committed
> with the code it describes. See `PLAYBOOK.md` §14, **Two libraries** — the rule that was missing,
> and the reason a product skill defaulted into the kit: **the kit had a path upward and none
> downward, so everything invented anywhere ended up here.**

---

## The 10 on standby — trigger written, has not fired

Not dead. Each has a moment it is waiting for, and the moment has not arrived on a real project.

| Skill | Waiting for | Honest assessment |
|---|---|---|
| `data-and-secrets` | The first API key, or the first personal data | **Downgraded 2026-08-26.** The reason given here — *"the assistant app needs a key on device"* — stopped being true when that plan was cut. It has no key and no account. Now waiting on round 6, where a share-intent package asks for a storage permission a text app should not need. |
| `regression-gate` | The first bug that gets fixed twice | **Will fire.** Only a matter of time. |
| `module-contract` | The assistant app's module seam | **Will fire.** It is that project's next step. |
| `non-functional` | Accounts, permissions, backups, monitoring | **Will fire** if anything is ever used by a second person. Not before. |
| `design-system` | The third screen that must match the first two | Asa has two screens. Close. |
| `onboarding-docs` | Someone else needs to run it | Fired once on the assistant app's README; dormant since. |
| `business-case` | Something needs approval or money | **Waiting on a real trigger** — the "one customer record" feature is the first candidate. |
| `inherit-codebase` | Taking over code someone else wrote | No such project exists yet. |
| `team-review` | A second person commits to the same repo | **Blocked, not waiting** — there is no second person, and no plan for one. |

---

## The 3 agents — 0 have ever run

| Agent | Should run | Runs so far |
|---|---|---|
| `reviewer` | Before every commit | **0** |
| `note-taker` | End of a round | **0** |
| `stack-review` | At checkpoints | **0** |

> ### Decided, 2026-08-25 — hook them, and here is where
>
> The question stopped being *"hook them or delete them"* the moment the wiring was drawn. **All
> three are connectors with nothing attached to the far end** — not idle, unattached:
>
> | Agent | Belongs to | Why it never ran |
> |---|---|---|
> | `reviewer` | **Step 11**, between Build and Test | Step 11 has no skill and leaves no trace. There was nothing to attach to. |
> | `note-taker` | The **report** job of the loop | That job did not exist until 2026-08-25. |
> | `stack-review` | **Conformance**, over the Design phase | Same. |
>
> All three connections are on the roadmap as `Next` item 4. Nothing is deleted.

**Three rounds of real work went past without one firing.** That was the oldest unexamined fact in
the kit. Two readings were written down for the next retrospective to choose between:

1. The trigger is written but nothing enforces it — the fix is a **hook**, not a firmer
   instruction. `PLAYBOOK.md` §11 already says this and it has not been done.
2. The work an agent would do is already happening inline, in which case the agents are
   duplication and should be deleted.

> ### Reading 0, found 2026-08-26 — they were never installed
>
> Neither of the two readings above was the answer, and the answer took one `ls`.
> **`.claude/agents` did not exist**, in the project or in the user profile. `install-skills.ps1`
> refused to create it, and said why in a comment:
>
> > *"Agents are deliberately NOT installed. 0 of 3 have run in five rounds and the open decision
> > is hook them or delete them."*
>
> The non-installation was manufacturing the evidence used to justify it. A subagent runs when it
> is invoked, and an uninstalled one cannot be invoked at all — so "0 runs" measured the installer,
> not the agents.
>
> **This is the same bug the installer itself was written to fix**, one folder over. The header of
> that script has recorded since 2026-08-24 that the kit had *"24 skills in a notes folder and
> Claude Code had none"*. The fix was applied to `skills/` and not to `agents/`.
>
> **The rule this earns:** *when something has never fired, check that it is installed before
> theorising about its trigger.* Two plausible explanations were written and neither was checked
> against the filesystem, because both were more interesting than the boring one. Cost: three
> rounds, and one open decision that was never actually open.
>
> Fixed the same day — the installer now copies `agents/*.md` into `.claude/agents` and prints
> them by name. Verified: 14 skills + 3 agents into a clean folder, all three listed.
>
> **Runs so far is still 0**, and now that number means something. `reviewer` is an acceptance
> criterion of the German app's round 3.

---

## Retirement rules

A skill earns its place or goes. Three rules, checked at retrospectives:

0. **Reachability first.** A dormancy count only counts if the thing was installed in a path the
   tool reads. Check that, then apply the rules below. *Added 2026-08-26, after three agents were
   judged for six rounds on a zero produced by their installer.*
1. **No trigger, no skill.** If nobody can name the moment it fires, it does not fire. Delete it.
2. **Two checkpoints dormant with a live trigger** — the trigger is wrong, not the skill. Rewrite
   the trigger once. If it stays dormant after that, delete the skill.
3. **Never delete because a session was busy.** Dormant is a measurement over time, not a mood.

**Nothing is retired in v1.0.** Every dormant skill above has a trigger that is plausibly still
ahead. First retirement review: the next checkpoint.

> ### Boundaries drawn, 2026-08-25
>
> The mapping onto the 13 steps found **six clusters** where two or three skills could fire on the
> same sentence, and exactly one description — `discovery` — that named a sibling and handed off.
>
> **13 descriptions now carry that line.** Each says which neighbour owns the job it does not:
> `discovery` ↔ `persona-check` ↔ `roadmap` · `sketch-the-product` ↔ `persona-check` ↔
> `design-system` · `research` ↔ `stack-choice` ↔ `toolchain-map` · `architecture-map` ↔
> `module-contract` · `first-test` ↔ `regression-gate` · `ship-it` ↔ `onboarding-docs`.
>
> One real duplicate was removed: `first-test` and `regression-gate` both claimed *"a bug that
> should not come back"* in near-identical words. `regression-gate` owns it; `first-test` owns
> creating the first check.
>
> **Standing cost of all 24 descriptions: ~3,550 tokens, up ~150.** The overlap cost nothing in
> tokens and everything in quality — on 2026-08-25 `persona-check` lost the *"design me a screen"*
> sentence to `sketch-the-product` three times and never fired.

---

## Why not just ship the ones that have fired?

**You can, and by default you should: `install-skills.ps1 -Core`.** It installs the skills that have
fired on real work and **names the ones it leaves out**, so nothing is silently missing.

The dormant ones stay in the package rather than being deleted, because a trigger that has not
happened yet is different from a trigger nobody can name — and this file is the map for the day one of
them fires wrongly. But **someone else's first hour should not be spent on untested things**, which is
what `-Core` is for.
