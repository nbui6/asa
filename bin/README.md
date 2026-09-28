# `asa\bin` — commands, not the app

`asa-brief` (Round 39 cp3) reads the same files Asa's own screens read and prints a short
markdown briefing — the manual's own §4 table, in one command instead of a human following it
by hand.

`asa-check` (Round 39 cp4) checks one project against the manual's own §7/§13 shapes and prints
*OK*, or one line per problem — never a stack trace, always something a person could act on.
Exits 0 (`OK`) or 1 (a real finding), so `check-notes.ps1` can run it over every project and
report only the ones with something to say.

## Put it on PATH, once per laptop

PowerShell, once, as yourself (not as admin — this only changes your own user PATH):

```powershell
[Environment]::SetEnvironmentVariable(
  'Path',
  "$([Environment]::GetEnvironmentVariable('Path', 'User'));$PWD\bin",
  'User'
)
```

Run that from `asa\`'s own root, then open a new terminal — PATH changes never apply to the one
you're already in.

## Use it

```
asa-brief --all
asa-brief --since 2026-09-25
asa-brief "northwind"
asa-brief "northwind" --area Sales
asa-brief "northwind" --round 38
asa-check "northwind"
```

It reads the projects folder from the same `%APPDATA%\Asa\settings.json` the app itself writes —
open Asa once and choose a folder before using this, or `asa-brief` will say so and stop rather
than guess one.

Needs the Dart SDK on PATH already (the one Flutter installs). No separate install step beyond
that and the PATH line above.
