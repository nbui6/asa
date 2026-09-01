# check-shareable.ps1 - is this repository safe to push?
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-shareable.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-shareable.ps1 -SelfTest
#
# Exit 0 = safe.  Exit 1 = something private is in a file that would be shared.
#
# Same shape as kit/check-boundaries.ps1, which has been catching real leaks
# since 2026-08-26. Two checks that always run, one list that starts empty,
# and a self-test - because a check nobody has seen fail is not a check.
#
# WHY THE LIST IS EMPTY AND IN THIS FILE
#
# This repository is private and shared with people who already know the names
# of the projects in it. Nothing here is secret from them. What would be a real
# mistake is a machine path or an email address, so those two are built in and
# always on. Add a name below only if this ever goes public, or if something
# turns up that a reader should not see.
#
# An earlier version of this script derived the list from folder names, the git
# email and the private notes. It worked, and it was thrown away: it solved a
# problem this project does not have, and it was harder to read than the thing
# it protected. Parked, not deleted - if the need arrives twice, build it.

param([switch]$SelfTest)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- the list. Empty on purpose. One name per line when you need it. ------

$private = @(
    # 'some-work-project'
)

# --- always on ------------------------------------------------------------

$builtin = @(
    @{ Why = 'a Windows user path'; Pattern = 'C:\\Users\\[A-Za-z0-9._-]+' },
    @{ Why = 'an email address';    Pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' }
)

# Files allowed to contain the terms. This script names them by definition.
$allowed = @('check-shareable.ps1')

function Test-Shareable {
    param([string]$Root, [string[]]$Private, [string[]]$Allowed)

    $hits = New-Object System.Collections.Generic.List[string]
    $skip = '[\\/](build|\.git|\.dart_tool|ephemeral)[\\/]'
    $files = Get-ChildItem -LiteralPath $Root -Recurse -File -Include `
               '*.md','*.dart','*.ps1','*.yaml','*.yml','*.json','*.txt' |
             Where-Object { $_.FullName -notmatch $skip }

    foreach ($f in $files) {
        if ($Allowed -contains $f.Name) { continue }
        $rel = $f.FullName.Substring($Root.Length).TrimStart('\','/')
        $n = 0
        foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8)) {
            $n++
            foreach ($b in $script:builtin) {
                if ($line -match $b.Pattern) { $hits.Add(("{0}:{1}  {2}" -f $rel, $n, $b.Why)) }
            }
            $lower = $line.ToLowerInvariant()
            foreach ($t in $Private) {
                # Whole words only. A substring match once reported "build" for
                # "bui" - 42 false positives, and a noisy check gets switched off.
                if ($lower -match ('(^|[^a-z0-9])' + [regex]::Escape($t.ToLowerInvariant()) + '([^a-z0-9]|$)')) {
                    $hits.Add(("{0}:{1}  a private name" -f $rel, $n))
                }
            }
        }
    }
    return @{ Hits = $hits; Count = $files.Count }
}

# --- self-test ------------------------------------------------------------

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-shareable-" + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $ok = $true
    $testPrivate = @('acme-widget')

    Set-Content -LiteralPath (Join-Path $sandbox 'clean.md') -Value 'Nothing private here.' -Encoding UTF8
    $r = Test-Shareable -Root $sandbox -Private $testPrivate -Allowed $allowed
    if ($r.Hits.Count -ne 0) { Write-Host "  FAIL  a clean folder reported $($r.Hits.Count)"; $ok = $false }
    else { Write-Host '  PASS  a clean folder reports nothing' }

    Set-Content -LiteralPath (Join-Path $sandbox 'path.md') -Value 'See C:\Users\someone\dev for details.' -Encoding UTF8
    $r = Test-Shareable -Root $sandbox -Private $testPrivate -Allowed $allowed
    if ($r.Hits.Count -ne 1) { Write-Host "  FAIL  a machine path was not caught (found $($r.Hits.Count))"; $ok = $false }
    else { Write-Host '  PASS  a machine path is caught, with its line number' }

    Set-Content -LiteralPath (Join-Path $sandbox 'mail.md') -Value 'Write to someone@example.com about it.' -Encoding UTF8
    $r = Test-Shareable -Root $sandbox -Private $testPrivate -Allowed $allowed
    if ($r.Hits.Count -ne 2) { Write-Host "  FAIL  an email was not caught (found $($r.Hits.Count))"; $ok = $false }
    else { Write-Host '  PASS  an email address is caught' }

    Set-Content -LiteralPath (Join-Path $sandbox 'name.md') -Value 'The acme-widget rollout is next.' -Encoding UTF8
    $r = Test-Shareable -Root $sandbox -Private $testPrivate -Allowed $allowed
    if ($r.Hits.Count -ne 3) { Write-Host "  FAIL  a private name was not caught (found $($r.Hits.Count))"; $ok = $false }
    else { Write-Host '  PASS  a name from the list is caught' }

    Set-Content -LiteralPath (Join-Path $sandbox 'word.md') -Value 'Rebuilding the acme-widgets plural should not match.' -Encoding UTF8
    $r = Test-Shareable -Root $sandbox -Private $testPrivate -Allowed $allowed
    if ($r.Hits.Count -ne 3) { Write-Host "  FAIL  whole-word matching is broken (found $($r.Hits.Count), expected 3)"; $ok = $false }
    else { Write-Host '  PASS  whole words only - a longer word is not a hit' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ---------------------------------------------------------

$result = Test-Shareable -Root $root -Private $private -Allowed $allowed

Write-Host ''
if ($result.Hits.Count -eq 0) {
    Write-Host ("Safe to push. {0} file(s) checked." -f $result.Count)
    exit 0
}
Write-Host ("NOT SAFE TO PUSH - {0} finding(s):" -f $result.Hits.Count)
foreach ($h in ($result.Hits | Select-Object -Unique)) { Write-Host "  $h" }
exit 1
