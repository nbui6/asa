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

# Same idea for a "### <heading>" subsection. Kept as a separate function
# rather than adding a -Level switch to the one above, because that one is
# covered by tests that should not change shape to accommodate a new caller.
function Get-MarkdownSubsection {
    param([string]$Path, [string]$Heading)

    if (-not (Test-Path $Path)) { return $null }

    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $out = New-Object System.Collections.Generic.List[string]
    $inside = $false

    foreach ($line in $lines) {
        if ($line -match '^#{1,3}\s') {
            if ($inside) { break }
            if ($line -match ('^###\s+' + [regex]::Escape($Heading) + '\s*$')) {
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

# workspace\ is a shape, not an address (ADR 0006): a folder holding
# exactly three siblings named asa, projects, and workshop. Walk upward
# from $From's parent until that shape is found, so this works from any
# username, drive letter, or machine with nothing edited. Returns $null,
# never a guess, when the search reaches the drive root without finding it.
function Find-WorkspaceRoot {
    param([string]$From)

    $current = Split-Path -Parent $From
    while ($current) {
        $hasAsa = Test-Path (Join-Path $current 'asa') -PathType Container
        $hasProjects = Test-Path (Join-Path $current 'projects') -PathType Container
        $hasWorkshop = Test-Path (Join-Path $current 'workshop') -PathType Container
        if ($hasAsa -and $hasProjects -and $hasWorkshop) { return $current }

        $next = Split-Path -Parent $current
        if (-not $next -or $next -eq $current) { return $null }
        $current = $next
    }
    return $null
}

# Reads one flat "key: value" frontmatter line from a markdown file. Good
# enough for asa.md's own frontmatter, which is exactly that shape - not a
# general YAML reader, on purpose, same reasoning project.dart's own
# parseFrontmatter gives for staying hand-written.
function Get-FrontmatterValue {
    param([string]$Path, [string]$Key)

    if (-not (Test-Path $Path)) { return $null }
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $null }

    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq '---') { break }
        if ($line -match ('^' + [regex]::Escape($Key) + ':\s*(.*)$')) {
            return $Matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return $null
}

# "today" / "1 day ago" / "N days ago" - same convention
# projects_scan.dart's stalenessLabel already uses in the app itself, so
# the hook and the app never describe the same gap two different ways. A
# date this cannot parse, or one in the future, is returned as-is rather
# than guessed at.
function Get-HumanizedAge {
    param([string]$DateString)

    $parsed = [datetime]::MinValue
    if (-not [datetime]::TryParse($DateString, [ref]$parsed)) { return $null }

    $days = (Get-Date).Date.Subtract($parsed.Date).Days
    if ($days -lt 0) { return $null }
    if ($days -eq 0) { return 'today' }
    if ($days -eq 1) { return '1 day ago' }
    return "$days days ago"
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

# Ranked work that is already waiting. Added 2026-08-25 for a specific
# failure: an item sat in ROADMAP.md "Now" for a whole session, undone,
# while the exact collision it described caused a real defect eight hours
# later. Nothing surfaced it, because nothing read the file. Analysis that
# is never re-read is analysis that did not happen.
$roadmap = Join-Path $root 'ROADMAP.md'
$now = Get-MarkdownSubsection -Path $roadmap -Heading 'Now'
if ($now) {
    $parts.Add('Ranked and waiting, from ROADMAP.md:')
    $parts.Add($now)
}

# Stage 0b. A plan without a signature means no round may be written, and
# that fact is worth more at the start of a session than at the end of one.
# The date pattern is deliberate: the template ships with underscores in
# this line, and underscores must not read as a signature.
$planMd = Join-Path $root 'PLAN.md'
if (Test-Path $planMd) {
    $planText = Get-Content -LiteralPath $planMd -Raw -Encoding UTF8
    if ($planText -match '(?m)^\s*Confirmed by:\s*([^\s_][^\r\n]*?)\s+on\s+(\d{4}-\d{2}-\d{2})') {
        $parts.Add("PLAN.md confirmed by $($Matches[1]) on $($Matches[2]).")
    } else {
        $parts.Add('PLAN.md exists but is NOT confirmed. PLAYBOOK.md stage 0b: no round note may be written until the Confirmed by line is signed.')
    }
}

# Asa's own real next-step, from the project note itself - a different
# question than CLAUDE.md's "Where we are" prose above, and printed as its
# own labelled block, never merged into one paragraph with it. Added
# 2026-09-08: this hook fires reliably for a local session, but a
# deciding/cloud session reaching the machine through a device bridge has
# no hook at all, so projects\asa\asa.md's own next-step sat unread for a
# full day. This fixes this session's half of that; the other half stays
# open (see HANDOVER.md).
$workspaceRoot = Find-WorkspaceRoot -From $root
if ($workspaceRoot) {
    $asaNote = Join-Path $workspaceRoot 'projects\asa\asa.md'
    $status = Get-FrontmatterValue -Path $asaNote -Key 'status'
    $nextStep = Get-FrontmatterValue -Path $asaNote -Key 'next-step'
    $updated = Get-FrontmatterValue -Path $asaNote -Key 'updated'

    if ($status -or $nextStep -or $updated) {
        $parts.Add('Asa project note (projects\asa\asa.md), separate from CLAUDE.md above:')
        if ($status) { $parts.Add("Status: $status") }
        if ($nextStep) { $parts.Add("Next step: $nextStep") }
        if ($updated) {
            $age = Get-HumanizedAge -DateString $updated
            if ($age) {
                $parts.Add("Updated: $updated ($age)")
            } else {
                $parts.Add("Updated: $updated")
            }
        }
    }
} else {
    $parts.Add('Could not find the workspace root (a folder with asa, projects and workshop as siblings) - skipping the Asa project-note block rather than guessing a path.')
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
