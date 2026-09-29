# FEEDBACK.md — fill this in and send it back

**Tester:** <name>  ·  **Kit version:** <see VERSION>  ·  **Dates:** <from> – <to>
**What you built:** <one line — what it was, and did it end up working?>

> **Ten minutes, and please be blunt.** *"It was good"* cannot change anything. *"I skipped stage 0
> because I already knew what the screen looked like"* changes the kit. Every question below exists
> because a vague answer to it once cost a session.

---

## 1. The numbers

| | |
|---|---|
| How many sittings, and roughly how long each | |
| How far did you get | *(day one / first round finished / committed something / gave up at …)* |
| **Did the process ever stop you building?** | yes / no — and where |
| Would you use it again without being asked | yes / no / only parts |

## 2. What you skipped — the most valuable section

**Every step you did not do, and why.** Not a confession; the most useful data in the test. A step
that gets skipped is wrong, badly placed, or badly explained, and only you can say which.

| Step | Why you skipped it | Did skipping it cost you anything later? |
|---|---|---|
| | | |

## 3. Where you got stuck

**Each time you were lost, blocked, or had to re-read something three times.**

| What you were trying to do | What happened | How you got out (or didn't) |
|---|---|---|
| | | |

## 4. Sentences you did not understand

**Quote them.** Copy the line and the file. The kit is written for someone who is not a professional
developer, so a sentence that assumes otherwise is a defect, not your fault.

| File | The sentence | What was unclear |
|---|---|---|
| | | |

## 5. The assistant

The kit is half process and half instructions to the AI. So:

| | |
|---|---|
| Did it ever ask you to do something **it could have done itself**? | *(copy-paste, moving files, finding a download)* |
| Did it ever tell you something was done **when you had not seen it work**? | |
| Did it explain things at the right level — too much, too little, or wrong? | |
| Did any **skill** fire when it should not have, or fail to fire when it should? | *(the list is in `SKILLS.md`)* |

## 6. The scripts

| | Worked? | If not, the exact error |
|---|---|---|
| `install-skills.ps1` | | |
| `hooks\install-hooks.ps1` | | |
| `hooks\test-hooks.ps1` | | |
| `check-boundaries.ps1` | | |

## 7. Three questions with no right answer

1. **What is the kit obviously missing?**

2. **What in it is pure ceremony** — something you did because you were told to, and it changed
   nothing?

3. **If you could delete one part of it, which?**

## 8. Anything else

*(Including: this is written for someone who is not me, and here is how.)*

---

**Send this file back.** It gets read, recorded in `KIT-LOG.md` with your name and the date, and
turned into the next version — which comes back to you. **A complaint you make twice becomes a
change**; the kit's own rule is that nothing changes on one sighting.

## Collected from projects - 2026-09-01

- **partner-trial-process** - 2026-09-01 - Switched from one file per decision to a single `decisions.md` log — *"too much file overhead for a project this size"*. **The reason was written at the bottom of the project note, where nothing looks.** A review an hour later recommended the opposite, unaware. _(convention changed)_

## Collected from projects - 2026-09-29

- **asa** - 2026-09-02 - Personal data could be written into a project note with nothing checking it. Raised from another project's FEEDBACK.md, caught by the session that did it. **`check-notes.ps1` written the same hour** — it scans every note for the things that travel with a name: address, phone, email, bank number. **It cannot detect a name on its own**, and that limit is in its header so nobody trusts it further. _(rule got a check)_
- **asa** - 2026-09-28 - The deciding session stamped nine log entries with clock times up to 19:10 while the laptop said 14:36 — guessed, not read. Removed; the Instruction for AI §12 now says a time is written only after reading the clock. _(rule)_
- **asa** - 2026-09-28 - A request ("get rid of my name everywhere") was read too widely and 111 files were changed at once, with no copy to go back to; undone by reversing it, not exactly. Two lessons: ask one question before a change across many files, and a mass change needs a backup first (→ 0037). A guessed clock time slipped in once more the same afternoon and was caught before sending. _(rule)_
- **asa** - 2026-09-28 - The convention of showing and asking per round (hard rule 19, `PLAYBOOK.md` section 8) was replaced by one whole delivery, and the reason was given in passing — in the author’s words, *"I am annoyed it keeps giving me small tasks... Always log and commit often in the process, this actually should be part of Asa tool rule"*. Recorded as ADR 0047 and as Asa’s own rule 17, and nowhere here — the kit still teaches the per-round show-ask-yes loop. Filed by the daily sweep on 2026-09-29, not by the session that changed it. _(convention changed)_
- **data-retention** - 2026-09-08 - The project moved from one file per decision to a single `decisions.md` log, and the reason was written only in that file’s own header — in the author’s words, *"One log, not one file each. Chosen for this project because the file overhead was not worth it at this size."* It was never recorded here, which rule 18 calls mandatory. Date taken from the log’s first entry; the header itself is undated. Filed by the daily sweep on 2026-09-23, not by the session that changed it. _(convention changed)_
- **data-retention** - 2026-09-23 - The two findings below this table, both dated 2026-09-08, were written as bullet points instead of as rows in it. `collect-feedback.ps1` reads only pipe-table rows, so neither has ever been collectable, and the script reports no new feedback rather than naming them — three weeks stationary and absent from every count of waiting findings made since. The lines are fine; the shape is what the channel cannot see. _(format mismatch)_
- **learning** - 2026-09-03 - A question about a screen was written in the code's vocabulary — "provenance block", "derived from the first paragraph" — and got *"I dont understand your question."* Rewritten as "the grey box at the bottom", it was answered in seconds. _(**A question is not asked until it is asked in his language.** Test: could he point at the thing it is about?)_
- **learning** - 2026-09-03 - The same two choices, drawn as five-line sketches of each outcome, worked where prose had failed. _(For anything about a screen, **draw the options, do not describe them.**)_
- **learning** - 2026-09-03 - The analysis behind this project was first delivered as a PNG. He rejected it: a plan that gets updated weekly cannot be a picture. _(**Match the format to the lifespan.** A picture for a decision at a moment; a file for anything that changes.)_
- **learning** - 2026-09-03 - Asked what was missing from the map, the answer was a rendered lesson nobody had asked for. His reply: *"What is the layers png for?… Dont invest time and efforts in creating things like this png, without a real reason."* _(**Answer the question asked.** A gap in a map is fixed by editing the map, not by teaching the missing thing on the spot. And the *match the format to the lifespan* rule was written one message earlier and broken immediately — a rule is not learned until it survives the next opportunity to break it.)_
- **learning** - 2026-09-03 - He restated the requirement in one sentence — *"keep track of the things I plan to learn, where I am in it, and also notes in each of it. Asa just need to give an overview and link"* — and it was smaller and clearer than anything built for it so far. _(**Ask for the requirement in one sentence before building the structure.** Three nouns and a scope, from him, beat an analysis.)_
- **license-commerce-integration** - 2026-09-03 - A schema reference document was kept up to date by **appending corrections** to it as understanding changed. After several rounds it reached 677 lines of layered "corrected 2026-09-0X" notes and the reader said plainly: *"I am confused, give me the schema again."* Reference docs and decision logs need opposite handling - the log accumulates, the reference gets rewritten clean and the history moves to the log. Nothing in the process said so. _(practice that did not work)_
- **marketing-system-roadmap** - 2026-09-21 - A convention for two overlapping projects was set inside the project note and nowhere else: one project owns the work, the other references it. In the author's words — *"That work stays there -- this roadmap references it rather than repeating it."* The reason is one line in a note; no process file says how overlapping projects divide ownership. Filed by the daily sweep on 2026-09-22, not by the session that wrote it. _(convention changed)_
- **partner-trial-process** - 2026-09-01 - Switched from one file per decision to a single `decisions.md` log — *"too much file overhead for a project this size"*. **The reason was written at the bottom of the project note, where nothing looks.** A review an hour later recommended the opposite, unaware. _(convention changed)_
- **partner-trial-process** - 2026-09-02 - A session wrote a realistic-looking personal name and address into a **project note** as an illustrative example. Caught by the session itself, not by anything else. `check-shareable.ps1` scans the kit repo and `collect-feedback.ps1` scans FEEDBACK rows - **project notes are scanned by neither**, so the "no personal data" rule applies there with no check behind it. Writing an example is exactly when a session reaches for something realistic. _(rule with no check)_
- **Pet** - 2026-09-14 - The project's fuller working history was deliberately kept in an assistant's own cross-session memory as well as in this folder — in the author's words, *"so a future Claude session on any device still has it even without this folder connected"*, with the on-disk file described as *"the on-disk copy ... readable with no AI involved."* The folder stops being the only channel between sessions: a second channel exists that no other session and no human can read, and nothing reconciles the two. Filed by the daily sweep on 2026-09-22, not by the session that wrote it. _(convention changed)_
