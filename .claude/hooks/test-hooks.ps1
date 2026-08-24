# test-hooks.ps1 - the machine check for the hooks themselves.
#
# Feeds fixture JSON to each hook and asserts the exit code and side effects.
# No Claude session, no network, no real repo. Run it in one command:
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File test-hooks.ps1
#
# Exit 0 = all passed. Exit 1 = something failed.
#
# Why exit codes are the thing being tested: on PreToolUse, 2 blocks and
# everything else does not. A gate that returns 1 when it means "no" is a gate
# that silently allows every commit, and nothing on screen would show it.

$ErrorActionPreference = 'Stop'

$hooksSource = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:pass = 0
$script:fail = 0

# Windows PowerShell 5.1 is the target, but the suite also has to run under
# pwsh so the scripts can be checked somewhere other than the one machine
# they are meant for. An untested test suite is not a machine check.
$script:psExe = 'powershell.exe'
if (-not (Get-Command 'powershell.exe' -ErrorAction SilentlyContinue)) {
    $script:psExe = 'pwsh'
}

function Say([string]$text) { Write-Host $text }

function Check([string]$name, [bool]$ok, [string]$detail) {
    if ($ok) {
        $script:pass++
        Say ("  PASS  " + $name)
    } else {
        $script:fail++
        Say ("  FAIL  " + $name + "  ->  " + $detail)
    }
}

