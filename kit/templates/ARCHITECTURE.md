# Architecture — <project>

**One page. If it grows past that, it has stopped being a map.**
Updated in the same commit as any change that adds, moves or removes a part.

Last checked against the actual folder tree: `<date>`

---

## In one sentence

<What this system is and what it does. If a newcomer reads only this line, what must they know?>

## The layers

<Draw it. The arrows matter more than the boxes.>

```
app/       ← entry point, navigation, wiring
   ↓
modules/   ← features. May import core. Never each other.
   ↓
core/      ← storage, settings, shared services. Imports nothing above.
```

## Where things live

<In the words someone would actually search for, not in architecture vocabulary.>

| I need to… | It lives in |
|---|---|
| change what a screen looks like | `…` |
| change how something is stored | `…` |
| add a setting | `…` |
| change what happens on startup | `…` |

## Rules, and how each is enforced

<A rule enforced only by memory is already broken somewhere.>

| Rule | Enforced by |
|---|---|
| `modules/` may import `core/`, never the reverse, never each other | `<lint rule / script>`, part of the machine check |
| One owner per piece of data | Review |

## Where a new thing goes

| Kind of thing | Goes in | Copy from |
|---|---|---|
| A new feature | `modules/<name>/` | `modules/_template/` |
| Something two features share | `core/<area>/` | — |

## What each module declares

<The same four or five items for every module, so nobody has to guess.>

- **Offers:** <its public surface>
- **Owns:** <its data>
- **Needs:** <shared services it depends on>
- **Settings:** <what a user can configure>

Everything not declared is private.

## What deliberately does not exist

<"There is no backend." "There is no shared utils folder." These lines prevent well-meaning
damage. Give the reason.>

| Not here | Why | What would change it |
|---|---|---|

## Known differences between this map and reality

<Honest list. An honest map of a messy system is useful; an aspirational one is a lie. Each line
should have a backlog entry.>

| Where reality differs | Backlog entry |
|---|---|
