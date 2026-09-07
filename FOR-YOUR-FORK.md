# Working on your own version of Asa

**For the one other person building on this.** You want features for your own projects, you do not
want them shared, and you do not want our releases trampling them. That is all fine and it is now
written down.

> **Status, honestly: the deal below is agreed. Two of the three seams are not built yet.** They
> are **v0.1.1**, and v0.1 does not have a green check yet. What works today is the fork and the
> merge — which is the part that matters most. This file says what is agreed; it will say
> "shipped in `<hash>`" when it is.

---

## The deal, in three lines

1. **Your fork is yours.** We never fetch from it, pull from it, or ask for its URL.
2. **Our releases never touch your files.** `git merge` handles it, plus the seams below.
3. **Anything you send us describes our Asa, never yours.**

## Fork, and stay up to date

```
# once
git remote add upstream https://github.com/nbui6/asa.git

# whenever you want our latest
git fetch upstream
git merge upstream/main
```

`git merge` brings our changes in and leaves your files alone. If you keep your work inside the
seams below, this is boring every time — which is the point.

## Where your code goes

| | | |
|---|---|---|
| **Your own fields** | put any key you like in your project's frontmatter and read it as `project.extra['your_key']` | **needs nothing from us** — this is the cheapest way to add something, and worth trying before writing a screen |
| **Your own screens** | `lib/local/`, registered in `lib/local/local_hubs.dart` | **we never write in that folder again**, so it cannot conflict |
| **Everything else** | `lib/core/`, `lib/hubs/` — ours | edit these and you own the merge |

**Rules, same as ours:** `local/` may import `core/` and `hubs/`. Nothing imports `local/` except
the one registration point. `core/` imports no Flutter.

**Note there is no plugin loading.** Flutter compiles ahead of time on Windows, so your features
are compiled into your own build. That is why this is a fork and not a plugin folder — the
vocabulary would be nicer, the mechanics would be identical.

### If you have Developer Mode, you can do better than we can

**Asa uses no Flutter plugins at all, and that is a limitation of the machine it is built on, not a
design choice.** On Windows, building with any plugin needs symlink support, which needs Developer
Mode or admin rights. We have neither, so anything with native platform code — file pickers,
notifications, secure storage, tray icons — is out of reach here.

**Check whether it is out of reach for you too:**

```
start ms-settings:developers
```

If that toggle is switchable, **your fork can use plugins and ours cannot.** The most immediate
payoff is already wired up: the first-run folder chooser is a text box you paste a path into,
because we could not ship a real dialog. The seam is left in on purpose —

```yaml
dependencies:
  file_selector: ^1.1.0     # flutter.dev's own package
```

```dart
ProjectsScreen(pickFolder: getDirectoryPath)
```

— and the button relabels itself from *"Use this folder"* to *"Choose folder…"*. Nothing else
changes. The widget tests already cover both.

**Please tell us if you do this**, in an issue. Not so we can copy your code — so we know the
constraint is ours alone, which changes what we are willing to build.

## What never crosses, in either direction

**From you to us:** nothing about your projects. Not in an issue, not in a test fixture, not in a
sample path. Your features, your project names, your screenshots — none of it needs to be here, and
we would rather not hold it.

**From us to you:** nothing about anyone else's projects either. Same rule, and it has already
nearly been broken in our own source.

**Neither of us, ever:** customer data, partner data, personal data about anyone. If a project note
would contain it, it does not belong in a project note.

## Sending feedback

**GitHub issues on this repository.** You have read access, which is enough to open one. Dated,
searchable, and it cannot get lost in a chat the way the last round of feedback did.

What is useful, roughly in order:

1. **"I could not do X without editing your file Y."** This is the single most valuable thing you
   can report — it is what earns a new seam, and it is invisible to us otherwise.
2. What you expected to see that was not there.
3. What you had to work out for yourself.
4. Whether you opened it a second time without being reminded to. A "no" is genuinely useful.

**Please describe what our Asa did, not what yours does** — and no screenshots that show your own
screens or project names. We cannot check this and are not trying to; it is easier for both of us
if the honest path is also the obvious one.

## What we owe you

- **Every release names what moved in `core/`.** One line. Your code compiles against it, so a
  rename is not free for you and we will stop treating it as free for us.
- **`lib/local/` stays untouched by us.** If you ever see a change of ours inside it, that is a bug
  in how we work, and it is worth an issue.
- **The known limit, said plainly:** the seams stop *merge conflicts*. They do not stop *compile
  errors*. If we change the shape of something in `core/` that you call, your build breaks and you
  fix it. That is the honest cost of building on a moving base, and it is why the release note
  exists.

## One thing that is not settled

Whether a tool built on work time, about work projects, belongs to the employer — and what that
means once two people build it and one keeps private features. **Nobody has asked.** It is not a
reason to stop, and it is worth one question to the right person before either of us builds much
more.
