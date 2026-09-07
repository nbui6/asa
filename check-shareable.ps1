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
# CHECK ONE: IS THE REPOSITORY ACTUALLY PRIVATE?
#
# On 2026-09-02 this repository was found to be PUBLIC. It had been believed
# private for two days, and that belief was written into this file and into
# CLAUDE.md rule 16 as the JUSTIFICATION for the two things below. Nobody had
# ever checked.
#
# So it is checked now, on every run, by asking GitHub's public API whether the
# repository is readable without an account. No token, no credentials: exactly
# the test a stranger performs. It FAILS CLOSED - if the answer cannot be
# obtained, the check does not pass.
#
# A security property that nothing verifies is a hope.
#
# WHY THE LIST IS EMPTY AND IN THIS FILE
#
# The list stays empty, but the reason is now narrower than it was. The old
# reason was "this repository is private and shared with people who already
# know the project names" - which was false at the time it was written. The
# reason that survives: the built-in checks catch the two things that are
# genuinely damaging wherever this ends up (a machine path, an email address),
# and a hand-maintained name list was tried twice and thrown away both times
# because a noisy check gets switched off. Add a name below when something
# turns up that a reader should not see - not pre-emptively.
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

# --- is it private? -------------------------------------------------------
#
# Split into three so that two of them are pure and can be self-tested:
#   Get-RemoteSlug     .git/config text  ->  'owner/repo' or ''
#   Resolve-Visibility HTTP status code  ->  'public' / 'private' / 'unknown'
# and one that is not, because it touches the network.

function Get-RemoteSlug {
    param([string]$ConfigText)
    # Reads .git/config as text rather than running git, so this works with no
    # git on PATH and never takes .git/index.lock.
    $m = [regex]::Match($ConfigText, 'url\s*=\s*\S*github\.com[:/]([^/\s]+)/([^/\s]+?)(\.git)?\s*$',
                        [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $m.Success) { return '' }
    return ($m.Groups[1].Value + '/' + $m.Groups[2].Value)
}

function Resolve-Visibility {
    param([int]$StatusCode)
    # 200 = a stranger can read it.
    # 404 = a stranger cannot. That covers private, renamed and deleted, and
    #       unauthenticated GitHub cannot tell those apart - which is fine,
    #       because all three mean "not readable by the world".
    if ($StatusCode -eq 200) { return 'public' }
    if ($StatusCode -eq 404) { return 'private' }
    return 'unknown'
}

function Get-RepoVisibility {
    param([string]$Root)

    $cfg = Join-Path $Root '.git\config'
    if (-not (Test-Path -LiteralPath $cfg)) {
        return @{ State = 'no-remote'; Detail = 'not a git repository' }
    }
    $slug = Get-RemoteSlug -ConfigText (Get-Content -LiteralPath $cfg -Raw)
    if ($slug -eq '') {
        return @{ State = 'no-remote'; Detail = 'no GitHub remote configured - nothing can be pushed' }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch { }

    $code = 0
    try {
        $r = Invoke-WebRequest -Uri ('https://api.github.com/repos/' + $slug) `
                               -Method Head -UseBasicParsing -TimeoutSec 15
        $code = [int]$r.StatusCode
    } catch {
        if ($_.Exception.Response -ne $null) {
            $code = [int]$_.Exception.Response.StatusCode
        } else {
            return @{ State = 'unknown'; Detail = ('could not reach api.github.com: ' + $_.Exception.Message); Slug = $slug }
        }
    }
    return @{ State = (Resolve-Visibility -StatusCode $code); Detail = ('HTTP ' + $code); Slug = $slug }
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

    # The visibility half. Pure functions only - the network is not mocked,
    # because a self-test that needs the internet is a self-test that fails on
    # a train and then gets switched off.
    $cfgText = "[remote `"origin`"]`n`turl = https://github.com/someone/some-repo.git`n"
    if ((Get-RemoteSlug -ConfigText $cfgText) -ne 'someone/some-repo') { Write-Host '  FAIL  the remote slug was not parsed'; $ok = $false }
    else { Write-Host '  PASS  owner/repo is read from .git/config text' }

    if ((Get-RemoteSlug -ConfigText "[core]`n`tbare = false`n") -ne '') { Write-Host '  FAIL  a config with no remote should give an empty slug'; $ok = $false }
    else { Write-Host '  PASS  no remote gives no slug' }

    if ((Resolve-Visibility -StatusCode 200) -ne 'public')  { Write-Host '  FAIL  200 must mean public'; $ok = $false }
    elseif ((Resolve-Visibility -StatusCode 404) -ne 'private') { Write-Host '  FAIL  404 must mean private'; $ok = $false }
    elseif ((Resolve-Visibility -StatusCode 500) -ne 'unknown') { Write-Host '  FAIL  anything else must mean unknown'; $ok = $false }
    else { Write-Host '  PASS  200 is public, 404 is private, everything else is unknown' }

    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ---------------------------------------------------------

$result = Test-Shareable -Root $root -Private $private -Allowed $allowed
$vis    = Get-RepoVisibility -Root $root

Write-Host ''

$visOk = $false
switch ($vis.State) {
    'private'   { Write-Host ("Private.  {0} is not readable without an account ({1})." -f $vis.Slug, $vis.Detail); $visOk = $true }
    'no-remote' { Write-Host ("No remote.  {0}." -f $vis.Detail); $visOk = $true }
    'public'    { Write-Host ("PUBLIC.  {0} is readable by anyone ({1})." -f $vis.Slug, $vis.Detail) }
    default     { Write-Host ("VISIBILITY UNKNOWN.  {0}" -f $vis.Detail)
                  Write-Host '  This check fails closed. Confirm in a signed-out browser before pushing.' }
}

if ($visOk -and $result.Hits.Count -eq 0) {
    Write-Host ("Safe to push. {0} file(s) checked." -f $result.Count)
    exit 0
}

Write-Host ''
Write-Host 'NOT SAFE TO PUSH.'
if (-not $visOk) { Write-Host '  - the repository is not confirmed private (see above)' }
if ($result.Hits.Count -gt 0) {
    Write-Host ("  - {0} finding(s) in files:" -f $result.Hits.Count)
    foreach ($h in ($result.Hits | Select-Object -Unique)) { Write-Host "      $h" }
}
exit 1
