# asa-projects-common.ps1 - shared helpers for the projects\-scoped hooks
# (Round 39 cp10). Dot-sourced by each one; never run directly.
#
# "Every hook first checks that the working folder is inside the projects
# folder (from settings.json) and does nothing otherwise" - round-39.md's
# own line. One place for that check, not five copies of it.

function Get-AsaSettings {
    $appData = $env:APPDATA
    if (-not $appData) { return $null }
    $path = Join-Path $appData 'Asa\settings.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        return ($text | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Get-AsaProjectsRoot {
    $settings = Get-AsaSettings
    if ($null -eq $settings) { return $null }
    if (-not $settings.projectsFolder) { return $null }
    return [string]$settings.projectsFolder
}

# The asa repo itself sits as the fixed sibling of the projects folder
# (rule 17's own workspace shape) - the same assumption
# `skills_catalog.dart`'s own `asaRepoPathFrom` already makes in Dart.
function Get-AsaRepoPath {
    param([string]$ProjectsRoot)
    if (-not $ProjectsRoot) { return $null }
    $parent = Split-Path -Parent $ProjectsRoot.TrimEnd('\', '/')
    if (-not $parent) { return $null }
    $candidate = Join-Path $parent 'asa'
    if (-not (Test-Path -LiteralPath $candidate)) { return $null }
    return $candidate
}

function Test-InsideProjects {
    param([string]$Cwd)
    $root = Get-AsaProjectsRoot
    if (-not $root) { return $false }
    if (-not $Cwd) { return $false }
    try {
        $rootFull = (Resolve-Path -LiteralPath $root -ErrorAction Stop).Path.TrimEnd('\', '/')
        $cwdFull = (Resolve-Path -LiteralPath $Cwd -ErrorAction Stop).Path.TrimEnd('\', '/')
    } catch {
        return $false
    }
    if ($cwdFull -eq $rootFull) { return $true }
    return $cwdFull.StartsWith($rootFull + '\') -or $cwdFull.StartsWith($rootFull + '/')
}

# "demo" from "C:\...\projects\demo" or "C:\...\projects\demo\plan" - null
# when [Cwd] IS the projects root itself, not one project inside it.
function Get-ProjectNameUnderRoot {
    param([string]$Cwd, [string]$Root)
    $rootFull = (Resolve-Path -LiteralPath $Root -ErrorAction SilentlyContinue).Path
    if (-not $rootFull) { $rootFull = $Root }
    $rootFull = $rootFull.TrimEnd('\', '/')
    $cwdFull = (Resolve-Path -LiteralPath $Cwd -ErrorAction SilentlyContinue).Path
    if (-not $cwdFull) { $cwdFull = $Cwd }
    $cwdFull = $cwdFull.TrimEnd('\', '/')
    if ($cwdFull -eq $rootFull) { return $null }
    if (-not $cwdFull.StartsWith($rootFull)) { return $null }
    $relative = $cwdFull.Substring($rootFull.Length).TrimStart('\', '/')
    if (-not $relative) { return $null }
    $firstSegment = ($relative -split '[\\/]')[0]
    if (-not $firstSegment) { return $null }
    return $firstSegment
}

# Reads stdin as JSON once. Returns $null on anything unreadable - callers
# fail open, same discipline every hook in this kit already follows.
function Read-HookInput {
    try {
        $raw = [Console]::In.ReadToEnd()
        if (-not $raw) { return $null }
        return ($raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

# The hook's own idea of "where Claude Code is running" - the input
# JSON's own `cwd` when it has one, else the process's real location.
function Get-HookCwd {
    param($Hook)
    if ($Hook -and $Hook.cwd) { return [string]$Hook.cwd }
    return (Get-Location).Path
}
