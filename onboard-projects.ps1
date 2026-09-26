# onboard-projects.ps1 - make every folder under a projects folder show up properly in Asa
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File onboard-projects.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File onboard-projects.ps1 -ProjectsFolder <path>
#   powershell -NoProfile -ExecutionPolicy Bypass -File onboard-projects.ps1 -Yes
#   powershell -NoProfile -ExecutionPolicy Bypass -File onboard-projects.ps1 -SelfTest
#
# Round 33/B - a second laptop, other projects: what it needs to just work.
#
# Run once against a projects folder. Changes nothing unless asked:
#
#   - a home note and HOW-ASA-WORKS.md               -> fine, nothing to do
#   - a home note, no HOW-ASA-WORKS.md                -> offers to copy the template in (y/n),
#                                                        never overwrites anything already there
#   - no home note at all                             -> never writes one (AGENTS.md: "Asa does
#                                                        not think, so Asa does not write one").
#                                                        Listed, with a ready-to-paste opener for
#                                                        any AI tool.
#
# -Yes answers every "copy the template in?" prompt with yes, without asking - for a machine
# with no interactive console, and for -SelfTest. The "no home note" case is never a prompt in
# the first place, -Yes or not: nothing here ever guesses what a home note should say.
#
# Exit 0 - every folder found is fully onboarded by the time this finishes. Exit 1 - at least one
# still needs a home note, or still has no HOW-ASA-WORKS.md and was answered no. Same convention
# as check-shareable.ps1: this reports what still needs a look, it does not treat that as a crash.

