# Changelog

**A released version stops being editable.** Before v1.0 this kit was a folder that changed
whenever something was learned. From v1.0 on, changes wait for a version — because feedback about
a kit that no longer exists is useless, and that is true even when the only user is you.

Versions are dated. The current one is at the top.

---

## v1.26 — 2026-09-04 — the drawing, the spec, and which one wins

**A screen was built twice against something the Boss had not agreed to, and both rounds obeyed
their instructions.** Full audit in the kit's own project folder,
`ANALYSIS-2026-09-04-built-the-wrong-version.md`. The short version: **the spec never contained the
design, and then the design was used as the acceptance criterion.**

Of eight reported "differences", **zero were the building session disobeying anything.** Seven were
the spec being silent about form — it said *"each row — title, status, date"*, which is data, not
layout. **The eighth was the build obeying the spec** (*"the provenance block stays below both,
unchanged"*) while the drawing showed no provenance block at all, and the review calling that
obedience a defect.

**Changed — six fixes, and only the last one prevents rather than detects**

- **`templates/SESSION-HANDOVER.md`: which document wins, declared.** *The prose owns data,
  behaviour and scope. The image owns form.* Where they disagree about form the image wins; where
  they disagree about data the prose wins **and the image is redrawn before the round starts.** A
  builder who has to guess this follows the document addressed to them, every time, and is right to.
- **The gate row became a check.** It had read *"Sketch approved? Yes — `<path>`"*, which is
  satisfied by typing. **The path had never existed, and was cited for three days.** The row now
  names the image *and its source*, and both are verified by **`check-refs.ps1`** — new, self-tested,
  deliberately narrow. `PLAYBOOK.md` §14 already said *a field that can be satisfied without being
  true is not yet a check*; this template had been committing that error on its most important row.
- **`templates/APPROVED.md`** — new. One row per drawing that actually got a yes: file, source,
  date, who, which screens, **and one sentence on what it must look like.** Rejected and superseded
  rows stay, because an argument about *"what we agreed"* is unanswerable without the history.
- **Filing is step four of sketching**, in both sketch skills. **Render → send → get a yes → file**,
  the image *and* its source, in the project's own folder. A `.png` can only be redrawn.
  **Shown is not saved** — the fifth entry in that row, and the most expensive.
- **`PLAYBOOK.md` §8's `Approved?` line gained a precondition:** if the round touched a screen, the
  approved drawing goes **next to the screenshot** before the question is asked. Two images in one
  message is the cheapest gate in this kit.
- **`PLAYBOOK.md` §14: reconcile the drawing and the spec before handover.** Read one against the
  other, list every disagreement and how it was resolved. **This is the only fix that prevents the
  failure**, because it attacks the lossy step — a human turning a picture into prose, unchecked,
  and then using the picture as the exam.

**And the rule that outlives the incident:** *never let one person draw the sketch, write the spec,
and judge the result.* That chain had five roles and one actor. The kit has a reviewer for code and
a persona check for screens; **it has nothing that checks a spec against the design it came from.**

---

## v1.25 — 2026-09-03 — the rule that billed the human

**One finding, and it had been costing a copy-paste round-trip on every check of every round.**

A rule read: *"Nico runs every `git` and `flutter` command himself. Never through an assistant's
device bridge — one left a stale `.git/index.lock`."* **One sentence, two claims, and the second is
the stated reason for the first.** The incident was the *deciding* session, through a bridge that
cannot delete a file it creates. The *building* session runs in a real shell — and had spent a
morning quoting this rule as the reason it could not run a test, handing every `flutter test` back
to the Boss to type. On a test-iteration loop.

**Changed**

- **`PLAYBOOK.md` §14 gained the mirror of its own best diagnostic.** §14 already asked *who does
  this rule actually bind, and who was standing just outside it* — for rules that **failed**. The
  new half is for rules that are **obeyed**: *when a rule names an incident as its reason, check
  that the actor it constrains is the actor from the incident.* **The tell: a rule whose cost is
  paid by someone the rule does not mention.**
- **`PLAYBOOK.md` §15 now names three roles, not two.** Deciding session · building session ·
  the Boss. The human's role is the one that gets left implicit, and its absence is what makes the
  other two read as contradictory — *"hand code work to Code"* against *"here is a command for
  you"*. Those are about **who writes** and **what the channel is**; neither says who types.
- **A who-runs-what split, written down**: the machine check belongs to the building session; the
  looking belongs to the Boss; commits happen after his yes; **anything that leaves the machine
  stays in his hands.** No check removed, no gate moved.
- **`templates/CLAUDE.md` asks for all of this on day one**, so a new project never has to discover
  it the expensive way.

**The reusable line:** **write a prohibition as the mechanism, never as the category of actor.**
*"Never through the device bridge"* is true forever. *"Assistants never run commands"* was never
what the incident showed.

---

## v1.24 — 2026-09-02 — the handover check gains its fifth line

**One change, in five places, and it is the fourth time this kit has been caught by the same
shape.** A building session finished a version, wrote a long and honest handover note — and
reported the round done **having shown nothing and committed nothing.** The Boss's instruction:

> *"Show me result, ask me if everything is okay, then commit after I approve or fix what I ask
> to. No round is finished before this."*

**Changed**

- **`PLAYBOOK.md` §8 is now five lines, not four.** The fifth is **`Approved?`** — the result was
  shown, the question *"is this right?"* was asked, and the answer came back. It is deliberately
  the last line and the only one that is not about the code.
- **The order is written into the rule: show → ask → fix or commit.** Not *commit, then show*,
  which turns the Boss into a reviewer of history instead of the person who decides. Stage 5 of
  §3 now names committing before a yes as **not allowed**.
- **`PLAYBOOK.md` §14 gained *Done is not delivered*** — the row of near-misses now runs four
  long: *installed is not fired* · *tested is not compiled* · *rendered is not seen* · **done is
  not shown**. All four are a step that was completed and then not delivered, and all four were
  invisible for one reason: **completion leaves an artefact, delivery does not.**
- **Three templates gained the field, because a rule with nothing to fill in gets remembered by
  whoever is least tired.** `templates/ROUND.md`'s *After* section, the upstream half of
  `templates/SESSION-HANDOVER.md`, and the definition of done in `templates/CLAUDE.md`.

**Also corrected:** `regression-gate` described §8 as "the three lines" (it had been four since
v1.4); `sketch-the-screen` pointed at "the fourth line" by position rather than by name, which
this change would have broken.

**Not changed:** the inner loop in §4 stays *change → run → check → commit*. The gate is
per **round**, not per change — a rule that asks the Boss to approve every small commit is a rule
that gets switched off in an afternoon.

---

## v1.22 — 2026-09-01 — the machine check grows two categories

**Outside feedback, and it found a hole the kit could not see in itself.** A code-quality standard
arrived in PHP terms — PHPStan level 10, Pint, PHPUnit, plus feature tests — and measured against
it the kit's machine check was **half a check**: static analysis at default strictness, and unit
tests. No formatting. No feature tests.

**Changed**

- **`first-test` now sets up four categories, not two** — format, analyse *at maximum*, unit,
  feature — wrapped in one script, in that order. Formatting because it is a minute's work and ends
  every layout argument; **feature tests because `PLAYBOOK.md` §8's "is it reachable?" had only ever
  been a question asked of a human**, and a feature test is the same question automated.
- **"Run the analyser" is no longer accepted as a level.** Every analyser ships with its dial turned
  down. `first-test` and `stack-choice` now name the dial per stack and require the setting to be
  written into the project's `CLAUDE.md`, because a level nobody recorded gets lowered by the first
  person who hits a warning.
- **`stack-choice` records three extra lines with every stack**: the formatter and its check flag,
  the analyser *and its level*, and the feature-test runner. Minutes on day one; a day or never in
  month three.
- **`PLAYBOOK.md` §14, the rule of two, gained an exception** — and it was written the day after the
  rule itself, because the rule was about to be misapplied to this very change. The rule of two
  guards against acting on one *inferred* pattern. **A stated requirement whose gap you can verify
  by looking is not an inference**, and waiting for it to happen twice is just slowness.

**Not changed:** "mostly passing" is still failing, and the order is still load-bearing — a project
once had 25 green tests over code that could not compile, because only the test step ran.

---

## v1.20 — 2026-08-31 — the kit learns it is a module

**One change, and it is about the kit's own place rather than its contents.**

The first outside tester reached a conclusion this kit had been circling for a week: **the build kit
is one layer of four** — Decide, **Build**, Remember, Improve — and it is only the second. Her
evidence was a class of failure the kit cannot reach: six incidents in one week where **the
information existed, in a file, correctly written, and nothing forced a look at it.** *Not knowledge
failures. Retrieval failures.* A build kit cannot fix those, because they happen before building
starts.

**Changed**

- **`KIT-LOG.md` and `kit-feedback` now route.** Feedback sorts into two kinds and only one is about
  the kit. The test is one question: *could a change to the build process have prevented this?* Yes →
  the kit's log. **No, because the information already existed and nothing looked at it** → the
  operating layer's log.
  **Why it is not tidiness:** a retrieval failure written into the kit's log lands somewhere with **no
  step able to act on it.** It reads as captured and is lost. Six accumulated that way in one week.
  Same error as a product skill defaulting into the kit — right content, wrong reader, one level up.

**Not changed, deliberately**

- **Nothing about the kit's contents, structure or independence.** The relationship is recorded in the
  *operating layer's* decision record, not here, and it is one line: **that layer may depend on this
  kit; this kit must never depend on it.** The test of the seam is that **the kit stays independently
  shippable** — it was sent to a tester who had never heard of the other layer, and it worked.
- `check-boundaries.ps1` keeps enforcing it. **It caught a product name being written into
  `kit-feedback` while this very entry was being drafted**, which is the seam doing its job on the
  person who drew it.

**Known limits**

- **Third re-framing of the top-level structure in eight days.** Each was better than the last, and a
  structure that changes weekly is one nobody can build on. Mitigated by committing to the dependency
  direction only and deferring the shape to a prototype already running by hand.

---

## v1.19 — 2026-08-31 — the first outside test

**Everything a second project asked for, in its priority order.** Different product, different stack,
different environment, no contact with this one. Its own verdict on the writing: *"sentences you did
not understand: none."* Everything else below.

> ### If you copied any of these into your project, here is what changed
>
> *New section, and per the tester the most valuable thing a changelog here can carry — the installer
> cannot see a file you copied out of the kit.*
>
> | Copied-out file | What changed |
> |---|---|
> | `templates/CLAUDE.md` → your `CLAUDE.md` | **Definition of done gained two items** — a line in the plain-language changelog, and a screenshot for any round that changes a screen. Plus a new *At the end of every session* block for the handover file. |
> | `templates/ROUND.md` → your round notes | No change this version. |
> | Anything quoting the **handover check** | It is **four lines now**, not three. The new one is **Reachable?** |
> | `check-boundaries.ps1`'s `$allowed` list, if you edited it | Add `package-for-tester.ps1` if you use the packaging script. |

**Added — the six she ranked**

1. **Triggers narrowed, and a rule for writing them.** *A trigger that fires on everything fires on
   nothing.* `persona-check` went from *"whenever UI is being designed, described, mocked up,
   wireframed or built"* — twenty to thirty moments a session — to **two named moments**;
   `explain-as-we-go` from *"throughout"* to session start plus named moments. `PLAYBOOK.md` §14
   carries the counting rule: **five or more occurrences a session and it will not fire.**
2. **Routing, and the two-session handover.** `PLAYBOOK.md` §15: *say which session the work belongs
   in before starting, and stop rather than build a degraded version in the wrong one.* Plus
   `templates/SESSION-HANDOVER.md` — downstream and upstream halves, and a line in
   `templates/CLAUDE.md` so the building session fills its half without being asked. **The two
   sessions already share the repository; only the *why* needs writing down.**
3. **Quality gates mapped onto six stacks, and CI.** `regression-gate` now turns *"strict analysis, a
   formatter, tests"* into real commands for Dart, TypeScript, Python, Go, Rust and C# — and asks the
   question a generic CI template misses: **what fails silently here?**
4. **Two new skills.** **`counter-proposal`** argues the opposite technical position at proposal time
   — one implementation instead of two, all of it in one place, what a queue removes, twice as
   boring, who maintains each part. **`sketch-the-screen`** draws the one screen about to change,
   mid-build. Plus `templates/HANDOVER-EXTERNAL.md`: problem with evidence, vocabulary, the sceptic's
   question answered first, one worked example — **then** structure.
5. **The documentation audience.** `templates/PRODUCT-CHANGELOG.md`, written for the person who owns
   the product and cannot read its code. A screenshot step and a changelog line in the definition of
   done, and an explicit split of **who may run git**.
6. **An installer that is safe to re-run.** `.kit-manifest.json` with a SHA256 per file, and a report
   that says **unchanged · updated · you edited this · new · no longer part of the kit**. A file you
   edited is kept and named, never silently replaced; `-Force` takes ours; `-DryRun` writes nothing.
   **The guarantee, in writing: the installer never creates, modifies or deletes a file it did not
   place.**

**Added — the smaller ones**

- **`templates/CONFLICTS.md`** — the known-conflicts list. **It was never in this kit**; it was hers,
  and she rated it the best value-per-line she had. It works because **it fires without being
  invoked**, which is the only mechanism available where the hooks cannot run.
- **The handover check is four lines.** The new one is **Reachable?** — three pieces of correct,
  tested, reviewed work were unreachable in one day, and the other three lines would have passed all
  three.
- **An environment table** — which parts of the kit work anywhere, and which need a local terminal in
  the project folder. Her hooks were *installed, registered and watched firing*, and never fire where
  she works. **The same is true here and had never been written down.**
- **Four laws promoted**, each now seen in two unrelated projects: remembering does not survive a busy
  week · a claim of coverage must name its denominator · a fix lives where the failure happens · **a
  default that is always accepted is not a default, it is the value.**

**Verified**

- Installer exercised through seven scenarios: fresh · re-run · a skill the kit did not write · a
  kit file edited locally · `-Force` · `-DryRun` · a file dropped from the kit. Each behaves as the
  guarantee says.
- Boundaries clean; self-test 5/5; hooks 34/34.

**Known limits**

- **This is one project's evidence for most of it**, and eleven items in one delivery overrides this
  kit's own *twice, not once* brake. **Recorded as an override, with its reason**, in `KIT-LOG.md`.
  Four of the items are twice-witnessed; the rest are not.
- **None of the new material has been used on real work yet.** Two new skills, four new templates and
  a rewritten installer, all written in one sitting — which is precisely the shape this kit distrusts
  when it sees it anywhere else.
- The stack table names six ecosystems; **one of them has ever been run here.**

---

## v1.18 — 2026-08-26 — audited, then fixed, then shipped

**The first release audited by something that had not written it. Verdict: DO NOT SHIP.** Nine
findings, seven of them invisible from inside. All fixed below and verified **inside the archive**.

**Fixed — the blocker**

- **`hooks/install-hooks.ps1` now copies itself** into a repo's `.claude\hooks`. It did not, while
  `test-hooks.ps1` shells out to it for four assertions — so the suite passed from the kit folder and
  **failed 4 of 34 from the folder the installer's own closing message tells you to use.** The first
  machine check a new user ever ran would have printed FAIL.

**Fixed — the package**

- **`package-for-tester.ps1`** — new. Excludes the author's own files, replaces names, blanks the
  product list in `check-boundaries.ps1`, packs, then **reads every text file back out of the zip** and
  **deletes the archive** if anything private survived, so a failed package cannot be sent by accident.
- **The sanitiser no longer annotates blindly.** Its first version welded *"(not shipped)"* onto all 38
  mentions of two filenames — including inside the template a tester copies into her own repo, and
  inside the skill whose job is to write that file. **A sanitiser is a program, and it was the only one
  here without a test.**

**Fixed — the kit itself, and these apply to every copy**

- **`PLAYBOOK.md` no longer calls the Boss "he"** — 17 pronouns, in a package going to a woman.
- `START-HERE.md`'s *"If you ever share this"* and `SKILLS.md`'s *"why not just ship the 9"* rewritten:
  both told the reader the kit had never been shared and was not meant to be. **It has been now**, so
  they are a procedure instead of a plan.
- `hooks/README.md` no longer states one laptop's facts as constraints on anyone else's; stale counts
  corrected (15 assertions → 34, "0 runs across 4 rounds" → "0 runs so far").
- `skills/onboarding-docs` bad example replaced — it quoted the author's product almost verbatim.
- `HANDOVER.md`: points at `VERSION` instead of naming a stale one, tells you to **open PowerShell in
  the unzipped folder** (never stated), and names `check-boundaries.ps1` — which `FEEDBACK.md` asks
  about and page one never mentioned.
- `START-HERE.md` now says `-Core`, matching `HANDOVER.md` instead of undoing it, and no longer offers
  a Mac.

**The rule underneath all of it: verify the artefact, not the source.** The folder was clean. The zip
was not the folder.

**Known limits**

- **Nothing has run on Windows PowerShell 5.1.** Everything here was exercised under pwsh 7. The 5.1
  paths read correctly and the first real 5.1 execution will be the tester's.
- The audit was one pass by one reader. It found nine things; it is not evidence there is no tenth.

---

## v1.17 — 2026-08-26 — what actually leaves the building

**Fixed — before the first copy reached anyone**

- **The tester package is now sanitised, and the sweep that said it already was, was wrong.** It had
  excluded `KIT-LOG.md` and `CHANGELOG.md` from the grep because those files legitimately name
  *products* — an exclusion written for one kind of match and applied to a different question. The log
  contained the kit author's first name 18 times. **`KIT-LOG.md` and `ROADMAP.md` are no longer
  shipped**, names and product references are replaced across 15 files, and
  `check-boundaries.ps1`'s own product list ships **blank, with a comment saying it is a blank to fill
  in rather than a default.**
- **`check-boundaries.ps1 -SelfTest` no longer depends on `$hard`.** Blanking that list for the tester
  broke the self-test — so **a fresh copy of the kit would have told its first outside user that its
  own checker was broken.** The self-test now carries its own names and passes on an unconfigured copy.

**Added**

- **`HANDOVER.md` — "When a new version arrives".** The line between *yours* (project, workshop,
  feedback, `check.json`) and *ours* (everything in the kit folder, replaced wholesale), a four-step
  update, and the one instruction that makes updating painless: **do not edit the kit's files — write
  the change in `FEEDBACK.md` instead**, so it comes back as part of the kit rather than as a patch to
  reapply.
- **`HANDOVER.md` — "Two files you will not find in here"**, saying plainly which two and why, so their
  absence reads as a decision rather than an omission.

**The rule underneath both fixes: verify the artefact, not the source.** The sweep read the folder; the
thing that ships is the zip. Every `.md` and `.ps1` **inside the archive** is now read back and grepped
after packing.

---

## v1.16 — 2026-08-26 — a profile that starts from what is already known

**Changed**

- **`templates/BOSS.md` — day one no longer starts empty.** The old instruction said to leave it
  mostly blank because *"half of it guessed is worse than a third of it true"*. The Boss disagreed and
  was right: **an assistant often already knows the person** — memory, previous work, whatever they
  have set up — and throwing that away wastes real evidence and charges them for an interview they did
  not ask for.
  The rule that replaces it keeps the original's protection: **fill it in, and mark every line
  `[known]` or `[guess]`.** A marked guess is safe, because it can be checked and deleted in seconds.
  **An unmarked guess is the only dangerous kind** — in a month nobody can tell it from an
  observation. Then **at most three questions**, about what could not be marked either way.
- **`HANDOVER.md`** — the tester's kickoff message updated to match, and **the kit now states plainly
  that it is Windows-only** rather than hedging about macOS. The scripts are PowerShell; this version
  targets one platform and says so, in the requirements and in the known limits.

**Why the correction is better than what it replaced.** The original rule optimised against one
failure — a confidently wrong profile — by giving up all the information. **Marking the lines gets
both**: nothing true is discarded, and nothing uncertain can quietly harden into fact.

---

## v1.15 — 2026-08-26 — the workshop can now be created by someone else

Three questions from the Boss about the handover, and the first one found a hole in it.

**Added**

- **`templates/MACHINE.md`.** `templates/BOSS.md` had existed for days; **the other half of the
  workshop had no template at all.** So a kit that tells you a workshop exists shipped without any way
  to make one. Found by asking *"her assistant needs to know about Machine and Boss so it can create
  something similar for her"* — which is the question the package could not answer.
- **`PLAYBOOK.md` §2 — the workshop joins the day-one triggered list**, firing on *the first project on
  a new machine, or with a new person*. It was described in §14 and created by nobody, which is how a
  concept with no trigger stays a concept.
- **`HANDOVER.md` — a first message for the tester's assistant**, ready to paste: read these three
  things, then create the workshop, **fill `MACHINE.md` by checking the machine rather than copying
  documentation, and leave `BOSS.md` mostly empty** because it is grown from dated observations, not
  guessed on day one.
- **`HANDOVER.md` — "Known limits", and a stated refusal to publish the roadmap.** Limits are listed
  so a tester does not spend an hour proving something already known. **Plans are deliberately
  withheld**: a tester who knows what is coming stops reporting it, and *"this is missing"* arriving
  independently is worth far more than agreement with a plan. The distinction is written into the file
  so it does not read as secrecy.

**Known limits**

- `templates/MACHINE.md` has been filled in exactly once, by its author, on the machine it was
  abstracted from.
- Nobody has yet run the paste-block. Whether an assistant handed those four sentences actually
  produces a useful `MACHINE.md` is the first thing this hands-over test will find out.

---

## v1.14 — 2026-08-26 — packaged for someone else

**The first time this kit leaves the machine it was written on.** `ship-it` has been dormant since the
kit existed, for the honest reason that nothing had ever left. It has now fired.

**Added**

- **`HANDOVER.md`** — one page for a first-time tester: what to install, **which two files to read and
  which not to**, what to build (something real, not work data), and what we actually want to know.
  It says outright that the kit is opinionated, that the opinions came from one project on one
  machine, and that *"this is written for someone who is not me"* is a valid finding.
- **`FEEDBACK.md`** — a form, not a request for comments. Eight sections, built so vague answers are
  hard to give. **Section 2 is the point: every step you skipped, and why.** A skipped step is wrong,
  badly placed, or badly explained, and only the person who skipped it can say which.

**The loop this sets up**, agreed with the Boss: package → a tester builds something real → the form
comes back → findings are recorded in `KIT-LOG.md` with a name and a date → next version → back to the
same tester. **The twice-not-once brake still applies**, which is stated in both new files: repeating
a complaint is not nagging, it is the mechanism.

**Verified before it shipped**

- **Personal-data sweep of the whole kit: clean.** No names, no email addresses, no machine paths.
  That is `Three homes` paying for itself the same day — `MACHINE.md` and `BOSS.md` live in the
  workshop, *outside* the kit, so the package could be handed over without editing a single file.
- `check-boundaries.ps1` clean; hooks 34/34.

**Known limits**

- **The scripts are Windows-first.** On macOS or Linux the process works and the four PowerShell
  scripts do not. Stated in `HANDOVER.md` rather than discovered.
- **One tester, one round of feedback, no baseline.** There is nothing to compare her experience
  against except one person's, on one project.

---

## v1.13 — 2026-08-26 — the freeze, and something to measure it with

**The eighth version cut today, and it exists to stop the ninth.** Named plainly, because the irony is
the finding: a kit that improves every time it chafes is a kit nobody can ever evaluate.

**Added**

- **`PLAYBOOK.md` §14 — "The freeze: one round where the kit is not allowed to change."** §14's
  stopping condition has always said *the kit is done enough when one product ships a round without
  needing a kit change mid-round* — **and it was never testable, because the kit always changed.**
  Round 3 carried **seven kit versions** around one session of product work. Every one was justified;
  nobody could say whether the round needed them or whether they were merely available.
  A frozen round logs process friction to `KIT-LOG.md` tagged `[FROZEN]` and **fixes nothing until
  after Commit**. Only something that makes the round *impossible* breaks a freeze; inconvenience
  never does. Then the observations are counted: **0 means the kit got out of the way** — the stopping
  condition, met once.
  This does not repeal the by-product rule. It puts a **delay** between the friction and the fix, so
  the friction can be counted first.
- **`PLAYBOOK.md` §14 + `templates/ROUND.md` — cost, measured with what is actually measurable.** The
  `Cost:` line has existed since 2026-08-25 and **has never been filled in**, while *"less costly"* is
  the first word of this kit's goal. Three honest instruments: **elapsed time**, **round-trips to the
  Boss**, and **kit changes during the round** — that last one being where a round quietly triples.
  **Token spend is explicitly excluded**: it cannot be measured from inside a session, and a number
  invented for a field is worse than an empty field, because the field then looks answered.

**Decided by the Boss**, 2026-08-26: *"yes do what needed to have a good kit."* Round 4 runs frozen.

**Known limits**

- **Nothing enforces a freeze.** It is declared in a round note and kept by discipline — and the
  person who has to keep it is the same one who benefits from breaking it.
- The reading of the result is untested: nobody knows yet whether a real round produces 0
  observations, 3, or 20. The first frozen round is the measurement, and it may well say the kit is
  further from finished than today felt.

---

## v1.12 — 2026-08-26 — a command handed over is a deliverable

**Added**

- **`PLAYBOOK.md` §15 — "Hand over the safe form of a command, not the clever one."** Round 3's commit
  was finished, tested and reviewed, and then stalled: the message was handed over as four `-m` chunks
  on one pasted line, the paste lost part of it, and **git opened `vim`** in front of someone who had
  never seen it. Five rules, of which the first does most of the work: **long text goes in a file the
  assistant writes** — `git commit -F` — so there is nothing to quote and no editor to escape.

**Why it is a version and not a log line.** §15 already said *if the assistant can do it, the
assistant does it*, and it was read as being about **who runs the command**. Running git on that
machine genuinely is the Boss's half. **The wording of it never was.** Third instance this week of the
same rule failing one step outside its scope, which is the §14 diagnostic doing its job — and all
three were found by the Boss getting stuck rather than by anything in the process.

**Known limits**

- Prose, not a check. Nothing inspects a command before it is handed over. A linting rule for
  "commands the assistant emits" is imaginable and does not exist.
- The rule names `vim` because that is what this machine opened. It does not tell you how to find out
  what any given machine will open, which is the question that would have prevented it.

---

## v1.11 — 2026-08-26 — a rule only binds who reads its file

Two additions, both from the same incident, ninety minutes after v1.10: **the round's own reviewer
blocked the round's commit.**

**Added**

- **`PLAYBOOK.md` §14 — "A rule that binds behaviour stays in the operational file, even when its
  evidence moves."** *Three homes*, added this morning, moved a project's machine facts into
  `MACHINE.md`. One of them was the rule *"never run git through the file bridge"*. Four hours later a
  subagent — whose instructions say to read `CLAUDE.md` for the hard rules — ran git through the
  bridge and left a lock file that blocked the commit. **Split the fact from the rule:** the
  measurement travels to the workshop, the instruction stays where everyone working in that repo is
  pointed. General form: *a rule only binds the people who are told to read the file it lives in.*
- **`PLAYBOOK.md` §10 — "Brief an agent with the constraints, not only the task."** Three things every
  dispatch carries beyond the work: what it may not do, what it cannot do and must say so, and where
  the rules live. **An agent inherits your instructions, not what you happen to know** — and this
  failure is silent by construction, because from inside the agent nothing went wrong.

**Worth recording as a win**

Second occurrence of a documented failure. **Ninety seconds to diagnose**, against a session the first
time, because the symptom and the cause were both written down and dated. First time this kit has hit
a repeat and had the answer waiting.

**Known limits**

- Nothing enforces either rule. Both are prose: one in a file agents are told to read, one in a
  briefing a human writes. A hook that refuses `git` from the bridge side would be enforcement, and it
  does not exist.
- The correction is one instance old. It says where a *rule* goes; it does not yet say what to do when
  a fact and a rule are the same sentence.

---

## v1.10 — 2026-08-26 — tested is not compiled

One change, from one hour of real building. The kit's oldest instrument — *one command that says pass
or fail* — turned out to be measuring less than it claimed.

**Changed**

- **`skills/first-test` — "on a compiled language, one command is not enough."** The test command
  compiles only what the tests import, so a file no test touches can contain an outright error while
  every test passes. Found the hard way: **24 tests green, and the app would not build**, on a
  one-word error in an unimported file. The skill now names the whole-build check per ecosystem
  (`flutter analyze`, `tsc --noEmit`, `mypy`, `go vet ./...`, `cargo check`, `dotnet build`) and says
  to run it **before** the tests, because a compile error makes every test result meaningless.

**Why it is a version of its own.** This is the third instance today of one shape:

| Claimed | Actually measured |
|---|---|
| 3 agents have never fired | 3 agents were never installed |
| the installer left the project's own skills alone | it also listed ten kit leftovers under that heading |
| 24 tests pass | 24 tests pass **over the subset of files the tests import** |

**A green number is a measurement of something. The question is always: of what?**

**Known limits**

- **Nothing makes the whole-build check run.** It is a line in `CLAUDE.md` and a habit; the commit
  gate still records only a passing *test* command. Wiring `analyze` into the gate is ranked, not done.
- The per-ecosystem commands are named from documentation for every language except Dart, where this
  one was measured.

---

## v1.9 — 2026-08-26 — three homes, and a check that enforces them

Answer to one question: *do we have a system to separate what belongs to a product from what belongs
to the kit?* The honest answer was no — one rule, for one artefact type, an hour old. This is the
system.

**Added**

- **`PLAYBOOK.md` §14 — "Three homes: the kit, the workshop, the product."** Replaces v1.8's *Two
  libraries*, which was right and incomplete. **The workshop is the home nobody thinks of:** facts
  like *"no admin rights on this laptop"* or *"PowerShell 5.1 has no `??`"* are not general enough for
  the kit and belong to no single product, so with two homes they land in whichever product was open —
  and the next product re-learns them or copies them. Two questions settle every case, and they are in
  the section.
- **`check-boundaries.ps1`** — scans the kit for product names, **exits 1** on a hit, and counts
  one-ecosystem technology separately as a warning, because *"flutter test, pytest, npm test"* teaches
  better than an abstraction. `-SelfTest` plants a leak, proves the scan catches it, and proves
  "ranking" is not the flashcard app. **A rule without a check is a preference.**
- **The workshop itself** — `MACHINE.md` and `BOSS.md`, beside the kit rather than inside it.
  `templates/BOSS.md` had existed unused for days with nowhere to live.
- **`test-hooks.ps1`: 30 → 34 assertions**, covering `check.json` detection. All four verified to fail
  against the old code — one vacuously, which is stated in the log rather than counted as a pass.

**Fixed — five leaks found by audit**

| | |
|---|---|
| `GLOSSARY.md` | **67 of 276 lines** were one product's build log. Split three ways: general definitions and the general lesson stay; measurements go to `MACHINE.md`; product statements go to the product's own glossary. |
| `templates/ASA-HUB.md` → **`templates/PROJECT-HUB.md`** | The kit told every reader to build a product they have never heard of. `START-HERE.md` and `obsidian-docs` updated with it. |
| `hooks/install-hooks.ps1` | `check.json` is now **detected** from the repo, not hard-coded to one product's command. An unrecognised project gets an **empty** command and a loud message — which leaves the commit gate inactive rather than wrong. |
| `PLAYBOOK.md` · `GLOSSARY.md` · `ROADMAP.md` | a product named in the version history and a milestone; four lines naming a person in rule text, now *"the Boss"* |
| `install-skills.ps1` | the two "not installed this run" cases are now reported separately — **kit leftovers** and **the project's own skills** were being printed under one heading, and rewording that heading to something specific is what exposed the wrong set. |

**Verified**

- `check-boundaries.ps1` → **clean, exit 0**; `-SelfTest` 5 of 5; hooks 34 of 34; installer clean at
  14 core + 3 agents, and its two leftover/foreign lists checked against a real previous install.

**Known limits**

- **Nothing automatically reads the workshop.** The pointer in a product's `CLAUDE.md` is the whole
  mechanism today. A hook that injects `MACHINE.md` at session start needs a path convention the kit
  does not have yet — roadmap, not this version.
- **The hard list in `check-boundaries.ps1` is hand-maintained.** A new product that nobody adds to it
  is a product the check silently does not cover. That is stated in the file, which is not the same as
  solved.
- The soft count is 40 mentions, all legitimate examples today. Nobody has decided what number would
  mean the kit had quietly become a Flutter kit.

---

## v1.8 — 2026-08-26 — two libraries

**Reverses v1.7's headline addition.** `content-pack` was a good skill in the wrong library, and the
rule that would have caught it did not exist. Third version in one session, which is its own note:
*cut the version at the end of the session.*

**Removed**

- **`skills/content-pack`** — deleted from the kit. It described how a *product's* content system
  works, not how to build products. Rewritten concretely and moved into the app repo it belongs to,
  at `.claude/skills/content-pack/`. The `stack-choice` handoff added for it in v1.7 is reverted.

**Added**

- **`PLAYBOOK.md` §14 — "Two libraries: kit skills and product skills."** The table, and the test:
  *would this skill still make sense in a project that has nothing to do with this product?* Yes →
  the kit. No → the product repo's `.claude/skills/`, committed with the code. When it is genuinely
  both, it is two skills.
  **The diagnosis matters more than the rule:** the kit had a promotion path *upward* since
  2026-08-22 and **no path downward and no home at the bottom** — so everything invented anywhere
  ended up in the kit. That is how a general package quietly becomes one project's notes, and it is
  invisible because each addition is individually useful.
- **A fourth row on §14's destination table** — *missing know-how* now has somewhere to go, in the
  same session rather than at the next version.
- **`templates/PRODUCT-SKILL.md`** — the shape of a product skill: the four things it must carry
  (the real schema copied from the repo, the paths, the validating command, and what nothing checks)
  and the three it must not do (restate the kit, become a decision record, describe a plan).
- **`skills/architecture-map` — "is any of this content rather than code?"** The one part of the
  deleted skill that is genuinely the kit's business: if material grows topic by topic while the code
  stays still, it is data files, and the map carries three lines about it — the layer, the one place
  that validates it, and a pointer to the ADR that fixed the format. **The schema itself is the
  product's business.**

**Changed**

- **`install-skills.ps1`** prints skills it did not install as **"the project's own skills"** rather
  than *"already there, not from this kit"*. Same behaviour, and it was always the right behaviour —
  it just read like an accident instead of the mechanism that makes two libraries possible.
- **`SKILLS.md`** back to 24 skills / 14 fired, with the removal recorded rather than tidied away.

**Verified**

- Installer clean at 14 core + 3 agents; 24 skills, 24 `.skill` archives, `architecture-map` and
  `stack-choice` rebuilt.

**Known limits**

- **The downward bounce has now happened once and the upward one is still only in the log** — no
  product skill has yet been written twice in two repos and promoted. The rule is symmetrical on
  paper only.
- `templates/PRODUCT-SKILL.md` has exactly one instance written against it.

---

## v1.7 — 2026-08-26 — asking a question the Boss can answer

Cut an hour after v1.6, in the same session — **which is itself the note.** v1.6 was stamped and
mirrored mid-session on the assumption the session's learning was over. It was not. *Cut the version
at the end of the session.*

**Added**

- **New skill: `content-pack`** — designing the file format for reference content that ships inside a
  product, then writing and validating packs against it. Fired on the German app the day it was
  written, so it is **not an addition by argument**: the kit's own record shows skills added by
  argument ran 4-of-5 dormant. Carries the three questions that decide a format, the
  whole-or-nothing loader rules, and the limit that matters — **a validator checks shape, never
  truth.**
- **`PLAYBOOK.md` §15 — "A question of category 1 travels with its explanation."** §15 said *when* to
  ask the Boss and nothing about **what an askable question looks like.** Two decisions were put up
  as three labels each and both came back *"I cant decide when I dont understand"* — one of them a
  one-way door. A decision now travels with plain terms, an analogy where a plain sentence does not
  land, **the options shown rather than described** (the same real example written both ways), and
  **the one fact that decides it**. *"JSON or YAML?"* is not answerable; *"will you ever hand-edit
  one of these files?"* is, and it settles it.
- **`skills/stack-choice`** hands off to `content-pack` in its description — choosing a serialisation
  format for your own content is not choosing a stack, and both descriptions matched the same
  sentences.

**Changed**

- **`SKILLS.md` counts corrected**: 25 skills, **15 have fired**. The file still said *"all 24, 9
  have ever fired"* in its title while listing fourteen fired rows below it.
- **`data-and-secrets` downgraded from "will fire, high confidence".** Its stated reason —
  *"the assistant app needs a key on device"* — stopped being true when that plan was cut. It now
  waits on round 6, and on a storage permission a text-sharing package should not need.

**Verified**

- Installer runs clean with 15 core skills + 3 agents; `content-pack.skill` archive rebuilt (25 of
  25 present).

**Known limits**

- **`content-pack` has fired once, on one pack, in one format.** Its claim that the second pack is
  where a format's mistakes surface is borrowed reasoning, not something this kit has watched happen.
- The §15 rule has been applied exactly once, in the message that followed the failure.

---

## v1.6 — 2026-08-26 — the unreachable half

Cut while starting round 3 of the German app. **One theme: the kit had been judging parts of itself
that were never installed anywhere they could run.**

**Fixed**

- **`install-skills.ps1` now installs the agents.** It had deliberately skipped `agents/`, and said
  why in a comment: *0 of 3 have run, and the open decision is hook them or delete them.*
  `.claude/agents` therefore did not exist in any scope, and **an uninstalled subagent cannot be
  invoked** — so the zero was measuring the installer, not the agents. The non-installation was
  manufacturing the evidence used to justify it.
  **This is the same bug the installer was written to fix**, one folder over: its own header has
  recorded since 2026-08-24 that twenty-four skills sat where Claude Code could not read them. The
  fix was applied to `skills/` and not to the folder beside it.

**Added**

- **`PLAYBOOK.md` §14 — "When something has never fired, check that it is installed before
  theorising about its trigger."** Three ordered questions, cheapest first. `SKILLS.md` had two
  written theories about the agents' silence — unenforced trigger, or duplicated work — and the
  retrospective was named as the place to choose between them. **The answer took one `ls`.** Both
  theories were more interesting than the boring one, which is why neither was checked.
- **`SKILLS.md` — retirement rule 0: reachability first.** A dormancy count is only evidence if the
  thing was reachable. Without this, the kit would eventually retire something for never firing from
  a folder nothing reads. The `-Core` switch and two log entries all reasoned about earned places
  while assuming reachability.
- **`templates/PLAN.md` — a `CLAUDE.md still true?` column on the re-confirmation table.** A plan
  can be re-confirmed twice while the file the assistant re-reads every session still describes the
  product that was rejected. Found in the German app: the Goal described a twelve-screen writing
  app, and two of eight hard rules governed an API key and a module seam the plan had cut.
- **`PLAYBOOK.md` §14 — two rows on the scope table**, both of this session's findings, since both
  are the same shape as the five already there: an existing rule failing one step outside its scope.

**Changed**

- **`PLAYBOOK.md` §10, *Wiring an agent*** — no longer says "copy that file". The installer does it,
  and the section now separates **installed** from **fired** as two facts each needing their own
  evidence.

**Verified**

- 14 skills + 3 agents into a clean project folder; all three agents printed by name; `.kit-version`
  records the counts. PowerShell 7.5.4.

**Known limits**

- **That Claude Code offers `reviewer` by name in a real session is still unverified.** It is an
  acceptance criterion of the German app's round 3, on the laptop, where it can actually be seen.
- The generalisation — *when you fix a class of bug, name the class and sweep it* — is written in
  §14 and has been applied exactly once, by hand.

---

## v1.5 — 2026-08-25 — the read link

The first version cut after using the kit end to end on a product that was not the kit.

**The theme, and it is one sentence.** Every failure this session sat on the same link of the same
chain — *observe → write it down → **read it back** → act.* The kit was already good at observing
and writing. It had almost nothing at reading back. Four of the six changes below are readers.

**Added**

- **`PLAYBOOK.md` §3, stage 0b — the plan, confirmed.** `templates/PLAN.md` with a
  `Confirmed by: <name>, <date>` line that a human fills. **No round note may be written before
  it.** Written after the assistant offered to start building three times in one conversation, each
  time before a plan existed. Every offer was reasonable; none should have been made. Approval was
  inferred because approval had nowhere to live.
- **`PLAYBOOK.md` §14 — "When a rule gets skipped, check its scope before writing a new one."**
  Five failures in one session, every one a rule that already existed failing just outside the
  scope it had been given. Not one needed a new rule. **The retrospective's first question is now
  *who does the existing rule actually bind?***
- **`PLAYBOOK.md` §14 — "An analysis is not finished until its conclusions are in a file something
  reads,"** with a table naming the destination for each kind of conclusion. Three of one session's
  five conclusions reached no file at all.
- **`PLAYBOOK.md` §15 — who does what.** `START-HERE.md` had always stated the human's half (*you
  run it and look*). The assistant's half was never written: **if the assistant can do it, the
  assistant does it.** A connected folder on the user's machine sat unused for a whole session
  while he was sent hunting for a download button.
