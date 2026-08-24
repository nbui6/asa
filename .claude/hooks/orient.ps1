# orient.ps1 - SessionStart hook
#
# Prints the project's current state into the session's opening context, so a
# session that starts nine days later starts oriented instead of blank.
#
# Contract: SessionStart. Exit 0, and whatever goes to stdout is added to the
# model's context as plain text. Cannot block anything.
#
# ASCII output only. Windows PowerShell 5.1 writes non-ASCII unpredictably, and
# a mangled character inside injected context is worse than no context.

$ErrorActionPreference = 'Stop'

# Drain stdin even though we do not need it. A hook that leaves the pipe
# unread can stall the caller.
try { [void][Console]::In.ReadToEnd() } catch { }

function Get-ProjectRoot {
    if ($env:CLAUDE_PROJECT_DIR -and (Test-Path $env:CLAUDE_PROJECT_DIR)) {
        return $env:CLAUDE_PROJECT_DIR
    }
    return (Get-Location).Path
}

# Returns one "## <heading>" section of a markdown file, heading included,
# stopping at the next heading of the same level.
function Get-MarkdownSection {
    param([string]$Path, [string]$Heading)

    if (-not (Test-Path $Path)) { return $null }

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $out = New-Object System.Collections.Generic.List[string]
    $inside = $false

    foreach ($line in $lines) {
        if ($line -match '^##\s') {
            if ($inside) { break }
            if ($line -match ('^##\s+' + [regex]::Escape($Heading))) {
                $inside = $true
                $out.Add($line)
                continue
            }
        }
        if ($inside) { $out.Add($line) }
    }

    if ($out.Count -eq 0) { return $null }
    return ($out -join "`n")
}

$root = Get-ProjectRoot
$claudeMd = Join-Path $root 'CLAUDE.md'

$parts = New-Object System.Collections.Generic.List[string]
$parts.Add('--- Project state, injected by the orient hook ---')

$where = Get-MarkdownSection -Path $claudeMd -Heading 'Where we are'
if ($where) {
    $parts.Add($where)
} else {
    $parts.Add('No "## Where we are" section found in CLAUDE.md.')
    $parts.Add('That section is what makes a cold start possible. Consider writing one.')
}

# Uncommitted work is the single most useful fact at the start of a session,
# and it is measured rather than typed.
try {
    $status = & git -C $root status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0) {
        if ($status) {
            $count = ($status | Measure-Object).Count
            $parts.Add("Uncommitted changes: $count file(s).")
            $parts.Add(($status | Select-Object -First 10) -join "`n")
        } else {
            $parts.Add('Working tree is clean.')
        }
    }
} catch { }

# Whether the machine check has passed since the last code change. Same source
# of truth the commit gate uses, so the two can never disagree.
$lastPass = Join-Path (Join-Path (Join-Path $root '.claude') 'hooks') '.last-pass'
if (Test-Path $lastPass) {
    $stamp = (Get-Content -LiteralPath $lastPass -Raw -Force).Trim()
    $parts.Add("Last recorded passing machine check: $stamp")
} else {
    $parts.Add('No passing machine check has been recorded yet. A commit will be blocked.')
}

$parts.Add('--- end injected state ---')

$text = ($parts -join "`n`n")

# Documented cap is 10000 characters. Truncate rather than be silently dropped.
if ($text.Length -gt 9500) {
    $text = $text.Substring(0, 9500) + "`n[truncated by the orient hook]"
}

# ASCII only, deliberately.
$text = $text -replace '[^\x09\x0A\x0D\x20-\x7E]', '?'

Write-Output $text
exit 0
