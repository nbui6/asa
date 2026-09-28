# sync-manual.ps1 - the manual, installed and kept in sync.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-manual.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-manual.ps1 -ProjectsFolder <path>
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-manual.ps1 -Check
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-manual.ps1 -Force
#
# Round 39 cp1. Copies templates\AGENTS.md and templates\CLAUDE.md to the root of the projects
# folder (the one in %APPDATA%\Asa\settings.json), and replaces every project's own
# HOW-ASA-WORKS.md with the ten-line pointer at templates\HOW-ASA-WORKS.md.
#
# NEVER overwrites a file that changed since this script itself last installed it, without saying
# so first - the same three-way diff (source now / installed now / installed last time) as
# kit\install-skills.ps1, tracked in its own manifest so a hand-edited HOW-ASA-WORKS.md in some
# project is never silently clobbered. -Force overwrites an edited copy anyway.
#
# -Check changes nothing: exits 1 the moment any installed copy no longer matches its template
# (check.ps1's own new step). -ProjectsFolder overrides the real folder from settings.json - used
# by onboard-projects.ps1 on a new laptop, and by this script's own -SelfTest.

param(
    [string]$ProjectsFolder,
    [switch]$Check,
    [switch]$Force,
    [switch]$Quiet,
    [string]$ManifestPath,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot   # kit\ -> repo root
$templatesDir = Join-Path $repoRoot 'templates'
$agentsTemplate = Join-Path $templatesDir 'AGENTS.md'
$claudeTemplate = Join-Path $templatesDir 'CLAUDE.md'
$howAsaWorksTemplate = Join-Path $templatesDir 'HOW-ASA-WORKS.md'

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

function Get-Sha256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$manifestPath = if ($ManifestPath) { $ManifestPath } else { Join-Path $env:APPDATA 'Asa\.manual-manifest.json' }

function Get-Manifest {
    if (-not (Test-Path -LiteralPath $manifestPath)) { return @{} }
    try {
        $m = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $result = @{}
        foreach ($prop in $m.PSObject.Properties) { $result[$prop.Name] = [string]$prop.Value }
        return $result
    } catch {
        return @{}
    }
}

# One (template, destination, manifestKey) triple per file this script owns - the root two, plus
# one HOW-ASA-WORKS.md per real project folder (mirroring onboard-projects.ps1's own filter: skip
# dot/underscore-prefixed folders, which are never projects).
function Get-Targets {
    param([string]$ProjectsRoot)

    $targets = New-Object System.Collections.Generic.List[object]
    $targets.Add([pscustomobject]@{
        Key      = 'AGENTS.md'
        Template = $agentsTemplate
        Dest     = Join-Path $ProjectsRoot 'AGENTS.md'
    })
    $targets.Add([pscustomobject]@{
        Key      = 'CLAUDE.md'
        Template = $claudeTemplate
        Dest     = Join-Path $ProjectsRoot 'CLAUDE.md'
    })

    foreach ($dir in (Get-ChildItem -LiteralPath $ProjectsRoot -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -match '^[._]') { continue }
        $targets.Add([pscustomobject]@{
            Key      = "$($dir.Name)\HOW-ASA-WORKS.md"
            Template = $howAsaWorksTemplate
            Dest     = Join-Path $dir.FullName 'HOW-ASA-WORKS.md'
        })
    }
    return $targets
}

# --- self-test ---------------------------------------------------------
# A check nobody has seen fail is not a check - especially the "never
# clobber an edit" guarantee, the one line here that would be expensive to
# get wrong.

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-sync-manual-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $sandboxManifest = Join-Path $sandbox '.manifest.json'
    $sandboxProjects = Join-Path $sandbox 'projects'
    New-Item -ItemType Directory -Path $sandboxProjects -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sandboxProjects 'proj-a') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sandboxProjects 'proj-b') -Force | Out-Null
    # A dot-prefixed folder is never a project - must never get a HOW-ASA-WORKS.md.
    New-Item -ItemType Directory -Path (Join-Path $sandboxProjects '.git') -Force | Out-Null

    $ok = $true
    function Invoke-Run {
        param([switch]$WithForce)
        # Splatting NAMED parameters needs a hashtable - an array splats
        # positionally, which silently mis-binds every switch and value.
        $scriptArgs = @{
            ProjectsFolder = $sandboxProjects
            ManifestPath   = $sandboxManifest
            Quiet          = $true
        }
        if ($WithForce) { $scriptArgs['Force'] = $true }
        & $PSCommandPath @scriptArgs
    }
    function Invoke-CheckRun {
        & $PSCommandPath -ProjectsFolder $sandboxProjects -ManifestPath $sandboxManifest -Check
    }

    Invoke-Run | Out-Null
    $howA = Join-Path $sandboxProjects 'proj-a\HOW-ASA-WORKS.md'
    $howB = Join-Path $sandboxProjects 'proj-b\HOW-ASA-WORKS.md'
    $rootAgents = Join-Path $sandboxProjects 'AGENTS.md'
    $hiddenHow = Join-Path $sandboxProjects '.git\HOW-ASA-WORKS.md'

    if ((Test-Path $howA) -and (Test-Path $howB) -and (Test-Path $rootAgents)) {
        Write-Host '  PASS  first run installs AGENTS.md and every project''s HOW-ASA-WORKS.md'
    } else { Write-Host '  FAIL  first run did not install everything expected'; $ok = $false }

    if (Test-Path $hiddenHow) {
        Write-Host '  FAIL  a dot-prefixed folder got a HOW-ASA-WORKS.md - it is never a project'; $ok = $false
    } else { Write-Host '  PASS  a dot-prefixed folder is left alone' }

    Invoke-CheckRun
    if ($LASTEXITCODE -ne 0) { Write-Host '  FAIL  -Check should pass right after a real install'; $ok = $false }
    else { Write-Host '  PASS  -Check passes right after a real install' }

    # Hand-edit one installed copy, then sync again without -Force.
    Set-Content -LiteralPath $howA -Value "EDITED BY HAND`n" -Encoding UTF8
    $editedHash = (Get-FileHash -LiteralPath $howA -Algorithm SHA256).Hash
    Invoke-Run | Out-Null
    $afterHash = (Get-FileHash -LiteralPath $howA -Algorithm SHA256).Hash
    if ($afterHash -eq $editedHash) {
        Write-Host '  PASS  an edited installed copy is kept, not silently overwritten'
    } else { Write-Host '  FAIL  an edited installed copy was overwritten without -Force'; $ok = $false }

    Invoke-CheckRun
    if ($LASTEXITCODE -ne 1) { Write-Host '  FAIL  -Check should fail while the edited copy differs from its template'; $ok = $false }
    else { Write-Host '  PASS  -Check fails while an installed copy has drifted' }

    # Now with -Force: the edit is overwritten.
    Invoke-Run -WithForce | Out-Null
    $forcedHash = (Get-FileHash -LiteralPath $howA -Algorithm SHA256).Hash
    $templateHash = (Get-FileHash -LiteralPath $howAsaWorksTemplate -Algorithm SHA256).Hash
    if ($forcedHash -eq $templateHash) {
        Write-Host '  PASS  -Force overwrites an edited installed copy'
    } else { Write-Host '  FAIL  -Force did not overwrite the edited copy'; $ok = $false }

    Invoke-CheckRun
    if ($LASTEXITCODE -ne 0) { Write-Host '  FAIL  -Check should pass again after -Force reinstalled it'; $ok = $false }
    else { Write-Host '  PASS  -Check passes again after -Force' }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

