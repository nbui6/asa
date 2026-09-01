# install-skills.ps1 - put the kit's skills where Claude Code can actually load them.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-skills.ps1
#
# Why this exists: on 2026-08-24 the kit had 24 skills in a notes folder and
# Claude Code had none. Neither ~/.claude/skills nor the project's
# .claude/skills had ever existed. Every session that "used the kit" used the
# playbook and the hooks; the skills were never in a path anything reads.
#
# Default is USER scope - one copy, every project. For a project-scoped copy
# that a colleague gets on clone:
#
#   ... -File install-skills.ps1 -Scope project -Project "C:\path\to\repo"
#
# Agents ARE installed, into .claude/agents. This reversed on 2026-08-26.
#
# The old comment here said agents were deliberately left out because "0 of 3
# have run in five rounds and the open decision is hook them or delete them".
# That was circular: they cannot run from a folder nothing loads, so the
# non-installation was producing the evidence used to justify it. It is the
# same bug this script was written to fix for skills, left in place one folder
# over. SKILLS.md listed two explanations for the silence and neither was
# "not installed".
#
# Installing them decides nothing. A subagent runs when it is invoked; an
# uninstalled one cannot be invoked at all. Present and unused is a
# measurement. Absent is not.

# -Core installs only the skills that have actually fired on real work.
# Ranked on 2026-08-25: ten descriptions that have never fired still compete
# for the same sentences as the ones that have, and six real collision
# clusters were found. Standing token cost is a rounding error; a wrong skill
# answering a sentence is not.
#
#   ... -File install-skills.ps1 -Core

param(
    [ValidateSet('user', 'project')][string]$Scope = 'user',
    [string]$Project,
    [switch]$Core,
    [switch]$DryRun,
    [switch]$Force
)

# -DryRun  report what would happen and change nothing.
# -Force   overwrite files you have edited locally. Without it they are kept
#          and named, and the run still succeeds.
#
# THE GUARANTEE, and it is meant to be quotable:
#
#   This installer never creates, modifies or deletes a file it did not place.
#
# It knows which files those are because it writes .kit-manifest.json at every
# install - the version, and a SHA256 per file. On the next run it compares
# three things: what the kit has now, what the manifest says it put there, and
# what is actually on disk. That is what separates "you edited this" from
# "the kit changed this" from "this was never ours", and without it every
# upgrade is a leap of faith. Asked for by the first outside tester, whose
# skills folder holds skills this kit did not write.

# The skills that have fired on real work, as recorded in SKILLS.md.
# When a dormant skill fires for the first time, add it here in the same
# commit that records it - otherwise this list becomes a second source of
# truth that quietly disagrees with SKILLS.md.
$coreSkills = @(
    'discovery', 'research', 'roadmap', 'stack-choice', 'toolchain-map',
    'persona-check', 'sketch-the-product', 'architecture-map',
    'first-test', 'debugging',
    'obsidian-docs', 'process-audit', 'kit-feedback', 'explain-as-we-go'
)

$ErrorActionPreference = 'Stop'

$kitRoot    = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsFrom = Join-Path $kitRoot 'skills'

if (-not (Test-Path $skillsFrom)) { throw "No skills folder next to this script: $skillsFrom" }

# --- where the home directory is, on any platform -----------------------
function Get-HomeDir {
    if ($env:USERPROFILE) { return $env:USERPROFILE }
    if ($env:HOME)        { return $env:HOME }
    return [Environment]::GetFolderPath('UserProfile')
}

if ($Scope -eq 'project') {
    if (-not $Project) { throw "-Scope project needs -Project <path to the repo>" }
    if (-not (Test-Path $Project)) { throw "No folder at: $Project" }
    $claudeDir = Join-Path $Project '.claude'
} else {
    $claudeDir = Join-Path (Get-HomeDir) '.claude'
}
$target      = Join-Path $claudeDir 'skills'
$agentTarget = Join-Path $claudeDir 'agents'

New-Item -ItemType Directory -Path $target -Force | Out-Null

$version = 'unknown'
$versionFile = Join-Path $kitRoot 'VERSION'
if (Test-Path $versionFile) { $version = (Get-Content -LiteralPath $versionFile -Raw).Trim() }

Write-Host "Kit v$version  ->  $target"
Write-Host ''

# --- copy every skill folder -------------------------------------------
#
# _installable holds packaged .skill archives for a different purpose - saving
# a skill into a Claude account. They are not loadable folders, so they are
# skipped rather than copied and left to confuse someone later.

function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

# What a previous run of this installer says it put here, and with what contents.
$manifestPath = Join-Path $claudeDir '.kit-manifest.json'
$previous = @{}
$previousVersion = '(none)'
if (Test-Path $manifestPath) {
    try {
        $m = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $previousVersion = [string]$m.version
        foreach ($prop in $m.files.PSObject.Properties) { $previous[$prop.Name] = [string]$prop.Value }
    } catch {
        Write-Host '  .kit-manifest.json could not be read - treating this as a first install.'
    }
}

