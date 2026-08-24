# record-test.ps1 - PostToolUse hook, matcher: Bash
#
# When the project's machine check runs AND its output says it passed, write a
# timestamp. Nothing else reads or writes that file except gate-commit.ps1.
#
# This is the evidence rule made mechanical. It was skipped three times when it
# depended on a person copying output; the machine now records it either way.
#
# Contract: PostToolUse cannot undo or block anything. Always exit 0 - a broken
# recorder must never stop work.

$ErrorActionPreference = 'Continue'

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
    # Unparseable input is not this hook's problem to solve loudly.
    exit 0
}

# Config lives next to the hooks so the same script works in any project.
$configPath = Join-Path (Join-Path (Join-Path $root '.claude') 'hooks') 'check.json'
if (-not (Test-Path $configPath)) { exit 0 }

try {
    $config = (Get-Content -LiteralPath $configPath -Raw -Encoding UTF8) | ConvertFrom-Json
} catch {
    exit 0
}

if (-not $config.command -or -not $config.passMarker) { exit 0 }

# What command was actually run?
$command = ''
if ($hook.tool_input -and $hook.tool_input.command) { $command = [string]$hook.tool_input.command }
if (-not $command) { exit 0 }

# Was it the machine check? Substring match, so "flutter test" also matches
# "cd C:\x; flutter test --no-pub".
if ($command.IndexOf($config.command, [StringComparison]::OrdinalIgnoreCase) -lt 0) { exit 0 }

# Did it pass? The output has to say so. An exit code alone is not enough:
# some test runners exit 0 while reporting failures.
#
# PostToolUse names this field 'tool_response', and for Bash it is an object
# with stdout and stderr rather than a string. Reading 'tool_output' - the name
# this hook first guessed - meant it never recorded anything, and its own test
# fed the same wrong name, so the test agreed with the bug. Every shape is
# accepted now, and the test feeds the real payload.
$output = ''
$response = $hook.tool_response
if (-not $response) { $response = $hook.tool_output }

if ($response -is [string]) {
    $output = $response
} elseif ($response) {
    foreach ($field in 'stdout', 'stderr', 'output') {
        $value = $response.$field
        if ($value) { $output += [string]$value + "`n" }
    }
    if (-not $output) { $output = [string]$response }
}

if (-not $output) { exit 0 }

if ($output.IndexOf($config.passMarker, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
    # Ran and did not pass. Deliberately leave the old timestamp untouched
    # rather than clearing it - clearing would hide that it once passed, and
    # the gate compares timestamps against file times anyway.
    exit 0
}

$hooksDir = Join-Path (Join-Path $root '.claude') 'hooks'
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }

$stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
Set-Content -LiteralPath (Join-Path $hooksDir '.last-pass') -Value $stamp -Encoding ASCII

exit 0
