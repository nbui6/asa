# check-refs.ps1 - does every file this project points at actually exist?
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\check-refs.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\check-refs.ps1 -SelfTest
#
# Exit 0 = every referenced file resolves.  Exit 1 = at least one does not.
#
# WHY THIS EXISTS
#
# On 2026-09-01 a handover gate said, in as many words:
#
#     Sketch seen and approved?  Yes - projects\asa\sketches\asa-v01b.png
#
# That file had never existed. The path was cited for three days - in the gate,
# in a spec, in a drift report - and a whole round was built against a
# recreation of the missing image, then rejected undiagnosably, because
# "it does not match what we agreed" cannot be answered when the thing agreed
# no longer exists.
#
# PLAYBOOK.md section 14 already says it: a field that can be satisfied without
# being true is not yet a check. "Approved? Yes - <path>" is satisfied by
# typing. This turns it into a check.
#
# SCOPE, DELIBERATELY NARROW
#
# Only paths inside backticks, containing a separator, ending in a known file
# extension. Folders, placeholders in angle brackets, deliberate test fixtures
# and URLs are skipped - a noisy check gets switched off, and this one has to
# survive being run on every round.
#
# HOW TO WRITE A PATH YOU DO NOT MEAN LITERALLY
#
# An illustrative shape is not a reference. Write it with a placeholder in it:
#
#     decisions/<nnnn>-<slug>.md      skipped, correctly
#     decisions/0001-slug.md          checked, and will fail
#
# The first real run flagged one of these. It was not a false positive - the
# document was claiming a file existed when it meant "files look like this."
# The convention costs two angle brackets and makes the difference visible.

param([switch]$SelfTest)

$ErrorActionPreference = 'Stop'
$kitRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $kitRoot
$outer    = Split-Path -Parent $repoRoot   # the workspace root, for projects\...

$extensions = @('.md','.png','.html','.dart','.ps1','.yaml','.yml','.json','.txt','.svg')

function Get-ReferencedPaths {
    # Pure. Text in, candidate paths out. Self-tested below.
    param([string]$Text, [string[]]$Extensions)

    $found = New-Object 'System.Collections.Generic.List[string]'
    foreach ($m in [regex]::Matches($Text, '`([^`\r\n]+)`')) {
        $c = $m.Groups[1].Value.Trim()

        if ($c -match '^<' -or $c -match '>$') { continue }          # <placeholder>
        if ($c -match '^(https?|http)') { continue }                 # a URL
        if ($c -match '^%') { continue }                             # %USERPROFILE%\...
        if ($c -match '^[A-Za-z]+:[^\\/]') { continue }              # dart:io, package:x
        if ($c -notmatch '[\\/]') { continue }                       # no separator, not a path
        if ($c -match '\s') { continue }                             # a command, not a path
        if ($c -match '\*') { continue }                             # a glob
        if ($c -match '(?i)^C:\\Users\\(test|someone|you)\\') { continue }  # deliberate fixtures

        # Characters that cannot appear in a Windows path. Backticked prose is
        # full of them - regex patterns, alternations, quoted strings. Filtered
        # BEFORE any path API sees the string.
        #
        # 2026-09-04: this line did not exist and the first real run died on
        # [System.IO.Path]::GetExtension - "Illegal characters in path" - after
        # a self-test of seven green passes. The sample the self-test ran on was
        # invented, and it was clean. The corpus was not.
        if ($c -match '[<>"|?*]') { continue }

        # Extension by regex, never by a path API. No input can throw.
        $ext = ''
        if ($c -match '(\.[A-Za-z0-9]{1,5})$') { $ext = $matches[1].ToLowerInvariant() }
        if ($Extensions -notcontains $ext) { continue }              # folders and the rest

        $found.Add($c)
    }
    return $found
}

function Resolve-Reference {
    # Pure given the two roots. Returns $true if the path resolves anywhere sane.
    param([string]$Candidate, [string]$RepoRoot, [string]$OuterRoot)

    $rel = $Candidate -replace '/', '\'
    foreach ($base in @($RepoRoot, $OuterRoot)) {
        if ([string]::IsNullOrEmpty($base)) { continue }
        if (Test-Path -LiteralPath (Join-Path $base $rel)) { return $true }
    }
    if (Test-Path -LiteralPath $rel) { return $true }
    return $false
}

# --- self-test ------------------------------------------------------------