- **`orient.ps1` now injects `ROADMAP.md` → `Now`** at session start, and flags a `PLAN.md` whose
  signature line is empty. **The direct fix for why the analysis was not acted on:** a ranked item
  in a file nobody opens is indistinguishable from an item nobody ranked.
- **`install-skills.ps1 -Core`** — installs the 14 skills that have fired, and **names** the 10 it
  leaves out. Silence about what was omitted is how a user comes to expect a skill that cannot fire.
- **`KIT-LOG.md` — a "What the process prevented" section.** The log recorded only failures, which
  made the kit look worse than it is and made retirement undecidable. Three products stopped on
  2026-08-25, each in minutes.

**Changed**

- **13 skill descriptions now name the sibling they hand off to**, using the pattern `discovery`
  already had and no other skill did. Six collision clusters closed:
  `discovery` ↔ `persona-check` ↔ `roadmap` · `sketch-the-product` ↔ `persona-check` ↔
  `design-system` · `research` ↔ `stack-choice` ↔ `toolchain-map` · `architecture-map` ↔
  `module-contract` · `first-test` ↔ `regression-gate` · `ship-it` ↔ `onboarding-docs`.
  One real duplicate removed — both `first-test` and `regression-gate` claimed *"a bug that should
  not come back"* in near-identical words.