# Runs a hook script with the given JSON on stdin, inside a sandbox project.
# Returns the exit code; stderr is captured, not printed.
function Invoke-Hook {
    param([string]$Script, [string]$Json, [string]$Root)

    $inFile  = Join-Path $Root '_in.json'
    $errFile = Join-Path $Root '_err.txt'
    $outFile = Join-Path $Root '_out.txt'
    Set-Content -LiteralPath $inFile -Value $Json -Encoding ASCII

    $old = $env:CLAUDE_PROJECT_DIR
    $env:CLAUDE_PROJECT_DIR = $Root
    try {
        $p = Start-Process -FilePath $script:psExe `
            -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $hooksSource $Script)) `
            -RedirectStandardInput $inFile `
            -RedirectStandardError $errFile `
            -RedirectStandardOutput $outFile `
            -NoNewWindow -Wait -PassThru
        return $p.ExitCode
    } finally {
        $env:CLAUDE_PROJECT_DIR = $old
    }
}

function Get-HookStdout([string]$Root) {
    $f = Join-Path $Root '_out.txt'
    if (Test-Path $f) { return (Get-Content -LiteralPath $f -Raw) }
    return ''
}

# --- sandbox -----------------------------------------------------------

$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("hooktest_" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path (Join-Path $sandbox '.claude') 'hooks') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $sandbox 'lib') -Force | Out-Null

Set-Content -LiteralPath (Join-Path (Join-Path (Join-Path $sandbox '.claude') 'hooks') 'check.json') -Encoding ASCII -Value @'
{
  "command": "flutter test",
  "passMarker": "All tests passed",
  "watch": ["lib", "test"]
}
'@

Set-Content -LiteralPath (Join-Path $sandbox 'CLAUDE.md') -Encoding ASCII -Value @'
# CLAUDE.md

## Goal
Something.

## Where we are
Round 2 built, not verified. Next: run the machine check.

## Session log
Old stuff.
'@

Set-Content -LiteralPath (Join-Path (Join-Path $sandbox 'lib') 'main.dart') -Encoding ASCII -Value 'void main() {}'

$lastPassPath = Join-Path (Join-Path (Join-Path $sandbox '.claude') 'hooks') '.last-pass'

function Set-LastPass([datetime]$whenUtc) {
    Set-Content -LiteralPath $lastPassPath -Value $whenUtc.ToString('yyyy-MM-ddTHH:mm:ssZ') -Encoding ASCII
    (Get-Item -LiteralPath $lastPassPath -Force).LastWriteTimeUtc = $whenUtc
}

function Clear-LastPass {
    if (Test-Path $lastPassPath) { Remove-Item -LiteralPath $lastPassPath -Force }
}

function Touch-Code([datetime]$whenUtc) {
    $f = Join-Path (Join-Path $sandbox 'lib') 'main.dart'
    (Get-Item -LiteralPath $f).LastWriteTimeUtc = $whenUtc
}

$now = (Get-Date).ToUniversalTime()

Say ''
Say 'Hook tests'
Say '=========='
Say ''

# --- gate-commit -------------------------------------------------------

Say 'gate-commit.ps1'

Clear-LastPass
Touch-Code $now.AddHours(-2)

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"flutter test"}}' $sandbox
Check 'allows a command that is not a commit' ($code -eq 0) "expected 0, got $code"

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' $sandbox
Check 'blocks a commit when nothing has ever passed' ($code -eq 2) "expected 2, got $code"

Set-LastPass $now.AddHours(-1)
$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' $sandbox
Check 'allows a commit when the pass is newer than the code' ($code -eq 0) "expected 0, got $code"

Touch-Code $now
$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' $sandbox
Check 'blocks a commit when code changed after the pass' ($code -eq 2) "expected 2, got $code"

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m \"x\""}}' $sandbox
Check 'lets --no-verify through' ($code -eq 0) "expected 0, got $code"

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit-graph write"}}' $sandbox
Check 'does not mistake git commit-graph for a commit' ($code -eq 0) "expected 0, got $code"

$code = Invoke-Hook 'gate-commit.ps1' 'not json at all' $sandbox
Check 'fails open on unparseable input' ($code -eq 0) "expected 0, got $code"

# --- record-test -------------------------------------------------------

Say ''
Say 'record-test.ps1'

# The payload below is the real PostToolUse shape: 'tool_response', an object
# with stdout and stderr. The first version of these tests invented
# 'tool_output', which is why the hook shipped never having recorded anything -
# a test that agrees with the bug proves nothing.
Clear-LastPass
$json = '{"tool_name":"Bash","tool_input":{"command":"flutter test"},"tool_response":{"stdout":"00:15 +18: All tests passed!","stderr":"","interrupted":false}}'
$code = Invoke-Hook 'record-test.ps1' $json $sandbox
Check 'exits 0 on a passing run' ($code -eq 0) "expected 0, got $code"
Check 'records a timestamp when the output says it passed' (Test-Path $lastPassPath) 'no .last-pass file was written'

Clear-LastPass
$json = '{"tool_name":"Bash","tool_input":{"command":"flutter test"},"tool_response":{"stdout":"00:12 +3 -1: Some tests failed.","stderr":""}}'
$code = Invoke-Hook 'record-test.ps1' $json $sandbox
Check 'records nothing when the output says it failed' (-not (Test-Path $lastPassPath)) 'a failing run was recorded as a pass'

Clear-LastPass
$json = '{"tool_name":"Bash","tool_input":{"command":"git status"},"tool_response":{"stdout":"All tests passed!","stderr":""}}'
$code = Invoke-Hook 'record-test.ps1' $json $sandbox
Check 'ignores output from a different command' (-not (Test-Path $lastPassPath)) 'recorded a pass from an unrelated command'

Clear-LastPass
$json = '{"tool_name":"Bash","tool_input":{"command":"flutter test"},"tool_response":"00:15 +18: All tests passed!"}'
$code = Invoke-Hook 'record-test.ps1' $json $sandbox
Check 'reads a plain-string response too' (Test-Path $lastPassPath) 'a string tool_response was ignored'

Clear-LastPass
$json = '{"tool_name":"Bash","tool_input":{"command":"flutter test"},"tool_response":{"stderr":"00:15 +18: All tests passed!","stdout":""}}'
$code = Invoke-Hook 'record-test.ps1' $json $sandbox
Check 'reads stderr as well as stdout' (Test-Path $lastPassPath) 'output on stderr was ignored'

# --- orient ------------------------------------------------------------

Say ''
Say 'orient.ps1'

# State is set here rather than inherited from the case above. When the
# recorder was fixed, the last record-test case started leaving a real stamp
# behind and this assertion failed - the test had been passing on the previous
# case's side effect, not on anything it arranged itself.
Clear-LastPass

$code = Invoke-Hook 'orient.ps1' '{"hook_event_name":"SessionStart","how":"startup"}' $sandbox
Check 'exits 0' ($code -eq 0) "expected 0, got $code"

$out = Get-HookStdout $sandbox
Check 'prints the Where we are section' ($out -match 'Round 2 built, not verified') 'section missing from stdout'
Check 'stops before the next heading' (-not ($out -match 'Old stuff')) 'it ran past the end of the section'
Check 'says a machine check has not passed' ($out -match 'no passing machine check|No passing machine check') 'missing the machine-check line'
Check 'output is ASCII only' (-not ($out -match '[^\x09\x0A\x0D\x20-\x7E]')) 'non-ASCII characters in output'

Set-Content -LiteralPath $lastPassPath -Value '2026-08-24T10:00:00Z' -Encoding ASCII
$code = Invoke-Hook 'orient.ps1' '{"hook_event_name":"SessionStart","how":"startup"}' $sandbox
$out = Get-HookStdout $sandbox
Check 'reports the recorded pass when there is one' ($out -match 'Last recorded passing machine check') 'the recorded pass was not mentioned'
Clear-LastPass

# --- done --------------------------------------------------------------

Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue

Say ''
Say ("$script:pass passed, $script:fail failed")
Say ''

if ($script:fail -gt 0) { Say 'FAIL'; exit 1 }
Say 'All hook tests passed'
exit 0
