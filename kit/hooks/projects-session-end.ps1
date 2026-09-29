# projects-session-end.ps1 - SessionEnd hook (Round 39 cp10), user-level.
#
# If the current project's own .asa-session.md is still open, closes it and
# appends the .asa-log.md line from what the other hooks recorded - "closed
# by the hook." Does nothing outside the projects folder, and nothing for a
# project with no open session.
#
# Contract: SessionEnd. Exit 0 always; nothing here blocks anything, the
# session is already ending.

$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'asa-projects-common.ps1')

$hook = Read-HookInput
$cwd = Get-HookCwd -Hook $hook

if (-not (Test-InsideProjects -Cwd $cwd)) { exit 0 }

$root = Get-AsaProjectsRoot
$projectName = Get-ProjectNameUnderRoot -Cwd $cwd -Root $root
if (-not $projectName) { exit 0 }

$projectFolder = Join-Path $root $projectName
$sessionPath = Join-Path $projectFolder '.asa-session.md'
if (-not (Test-Path -LiteralPath $sessionPath)) { exit 0 }

$text = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8
if ($text -notmatch '(?m)^status:\s*open\s*$') { exit 0 }

$openedMatch = [regex]::Match($text, '(?m)^opened:\s*(.+)$')
$opened = if ($openedMatch.Success) { $openedMatch.Groups[1].Value.Trim() } else { '' }
$now = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')

$closedText = [regex]::Replace($text, '(?m)^status:\s*open\s*$', 'status: closed')
$closedText = [regex]::Replace($closedText, '(?m)^updated:.*$', "updated: $now")
Set-Content -LiteralPath $sessionPath -Value $closedText -Encoding UTF8 -NoNewline

$logPath = Join-Path $projectFolder '.asa-log.md'
$dateOnly = (Get-Date).ToString('yyyy-MM-dd')
$logLine = "- $dateOnly $opened-$now (closed by the hook) - session ended without a manual close`n"
Add-Content -LiteralPath $logPath -Value $logLine -Encoding UTF8

exit 0