- **Stage 0 may no longer deliver a mockup nobody has opened.** A sketch was published with one
  stray quote in a JavaScript string; every screen rendered blank, and it was described screen by
  screen and offered for signature from the source. **A mockup is code, and code that has not been
  run is a claim.**
- **A plan whose sketch contradicts it cannot be confirmed.** Redraw first. Noting the contradiction
  in a footnote and asking anyway was tried, and the answer was *"written is not enough."*
- **`templates/ROUND.md`** gains `Plan:` (with the confirmation date), `Sketch:` and `Cost:`.
- **The kit-change rule, now written down** — it governed a whole session while existing only in
  conversation. *The kit changes only as a by-product of building something else* — **plus the
  exception that matters more than the rule:** an item already ranked from a measured finding needs
  a slot, not new friction. Without that clause the rule blocked the very work it was meant to
  prioritise, and the collision it delayed caused a real miss eight hours later.
- **A stopping condition, at last:** the kit is done enough when one product ships without needing
  a kit change mid-round.
- **`ROADMAP.md`** re-ranked with a `Done` section, and `business-case` finally referenced by step 4.
- **`SKILLS.md`** — the agents question is **decided**: hook them, and the wiring says where.
  `reviewer` → step 11, `note-taker` → the report job, `stack-review` → conformance over Design.
  All three were unattached, not idle. Nothing deleted.

