# install-hooks.ps1 - copy the hooks into a project and register them.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-hooks.ps1 -Project "C:\path\to\repo"
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-hooks.ps1 -Scope user
#
# Merges into .claude/settings.json rather than overwriting it. Anything already
# in that file is left alone; a hook entry that is already present is not added
# twice, so running this again is safe.
#
# -Scope project (the default) is everything this script always did: the
# kit's own dev hooks (orient/record-test/gate-commit), into one repo's own
# .claude\settings.json.
#
# -Scope user (Round 39 cp10) is a different, independent thing: the five
# projects\-scoped hooks (SessionStart/PostToolUse/Stop x2/SessionEnd),
# into ~/.claude/settings.json - once, for this Windows account, so they
# fire in any project folder below `projects\`, not one repo. No -Project,
# no git-repo check: there is no single repo this half installs into.

# -Project is the FULL PATH to the repo, not a name. It used to be mandatory,
# which made PowerShell prompt with a bare "Project:" - and on 2026-08-25 that
# was reasonably read as a request for a project name. It now defaults to the
# current folder, and refuses to install into anything that is not a git repo.
param(
    [string]$Project = (Get-Location).Path,
    [ValidateSet('project', 'user')]
    [string]$Scope = 'project'
)

# --- shared settings.json helpers (both scopes use these) --------------
#
# Why this exists: on Windows PowerShell 5.1,
#   (New-Object PSObject).PSObject.Properties.Name
# is $null, not an empty list. Calling .Contains() on it throws
# "You cannot call a method on a null-valued expression".
# Indexing Properties[name] is null-safe on both 5.1 and 7.

function Test-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return ($null -ne $Object.PSObject.Properties[$Name])
}