$installed = New-Object System.Collections.Generic.List[string]
$skipped   = New-Object System.Collections.Generic.List[string]
$dormant   = New-Object System.Collections.Generic.List[string]

# Per-file outcomes, which is what the report at the end is made of.
$newFiles     = New-Object System.Collections.Generic.List[string]
$updatedFiles = New-Object System.Collections.Generic.List[string]
$sameFiles    = New-Object System.Collections.Generic.List[string]
$editedFiles  = New-Object System.Collections.Generic.List[string]
$manifest     = @{}

foreach ($dir in (Get-ChildItem -LiteralPath $skillsFrom -Directory)) {
    if ($dir.Name -eq '_installable') { continue }

    if ($Core -and ($coreSkills -notcontains $dir.Name)) {
        $dormant.Add($dir.Name)
        continue
    }

    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) {
        $skipped.Add($dir.Name + ' (no SKILL.md)')
        continue
    }

    $dest = Join-Path $target $dir.Name
    if (-not $DryRun) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

    # File by file, not a blanket recursive copy: a blanket copy cannot tell
    # "you edited this" from "this is out of date".
    foreach ($src in (Get-ChildItem -LiteralPath $dir.FullName -Recurse -File)) {
        $rel = $dir.Name + '/' + $src.FullName.Substring($dir.FullName.Length).TrimStart('\','/').Replace('\','/')
        $dst = Join-Path $target ($rel -replace '/', [System.IO.Path]::DirectorySeparatorChar)

        $srcHash  = Get-Sha256 $src.FullName
        $dstHash  = Get-Sha256 $dst
        $wasHash  = $previous[$rel]

        $manifest[$rel] = $srcHash

        if ($null -eq $dstHash) {
            $newFiles.Add($rel)
        } elseif ($dstHash -eq $srcHash) {
            $sameFiles.Add($rel); continue
        } elseif ($wasHash -and $dstHash -ne $wasHash) {
            # On disk, and different from BOTH what we shipped last time and
            # what we ship now: somebody edited it. Not ours to overwrite.
            $editedFiles.Add($rel)
            if (-not $Force) { continue }
        } else {
            $updatedFiles.Add($rel)
        }

        if (-not $DryRun) {
            $parent = Split-Path -Parent $dst
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $src.FullName -Destination $dst -Force
        }
    }
    $installed.Add($dir.Name)
}

foreach ($n in $installed) { Write-Host "  installed  $n" }
foreach ($n in $skipped)   { Write-Host "  SKIPPED    $n" }

# Named, never silent. A skill left out without being listed is a skill the
# user will one day expect to fire and be unable to explain.
if ($dormant.Count -gt 0) {
    Write-Host ''
    Write-Host "-Core: left out $($dormant.Count) skill(s) that have never fired -"
    Write-Host "  $($dormant -join ', ')"
    Write-Host '  Re-run without -Core to install everything.'
}

# --- anything already there that this run did not install ---------------
#
# Two very different cases, and reporting them as one was a bug on
# 2026-08-26: with -Core, the ten dormant KIT skills left over from an
# earlier full install were printed under the heading "project's own
# skills", which is simply false. A heading that can be printed over the
# wrong list is not a report.
#
# So: compare against every skill name the kit HAS, not against the ones
# this run happened to copy.
#
#   - a name the kit has, not installed this run -> a leftover from an
#     earlier install. Never deleted; a skill is not the installer's to
#     remove.
#   - a name the kit does not have at all        -> somebody else's. In a
#     project scope that is the product's own skill, which lives there on
#     purpose (PLAYBOOK.md 14, "Two libraries").

$kitSkillNames = @()
foreach ($d in (Get-ChildItem -LiteralPath $skillsFrom -Directory)) {
    if ($d.Name -ne '_installable') { $kitSkillNames += $d.Name }
}

$leftover = New-Object System.Collections.Generic.List[string]
$foreign  = New-Object System.Collections.Generic.List[string]
foreach ($dir in (Get-ChildItem -LiteralPath $target -Directory)) {
    if ($installed.Contains($dir.Name)) { continue }
    if ($kitSkillNames -contains $dir.Name) { $leftover.Add($dir.Name) }
    else { $foreign.Add($dir.Name) }
}

if ($leftover.Count -gt 0) {
    Write-Host ''
    Write-Host "Kit skills already present that this run did not install ($($leftover.Count)):"
    Write-Host "  $($leftover -join ', ')"
    Write-Host '  Left in place from an earlier install. Nothing is deleted here.'
}
if ($foreign.Count -gt 0) {
    Write-Host ''
    Write-Host "Not from this kit - left alone (the project's own skills):"
    foreach ($n in $foreign) { Write-Host "  $n" }
}