**Verified, not assumed**

- **Hook suite: 30 assertions, 0 failures** — up from 25. All five new ones were **run against the
  old code and seen to fail**, then against the new code and seen to pass.
- **Two of those five passed vacuously on the first attempt** — negative assertions that are
  trivially true when nothing is printed at all. Paired with a positive signal and re-verified.
  Fourth appearance of that pattern this week; first time the rule caught it instead of the bug.
- `-Core` tested both ways: 14 installed with it, 24 without, the 10 omitted named.

**Known limits, stated rather than hidden**

- **The `awaiting:` field still does not exist.** `PLAN.md` covers plan approval; every *other* step
  that stops at the Boss still records nothing. `Next` item 2.
- **Conformance is 1 of 16 checks.** `gate-commit.ps1` computes step 12's proof and nothing else.
- **Cost is still not measured.** `templates/ROUND.md` has the line; no round has yet filled it with
  a number. *Less costly* is the first word of this kit's purpose and the only one with no instrument.
- **`persona-check` did not fire once** across three sketches on 2026-08-25 — the exact collision the
  mapping predicted that morning. The boundary line is in now; it has not yet been proved to work.
- **The three agents are decided but not hooked.** 0 runs still stands.

---

## v1.4 — 2026-08-24 — the skills were never installed