function Set-Prop {
    param($Object, [string]$Name, $Value)
    if (Test-Prop $Object $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

function New-HookEntry {
    param([string]$Command, [string]$Matcher)
    $inner = New-Object PSObject
    Set-Prop $inner 'type'    'command'
    Set-Prop $inner 'command' $Command
    Set-Prop $inner 'timeout' 30

    $entry = New-Object PSObject
    if ($Matcher) { Set-Prop $entry 'matcher' $Matcher }
    Set-Prop $entry 'hooks' @($inner)
    return $entry
}

function Add-HookTo {
    param($Settings, [string]$EventName, [string]$Command, [string]$Matcher, [string]$MatchOn)

    $existing = @()
    if (Test-Prop $Settings.hooks $EventName) {
        $existing = @($Settings.hooks.$EventName)
    }

    foreach ($e in $existing) {
        if ($null -eq $e) { continue }
        foreach ($h in @($e.hooks)) {
            if ($null -eq $h) { continue }
            if ($h.command -and ([string]$h.command).Contains($MatchOn)) {
                Write-Host "$EventName -> $MatchOn already registered, skipping"
                return $Settings
            }
        }
    }

    $updated = @($existing) + @(New-HookEntry -Command $Command -Matcher $Matcher)
    Set-Prop $Settings.hooks $EventName $updated
    Write-Host "registered $EventName -> $MatchOn"
    return $Settings
}

function Read-SettingsFile {
    param([string]$Path)
    if (Test-Path $Path) {
        $backup = "$Path.backup-" + (Get-Date).ToString('yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $Path -Destination $backup -Force
        Write-Host "backed up existing settings.json"
        $text = Get-Content -LiteralPath $Path -Raw
        $text = $text -replace "^\xEF\xBB\xBF", '' -replace "^\uFEFF", ''
        if ($text.Trim()) {
            $settings = $text | ConvertFrom-Json
        } else {
            $settings = New-Object PSObject
        }
    } else {
        $settings = New-Object PSObject
    }
    if (-not (Test-Prop $settings 'hooks')) {
        Set-Prop $settings 'hooks' (New-Object PSObject)
    }
    return $settings
}

function Write-SettingsFile {
    param($Settings, [string]$Path)
    $json = $Settings | ConvertTo-Json -Depth 12
    # No byte order mark - Set-Content -Encoding UTF8 on Windows PowerShell
    # 5.1 writes one, and a leading BOM makes the JSON unparseable for
    # anything that does not strip it.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
    $firstBytes = [System.IO.File]::ReadAllBytes($Path)[0..2] -join ' '
    Write-Host ''
    Write-Host "wrote settings.json  (first bytes: $firstBytes  <- must not be 239 187 191)"
}

# --- -Scope user: the projects\-scoped hooks, once per Windows account --

if ($Scope -eq 'user') {
    $ErrorActionPreference = 'Stop'
    $source = Split-Path -Parent $MyInvocation.MyCommand.Path
    $userClaudeDir = Join-Path $HOME '.claude'
    $userHooksDir = Join-Path $userClaudeDir 'hooks'
    New-Item -ItemType Directory -Path $userHooksDir -Force | Out-Null

    $projectsHookFiles = @(
        'asa-projects-common.ps1',
        'projects-session-start.ps1',
        'projects-post-tool-use.ps1',
        'projects-stop-six-moments.ps1',
        'projects-stop-check.ps1',
        'projects-session-end.ps1'
    )
    foreach ($f in $projectsHookFiles) {
        Copy-Item -LiteralPath (Join-Path $source $f) -Destination (Join-Path $userHooksDir $f) -Force
        Write-Host "copied $f -> $userHooksDir"
    }

    $userSettingsPath = Join-Path $userClaudeDir 'settings.json'
    $settings = Read-SettingsFile -Path $userSettingsPath

    function Cmd([string]$Name) {
        return 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $userHooksDir $Name) + '"'
    }

    $settings = Add-HookTo -Settings $settings -EventName 'SessionStart' -Command (Cmd 'projects-session-start.ps1') -Matcher '' -MatchOn 'projects-session-start.ps1'
    $settings = Add-HookTo -Settings $settings -EventName 'PostToolUse'  -Command (Cmd 'projects-post-tool-use.ps1') -Matcher 'Write|Edit|MultiEdit' -MatchOn 'projects-post-tool-use.ps1'
    $settings = Add-HookTo -Settings $settings -EventName 'Stop'         -Command (Cmd 'projects-stop-six-moments.ps1') -Matcher '' -MatchOn 'projects-stop-six-moments.ps1'
    $settings = Add-HookTo -Settings $settings -EventName 'Stop'         -Command (Cmd 'projects-stop-check.ps1') -Matcher '' -MatchOn 'projects-stop-check.ps1'
    $settings = Add-HookTo -Settings $settings -EventName 'SessionEnd'   -Command (Cmd 'projects-session-end.ps1') -Matcher '' -MatchOn 'projects-session-end.ps1'

    Write-SettingsFile -Settings $settings -Path $userSettingsPath

    Write-Host ''
    Write-Host 'Done. The projects\-scoped hooks are installed for this Windows account.'
    Write-Host 'Restart Claude Code so it reads the new ~/.claude/settings.json.'
    exit 0
}

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Project)) { throw "No folder at: $Project" }

$Project = (Resolve-Path -LiteralPath $Project).Path

# Hooks belong in a repo. Without this guard, running the script from the wrong
# folder silently installs them somewhere harmless-looking and nothing fires.
if (-not (Test-Path (Join-Path $Project '.git'))) {
    throw @"
Not a git repository: $Project

-Project takes the FULL PATH to the repo, not a project name. Either cd into the
repo and run this with no arguments, or pass the path:

  ... -File install-hooks.ps1 -Project C:\path\to\your\repo
"@
}

Write-Host "Installing hooks into: $Project"
Write-Host ''

$source   = Split-Path -Parent $MyInvocation.MyCommand.Path
$claudeIn = Join-Path $Project '.claude'
$hooksIn  = Join-Path $claudeIn 'hooks'