param(
    [string]$ProjectsFolder,
    [switch]$Yes,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateNote = Join-Path $repo 'templates\project-note.md'
$templateHowAsaWorks = Join-Path $repo 'templates\HOW-ASA-WORKS.md'

function Get-RealProjectsFolder {
    param([string]$Explicit)

    if ($Explicit) { return $Explicit }

    $settingsPath = Join-Path $env:APPDATA 'Asa\settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) { return $null }

    try {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
    if ($settings.projectsFolder) { return $settings.projectsFolder }
    return $null
}

# A folder counts as having a home note the same way Asa's own project_reader.dart does: a file
# named after the folder first, otherwise the first .md file whose first line is "---".
function Get-HomeNote {
    param([string]$FolderPath)

    $folderName = Split-Path -Leaf $FolderPath
    $named = Join-Path $FolderPath "$folderName.md"
    if (Test-Path -LiteralPath $named) { return $named }

    foreach ($md in (Get-ChildItem -LiteralPath $FolderPath -Filter '*.md' -File -ErrorAction SilentlyContinue)) {
        $first = Get-Content -LiteralPath $md.FullName -TotalCount 1 -Encoding UTF8
        if ($first -and $first.Trim() -eq '---') { return $md.FullName }
    }
    return $null
}

function Get-Opener {
    param([string]$FolderPath)

    $folderName = Split-Path -Leaf $FolderPath
    return @(
        "This folder is a project I want in Asa: $FolderPath.",
        "Read HOW-ASA-WORKS.md in it first. Then write $folderName.md exactly as that file says, from",
        "what is really in the folder. Don't change or delete anything that's already there."
    ) -join "`n"
}

# Walks one projects folder. Returns a report object; writes only when asked to (CopyTemplate) and
# only ever adds HOW-ASA-WORKS.md - never a home note, never an overwrite.
function Invoke-Onboard {
    param(
        [string]$ProjectsRoot,
        [bool]$AutoYes,
        [switch]$Quiet
    )

    $result = [pscustomobject]@{
        Fine          = New-Object System.Collections.Generic.List[string]
        Copied        = New-Object System.Collections.Generic.List[string]
        DeclinedOrNo  = New-Object System.Collections.Generic.List[string]
        NoHomeNote    = New-Object System.Collections.Generic.List[string]
    }

    $dirs = Get-ChildItem -LiteralPath $ProjectsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^[._]' }

    foreach ($dir in $dirs) {
        $homeNote = Get-HomeNote -FolderPath $dir.FullName
        $howAsaWorks = Join-Path $dir.FullName 'HOW-ASA-WORKS.md'
        $hasHowAsaWorks = Test-Path -LiteralPath $howAsaWorks

        if (-not $homeNote) {
            $result.NoHomeNote.Add($dir.Name)
            if (-not $Quiet) {
                Write-Host ''
                Write-Host "No home note: $($dir.Name)"
                Write-Host '  Paste this into any AI tool:'
                Write-Host ''
                (Get-Opener -FolderPath $dir.FullName) -split "`n" | ForEach-Object { Write-Host "    $_" }
            }
            continue
        }

        if ($hasHowAsaWorks) {
            $result.Fine.Add($dir.Name)
            continue
        }

        $doIt = $AutoYes
        if (-not $AutoYes -and -not $Quiet) {
            $answer = Read-Host "  $($dir.Name) has no HOW-ASA-WORKS.md. Copy the template in? (y/n)"
            $doIt = ($answer -match '^(y|yes)$')
        }

        if ($doIt) {
            Copy-Item -LiteralPath $templateHowAsaWorks -Destination $howAsaWorks
            $result.Copied.Add($dir.Name)
        } else {
            $result.DeclinedOrNo.Add($dir.Name)
        }
    }

    return $result
}

# --- self-test --------------------------------------------------------------
# A check nobody has seen fail is not a check.

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-onboard-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $ok = $true

    $complete = Join-Path $sandbox 'complete-project'
    New-Item -ItemType Directory -Path $complete -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $complete 'complete-project.md') -Encoding UTF8 -Value "---`nproject: Complete`nstatus: idea`n---`n"
    Copy-Item -LiteralPath $templateHowAsaWorks -Destination (Join-Path $complete 'HOW-ASA-WORKS.md')

    $noHowAsaWorks = Join-Path $sandbox 'no-how-asa-works'
    New-Item -ItemType Directory -Path $noHowAsaWorks -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $noHowAsaWorks 'no-how-asa-works.md') -Encoding UTF8 -Value "---`nproject: No template yet`nstatus: idea`n---`n"

    $noHomeNote = Join-Path $sandbox 'no-home-note'
    New-Item -ItemType Directory -Path $noHomeNote -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $noHomeNote 'notes.txt') -Encoding UTF8 -Value 'not a home note'

    $r1 = Invoke-Onboard -ProjectsRoot $sandbox -AutoYes $true -Quiet
    if ($r1.Fine.Count -ne 1 -or $r1.Fine[0] -ne 'complete-project') {
        Write-Host "  FAIL  expected 'complete-project' already fine, got: $($r1.Fine -join ', ')"; $ok = $false
    } else { Write-Host "  PASS  a folder with a home note and HOW-ASA-WORKS.md is left alone" }

    if ($r1.Copied.Count -ne 1 -or $r1.Copied[0] -ne 'no-how-asa-works') {
        Write-Host "  FAIL  expected 'no-how-asa-works' copied into, got: $($r1.Copied -join ', ')"; $ok = $false
    } else { Write-Host "  PASS  a folder with a home note but no HOW-ASA-WORKS.md gets the template, when told yes" }

    if ($r1.NoHomeNote.Count -ne 1 -or $r1.NoHomeNote[0] -ne 'no-home-note') {
        Write-Host "  FAIL  expected 'no-home-note' listed, got: $($r1.NoHomeNote -join ', ')"; $ok = $false
    } else { Write-Host "  PASS  a folder with no home note is listed, never written to" }

    if (Test-Path -LiteralPath (Join-Path $noHomeNote 'no-home-note.md')) {
        Write-Host '  FAIL  a home note was written where none existed'; $ok = $false
    } else { Write-Host '  PASS  no home note was invented' }

    # Second run: everything that was fixable is now fine, and nothing changes further.
    $r2 = Invoke-Onboard -ProjectsRoot $sandbox -AutoYes $true -Quiet
    if ($r2.Fine.Count -ne 2 -or $r2.Copied.Count -ne 0) {
        Write-Host "  FAIL  second run expected 2 already-fine and 0 newly-copied, got Fine=$($r2.Fine.Count) Copied=$($r2.Copied.Count))"; $ok = $false
    } else { Write-Host '  PASS  a second run changes nothing further - both real projects now read as fine' }

    if ($r2.NoHomeNote.Count -ne 1) {
        Write-Host '  FAIL  the no-home-note folder should still be listed on a second run'; $ok = $false
    } else { Write-Host '  PASS  the no-home-note folder is still listed, run after run, since nothing here can fix it' }

    # The "no" path: told not to copy, nothing is written, and it is reported as still needing it.
    $noHowAsaWorks2 = Join-Path $sandbox 'declined'
    New-Item -ItemType Directory -Path $noHowAsaWorks2 -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $noHowAsaWorks2 'declined.md') -Encoding UTF8 -Value "---`nproject: Declined`nstatus: idea`n---`n"
    $r3 = Invoke-Onboard -ProjectsRoot (Split-Path -Parent $noHowAsaWorks2) -AutoYes $false -Quiet
    # AutoYes false with -Quiet never prompts (no console in a self-test) - Quiet short-circuits
    # the Read-Host the same way a machine with no interactive console must.
    if ($r3.DeclinedOrNo -notcontains 'declined') {
        Write-Host '  FAIL  a folder answered no (or never prompted) should stay reported, not silently dropped'; $ok = $false
    } else { Write-Host '  PASS  answered no (or unattended): nothing written, still reported' }
    if (Test-Path -LiteralPath (Join-Path $noHowAsaWorks2 'HOW-ASA-WORKS.md')) {
        Write-Host '  FAIL  a template was copied in without being told yes'; $ok = $false
    } else { Write-Host '  PASS  never overwrites, never copies without a yes' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ------------------------------------------------------------

$projectsRoot = Get-RealProjectsFolder -Explicit $ProjectsFolder
if (-not $projectsRoot -or -not (Test-Path -LiteralPath $projectsRoot)) {
    Write-Host ''
    Write-Host 'No projects folder to onboard.'
    Write-Host '  Pass -ProjectsFolder <path>, or choose a folder in Asa first (settings.json).'
    exit 1
}

Write-Host ''
Write-Host "Onboarding: $projectsRoot"

$result = Invoke-Onboard -ProjectsRoot $projectsRoot -AutoYes:$Yes

Write-Host ''
Write-Host 'Summary:'
Write-Host ("  Already fine:            {0}" -f $result.Fine.Count)
Write-Host ("  HOW-ASA-WORKS.md added:  {0}" -f $result.Copied.Count)
Write-Host ("  Still missing it:        {0}" -f $result.DeclinedOrNo.Count)
Write-Host ("  No home note at all:     {0}" -f $result.NoHomeNote.Count)
Write-Host ''

if ($result.NoHomeNote.Count -gt 0 -or $result.DeclinedOrNo.Count -gt 0) {
    exit 1
}
exit 0
