# check-notes.ps1 - asa-check, run over every real project
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-notes.ps1
#
# Round 39 cp4's own line: "check-notes.ps1 (workspace root) runs it for every project." One
# project's own shape is `asa-check "<project>"` (bin\check.dart); this is the sweep across all
# of them, the same convention collect-feedback.ps1 already uses - the projects folder is the
# fixed sibling of this repo (rule 17), never read from settings.json, because this script runs
# from a shell, not from the app.
#
# Exit 0 when every project is clean, 1 when at least one has something to say - a real gate,
# unlike collect-feedback.ps1's own "it reports, never blocks" (that script moves data; this one
# is a check).

param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $MyInvocation.MyCommand.Path   # ...\workspace\asa
$root = Split-Path -Parent $repo                          # ...\workspace
$projectsRoot = Join-Path $root 'projects'

if (-not (Test-Path -LiteralPath $projectsRoot)) {
    Write-Host "No projects folder at $projectsRoot - nothing to check."
    exit 0
}

$dirs = Get-ChildItem -LiteralPath $projectsRoot -Directory |
    Where-Object { $_.Name -notmatch '^[._]' }

$dirty = New-Object System.Collections.Generic.List[string]

foreach ($dir in $dirs) {
    $output = & dart run (Join-Path $repo 'bin\check.dart') $dir.Name 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) { continue }

    $dirty.Add($dir.Name)
    if (-not $Quiet) {
        Write-Host ''
        Write-Host "$($dir.Name):"
        foreach ($line in $output) { Write-Host "  $line" }
    }
}

Write-Host ''
if ($dirty.Count -eq 0) {
    Write-Host "OK - $($dirs.Count) project(s), nothing to report."
    exit 0
}

Write-Host "$($dirty.Count) of $($dirs.Count) project(s) have something to report: $($dirty -join ', ')"
exit 1
