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

# Until 2026-08-24 the suite only ever checked exit codes, so a gate that
# blocked for the right reason but printed the wrong path passed every test.
# The message is part of the contract: it is the only thing the human reads.
function Get-HookStderr([string]$Root) {
    $f = Join-Path $Root '_err.txt'
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

$err = Get-HookStderr $sandbox
Check 'names the file that changed, repo-relative' ($err -match 'lib[\\/]main\.dart') 'the changed file was not named relative to the repo'
Check 'does not print the absolute path' (-not ($err -match '(?i)' + [regex]::Escape($sandbox))) 'the message leaked the full path instead of a relative one'
Check 'names both timestamps' (($err -match 'last pass:') -and ($err -match 'changed:')) 'one of the two timestamps is missing'
Check 'says how to unblock' ($err -match 'flutter test') 'the message does not name the command to run'

# The real defect (2026-08-24) was a case-SENSITIVE Replace against
# CLAUDE_PROJECT_DIR, so the message printed the absolute path. Windows casing
# cannot be reproduced on a case-sensitive filesystem, so this test uses the
# same class of mismatch that IS portable: a root that points at the same
# folder while not being a string prefix of the file's path.
#
# Verified to FAIL against the old implementation before the fix was kept.
$dotted = Join-Path $sandbox '.'
$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"x\""}}' $dotted
$err = Get-HookStderr $dotted
Check 'blocks when the project dir is expressed differently' ($code -eq 2) "expected 2, got $code"
Check 'still names the file relative to the repo' (-not ($err -match [regex]::Escape($sandbox))) 'the absolute path leaked when the root was not a plain prefix'

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m \"x\""}}' $sandbox
Check 'lets --no-verify through' ($code -eq 0) "expected 0, got $code"

$code = Invoke-Hook 'gate-commit.ps1' '{"tool_name":"Bash","tool_input":{"command":"git commit-graph write"}}' $sandbox
Check 'does not mistake git commit-graph for a commit' ($code -eq 0) "expected 0, got $code"

$code = Invoke-Hook 'gate-commit.ps1' 'not json at all' $sandbox
Check 'fails open on unparseable input' ($code -eq 0) "expected 0, got $code"

# --- record-test -------------------------------------------------------

Say ''
Say 'record-test.ps1'

# The payloads below are the REAL PostToolUse shape: 'tool_response', an object
# with stdout and stderr. The first version of these tests invented
# 'tool_output', which is why the hook shipped having never recorded anything.
# A test written against the wrong contract agrees with the bug and proves
# nothing. Captured from a live payload on 2026-08-24, not recalled.

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

# State is arranged here rather than inherited from the case above. When the
# recorder was fixed, the previous case started leaving a real stamp behind and
# this section failed - it had been passing on a side effect, not on anything it
# set up itself. An order-dependent test is a test that lies when reordered.
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

# --- ranked work, and the plan gate, surfaced at session start ----------
#
# Added 2026-08-25. A ROADMAP item sat in Now, undone, for a whole session
# while the collision it described caused a real defect. Nothing read the
# file, so nothing said so.

Set-Content -LiteralPath (Join-Path $sandbox 'ROADMAP.md') -Encoding ASCII -Value @'
# Roadmap

## Part 2 - what to do about it

### Now

| # | Do | Sessions |
|---|---|---|
| 1 | Map the skills onto the steps | 1 |

### Next

| # | Do | Sessions |
|---|---|---|
| 3 | A kit installer | 1 |
'@

$code = Invoke-Hook 'orient.ps1' '{"hook_event_name":"SessionStart","how":"startup"}' $sandbox
$out = Get-HookStdout $sandbox
Check 'surfaces the ROADMAP Now items' ($out -match 'Map the skills onto the steps') 'the Now section was not injected'
# Paired with the positive signal on purpose. On its own, "Next is absent"
# is trivially true when nothing was injected at all - a negative assertion
# that passes on absence is not a test.
Check 'stops before the Next section' (($out -match 'Map the skills onto the steps') -and (-not ($out -match 'A kit installer'))) 'it injected nothing, or ran past Now into Next'

