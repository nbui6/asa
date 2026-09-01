# check-boundaries.ps1 - is anything in this kit actually about one product?
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-boundaries.ps1
#
# Exit 0 = clean.  Exit 1 = a product name is written into the kit.
#
# Why this exists: on 2026-08-26 an audit found five leaks, including a
# glossary a quarter of which was one product's build log and an onboarding
# step telling every reader to build a product they had never heard of. Each
# had been added by someone being helpful. Nothing was watching.
#
# PLAYBOOK.md 14, "Three homes":
#
#   kit       - how do we build anything?          this folder
#   workshop  - what is true of this machine,      MACHINE.md, BOSS.md
#               and this Boss?
#   product   - what is this thing, and how        the product's own repo
#               does it work?
#
# A rule is not a system. This is the part that makes it one.

param(
    [switch]$Quiet,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- what counts as a leak ---------------------------------------------
#
# HARD: product proper nouns. These are never legitimately in kit prose.
# Add a name here the day a new product starts, or this check quietly
# stops covering it.

$hard = @(
    'german memory layer',
    'der/die/das',
    'der die das',
    'konjunktiv',
    'asa'
)

# Not hard: 'anki', 'obsidian', 'claude code'. Those are OTHER people's
# products, and a kit may legitimately name a tool as an example - the same
# way it names PowerShell or git. The list is for the products WE build.

# SOFT: one-ecosystem technology. Legitimate as an example -
# "flutter test, pytest, npm test" teaches better than an abstraction -
# so these are counted and shown, never failed on. A human reads the number
# and asks whether the kit has quietly become a Flutter kit.

$soft = @('flutter', 'gradle', 'dart', 'pubspec', 'apk', 'android studio', 'anki')

# Files whose job is to cite real cases. A log of what went wrong is
# worthless without naming what went wrong.
#
#   KIT-LOG    - the record of real failures on real products
#   CHANGELOG  - what changed, and on which product it was found
#   SKILLS     - which skill fired, and on what
#   ROADMAP    - ranked work, and the product currently proving the kit
#   this file  - it contains the list of names by definition
#   package-for-tester.ps1 - the sanitiser. Same reason: the names it strips
#                 have to be written down somewhere, and that somewhere is it.
#                 Missed on the first pass, which is the checker's own lesson
#                 about exceptions arriving one file short.

$allowed = @('KIT-LOG.md', 'CHANGELOG.md', 'SKILLS.md', 'ROADMAP.md',
             'check-boundaries.ps1', 'package-for-tester.ps1')

# --- the scan -----------------------------------------------------------

function Test-Boundaries {
    param([string]$Root, [string[]]$Hard, [string[]]$Soft, [string[]]$Allowed, [switch]$Silent)

    $hardHits = New-Object System.Collections.Generic.List[string]
    $softHits = New-Object System.Collections.Generic.List[string]

    $files = Get-ChildItem -LiteralPath $Root -Recurse -File -Include '*.md', '*.ps1' |
             Where-Object { $_.FullName -notmatch '[\\/](_to_delete|_installable|\.git)[\\/]' }

    foreach ($f in $files) {
        if ($Allowed -contains $f.Name) { continue }
        $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
        $n = 0
        foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8)) {
            $n++
            $lower = $line.ToLowerInvariant()
            # Whole words only. A substring match reported "ranking" as the
            # flashcard app Anki four times on the first real run - a checker
            # whose first output is four false positives is a checker people
            # switch off.
            foreach ($term in $Hard) {
                if ($lower -match ('(^|[^a-z0-9])' + [regex]::Escape($term) + '([^a-z0-9]|$)')) { $hardHits.Add("$rel`:$n  $term") }
            }
            foreach ($term in $Soft) {
                if ($lower -match ('(^|[^a-z0-9])' + [regex]::Escape($term) + '([^a-z0-9]|$)')) { $softHits.Add("$rel`:$n  $term") }
            }
        }
    }

    if (-not $Silent) {
        if ($hardHits.Count -gt 0) {
            Write-Host ''
            Write-Host "PRODUCT NAMES IN THE KIT ($($hardHits.Count)):"
            foreach ($h in $hardHits) { Write-Host "  $h" }
            Write-Host ''
            Write-Host '  Each of these is a fact about one product, sitting in a package meant for'
            Write-Host '  every project. Move it to the product repo, or rewrite the sentence so it'
            Write-Host '  is true of any project. PLAYBOOK.md 14, "Three homes".'
        }
        if ($softHits.Count -gt 0) {
            Write-Host ''
            Write-Host "One-ecosystem technology mentioned ($($softHits.Count)) - not a failure:"
            $byFile = $softHits | Group-Object { ($_ -split ':')[0] } | Sort-Object Count -Descending
            foreach ($g in $byFile) { Write-Host ("  {0,-40} {1}" -f $g.Name, $g.Count) }
            Write-Host ''
            Write-Host '  Fine as examples. Worth a look if one ecosystem is the only one named.'
        }
    }

    return @{ Hard = $hardHits; Soft = $softHits }
}

