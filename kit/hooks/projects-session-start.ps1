# projects-session-start.ps1 - SessionStart hook (Round 39 cp10), user-level.
#
# Runs asa-brief for the current project (or --all at the projects root
# itself), printing its output as session-opening context - "the AI starts
# caught up without being told." Does nothing outside the projects folder.
#
# Contract: SessionStart. Exit 0 always; stdout becomes context, never
# blocks anything.

$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'asa-projects-common.ps1')

$hook = Read-HookInput
$cwd = Get-HookCwd -Hook $hook

if (-not (Test-InsideProjects -Cwd $cwd)) { exit 0 }

$root = Get-AsaProjectsRoot
$asaRepo = Get-AsaRepoPath -ProjectsRoot $root
if (-not $asaRepo) { exit 0 }

$briefScript = Join-Path $asaRepo 'bin\brief.dart'
if (-not (Test-Path -LiteralPath $briefScript)) { exit 0 }

$projectName = Get-ProjectNameUnderRoot -Cwd $cwd -Root $root

try {
    if ($projectName) {
        $output = & dart run $briefScript $projectName 2>$null
    } else {
        $output = & dart run $briefScript --all 2>$null
    }
} catch {
    exit 0
}

if ($output) { Write-Host ($output -join "`n") }
exit 0
