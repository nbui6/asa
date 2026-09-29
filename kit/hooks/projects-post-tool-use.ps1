# projects-post-tool-use.ps1 - PostToolUse hook (Round 39 cp10), user-level.
# Matcher: Write|Edit|MultiEdit.
#
# Updates the touched project's own .asa-session.md - opening it if none is
# open yet - so the mechanical part of the record isn't the AI's job any
# more. Does nothing outside the projects folder, and nothing for a write
# that didn't touch a real file path under one project.
#
# Contract: PostToolUse. Exit 0 always; this hook never blocks anything.

$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'asa-projects-common.ps1')

$hook = Read-HookInput
if (-not $hook) { exit 0 }
$cwd = Get-HookCwd -Hook $hook

if (-not (Test-InsideProjects -Cwd $cwd)) { exit 0 }

$root = Get-AsaProjectsRoot
$projectName = Get-ProjectNameUnderRoot -Cwd $cwd -Root $root
if (-not $projectName) { exit 0 }

$filePath = $null
if ($hook.tool_input -and $hook.tool_input.file_path) { $filePath = [string]$hook.tool_input.file_path }
if (-not $filePath) { exit 0 }

# Only a write really under this same project's own folder - a write
# somewhere else entirely (a temp file, another project by absolute path)
# is not this project's own session activity.
$projectFolder = Join-Path $root $projectName
try {
    $projectFull = (Resolve-Path -LiteralPath $projectFolder -ErrorAction Stop).Path.TrimEnd('\', '/')
    $fileFull = [System.IO.Path]::GetFullPath($filePath).TrimEnd('\', '/')
} catch {
    exit 0
}
if (-not ($fileFull.StartsWith($projectFull + '\') -or $fileFull -eq $projectFull)) { exit 0 }

$sessionPath = Join-Path $projectFolder '.asa-session.md'
$now = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
$relativeFile = $fileFull.Substring($projectFull.Length).TrimStart('\', '/')

if (Test-Path -LiteralPath $sessionPath) {
    $text = Get-Content -LiteralPath $sessionPath -Raw -Encoding UTF8
    if ($text -match '(?m)^status:\s*open\s*$') {
        $text = [regex]::Replace($text, '(?m)^updated:.*$', "updated: $now")
        # No existing `updated:` line - append one right after `opened:`.
        if ($text -notmatch '(?m)^updated:') {
            $text = [regex]::Replace($text, '(?m)^(opened:.*)$', "`$1`nupdated: $now")
        }
        if ($text -notmatch [regex]::Escape("Last write: $relativeFile")) {
            $text = $text.TrimEnd() + "`nLast write: $relativeFile`n"
        }
        Set-Content -LiteralPath $sessionPath -Value $text -Encoding UTF8 -NoNewline
    }
    # status: closed - a closed session is not reopened by a background
    # hook; that is the AI's own call at the start of its next real turn.
} else {
    $content = @"
---
status: open
opened: $now
opened-by: (hook - PostToolUse)
updated: $now
---
Doing:
Last done:
Next:
Last write: $relativeFile
"@
    Set-Content -LiteralPath $sessionPath -Value $content -Encoding UTF8 -NoNewline
}

exit 0