if ($SelfTest) {
    $ok = $true

    $sample = @'
See `projects\asa\sketches\asa-v01b.png` and `lib/core/decision.dart`.
Placeholders: `<path/to/sketch.png>` and `%USERPROFILE%\workspace\x.md`.
Not paths: `dart:io`, `flutter test`, `lib/core/`, `check.ps1`.
A fixture: `C:\Users\test\projects\a.md`. A glob: `asa/decisions/*.md`.
'@
    $paths = Get-ReferencedPaths -Text $sample -Extensions $extensions

    if ($paths.Count -ne 2) { Write-Host "  FAIL  expected 2 paths, got $($paths.Count): $($paths -join ', ')"; $ok = $false }
    else { Write-Host '  PASS  two real paths found in a mixed sample' }

    if ($paths -notcontains 'projects\asa\sketches\asa-v01b.png') { Write-Host '  FAIL  a backslash path was not picked up'; $ok = $false }
    else { Write-Host '  PASS  a Windows-style path is picked up' }

    if ($paths -notcontains 'lib/core/decision.dart') { Write-Host '  FAIL  a forward-slash path was not picked up'; $ok = $false }
    else { Write-Host '  PASS  a forward-slash path is picked up' }

    foreach ($skip in @('<path/to/sketch.png>','dart:io','lib/core/','check.ps1','asa/decisions/*.md')) {
        if ($paths -contains $skip) { Write-Host "  FAIL  '$skip' should have been skipped"; $ok = $false }
    }
    Write-Host '  PASS  placeholders, package prefixes, bare folders and globs are skipped'

    if ($paths | Where-Object { $_ -like 'C:\Users\test\*' }) { Write-Host '  FAIL  a deliberate test fixture was flagged'; $ok = $false }
    else { Write-Host '  PASS  deliberate C:\Users\test fixtures are skipped' }

    # The crash of 2026-09-04, pinned. These are real strings from this
    # repository's own markdown, not invented ones - the reason the first
    # self-test passed while the first real run died.
    $nasty = @'
Patterns: `C:\Users\[A-Za-z0-9._-]+` and `'(^|[^a-z0-9])'`.
Alternation: `(test|someone|you)`. A question: `settings.json?`.
Angle brackets mid-string: `lib/hubs/<name>/screen.dart`.
A quote: `"assets/x.png"`. A glob: `kit/skills/*/SKILL.md`.
'@
    try {
        $n = Get-ReferencedPaths -Text $nasty -Extensions $extensions
        Write-Host ("  PASS  path-illegal characters do not throw (" + $n.Count + " path(s) taken from that line)")
    } catch {
        Write-Host "  FAIL  threw on path-illegal characters: $($_.Exception.Message)"; $ok = $false
    }

    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("refs-" + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path (Join-Path $sandbox 'sub') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $sandbox 'sub\there.md') -Value 'x' -Encoding UTF8

    if (-not (Resolve-Reference -Candidate 'sub/there.md' -RepoRoot $sandbox -OuterRoot $null)) { Write-Host '  FAIL  an existing file was reported missing'; $ok = $false }
    else { Write-Host '  PASS  an existing file resolves' }

    if (Resolve-Reference -Candidate 'sub/gone.md' -RepoRoot $sandbox -OuterRoot $null) { Write-Host '  FAIL  a missing file was reported present'; $ok = $false }
    else { Write-Host '  PASS  a missing file is reported missing' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ---------------------------------------------------------

$targets = @()
foreach ($name in @('HANDOVER.md','CLAUDE.md','ARCHITECTURE.md','README.md')) {
    $f = Join-Path $repoRoot $name
    if (Test-Path -LiteralPath $f) { $targets += $f }
}

$missing = New-Object 'System.Collections.Generic.List[string]'
$checked = 0

foreach ($f in $targets) {
    $n = 0
    foreach ($line in (Get-Content -LiteralPath $f -Encoding UTF8)) {
        $n++
        foreach ($c in (Get-ReferencedPaths -Text $line -Extensions $extensions)) {
            $checked++
            if (-not (Resolve-Reference -Candidate $c -RepoRoot $repoRoot -OuterRoot $outer)) {
                $missing.Add(("{0}:{1}  {2}" -f (Split-Path -Leaf $f), $n, $c))
            }
        }
    }
}

Write-Host ''
if ($missing.Count -eq 0) {
    Write-Host ("Every reference resolves. {0} path(s) checked in {1} file(s)." -f $checked, $targets.Count)
    exit 0
}
Write-Host ("BROKEN REFERENCES - {0} of {1} path(s) do not exist:" -f $missing.Count, $checked)
foreach ($m in ($missing | Select-Object -Unique)) { Write-Host "  $m" }
Write-Host ''
Write-Host 'A gate row that names a file which is not there is not a check. Fix the file or the path.'
exit 1