New-Item -ItemType Directory -Path $hooksIn -Force | Out-Null

# Running the installer from the folder it installs into is not a mistake worth
# an error message. It happens the moment someone re-runs the copy that is
# already in .claude\hooks - which is exactly what happened on 2026-08-25.
# Copy-Item throws "Cannot overwrite the item with itself" and the run dies
# before registering anything, which is the part that actually matters.
$sameFolder = ((Resolve-Path -LiteralPath $source).Path.TrimEnd('\','/') -eq
               (Resolve-Path -LiteralPath $hooksIn).Path.TrimEnd('\','/'))

if ($sameFolder) {
    Write-Host 'Scripts are already in place (running from the destination) - skipping the copy.'
} else {
    # install-hooks.ps1 is in this list because test-hooks.ps1 shells out to it
    # for four assertions. Left out, the suite fails 4 of 34 the first time
    # anyone runs it from .claude\hooks - which is what the closing message of
    # this very script tells them to do. Found by an audit, 2026-08-26.
    foreach ($f in @('orient.ps1', 'record-test.ps1', 'gate-commit.ps1', 'test-hooks.ps1', 'install-hooks.ps1')) {
        Copy-Item -LiteralPath (Join-Path $source $f) -Destination (Join-Path $hooksIn $f) -Force
        Write-Host "copied $f"
    }
}

# check.json is configuration, not code. Never overwrite an existing one.
#
# The default used to be hard-coded to "flutter test" - one product's command
# shipped as the kit's default (fixed 2026-08-26). It is now read off the
# repo: whatever project files are actually present decide it, and a project
# the kit does not recognise gets an empty command and is told to fill it in,
# which is more honest than a guess that happens to be wrong.

$checkPath = Join-Path $hooksIn 'check.json'
if (-not (Test-Path $checkPath)) {

    $cmd = ''
    $marker = ''
    $watch = '["src"]'

    if (Test-Path (Join-Path $Project 'pubspec.yaml')) {
        $cmd = 'flutter test'; $marker = 'All tests passed'; $watch = '["lib", "test"]'
    } elseif (Test-Path (Join-Path $Project 'package.json')) {
        $cmd = 'npm test'; $marker = 'passing'; $watch = '["src", "test"]'
    } elseif ((Test-Path (Join-Path $Project 'pyproject.toml')) -or
              (Test-Path (Join-Path $Project 'requirements.txt'))) {
        $cmd = 'pytest -q'; $marker = 'passed'; $watch = '["src", "tests"]'
    } elseif (Test-Path (Join-Path $Project 'go.mod')) {
        $cmd = 'go test ./...'; $marker = 'ok'; $watch = '["."]'
    } elseif (Test-Path (Join-Path $Project 'Cargo.toml')) {
        $cmd = 'cargo test'; $marker = 'test result: ok'; $watch = '["src", "tests"]'
    }

    $json = @"
{
  "command": "$cmd",
  "passMarker": "$marker",
  "watch": $watch
}
"@
    Set-Content -LiteralPath $checkPath -Encoding ASCII -Value $json

    if ($cmd -eq '') {
        Write-Host 'created check.json with an EMPTY command - the kit could not tell what this'
        Write-Host '  project is built with. Open it and fill in your pass/fail command, or the'
        Write-Host '  commit gate has nothing to check.'
    } else {
        Write-Host "created check.json  ->  $cmd   (detected from this repo; edit if wrong)"
    }
} else {
    Write-Host 'check.json already exists, left alone'
}

# --- helpers -----------------------------------------------------------
#
# Why this exists: on Windows PowerShell 5.1,
#   (New-Object PSObject).PSObject.Properties.Name
# is $null, not an empty list. Calling .Contains() on it throws
# "You cannot call a method on a null-valued expression".
# Indexing Properties[name] is null-safe on both 5.1 and 7.

function Test-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $false }
    return ($null -ne $Object.PSObject.Properties[$Name])
}

function Set-Prop {
    param($Object, [string]$Name, $Value)
    if (Test-Prop $Object $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
}

# --- merge settings.json ------------------------------------------------

$settingsPath = Join-Path $claudeIn 'settings.json'

if (Test-Path $settingsPath) {
    $backup = Join-Path $claudeIn ('settings.json.backup-' + (Get-Date).ToString('yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $settingsPath -Destination $backup -Force
    Write-Host 'backed up existing settings.json'
    $text = Get-Content -LiteralPath $settingsPath -Raw
    # Strip a byte order mark if one is present, or ConvertFrom-Json fails on it.
    $text = $text -replace "^\xEF\xBB\xBF", '' -replace "^\uFEFF", ''
    if ($text.Trim()) {
        $settings = $text | ConvertFrom-Json
    } else {
        $settings = New-Object PSObject
    }
} else {
    $settings = New-Object PSObject
}

if (-not (Test-Prop $settings 'hooks')) {
    Set-Prop $settings 'hooks' (New-Object PSObject)
}

function New-HookEntry {
    param([string]$ScriptName, [string]$Matcher)

    $cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PROJECT_DIR}/.claude/hooks/' + $ScriptName + '"'

    $inner = New-Object PSObject
    Set-Prop $inner 'type'    'command'
    Set-Prop $inner 'command' $cmd
    Set-Prop $inner 'timeout' 30

    $entry = New-Object PSObject
    if ($Matcher) { Set-Prop $entry 'matcher' $Matcher }
    Set-Prop $entry 'hooks' @($inner)
    return $entry
}

function Add-Hook {
    param([string]$EventName, [string]$ScriptName, [string]$Matcher)

    $existing = @()
    if (Test-Prop $settings.hooks $EventName) {
        $existing = @($settings.hooks.$EventName)
    }

    foreach ($e in $existing) {
        if ($null -eq $e) { continue }
        foreach ($h in @($e.hooks)) {
            if ($null -eq $h) { continue }
            if ($h.command -and ([string]$h.command).Contains($ScriptName)) {
                Write-Host "$EventName -> $ScriptName already registered, skipping"
                return
            }
        }
    }

    $updated = @($existing) + @(New-HookEntry -ScriptName $ScriptName -Matcher $Matcher)
    Set-Prop $settings.hooks $EventName $updated
    Write-Host "registered $EventName -> $ScriptName"
}

Add-Hook -EventName 'SessionStart' -ScriptName 'orient.ps1'      -Matcher ''
Add-Hook -EventName 'PostToolUse'  -ScriptName 'record-test.ps1' -Matcher 'Bash'
Add-Hook -EventName 'PreToolUse'   -ScriptName 'gate-commit.ps1' -Matcher 'Bash'

$json = $settings | ConvertTo-Json -Depth 12

# Written with no byte order mark. Set-Content -Encoding UTF8 on Windows
# PowerShell 5.1 writes a BOM, and a leading BOM makes the JSON unparseable
# for anything that does not strip it. Third encoding bug of the same family
# in one day, so this one is explicit rather than default.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($settingsPath, $json, $utf8NoBom)

$firstBytes = [System.IO.File]::ReadAllBytes($settingsPath)[0..2] -join ' '
Write-Host ''
Write-Host "wrote settings.json  (first bytes: $firstBytes  <- must not be 239 187 191)"

Write-Host ''
Write-Host 'Done.'
Write-Host ''
Write-Host 'Next:'
Write-Host "  1. Check .claude/hooks/check.json matches your machine check"
Write-Host "  2. powershell -NoProfile -ExecutionPolicy Bypass -File `"$hooksIn\test-hooks.ps1`""
Write-Host "  3. Restart Claude Code in this folder so it reads the new settings"