$projectsRoot = Get-RealProjectsFolder -Explicit $ProjectsFolder
if (-not $projectsRoot -or -not (Test-Path -LiteralPath $projectsRoot)) {
    if ($Check) {
        # Nothing configured yet (a fresh clone, or CI with no real
        # projects folder) is not drift - there is nothing to compare
        # against. check.ps1's own step passes rather than failing an
        # environment that was never wired to a projects folder at all.
        Write-Host 'No projects folder configured (settings.json) - nothing to check.'
        exit 0
    }
    Write-Host ''
    Write-Host 'No projects folder to sync the manual into.'
    Write-Host '  Pass -ProjectsFolder <path>, or choose a folder in Asa first (settings.json).'
    exit 1
}

$targets = Get-Targets -ProjectsRoot $projectsRoot
$previous = Get-Manifest

if ($Check) {
    $problems = New-Object System.Collections.Generic.List[string]
    foreach ($t in $targets) {
        $srcHash = Get-Sha256 $t.Template
        $dstHash = Get-Sha256 $t.Dest
        if ($null -eq $dstHash) {
            $problems.Add("missing: $($t.Key)")
        } elseif ($dstHash -ne $srcHash) {
            $problems.Add("out of date: $($t.Key)")
        }
    }
    if ($problems.Count -gt 0) {
        Write-Host "manual out of sync ($($problems.Count)):"
        foreach ($p in $problems) { Write-Host "  $p" }
        Write-Host ''
        Write-Host '  Run: powershell -NoProfile -ExecutionPolicy Bypass -File kit\sync-manual.ps1'
        exit 1
    }
    Write-Host "$($targets.Count) file(s), every installed copy matches its template."
    exit 0
}