**Confirmed, not suspected.** `~/.claude/skills` and the project's `.claude/skills` **did not
exist**. Since the kit began, Claude Code has never had access to a single one of its 24 skills.

Everything that "used the kit" used the playbook, the templates and the hooks. The skills fired
only in Cowork sessions, where they are loaded from the conversation — **the count was measuring
the wrong place.**

**Added**

- `install-skills.ps1` — copies every skill folder into `~/.claude/skills` (default) or a
  project's `.claude/skills`. Records the kit version in `.kit-version` so drift is visible.
- `VERSION` — one line, so a script can read it rather than a human parsing this file.

**Decided**

- **User scope by default.** One copy, every project, one source of truth in the kit folder.
  What it gives up — travelling to a colleague on clone — is deferred anyway, and `-Scope project`
  exists for the day it is not.
- **Agents are deliberately not installed.** 0 of 3 have run in five rounds and the open question
  is *hook them or delete them*. Installing them would quietly answer a question nobody decided.

**Two behaviours worth knowing**

- A skill folder already there that the kit did not put there is **listed and left alone**.
  Deleting someone's own work would be the worst kind of helpful.
- Re-running is safe. Kit skills are overwritten; that is the point of a version stamp.

**Found on the first real run:** `VERSION` shipped saying `1.3` while this entry says `1.4` — it
was written before the entry that names the version. **The one file whose job is to detect drift
was itself drifted, on its first use.** Corrected to `1.4`.

