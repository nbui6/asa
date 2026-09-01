# Toolchain — <project>

**What this project actually runs on**, what each part owns, and which parts of the kit apply.
Updated in the same session as any tool joining or leaving. Last checked: `<date>`

---

## 1. The tools

| Tool | Built / adopted | Owns | Must not | Replaceable? | Review |
|---|---|---|---|---|---|
| | | | | | `<date>` |

<Every job has exactly one owner. If two tools could do something, decide which does — and write
the other one's "must not". That line is what prevents duplicated work later.>

<Adopted tools are dependencies with no manifest entry. Give each a review date and let the
`stack-review` agent read this table.>

## 2. System context

<Who uses it, what you build, what you adopted, and what data passes between them. One screen.
The arrows matter more than the boxes. Mark anything reached by two tools — that is where drift
starts.>

```
        <person>
            │ uses
            ▼
   ┌──────────────────┐                 ┌────────────────┐
   │  <what you build>│ ───────────────▶│ <shared data>  │
   └──────────────────┘                 └────────────────┘
            │                                  ▲
            ▼                                  │
     <adopted tool> ────────────────────────────
```

## 3. Boundaries that must not move

<The two or three lines you will be tempted to cross. Written as what *not* to do, because that
is the only place in this kit where a prohibition beats a positive rule — a boundary is defined
by its edge.>

- <e.g. "The built tool never becomes a text editor. Prose is written in the assistant.">

## 4. How this kit applies here

**Skills that apply, with any project rule they take on:**

| Skill | Project-specific rule |
|---|---|

**Skills that do not apply, and why:**

| Skill | Why not |
|---|---|

**Triggers set for this project:**

| Skill | Fires when |
|---|---|

**What this project adds that the kit does not have:**

<Conventions this project needs. Frontmatter fields, naming, folder rules.>

## 5. Known risks in the toolchain

| Tool | Risk | What we would do |
|---|---|---|

<Unmaintained plugins, single-maintainer projects, anything whose disappearance would hurt. An
adopted tool that breaks is a trigger, not an emergency — if the data is plain files.>