$newFiles = New-Object System.Collections.Generic.List[string]
$updatedFiles = New-Object System.Collections.Generic.List[string]
$sameFiles = New-Object System.Collections.Generic.List[string]
$editedFiles = New-Object System.Collections.Generic.List[string]
$manifest = @{}

foreach ($t in $targets) {
    $srcHash = Get-Sha256 $t.Template
    $dstHash = Get-Sha256 $t.Dest
    $wasHash = $previous[$t.Key]
    $manifest[$t.Key] = $srcHash

    if ($null -eq $dstHash) {
        $newFiles.Add($t.Key)
    } elseif ($dstHash -eq $srcHash) {
        $sameFiles.Add($t.Key)
        continue
    } elseif ($wasHash -and $dstHash -ne $wasHash) {
        # On disk, and different from both what we installed last time and what we'd install
        # now: somebody (the Boss, or an AI on their behalf) edited it. Not ours to overwrite.
        $editedFiles.Add($t.Key)
        if (-not $Force) { continue }
    } else {
        $updatedFiles.Add($t.Key)
    }

    $parent = Split-Path -Parent $t.Dest
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $t.Template -Destination $t.Dest -Force
}

if (-not $Quiet) {
    Write-Host "Projects folder: $projectsRoot"
    Write-Host ("  unchanged  {0}" -f $sameFiles.Count)
    Write-Host ("  updated    {0}" -f $updatedFiles.Count)
    Write-Host ("  new        {0}" -f $newFiles.Count)
    if ($editedFiles.Count -gt 0) {
        Write-Host ''
        if ($Force) {
            Write-Host "  OVERWRITTEN, because -Force was given ($($editedFiles.Count)):"
        } else {
            Write-Host "  YOU EDITED THESE - kept, not overwritten ($($editedFiles.Count)):"
        }
        foreach ($f in $editedFiles) { Write-Host "    $f" }
    }
}

$manifestDir = Split-Path -Parent $manifestPath
if (-not (Test-Path -LiteralPath $manifestDir)) { New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sorted = [ordered]@{}
foreach ($k in ($manifest.Keys | Sort-Object)) { $sorted[$k] = $manifest[$k] }
[System.IO.File]::WriteAllText($manifestPath, ($sorted | ConvertTo-Json -Depth 2), $utf8NoBom)

exit 0