# --- self-test ----------------------------------------------------------
#
# A check that has never been seen to fail is not a check. This plants a
# leak in a temporary folder, proves the scan catches it, removes it, and
# proves the scan then passes.

if ($SelfTest) {
    # The self-test uses its OWN name list, not $hard. Otherwise a fresh copy
    # of the kit - where $hard is deliberately empty until you fill it in -
    # would report its own self-test as broken.
    $testHard = @('acme-widget', 'zebra-app')
    $testSoft = @('flutter', 'anki')

    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("kit-boundaries-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $ok = $true

    Set-Content -LiteralPath (Join-Path $sandbox 'clean.md') -Value 'Every project needs one command that says pass or fail.' -Encoding UTF8
    $r = Test-Boundaries -Root $sandbox -Hard $testHard -Soft $testSoft -Allowed $allowed -Silent
    if ($r.Hard.Count -ne 0) { Write-Host "  FAIL  a clean folder reported $($r.Hard.Count) leak(s)"; $ok = $false }
    else { Write-Host '  PASS  a clean folder reports nothing' }

    Set-Content -LiteralPath (Join-Path $sandbox 'leak.md') -Value 'Copy this into your acme-widget hub and fill it in.' -Encoding UTF8
    $r = Test-Boundaries -Root $sandbox -Hard $testHard -Soft $testSoft -Allowed $allowed -Silent
    if ($r.Hard.Count -ne 1) { Write-Host "  FAIL  a planted product name was not caught (found $($r.Hard.Count))"; $ok = $false }
    else { Write-Host '  PASS  a planted product name is caught, with its line number' }

    Set-Content -LiteralPath (Join-Path $sandbox 'KIT-LOG.md') -Value 'The acme-widget review killed the idea.' -Encoding UTF8
    $r = Test-Boundaries -Root $sandbox -Hard $testHard -Soft $testSoft -Allowed $allowed -Silent
    if ($r.Hard.Count -ne 1) { Write-Host '  FAIL  an allowed file is meant to be able to name products'; $ok = $false }
    else { Write-Host '  PASS  an allowed file may name products' }

    Set-Content -LiteralPath (Join-Path $sandbox 'soft.md') -Value 'Most tools ship a starter test: flutter test, pytest, npm test.' -Encoding UTF8
    $r = Test-Boundaries -Root $sandbox -Hard $testHard -Soft $testSoft -Allowed $allowed -Silent
    if ($r.Soft.Count -lt 1 -or $r.Hard.Count -ne 1) { Write-Host '  FAIL  a technology name should count as soft, never hard'; $ok = $false }
    else { Write-Host '  PASS  a technology name counts as soft, not hard' }

    # "ranking" contains "anki"; "zebra-application" contains "zebra-app".
    Set-Content -LiteralPath (Join-Path $sandbox 'boundary.md') -Value 'Mid-milestone re-ranking is how nothing gets finished in a zebra-application.' -Encoding UTF8
    $r = Test-Boundaries -Root $sandbox -Hard $testHard -Soft $testSoft -Allowed $allowed -Silent
    if ($r.Hard.Count -ne 1) { Write-Host "  FAIL  a word CONTAINING a product name matched (found $($r.Hard.Count), expected only the 1 planted leak)"; $ok = $false }
    else { Write-Host '  PASS  whole words only - "ranking" and "zebra-application" are not hits' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run -------------------------------------------------------

$result = Test-Boundaries -Root $root -Hard $hard -Soft $soft -Allowed $allowed -Silent:$Quiet

Write-Host ''
if ($result.Hard.Count -eq 0) {
    Write-Host "Boundaries clean. $($result.Soft.Count) technology mention(s), which are allowed as examples."
    exit 0
}
Write-Host "$($result.Hard.Count) product name(s) in the kit. Exit 1."
exit 1
