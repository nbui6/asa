# Glossary

Every term this kit uses. All of these are words real developers use — none are invented for this
document. Look one up, then get back to work.

**Each entry has up to three parts.** Added 2026-08-25, because an explanation given in a
conversation is gone by the time you read the log four months later.

| Part | |
|---|---|
| **The term**, and the real full name if it has one | So you can search for it outside this project |
| **What it is**, plainly — and *why it mattered here*, dated | A definition you could look up anywhere is worth nothing. The reason it cost you an evening is worth everything. |
| ***An analogy, in italics*** | Only where a plain sentence does not land on its own |

**Two rules about the analogies, both learned the hard way.**

1. **An analogy may illustrate a conclusion. It may never *be* one.** On 2026-08-24 an analogy in
   this project ("a car dashboard shows measured state, a map shows the plan") was used to argue a
   design decision, and the Boss rejected it in four words: *"a car dashboard can have GPS."* He was
   right. The argument has to stand on its own before an analogy is allowed near it.
2. **No analogy is better than a forced one.** Where the plain sentence is already clear, adding
   one is noise — and a near-fitting analogy actively misleads, because the parts that do not
   correspond are invisible.

---

## Process

**Acceptance criteria** — the conditions that must be true for *this specific piece of work* to
count as done. Written before any code.

**Definition of done** — the standing bar that applies to *every* piece of work in the project
(e.g. tests pass, reviewed, committed). Written once.

**Backlog** — the list of things you decided not to do yet. Ideas go here instead of into the
current work.

**Charter** — one page saying what you are building, for whom, and what it explicitly is not.

**Milestone** — a chunk of work with an outcome. **Checkpoint** — the moment you stop and look.

**Retrospective (retro)** — a short review at a checkpoint where you change how you work, not
what you build.

**Scope creep** — the project quietly growing. The main cause of unfinished side projects.

**Spike** — a small throwaway piece of code written only to answer a question. Deleted after.

**Blast radius** — how much can break from one change. Keep it small so a failure has one
possible cause.

---

## Git

**Repository (repo)** — a folder whose history git tracks.

**Commit** — a save point. Lives on your disk. Sends nothing anywhere.

**Remote** — a server your repo can be connected to (GitHub, Azure DevOps). None exists unless
you add one.

**Push** — upload commits to a remote. This is the step that publishes. `commit` ≠ `push`.

**Branch** — a parallel line of work. `main` or `master` is the default one.

**Diff** — the exact lines a change adds and removes. What a reviewer reads.

**Revert / roll back** — return to an earlier commit. This is why commits are free and worth
making often.

**`.gitignore`** — a file listing what git must never track. Where secrets are kept out.

---

## Code and tooling

**PATH** — the list of folders your operating system searches when you type a command. "Command
not recognized" almost always means PATH, or a terminal window opened before PATH changed.

**Dependency / package / library** — code someone else wrote that your project uses. Every one
is something you must understand, update and eventually debug.

**Package manager** — the tool that installs dependencies (`npm`, `pip`, `pub`).

**Build** — turning source code into something runnable. Also used loosely to mean "write the
code".

**Compile error** — the code is not valid and nothing ran. **Runtime error** — it ran and then
broke.

**Stack trace** — the list of function calls at the moment something broke. Read it from the
bottom up; the top is usually library code, the useful line is yours.

**Side effect** — a function doing something beyond returning a value (writing to a database,
sending an email). Hidden side effects are the hardest thing to catch by reading.

**Refactor** — changing how code is written without changing what it does.

**Regression** — something that used to work and stopped. What automated tests are mainly for.

**Linter / static analysis** — a tool that reads your code without running it and flags
problems.

**Test suite** — the collection of automated checks. **Unit test** — checks one small piece.
**Integration test** — checks pieces working together.

**Environment variable** — a value supplied to a program from outside its code. How secrets stay
out of files. Often kept in a `.env` file, which goes in `.gitignore`.

