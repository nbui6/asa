# sync-skills.ps1 - one source for every skill: kit\skills\ -> .claude\skills\
# (so this repo's own Claude Code session loads exactly what the kit ships),
# and dist\skills\*.zip, one archive per skill, for uploading to any other
# Claude account by hand.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-skills.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-skills.ps1 -Check
#
# Round 39 cp0, 2026-09-28 - found the account's own .claude\skills\ copies
# were older than kit\skills\: a skill added to the kit (this round's own
# `asa` skill) was invisible to this very session until this script existed.
# `check.ps1` runs this with -Check, which changes nothing and exits 1 the
# moment the two folders differ - so that drift can't happen silently again.
#
# Reuses kit\install-skills.ps1 for the actual copy (project scope, -Force:
# kit\skills\ is the one source of truth for THIS repo's own .claude\skills\,
# never something a session is expected to hand-edit in place). -Check does
# its own, simpler file-by-file hash comparison rather than parsing that
# installer's -DryRun report - a direct pass/fail, not text-scraping.

param([switch]$Check)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot   # kit\ -> repo root
$kitSkills = Join-Path $repoRoot 'kit\skills'
$installedSkills = Join-Path $repoRoot '.claude\skills'
$installer = Join-Path $repoRoot 'kit\install-skills.ps1'

if (-not (Test-Path $kitSkills)) { throw "No folder at: $kitSkills" }

function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-SkillFiles([string]$Root) {
    # dir\file.md -> a relative path, forward slashes, so the two sides of
    # the comparison never disagree only because of a slash direction.
    $files = @{}
    if (-not (Test-Path $Root)) { return $files }
    foreach ($f in (Get-ChildItem -LiteralPath $Root -Recurse -File)) {
        $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/').Replace('\', '/')
        $files[$rel] = $f.FullName
    }
    return $files
}

if ($Check) {
    $kitNames = @()
    foreach ($d in (Get-ChildItem -LiteralPath $kitSkills -Directory)) {
        if ($d.Name -eq '_installable') { continue }
        $kitNames += $d.Name
    }

    $fromKit = @{}
    foreach ($name in $kitNames) {
        $skillDir = Join-Path $kitSkills $name
        foreach ($pair in (Get-SkillFiles $skillDir).GetEnumerator()) {
            $fromKit["$name/$($pair.Key)"] = $pair.Value
        }
    }
    $fromInstalled = @{}
    foreach ($name in $kitNames) {
        $skillDir = Join-Path $installedSkills $name
        foreach ($pair in (Get-SkillFiles $skillDir).GetEnumerator()) {
            $fromInstalled["$name/$($pair.Key)"] = $pair.Value
        }
    }

    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($rel in ($fromKit.Keys | Sort-Object)) {
        if (-not $fromInstalled.ContainsKey($rel)) {
            $problems.Add("missing from .claude\skills\: $rel")
            continue
        }
        $kitHash = Get-Sha256 $fromKit[$rel]
        $installedHash = Get-Sha256 $fromInstalled[$rel]
        if ($kitHash -ne $installedHash) {
            $problems.Add("out of date in .claude\skills\: $rel")
        }
    }
    foreach ($rel in ($fromInstalled.Keys | Sort-Object)) {
        if (-not $fromKit.ContainsKey($rel)) {
            $problems.Add("in .claude\skills\ but not in kit\skills\: $rel")
        }
    }

    if ($problems.Count -gt 0) {
        Write-Host "skills out of sync ($($problems.Count)):"
        foreach ($p in $problems) { Write-Host "  $p" }
        Write-Host ''
        Write-Host '  Run: powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-skills.ps1'
        exit 1
    }
    Write-Host "$($kitNames.Count) skill(s), .claude\skills\ matches kit\skills\ exactly."
    exit 0
}

Write-Host '[1/2] .claude\skills\ <- kit\skills\ (project scope, one source)'
& $installer -Scope project -Project $repoRoot -Force

Write-Host ''
Write-Host '[2/2] dist\skills\*.zip - one archive per skill, for uploading to any account'
$distDir = Join-Path $repoRoot 'dist\skills'
if (Test-Path $distDir) { Remove-Item -Recurse -Force $distDir }
New-Item -ItemType Directory -Path $distDir -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipped = 0
foreach ($dir in (Get-ChildItem -LiteralPath $kitSkills -Directory)) {
    if ($dir.Name -eq '_installable') { continue }
    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) { continue }

    $zipPath = Join-Path $distDir "$($dir.Name).zip"
    if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    # SKILL.md sits at the zip's own top level (not nested a folder deep) -
    # a self-contained package, matching what an upload expects to unpack.
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $dir.FullName, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false
    )
    Write-Host "  wrote $($dir.Name).zip"
    $zipped++
}

Write-Host ''
Write-Host "$zipped skill(s) zipped into $distDir"
