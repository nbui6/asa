# projects-stop-six-moments.ps1 - Stop hook (Round 39 cp10), user-level.
#
# A plain word match, no model call, no cost (the user has no API budget, and
# whether a "type": "prompt" hook bills separately isn't documented).
# Blocks once with a short reminder when the user's own message this turn
# holds one of the six-moments' words AND nothing under projects\ was
# written this turn AND the answer has no Logged: line. A word match will
# sometimes remind when nothing actually happened - that costs one line,
# not a real error.
#
# Contract: Stop. Exit 2 blocks (stderr is the reason shown back); exit 0
# allows. Fails open on anything it can't read.

$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'asa-projects-common.ps1')

function Allow { exit 0 }

$hook = Read-HookInput
if (-not $hook) { Allow }
if ($hook.stop_hook_active) { Allow }

$cwd = Get-HookCwd -Hook $hook
if (-not (Test-InsideProjects -Cwd $cwd)) { Allow }

$root = Get-AsaProjectsRoot
$projectName = Get-ProjectNameUnderRoot -Cwd $cwd -Root $root
if (-not $projectName) { Allow }

# The six moments' own words (Instruction for AI §3, step 5), plus their
# German forms - this workspace's own AI sessions are not only English.
$momentWords = @(
    'yes', 'ok', "let's", 'decide', 'change', 'should', 'rule',
    'always', 'never', 'done', 'result',
    'ja', 'ändern', 'entscheiden', 'regel', 'immer', 'nie', 'fertig', 'ergebnis'
)

$lastUserMessage = ''
if ($hook.last_user_message) { $lastUserMessage = [string]$hook.last_user_message }
if (-not $lastUserMessage -and $hook.transcript_path -and (Test-Path -LiteralPath $hook.transcript_path)) {
    try {
        $lines = Get-Content -LiteralPath $hook.transcript_path -Encoding UTF8
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if (-not $lines[$i]) { continue }
            try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
            $role = $null
            if ($entry.message -and $entry.message.role) { $role = [string]$entry.message.role }
            if ($role -ne 'user') { continue }
            $content = $entry.message.content
            if ($content -is [string]) {
                $lastUserMessage = $content
            } elseif ($content) {
                $parts = @()
                foreach ($block in @($content)) {
                    if ($block.type -eq 'text' -and $block.text) { $parts += [string]$block.text }
                }
                $lastUserMessage = [string]::Join("`n", $parts)
            }
            break
        }
    } catch { }
}

$lower = $lastUserMessage.ToLowerInvariant()
$hasMomentWord = $false
foreach ($word in $momentWords) {
    if ($lower -match "(?<![a-zA-Z])$([regex]::Escape($word))(?![a-zA-Z])") {
        $hasMomentWord = $true
        break
    }
}
if (-not $hasMomentWord) { Allow }

# Nothing written this turn - the session file's own `updated:` is the
# same simple signal PostToolUse already keeps; a write in the last
# minute is "this turn," loosely - good enough for a reminder, not a
# proof.
$sessionPath = Join-Path (Join-Path $root $projectName) '.asa-session.md'
$writtenRecently = $false
if (Test-Path -LiteralPath $sessionPath) {
    $text = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8
    if ($text -match '(?m)^updated:\s*(.+)$') {
        $updated = $null
        try { $updated = [DateTime]::Parse($Matches[1].Trim()) } catch { }
        if ($updated -and ((Get-Date) - $updated).TotalMinutes -lt 2) { $writtenRecently = $true }
    }
}
if ($writtenRecently) { Allow }

$lastAnswer = ''
if ($hook.last_assistant_message) { $lastAnswer = [string]$hook.last_assistant_message }
if ($lastAnswer -match '(?m)^Logged:') { Allow }

[Console]::Error.WriteLine(
    'Check the six moments (Instruction for AI section 3, step 5): record what happened, then end with a Logged: line.'
)
exit 2