# An unsigned plan: the template ships with underscores on that line, and
# underscores must never read as a signature.
Set-Content -LiteralPath (Join-Path $sandbox 'PLAN.md') -Encoding ASCII -Value @'
# Plan - something

Confirmed by: ______________  on ____________

## What it is
A thing.
'@
$code = Invoke-Hook 'orient.ps1' '{"hook_event_name":"SessionStart","how":"startup"}' $sandbox
$out = Get-HookStdout $sandbox
Check 'flags an unsigned plan' ($out -match 'NOT confirmed') 'an unsigned plan was not flagged'

Set-Content -LiteralPath (Join-Path $sandbox 'PLAN.md') -Encoding ASCII -Value @'
# Plan - something

Confirmed by: Nico Bui       on 2026-08-25

## What it is
A thing.
'@
$code = Invoke-Hook 'orient.ps1' '{"hook_event_name":"SessionStart","how":"startup"}' $sandbox
$out = Get-HookStdout $sandbox
Check 'reports a signed plan with who and when' (($out -match 'confirmed by Nico Bui') -and ($out -match '2026-08-25')) 'the signature was not read back'
Check 'does not call a signed plan unconfirmed' (($out -match 'confirmed by Nico Bui') -and (-not ($out -match 'NOT confirmed'))) 'it said nothing about the plan, or called a signed plan unsigned'

Remove-Item -LiteralPath (Join-Path $sandbox 'PLAN.md') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $sandbox 'ROADMAP.md') -Force -ErrorAction SilentlyContinue

# --- install-hooks.ps1: check.json is detected, not assumed ------------
#
# Until 2026-08-26 the installer wrote "flutter test" into every new
# check.json - one product's command as the kit's default. These three
# assertions are what stops that coming back.

function New-Repo([string]$name, [string]$marker) {
    $r = Join-Path ([System.IO.Path]::GetTempPath()) ("kit-hooks-" + $name + "-" + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path (Join-Path $r '.git') -Force | Out-Null
    if ($marker) { Set-Content -LiteralPath (Join-Path $r $marker) -Value 'x' -Encoding ASCII }
    return $r
}

function Get-CheckCommand([string]$Root) {
    $p = Join-Path (Join-Path (Join-Path $Root '.claude') 'hooks') 'check.json'
    if (-not (Test-Path $p)) { return '<<no check.json>>' }
    return [string](((Get-Content -LiteralPath $p -Raw -Encoding UTF8) | ConvertFrom-Json).command)
}

function Install-Into([string]$Root) {
    $out = Join-Path $Root '_install.txt'
    $p = Start-Process -FilePath $script:psExe `
        -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $hooksSource 'install-hooks.ps1'), '-Project', $Root) `
        -RedirectStandardOutput $out -NoNewWindow -Wait -PassThru
    return (Get-Content -LiteralPath $out -Raw)
}

$flutterRepo = New-Repo 'flutter' 'pubspec.yaml'
Install-Into $flutterRepo | Out-Null
Check 'check.json is detected from a Flutter repo' ((Get-CheckCommand $flutterRepo) -eq 'flutter test') ("got: " + (Get-CheckCommand $flutterRepo))

$nodeRepo = New-Repo 'node' 'package.json'
Install-Into $nodeRepo | Out-Null
Check 'check.json is detected from a Node repo' ((Get-CheckCommand $nodeRepo) -eq 'npm test') ("got: " + (Get-CheckCommand $nodeRepo))

$plainRepo = New-Repo 'plain' ''
$plainOut = Install-Into $plainRepo
Check 'an unrecognised repo gets an empty command, not a guess' ((Get-CheckCommand $plainRepo) -eq '') ("got: " + (Get-CheckCommand $plainRepo))
Check 'and it says so loudly' ($plainOut -match 'EMPTY command') 'the installer did not warn that the command is empty'

foreach ($r in @($flutterRepo, $nodeRepo, $plainRepo)) {
    Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue
}

# --- done --------------------------------------------------------------

Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue

Say ''
Say ("$script:pass passed, $script:fail failed")
Say ''

if ($script:fail -gt 0) { Say 'FAIL'; exit 1 }
Say 'All hook tests passed'
exit 0
