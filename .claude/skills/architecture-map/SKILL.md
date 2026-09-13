---
name: architecture-map
description: Create and maintain ARCHITECTURE.md — the one page that says where everything in a project lives, what may depend on what, and where to add a new thing. Use this on day one of any project, whenever a new module, folder or major component is added, whenever someone asks where something should go or where a given feature lives, when a codebase has grown past what fits in one head or one context window, or when onboarding anyone (human or agent) who has to navigate the code. Also use when files are hard to find, similar code exists in two places, or the folder structure no longer matches what the project does. Do not use it to define the contract between two modules or what one module may import from another (that is module-contract, which fires at the second module).
---

# The architecture map

One page that answers three questions without reading any code:

1. **Where does a given thing live?**
2. **What is allowed to depend on what?**
3. **Where does a new thing go?**

It costs twenty minutes on day one. Written after the fact it takes days and is wrong, because
by then the structure is whatever happened rather than whatever was intended.

---

## Why this matters more with an assistant than without

An assistant's view of your codebase shrinks as the codebase grows — it can only hold so much at
once. Past a certain size it stops seeing the whole project and starts guessing, and the
characteristic failure is **writing a second copy of something that already exists**.

`ARCHITECTURE.md` is the fix: a map small enough to read every session, accurate enough to
navigate from. The assistant reads the map, then loads only the files the map points at.

The same file is what lets a new human be useful on day one instead of week three.

---

## What goes in it

Keep it to one page. A map the size of the territory is not a map.

**1. The layers, and the dependency direction.** Draw it, even in plain text. The arrows are the
important part — a diagram with no direction is decoration.

```
app/      ← the shell: navigation, entry point, wiring
  ↓
modules/  ← features. May import core. Never each other.
  ↓
core/     ← storage, settings, shared services. Imports nothing above it.
```

**2. A table of where things live**, in the words someone would search for.

| I need to… | It lives in |
|---|---|
| change what a screen looks like | `modules/<name>/ui/` |
| change how something is stored | `core/storage/` |
| add a setting | `core/settings/` |

**3. The rules that must not be broken**, with how each is enforced. A rule enforced only by
memory is a rule that is already broken somewhere.

> `modules/` may import `core/`. Never the reverse. Never each other.
> Enforced by: `<the lint rule or check>` — run by the machine check.

**4. Where a new thing goes.** One line per kind of thing. This is the section people actually
use.

**5. What deliberately does not exist**, and why. "There is no backend" and "there is no shared
utils folder" prevent a lot of well-meaning damage.

---

## Choosing the boundaries

The boundary that matters is the one that lets someone **change one thing without reading
everything**.

- **Split by feature, not by file type.** `modules/invoices/` beats a `controllers/` folder
  holding thirty unrelated controllers. Feature folders keep a change in one place.
- **One direction only.** Circular dependencies are what turns a codebase into one big thing
  where everything must be understood at once.
- **A shared layer is for things genuinely shared by two or more features.** A `utils` folder
  that everything imports is a boundary that failed.
- **Fewer, clearer boundaries beat many precise ones.** Three folders someone can hold in their
  head beat twelve that are theoretically correct.

---

## Make the rule mechanical

A dependency rule written in a document decays. Whenever the language allows it, enforce it:

- an import lint rule, a layered-architecture check, or a small script that greps for forbidden
  imports
- run it as part of the machine check, so a violation fails the build rather than being noticed
  in review

If no tool exists, a fifteen-line script that fails on a forbidden import string is enough. The
point is that it fails, not that it is sophisticated.

---

## Keeping it true

An architecture map that has drifted is worse than none, because people trust it.

| Moment | What happens |
|---|---|
| A new module, folder or service is added | The map is updated **in the same commit** |
| The dependency rule changes | The map and the enforcing check change together |
| At each checkpoint | Re-read it against the actual folder tree and fix the differences |
| A new person cannot find something | That gap goes in the map, and nothing else |

The `reviewer` agent should check that a change adding a new part also updated the map.

---

## Starting from an existing mess

If the project already exists and has no map:

1. List the top-level folders and say, honestly, what each one actually holds today — including
   "mixed, unclear".
2. Draw the dependencies that **actually** exist, not the intended ones. Grep the imports.
3. Mark the ones that violate the direction you want. Do not fix them yet.
4. Write the intended structure next to the real one, and turn each violation into a backlog
   entry with a trigger.

An honest map of a messy system is immediately useful. An aspirational map of it is a lie.

---

## One question to ask every time: is any of this content rather than code?

Ask it while drawing the map, because the answer changes the folder tree:

> **Is there material here that will grow topic by topic for years while the code stays the same?**
> Grammar rules, lesson sets, checklists, a catalogue, procedures, a lookup table.

If yes, **it is data, and it belongs in files the product loads — not in source code.** Written into
a `const` list or a `switch`, every new topic becomes a code change, a build and a release, and
nobody without a developer can add anything.

The map's job is three lines:

1. **Where the content files live**, as their own layer — with the rule that code may read them and
   they may never reach back
2. **Which one part loads and validates them**, so a malformed file fails in one place, loudly, and
   the rest of the app never sees a half-loaded pack
3. **A pointer to the ADR that fixed the format.** The format is a one-way door: change it at file
   twenty and all twenty need migrating. `templates/ADR.md`, dated, with the rejected options.

Then stop. **How that product's content is actually shaped — the schema, the fields, what counts as
valid — is the product's own knowledge**, and it goes in a skill in the product repo:
`templates/PRODUCT-SKILL.md`, and `PLAYBOOK.md` §14 for which library it belongs to.
