# gate-commit.ps1 - PreToolUse hook, matcher: Bash
#
# Blocks "git commit" unless the project's machine check has passed since the
# last change to watched code.
#
# Contract: PreToolUse. Exit 2 blocks the tool and sends stderr back to the
# model as feedback. Exit 0 allows. Any other non-zero is a non-blocking error,
# so 1 must never be used to mean "no".
#
# The commit itself is never modified or rewritten - it is allowed or refused.

$ErrorActionPreference = 'Continue'

function Deny([string]$message) {
    [Console]::Error.WriteLine($message)
    exit 2
}

function Get-ProjectRoot {
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path $env:CLAUDE_PROJECT_DIR)) {
        return $env:CLAUDE_PROJECT_DIR
    }
    return (Get-Location).Path
}

$root = Get-ProjectRoot

try {
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { exit 0 }
    $hook = $raw | ConvertFrom-Json
} catch {
    # A gate that cannot read its input must not block work. Fail open, and be
    # loud about it in the test suite instead.
    exit 0
}

$command = ''
if ($hook.tool_input -and $hook.tool_input.command) { $command = [string]$hook.tool_input.command }
if (-not $command) { exit 0 }

# Only "git commit". Not "git commit-graph", not a commit inside a string.
if ($command -notmatch '(^|[\s;&|])git\s+commit(\s|$)') { exit 0 }

# An explicit escape hatch, because a gate with no override gets disabled
# entirely the first time it is wrong.
if ($command -match '--no-verify') { exit 0 }

$configPath = Join-Path (Join-Path (Join-Path $root '.claude') 'hooks') 'check.json'
if (-not (Test-Path $configPath)) {
    # No config means this project opted out. Not an error.
    exit 0
}

try {
    $config = (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8) | ConvertFrom-Json
} catch {
    Deny "The commit gate could not read .claude/hooks/check.json. Fix or delete that file, then commit again."
}

$checkCommand = [string]$config.command
$watch = @($config.watch)
if (-not $checkCommand) { exit 0 }

$lastPassPath = Join-Path (Join-Path (Join-Path $root '.claude') 'hooks') '.last-pass'

if (-not (Test-Path $lastPassPath)) {
    Deny @"
BLOCKED: no passing run of the machine check has been recorded.

Run this first:
  $checkCommand

Then commit again. To commit anyway, add --no-verify and say why in the message.
"@
}

$lastPass = (Get-Item -LiteralPath $lastPassPath -Force).LastWriteTimeUtc

# Find the newest watched file. If anything is newer than the last passing
# run, that run no longer proves anything about the current code.
$newestFile = $null
$newestTime = [DateTime]::MinValue

foreach ($dir in $watch) {
    $full = Join-Path $root $dir
    if (-not (Test-Path $full)) { continue }
    $files = Get-ChildItem -LiteralPath $full -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        if ($f.LastWriteTimeUtc -gt $newestTime) {
            $newestTime = $f.LastWriteTimeUtc
            $newestFile = $f.FullName
        }
    }
}

if ($newestFile -and $newestTime -gt $lastPass) {
    $rel = $newestFile.Replace($root, '').TrimStart('\')
    $passStr = $lastPass.ToString('yyyy-MM-dd HH:mm:ss') + ' UTC'
    $fileStr = $newestTime.ToString('yyyy-MM-dd HH:mm:ss') + ' UTC'
    Deny @"
BLOCKED: code changed after the last passing machine check.

  last pass:  $passStr
  changed:    $rel
              $fileStr

Run this first:
  $checkCommand

Then commit again. To commit anyway, add --no-verify and say why in the message.
"@
}

exit 0
