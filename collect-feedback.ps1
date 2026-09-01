# collect-feedback.ps1 - pull process feedback out of the projects and into the kit
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File collect-feedback.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File collect-feedback.ps1 -SelfTest
#
# Exit 0 always. This reports; it never blocks anything.
#
# WHY
#
# Feedback about the way of working is written where the work is - inside a project folder, by
# whoever is there, often by a session that cannot see the kit at all. The kit is in a git
# repository; the projects are deliberately outside it, so nothing of the owner's work can ever be
# committed. That boundary is load-bearing and this script does not cross it carelessly.
#
# What it moves: the one-line rows of each project's FEEDBACK.md table.
# What it does not move: anything else in that folder, ever.
#
# FEEDBACK.md says at the top, in the template every project gets: process only, never project
# content. A line that names something private is a mistake in that line, so this script checks
# every row before copying it and refuses the ones that look wrong.

param([switch]$SelfTest, [switch]$Quiet)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path   # ...\workspace\asa
$root = Split-Path -Parent $repo                          # ...\workspace
$kitFeedback = Join-Path $repo 'kit\FEEDBACK.md'

# A row that mentions any of these is not copied. Same two checks as check-shareable:
# a machine path and an email address - the realistic accidents.
$unsafe = @(
    @{ Why = 'a machine path';   Pattern = '[A-Za-z]:\\Users\\[A-Za-z0-9._-]+' },
    @{ Why = 'an email address'; Pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' }
)

function Get-Rows {
    param([string]$ProjectsRoot)

    $rows = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $ProjectsRoot)) { return $rows }

    foreach ($dir in (Get-ChildItem -LiteralPath $ProjectsRoot -Directory | Where-Object { $_.Name -notmatch '^[._]' })) {
        $f = Join-Path $dir.FullName 'FEEDBACK.md'
        if (-not (Test-Path -LiteralPath $f)) { continue }
        foreach ($line in (Get-Content -LiteralPath $f -Encoding UTF8)) {
            $t = $line.Trim()
            # A data row: starts and ends with a pipe, has content, and is not the header
            # or the ruler. The empty seed row "| | | |" is skipped by the content test.
            if ($t -notmatch '^\|.*\|$') { continue }
            if ($t -match '^\|\s*-{2,}') { continue }
            if ($t -match '^\|\s*Date\s*\|') { continue }
            $cells = ($t.Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
            if (($cells | Where-Object { $_ -ne '' }).Count -lt 2) { continue }

            $bad = $null
            foreach ($u in $unsafe) { if ($t -match $u.Pattern) { $bad = $u.Why; break } }

            $rows.Add([pscustomobject]@{
                Project = $dir.Name
                Date    = $cells[0]
                Text    = $cells[1]
                Kind    = if ($cells.Count -gt 2) { $cells[2] } else { '' }
                Unsafe  = $bad
            })
        }
    }
    return $rows
}

# --- self-test ------------------------------------------------------------
# A check nobody has seen fail is not a check.

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-collect-" + [guid]::NewGuid().ToString('N').Substring(0,8))
    $pr = Join-Path $sandbox 'projects'
    New-Item -ItemType Directory -Path (Join-Path $pr 'alpha') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $pr '_archive') -Force | Out-Null
    $ok = $true

    Set-Content -LiteralPath (Join-Path $pr 'alpha\FEEDBACK.md') -Encoding UTF8 -Value @(
        '# Feedback - Alpha', '',
        '| Date | What happened | Kind |',
        '|---|---|---|',
        '| 2026-09-01 | The sketch step was skipped and nothing broke | step skipped |',
        '| | | |',
        '| 2026-09-02 | Path C:\Users\someone\dev came up | leak |'
    )
    Set-Content -LiteralPath (Join-Path $pr '_archive\FEEDBACK.md') -Encoding UTF8 -Value '| 2026-09-01 | should not be read | x |'

    $r = Get-Rows -ProjectsRoot $pr
    if ($r.Count -ne 2) { Write-Host "  FAIL  expected 2 rows, got $($r.Count)"; $ok = $false }
    else { Write-Host '  PASS  header, ruler and the empty seed row are skipped' }
    if (($r | Where-Object { $_.Project -eq '_archive' }).Count -ne 0) { Write-Host '  FAIL  read an underscore folder'; $ok = $false }
    else { Write-Host '  PASS  _archive and dot-folders are not read' }
    $u = @($r | Where-Object { $_.Unsafe })
    if ($u.Count -ne 1) { Write-Host "  FAIL  expected 1 unsafe row, got $($u.Count)"; $ok = $false }
    else { Write-Host '  PASS  a row containing a machine path is held back, not copied' }
    $s = @($r | Where-Object { -not $_.Unsafe })
    if ($s.Count -ne 1 -or $s[0].Kind -ne 'step skipped') { Write-Host '  FAIL  a clean row did not survive intact'; $ok = $false }
    else { Write-Host '  PASS  a clean row keeps its date, text and kind' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ---------------------------------------------------------

$rows = Get-Rows -ProjectsRoot (Join-Path $root 'projects')
$safe   = @($rows | Where-Object { -not $_.Unsafe })
$held   = @($rows | Where-Object { $_.Unsafe })

if (-not (Test-Path -LiteralPath $kitFeedback)) {
    Set-Content -LiteralPath $kitFeedback -Encoding UTF8 -Value @('# Feedback', '')
}
$existing = Get-Content -LiteralPath $kitFeedback -Raw -Encoding UTF8

# Only lines not already there. The text is the identity - if a line is edited in the project
# it arrives as a new line, which is correct: the edit is the new information.
$new = @($safe | Where-Object { $existing -notlike ('*' + $_.Text + '*') })

Write-Host ''
if ($new.Count -gt 0) {
    $stamp = Get-Date -Format 'yyyy-MM-dd'
    $block = @('', "## Collected from projects - $stamp", '')
    foreach ($r in $new) {
        $k = if ($r.Kind) { " _($($r.Kind))_" } else { '' }
        $block += "- **$($r.Project)** - $($r.Date) - $($r.Text)$k"
    }
    Add-Content -LiteralPath $kitFeedback -Encoding UTF8 -Value $block
    Write-Host ("Collected {0} new line(s) into kit\FEEDBACK.md:" -f $new.Count)
    foreach ($r in $new) { Write-Host ("  {0,-24} {1}" -f $r.Project, $r.Text) }
    Write-Host ''
    Write-Host '  Commit it with the next push. Nothing else was copied out of the projects.'
} else {
    Write-Host ("No new feedback. {0} line(s) already collected." -f $safe.Count)
}

if ($held.Count -gt 0) {
    Write-Host ''
    Write-Host ("HELD BACK - {0} line(s) look like they contain something private:" -f $held.Count)
    foreach ($r in $held) { Write-Host ("  {0}  ({1}) - rewrite the line in that project's FEEDBACK.md" -f $r.Project, $r.Unsafe) }
    Write-Host '  Not copied, and not deleted. The line stays where it is until someone fixes it.'
}
Write-Host ''
exit 0