**API** — a way for one program to ask another program for something.

**Frontend** — what the user sees. **Backend** — the part on a server. A project can have no
backend at all, and often should not have one at first.

**Data model** — how your information is structured. The decision that is most expensive to
change later.

---

## AI assistant

**Context / context window** — everything the assistant can currently see: your messages, files
it has read, its own previous output. It is finite, and performance degrades as it fills.

**Compaction** — the assistant summarising older parts of the conversation to make room. Details
get lost, which is why decisions belong in files, not in chat.

**Hallucination** — the assistant producing something plausible and wrong. Most common with
version numbers, menu paths, library names and API details. This is why the kit asks for
commands and their output rather than claims.

**Skill** — a set of instructions the assistant loads when a matching job comes up.

**Agent / subagent** — a separate assistant with its own context. Useful when *not* knowing your
reasoning is the point, as with code review.

**Hook** — a script that runs automatically at a fixed moment and can block until it passes.
Instructions are advisory; a hook is not.

**Plan mode** — a read-only mode where the assistant explores and proposes, but cannot edit.

**MCP** — a way to connect an assistant to an external tool or data source.

---

## Product

**Persona** — a written description of a specific user, concrete enough to disagree with.

**Acceptance test** — the act of checking a built thing against its **acceptance criteria**. The
criteria are the written conditions; the test is running through them.

**MVP** — the smallest version that is genuinely useful to one real person. Not "a bad version
of the full thing".

**Technical debt** — a shortcut you took that will cost more later. Fine when named and written
down; expensive when silent.

**GDPR** — the EU regulation on personal data. Relevant the moment your software touches
information about a person, including names and email addresses.

---

## This kit's own terms

**Trigger** — the moment a rule fires. The kit's central idea: a rule whose moment cannot be named
will not happen.

**Handover check** — the three lines (Exists? / Checked? / Honest?) that accompany anything the
assistant hands you, each carrying a real command and its output.

**Machine check** — the one command that says pass or fail for the project. Also called the
pass/fail command.

**Human line / machine line** — the two halves of a set of acceptance criteria: what you observe,
and what a command proves.

**Regression gate** — the machine check promoted to blocking: nothing merges while it is red.

**The loop** — change one small thing → run it → check it → commit. Distinct from a product's
**core loop**, which is the main path a *user* takes through the software.

**Two-strike rule** — after two failed attempts at the same problem, clear the context and rewrite
the prompt instead of trying a third time.

**Verified findings** — things measured on your machine, with a date. The docs are a claim; the
running system is the fact.

**Complexity log** — one line for anything clever that survived, and why the boring version was
not enough. A receipt, not a ban.

**Architecture map** (`ARCHITECTURE.md`) — one page: where things live, what may depend on what,
where a new thing goes.

**Module contract** — what a part of the system declares: what it offers, owns, needs, and its
settings. Everything else is private.

**ADR — architecture decision record** — one page per significant decision: context, options, the
choice, and what would change it. Real, widely used term.

**Non-functional requirements** — the things nobody asks for and everybody assumes: permissions,
audit, backups, monitoring, accessibility, cost.

**Drift** — documents and reality quietly diverging. Nothing fails when it happens, which is why
it needs a scheduled check.

---

## Build, tooling and platform terms

**Definitions live here. Measurements do not.** Every entry below was learned the hard way on a real
round — but *"the first Gradle build took 10 m 26 s on this laptop"* is a fact about **a machine**, and
*"this app receives its text through the share sheet"* is a fact about **one product**. Those belong
in `MACHINE.md` and in the product's own glossary. `PLAYBOOK.md` §14, **Three homes**.

So each entry here is the general term, plus the general lesson, and nothing that is only true of one
laptop or one app. *Split out on 2026-08-26, when a quarter of this file turned out to be one
product's build log.*

