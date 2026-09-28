# delivery-check.ps1 - Stop hook, blocks ending the turn while
# projects\asa\rounds\delivery-v1.md's own Progress checklist has an
# unticked item and the last answer isn't a real stop (BLOCKED:/DECISION
# NEEDED:). ADR 0047's own line: "keep going by itself."
#
# Contract: Stop. Exit 2 blocks (stderr goes back to the model as the
# reason); exit 0 allows. Fails open on anything it can't read - a gate
# that can't read its input must not block (same rule gate-commit.ps1
# already follows).
#
# Deliberately temporary: this file, and its one line in
# .claude\settings.json, are removed once delivery-v1.md's own handover
# is done - see that file's own closing checklist item.

$ErrorActionPreference = 'Continue'

function Allow { exit 0 }

try {
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { Allow }
    $hook = $raw | ConvertFrom-Json
} catch {
    Allow
}

# Never re-block the same turn the hook itself is already handling.
if ($hook.stop_hook_active) { Allow }

function Get-ProjectRoot {
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path $env:CLAUDE_PROJECT_DIR)) {
        return $env:CLAUDE_PROJECT_DIR
    }
    return (Get-Location).Path
}

$root = Get-ProjectRoot
$deliveryFile = Join-Path (Join-Path (Join-Path (Join-Path (Split-Path -Parent $root) 'projects') 'asa') 'rounds') 'delivery-v1.md'

if (-not (Test-Path -LiteralPath $deliveryFile)) { Allow }

$deliveryText = Get-Content -LiteralPath $deliveryFile -Raw -Encoding UTF8
$progressStart = $deliveryText.IndexOf('## Progress')
if ($progressStart -lt 0) { Allow }
$progressBlock = $deliveryText.Substring($progressStart)

$hasUnticked = $progressBlock -match '(?m)^\s*-\s*\[ \]'
if (-not $hasUnticked) { Allow }

# The last real answer, read straight from the transcript - round-39.md's
# own cp10 note says the Stop hook "gets transcript_path"; this reads it
# the same way, rather than depending on a convenience field this repo's
# own hooks have never used before.
$lastMessage = ''
try {
    if ($hook.transcript_path -and (Test-Path -LiteralPath $hook.transcript_path)) {
        $lines = Get-Content -LiteralPath $hook.transcript_path -Encoding UTF8
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            if (-not $lines[$i]) { continue }
            try {
                $entry = $lines[$i] | ConvertFrom-Json
            } catch {
                continue
            }
            $role = $null
            if ($entry.message -and $entry.message.role) { $role = [string]$entry.message.role }
            elseif ($entry.role) { $role = [string]$entry.role }
            if ($role -ne 'assistant') { continue }

            $content = $null
            if ($entry.message -and $entry.message.content) { $content = $entry.message.content }
            elseif ($entry.content) { $content = $entry.content }

            if ($content -is [string]) {
                $lastMessage = $content
            } elseif ($content) {
                $textParts = @()
                foreach ($block in @($content)) {
                    if ($block.type -eq 'text' -and $block.text) { $textParts += [string]$block.text }
                }
                $lastMessage = [string]::Join("`n", $textParts)
            }
            break
        }
    }
} catch {
    $lastMessage = ''
}

# Falls back to a convenience field if this Claude Code version has one -
# harmless to check, never the only source trusted.
if (-not $lastMessage -and $hook.last_assistant_message) {
    $lastMessage = [string]$hook.last_assistant_message
}

$trimmed = $lastMessage.TrimStart()
if ($trimmed.StartsWith('BLOCKED:') -or $trimmed.StartsWith('DECISION NEEDED:')) { Allow }

[Console]::Error.WriteLine('Delivery v1: continue with the next item.')
exit 2
