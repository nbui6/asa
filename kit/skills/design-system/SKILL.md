---
name: design-system
description: Make many features look and behave like one product — shared colours, spacing, type, components and interaction patterns, defined once and reused. Use this when a product will have more than two or three screens, when a second feature or module is being added, when screens built at different times look inconsistent, when several people build UI on the same product, or before any visual work on a product meant to grow. Also use when someone asks how to keep the UI coherent or why the app feels like separate tools stitched together. Do not use it to decide which screens should exist (that is sketch-the-product) or whether one screen fits the person using it (that is persona-check).
---

# Design system

`persona-check` asks whether **one screen** fits **one person**. This asks a different question:

> **Do ten features feel like one product, or like ten tools that happen to share a login?**

Nothing else in a growing product answers that, and it is the difference users actually notice.
They rarely say "inconsistent spacing" — they say it feels unfinished, and they trust it less.

---

## Why it is a structural decision, not a styling one

Assisted development makes this worse, not better. Each feature is generated in its own session,
each session makes reasonable local choices, and the choices differ. Six features later you have
four button styles, three date formats and two ideas of what "cancel" means.

Fixing that later means touching every screen. Deciding it once, early, costs an afternoon. Same
class of decision as the module seam: **cheap now, a rewrite later.**

---

## The smallest useful version — do this on day one

Not a component library. A single file of decisions, written down, that every screen refers to.

**1. Colour, as roles not values.** Name what a colour is *for*, never what it looks like.

```
background · surface · text · text-muted · primary(action) · danger · success · border
```

`primary` can change from blue to green in one place. `blue-500` scattered across forty files
cannot. Check contrast against a standard while choosing, not afterwards — it constrains the
palette, and finding out later means picking again.

**2. Spacing, on a scale.** One base unit and multiples: `4 · 8 · 16 · 24 · 32 · 48`. Any spacing
off the scale is a bug. This one rule removes most of the "feels sloppy" without any taste being
required.

**3. Type, three or four sizes.** Page title, section title, body, small. Two weights. That is
enough for an internal product, and more is how it starts to look accidental.

**4. Components with one definition each.** Button, input, card, table, dialog, empty state,
error state, loading state. Defined once, imported everywhere. **The last three matter most** —
they are the ones every session reinvents, and the ones users hit on their worst day.

**5. Interaction rules.** Where do errors appear? What happens while something loads? How is
"nothing here yet" shown? Where do destructive actions confirm? Decide once; these are the
inconsistencies people feel without naming.

**6. Content rules.** Date format, number format, capitalisation of buttons and headings, and the
vocabulary — if the persona says "renewal", the interface never says "subscription expiry". One
word per concept, written down.

---

## Do not build it from scratch

For an internal tool, use an existing component library and configure the tokens. Building a
design system is a project; configuring one is an afternoon. The `stack-choice` skill applies —
boring, well-documented, widely used beats novel.

The decisions above still have to be made. A library gives you the components, not the choices.

---

## Where it lives, and how it stays true

- `DESIGN.md` next to `ARCHITECTURE.md` — the tokens, the components, the rules. One page.
- The tokens live in **code**, in one file, imported everywhere. A design system that exists only
  as a document is a document.
- New component? It goes in the shared place and into `DESIGN.md`, in the same commit.
- The `reviewer` agent checks new UI against it: hard-coded colours, spacing off the scale,
  a fourth button variant, a date formatted a new way.

---

## Different users, one product

When there are sub-groups — different roles, ages, technical confidence — the answer is **one
system, adjusted**, not separate designs.

- **Same layout, different content.** Someone senior sees more; the shell is identical.
- **Progressive disclosure.** The simple path is the default; depth is one click away. This
  serves both groups without two designs to maintain.
- **Accessibility is the floor, not a variant.** The baseline and why it is often legally
  required live in the `non-functional` skill — apply it here rather than restating it.

Write a persona per sub-group (five minutes each) and check the same screen against each. Where
two genuinely conflict, that is a finding to surface — not something to average away.

---

## Checking it

At each checkpoint, put three screens built at different times side by side. Then ask:

1. Same spacing rhythm?
2. Same button and input treatment?
3. Same words for the same concepts?
4. Do the empty, loading and error states look like the same product?

Whatever fails is the next entry in `DESIGN.md` — and usually one shared component away from
being fixed everywhere at once.