The lesson is small and reusable: **the version is bumped as the *last* act of a release**, after
the changelog entry exists, never before.

**Found by running it:** `Copy-Item -LiteralPath` does not expand `*` — it takes the wildcard
literally and fails on the first folder. Four scenarios were run before shipping: fresh install,
re-run with a hand-written skill present, project scope, and project scope with the argument
missing.

---

## v1.3 — 2026-08-24 — the gate is proven, and the suite reads messages

The hooks round is **complete**: all four acceptance criteria evidenced on a real repo, including
the one that mattered — the gate blocked *after a code change*, naming both timestamps.

**Fixed**

- `gate-commit.ps1` printed the **absolute** path of the changed file instead of the repo-relative
  one. Cause: `$newestFile.Replace($root, '')` — a case-**sensitive** string match that silently
  does nothing when `CLAUDE_PROJECT_DIR` and the file's `FullName` disagree. Now uses
  `Resolve-Path -Relative`, which asks the filesystem instead of comparing strings, and is
  therefore right whichever mismatch it was — **the cause was diagnosed but never confirmed**, and
  this fix does not depend on the diagnosis being right.

**Added**

- The suite can now read a hook's **stderr**. Until today it only ever checked exit codes, so a
  gate that blocked for the right reason while printing the wrong thing passed every test. **The
  message is part of the contract** — it is the only part a human reads.