# --- copy the agents ----------------------------------------------------
#
# Agents are single .md files with YAML front matter, not folders. They go to
# .claude/agents, which Claude Code reads for the subagent_type names it will
# accept. -Core does not apply: there are three, and leaving one out is what
# kept them at zero runs.

$agentsFrom     = Join-Path $kitRoot 'agents'
$agentsInstalled = New-Object System.Collections.Generic.List[string]

if (Test-Path $agentsFrom) {
    New-Item -ItemType Directory -Path $agentTarget -Force | Out-Null
    Write-Host ''
    foreach ($f in (Get-ChildItem -LiteralPath $agentsFrom -Filter '*.md' -File)) {
        $rel = 'agents/' + $f.Name
        $dst = Join-Path $agentTarget $f.Name
        $srcHash = Get-Sha256 $f.FullName
        $dstHash = Get-Sha256 $dst
        $wasHash = $previous[$rel]
        $manifest[$rel] = $srcHash

        $verdict = 'new'
        $write = $true
        if ($null -ne $dstHash) {
            if ($dstHash -eq $srcHash) { $verdict = 'unchanged'; $write = $false }
            elseif ($wasHash -and $dstHash -ne $wasHash) { $verdict = 'YOU EDITED THIS'; $write = [bool]$Force }
            else { $verdict = 'updated' }
        }
        if ($write -and -not $DryRun) { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force }

        $agentsInstalled.Add([System.IO.Path]::GetFileNameWithoutExtension($f.Name))
        Write-Host ("  agent      {0,-16} {1}" -f [System.IO.Path]::GetFileNameWithoutExtension($f.Name), $verdict)
    }
} else {
    Write-Host ''
    Write-Host "  no agents folder next to this script - none installed"
}

# --- what this run actually did ------------------------------------------

Write-Host ''
if ($previousVersion -ne '(none)') { Write-Host "Previously installed: v$previousVersion" }

Write-Host ("  unchanged        {0}" -f $sameFiles.Count)
Write-Host ("  updated          {0}" -f $updatedFiles.Count)
Write-Host ("  new              {0}" -f $newFiles.Count)

if ($editedFiles.Count -gt 0) {
    Write-Host ''
    if ($Force) {
        Write-Host "  OVERWRITTEN, because -Force was given ($($editedFiles.Count)):"
    } else {
        Write-Host "  YOU EDITED THESE - kept, not overwritten ($($editedFiles.Count)):"
    }
    foreach ($f in $editedFiles) { Write-Host "    $f" }
    if (-not $Force) {
        Write-Host '    Your version is still there. Re-run with -Force to take the kit''s,'
        Write-Host '    or move your change into the kit so it survives the next upgrade.'
    }
}

# In the manifest, absent from the kit: removed in this version. Never deleted
# here - a file the user may have come to rely on is not the installer's to
# remove. Named, so the removal is visible.
$removed = New-Object System.Collections.Generic.List[string]
foreach ($rel in $previous.Keys) { if (-not $manifest.ContainsKey($rel)) { $removed.Add($rel) } }
if ($removed.Count -gt 0 -and -not $Core) {
    Write-Host ''
    Write-Host "  no longer part of the kit, left on disk ($($removed.Count)):"
    foreach ($f in $removed) { Write-Host "    $f" }
}

# --- the manifest --------------------------------------------------------
#
# version + a SHA256 per file. This is what makes the next upgrade legible
# instead of a leap of faith.

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($DryRun) {
    Write-Host ''
    Write-Host 'DRY RUN - nothing was written, including the manifest.'
    exit 0
}

$manifestObject = [ordered]@{
    version   = $version
    installed = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    from      = $kitRoot
    scope     = $Scope
    core      = [bool]$Core
    files     = [ordered]@{}
}
foreach ($k in ($manifest.Keys | Sort-Object)) { $manifestObject.files[$k] = $manifest[$k] }
[System.IO.File]::WriteAllText($manifestPath, ($manifestObject | ConvertTo-Json -Depth 4), $utf8NoBom)

$stamp = @"
kit version: $version
installed:   $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
from:        $kitRoot
scope:       $Scope
skills:      $($installed.Count)
agents:      $($agentsInstalled.Count) ($($agentsInstalled -join ', '))
manifest:    $manifestPath
"@
[System.IO.File]::WriteAllText((Join-Path $target '.kit-version'), $stamp, $utf8NoBom)

Write-Host ''
Write-Host "$($installed.Count) skills and $($agentsInstalled.Count) agents installed. Kit v$version."
Write-Host "Manifest: $manifestPath  -  $($manifest.Count) files, one hash each."
Write-Host ''
Write-Host 'Next:'
Write-Host '  1. Restart Claude Code so it picks them up'
Write-Host '  2. In a session, run  /skills  to confirm they are listed'
Write-Host '  3. Ask for a review and check the agent is offered by name'
Write-Host '  4. On a new kit version, run this again - it will tell you what it changed'