**APK — Android Package** — the single installable file an Android app ships as; Windows' `.exe` is
the closest equivalent. `flutter build apk` writes it to `build\app\outputs\flutter-apk\`.
**Producing one is not installing one** — a build that succeeds has put a file on your laptop and
nothing on your phone.

**Gradle** — the build system Android uses. It reads the `build.gradle.kts` files, fetches whatever
they name, and compiles. **The first build of a project is minutes and later builds are seconds**,
because the first one downloads the world.
*Like a kitchen that has to be stocked before the first meal and is stocked from then on.*

**NDK — Native Development Kit** — the toolkit Android needs to compile C and C++ code. **A Flutter
version can pin one exact NDK version and be unable to install it**, because the installer it calls
(`sdkmanager`) is deprecated. Symptom: a long build ending in *"Android sdkmanager did not install
NDK …"*. Fix by hand: Android Studio → SDK Manager → SDK Tools → **tick "Show Package Details"** →
the exact version named in the error.
*Like a machine that takes one specific drill bit: it will not accept a near-equivalent, and it will
not go out and buy one for you.*

**API level** — the version number of Android's own toolkit, and **not** the version on the phone.
Android 15 on the handset is API 35, while the laptop may build against 36 or 37. **An app built
against a higher level still runs on a lower phone**, as long as its declared minimum is lower still
— which is why *"install API 36"* and *"my phone says 15"* are both correct at once.

**SDK Manager** — the screen inside Android Studio that installs pieces of the Android toolkit.
**"Show Package Details" is the checkbox that matters**: without it you are offered "latest" only, and
cannot pick the one exact version something pins.

**`flutter doctor`** — a self-check that lists what Flutter thinks is installed. It shells out to other
tools and **can report a problem that does not exist, or miss one that does.** The general rule, and
it applies to every tool of this kind: **treat a self-check as a hint. The build is the fact.**
*(Dated instances: `MACHINE.md`.)*

**Share sheet** — the panel Android slides up when you tap *Share*, listing the apps that can receive
what you are sharing. It is part of Android, not of any one app, and **any app can register to appear
in it.** Which means a product can receive text from any other app with **no export, no file, and no
dependency on one specific partner app** — often the cheapest integration available.

**Line endings — CRLF and LF** — Windows ends a line with two invisible characters, Linux and Mac with
one. Git hides this with `core.autocrlf`. **Run git against a Windows repo from a Linux-side tool and
that setting is absent**, so every file in the repo reads as changed — thousands of insertions and
deletions that are byte-identical once the extra character is stripped. Check with
`git -c core.autocrlf=true diff` before believing a huge diff.
*Like two countries writing dates as 08/25 and 25/08 — same day, and every line looks wrong.*

**`.git/index.lock`** — a file git creates while it works and deletes when it finishes, so two git
processes cannot write at once. **A tool that can create files but not delete them leaves the lock
behind**, and every later `git add` fails with *"Another git process seems to be running"*. Fix:
delete the lock, once you know nothing is actually running.
*Like a key left in a door that only opens from the other side.*

**Mandatory parameter (PowerShell)** — a script input with no default. PowerShell asks for it by
printing the parameter's *name* and nothing else — so a `-Project` that wanted a full path prompts
`Project:` and reads as a request for a project *name*. **A prompt that shows only a name is not a
question anybody can answer**: give the parameter a default and a real error message instead.

**TSV — tab-separated values** — a plain text table, one row per line, columns split by tab
characters. **Anki imports it directly** with a `#separator:Tab` header line, so writing cards Anki
can read needs no library at all.

**Spaced repetition** — reviewing something at growing intervals — tomorrow, then three days, then ten
— and resetting to tomorrow when you get it wrong. **Arithmetic, not AI**, which is why it never needs
a model.

**FSRS — Free Spaced Repetition Scheduler** — the published algorithm that decides those intervals,
built into Anki and available as a package in several languages. Worth taking over inventing one: it
is free, instant, and gives the same answer every time.