- Five new assertions on the blocked message: names the file relative to the repo, does not leak
  the absolute path, names both timestamps, says which command to run, and survives a project dir
  that is not a plain string prefix of the file path.

**25 assertions, 0 failures.**

### The honest part

The first four message assertions **passed against the buggy code**. Windows casing cannot be
reproduced on a case-sensitive filesystem, so the tests agreed with the bug — the exact pattern
this changelog described in v1.2, one version later, in the tests written to prevent it.

A probe settled it rather than argument:

```
case match      -> /lib/main.dart
trailing sep    -> lib/main.dart
different case  -> /tmp/probe/lib/main.dart     <- the bug, demonstrated
```

The fifth assertion uses the **same class** of mismatch in a portable form — a root that points at
the same folder without being a string prefix — and it **fails against the old implementation**.
Checked in both directions before the fix was kept.

**The lesson is not "test harder". It is that a rule written down is not a rule followed** — §5
says break the thing and watch the test fail, and it had to be done deliberately here, one message
after writing it.

---

## v1.2 — 2026-08-24 — the recorder never worked

v1.1 shipped a hook that could not fire, and a test suite that said it could.

**Fixed**

- `record-test.ps1` read `$hook.tool_output`. **That field does not exist.** The real PostToolUse
  payload is `tool_response`, an object with `stdout` and `stderr`. The hook had never written
  `.last-pass` once, which is why the commit gate blocked everything and the orient hook kept
  reporting "no passing machine check". Verified against a **captured live payload**, not the docs.
