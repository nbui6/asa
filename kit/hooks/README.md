# Hooks — the rules that fire without being remembered

`PLAYBOOK.md` §11: *"When a trigger keeps getting skipped, stop trusting instructions and make it
mechanical. Instructions are advisory; a hook is not."*

These are that. Three hooks, one config file, one test suite.

---

## What each one does

| Hook | Fires on | Blocks? | Job |
|---|---|---|---|
| `orient.ps1` | `SessionStart` | no | Prints the project's state into the opening context |
| `record-test.ps1` | `PostToolUse`, Bash | no | Records a timestamp when the machine check passes |
| `gate-commit.ps1` | `PreToolUse`, Bash | **yes** | Refuses `git commit` if code changed since that pass |

The last two share one file — `.claude/hooks/.last-pass` — so they can never disagree about
whether the project is tested.

**What this fixes, with the numbers that justified it:**

| Chronic problem | Count before hooks |
|---|---|
| The evidence rule gets skipped | 3 times, fixed twice by rewording, still failing |
| Rounds called done without a run | Rounds 0, 1 and 2 |
| Resuming cold with no context | Every session |

---

## Install into a project

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File install-hooks.ps1 -Project "C:\path\to\repo"
```

It writes `.claude/hooks/*.ps1`, `.claude/hooks/check.json`, and merges the hook entries into
`.claude/settings.json` without touching anything else already in that file.

Then tell it what your machine check is — `.claude/hooks/check.json`:

```json
{
  "command": "flutter test",
  "passMarker": "All tests passed",
  "watch": ["lib", "test"]
}
```

| Field | Means |
|---|---|
| `command` | Substring that identifies your pass/fail command |
| `passMarker` | Text the output must contain to count as a pass |
| `watch` | Folders whose file times decide whether the pass is stale |

**`passMarker` is not optional rigour.** Some runners exit 0 while reporting failures, so the exit
code alone is not evidence. The output has to say it passed.

**Delete `check.json` to opt a project out.** No config, no gate.

---

## Test them

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File test-hooks.ps1
```

34 assertions against fixture JSON in a temp sandbox. No Claude session, no network, no real repo.

**What is actually being tested is the exit codes**, because on `PreToolUse` **2 blocks and
everything else does not**. A gate that returns `1` when it means "no" allows every commit, and
nothing on screen would show it. That failure is invisible without this suite — which is why the
suite exists.

---

## Windows notes, all of them learned the hard way

| Constraint | Why |
|---|---|
| **PowerShell, not Bash** | `bash` and `jq` cannot be assumed present on Windows, and every Bash example in the official docs parses the hook's JSON with `jq`. |
| **`-NoProfile` always** | A profile that echoes anything corrupts the hook's stdout, and JSON parsing fails silently. |
| **`-ExecutionPolicy Bypass`** | Default policy refuses unsigned `.ps1`. |
| **Written for PowerShell 5.1** | So: no `-AsHashtable`, no `??`, no ternary. They also run under `pwsh` 7 — 5.1 is the floor, not an assumption about your machine. |
| **ASCII output only** | 5.1 mangled em dashes in a script earlier the same day. `orient.ps1` strips non-ASCII before printing. |

---

## Design rules these follow

**1. Fail open, except the gate's own config.** A hook that cannot read its input exits 0 and lets
work continue. A broken tool must not become a broken workflow. The one exception is a `check.json`
that exists but will not parse — that is a mistake worth stopping for, because silently ignoring it
would mean the gate is off while it looks on.

**2. `--no-verify` always works.** A gate with no override gets switched off entirely the first
time it is wrong. An override that leaves a trace in the commit is better than a disabled hook.

**3. Never rewrite the command.** These allow or refuse. Hooks can rewrite tool input; when two
hooks do, the last to finish wins and they run in parallel, so the result is non-deterministic.
Not worth it.

**4. `record-test` never clears a pass.** A failing run leaves the old timestamp alone. The gate
compares that timestamp against file times, so a stale pass is caught anyway — and clearing it
would hide that the project ever worked.

---

## What is deliberately not here

**Making the `reviewer` agent run.** 0 runs so far is the loudest number in the kit. There
is an `agent` hook type, but the documentation on it is thin, and this file does not build on
anything unverified. The next round decides one of two things: hook it, or delete all three agents.

**A session-end question.** `SessionEnd` cannot block and has a 1.5-second budget, so it cannot ask
anything. Prompting for the improvement question needs a different mechanism.

---

## Sources

Verified against the documentation on 2026-08-24 rather than recalled:

- [Automate actions with hooks](https://code.claude.com/docs/en/hooks-guide)
- [Hooks reference](https://code.claude.com/docs/en/hooks)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