- `test-hooks.ps1` mocked the same invented field name, so 16/16 passed against a hook that could
  never work. Now uses the real payload shape, plus two cases for a plain-string response and for
  output arriving on stderr.
- One order-dependent assertion in the orient section: it had been passing on the *previous* test's
  side effect. Once the recorder started working, it failed. Now it arranges its own state.

**19 assertions, 0 failures — and the suite was checked against the bug.** Reintroducing the old
field name makes 3 tests fail. A test that cannot fail is not a test, and this one previously
could not.

---

## PATTERN — a test written against the wrong contract confirms the bug

Three occurrences in one day, same shape every time:

| Where | The test asserted | So the suite |
|---|---|---|
| `widget_test.dart` | the **mangled** title `Asa â€" Product Hub` | passed while the UI was visibly wrong |
| `test-hooks.ps1` | an invented field `tool_output` | passed while the hook never fired |
| `install-hooks.ps1` | *(no test at all — "it's just plumbing")* | shipped the only unguarded null in the set |

**The rule this produces:** after writing a test, break the thing it tests and watch the test fail.
A test that has never been seen to fail is a claim, not a check. Added to `PLAYBOOK.md` §5.

The second row is the dangerous one: **the test and the code were written from the same wrong
assumption at the same time.** No amount of care inside that assumption would have caught it. Only
a real payload could — which is why the fix was verified by capturing one.

---

## v1.1 — 2026-08-24 — hooks

The kit's first executable code. Until now it was entirely documents.

**Added**

- `hooks/` — three hooks that make the kit's most-skipped rules fire without being remembered:
  - `orient.ps1` (`SessionStart`) — injects the project's "Where we are", uncommitted file count
    and last passing check into the opening context
  - `record-test.ps1` (`PostToolUse`) — writes a timestamp when the machine check output says it
    passed. **The evidence rule, moved off the human.**
  - `gate-commit.ps1` (`PreToolUse`) — exit 2 blocks `git commit` when watched code is newer than
    the last passing check
- `hooks/test-hooks.ps1` — 16 assertions, one command, no Claude session needed
- `hooks/install-hooks.ps1` — merges into a project's `.claude/settings.json` without overwriting

**Verified, not assumed**

- Hook events, exit-code semantics and matcher rules checked against the current documentation
  rather than recalled. Exit **2** blocks; exit 1 does not — a gate returning 1 would silently
  allow every commit.
- The suite was **run**: 16 passed, 0 failed, under PowerShell 7 on Linux before delivery.
- **A real bug was found by running it:** `Get-Item` skips dot-prefixed files without `-Force` on
  Linux. Harmless on Windows, fatal in the test sandbox. Fixed in `gate-commit.ps1` too.
- All five scripts are ASCII-only and written with a UTF-8 BOM, because Windows PowerShell 5.1
  decodes a BOM-less file as Windows-1252 — the bug that mangled an em dash earlier the same day.

**Constraints this machine forced**

`bash` and `jq` are both absent, so every Bash example in the hooks documentation would fail here.
PowerShell **5.1** only: no `-AsHashtable`, no `??`, no ternary, `-NoProfile` mandatory.

**Still not done**

- Making the `reviewer` agent run. There is an `agent` hook type but the docs on it are thin, and
  nothing here is built on an unverified claim. Next round: hook it, or delete all three agents.
- A session-end question. `SessionEnd` cannot block and has a 1.5-second budget, so it cannot ask.

---

## v1.0 — 2026-08-24 — first usable release

The version to start building with. Nothing here is new capability; it is the point at which the
kit stopped being a work in progress.

**Added**

- `CHANGELOG.md` — this file. Released versions are now fixed points.
- `SKILLS.md` — all 24 skills mapped by whether they have ever fired, and what triggers each one.
  Nothing deleted; the dormant ones are named as dormant.
- `templates/ASA-HUB.md` — one note to navigate from. The door into everything else.
- `PLAYBOOK.md` §14 — the improvement loop, made mechanical: one closing question per session.
- `PLAYBOOK.md` §7 rule 8 — **a retired term is a banned term.**

**Changed**

- `START-HERE.md` — step 6 is the Asa Hub; the sharing section is honest about what sharing
  would require.
- Stage 0 (`sketch-the-product`) is now listed in the day-one table rather than only in §3.

**Known limits, stated rather than hidden**

- **15 of 24 skills have never fired.** They are documented and left in place. `SKILLS.md` says
  which, and each has a written trigger.
- **3 agents exist; none has ever run.** Three rounds of real work went past without one firing.
  That is a finding, not a feature.
- **One user.** Everything is structured so a second person is possible, but nothing has been
  tested by anyone else, so no claim is made that it works for them.
- **The evidence rule has been skipped three times.** Pattern 1 in `KIT-LOG.md` documents two
  attempted fixes. The second has not yet been tested over enough sessions to say it holds.

---

## Before v1.0

Not versions — a folder that changed daily. Kept here so the shape of the learning is visible.

| Date | What happened |
|---|---|
| 2026-08-24 | Stage 0 added: sketch the whole product before the first feature. Found by the Boss, not by any audit. |
| 2026-08-23 | `SCALING.md` and five scaling skills added after the Boss overruled the argument against them. |
| 2026-08-22 | `process-audit` run against the kit itself: nine real defects, including the reviewer agent's instructions existing twice and already drifted. |
| 2026-08-22 | `BOSS.md` added — a profile built from dated corrections in his own words. |
| 2026-08-21 | v4 of the playbook: every invented name replaced with the term real developers use. |
| 2026-08-21 | First version. Five stages, one project. |

---

## How a version gets cut

0. **The version number is changed last.** `VERSION` is bumped after the changelog entry exists,
   never before — otherwise the file that exists to detect drift ships already drifted, which
   happened on v1.4's first run.
1. The current work is finished and committed.
2. `KIT-LOG.md` patterns are read. Anything seen **twice** becomes a change; anything seen once
   stays a log line.
3. The changes go in the **Added / Changed / Removed** lists above, with the version and date.
4. **Known limits are written down.** A release that hides what has not been tested is how a kit
   loses the trust of the person using it — including when that person is you in four months.
5. Only then does the version number change.
