# projects-stop-check.ps1 - Stop hook (Round 39 cp10), user-level.
#
# Runs asa-check on the current project; a real finding blocks with the
# plain message, the same words asa-check itself prints. No model call.
#
# Contract: Stop. Exit 2 blocks; exit 0 allows. Fails open on anything it
# can't read or run - a gate that can't check must not block.

$ErrorActionPreference = 'Continue'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'asa-projects-common.ps1')

function Allow { exit 0 }

$hook = Read-HookInput
if ($hook -and $hook.stop_hook_active) { Allow }

$cwd = Get-HookCwd -Hook $hook
if (-not (Test-InsideProjects -Cwd $cwd)) { Allow }

$root = Get-AsaProjectsRoot
$projectName = Get-ProjectNameUnderRoot -Cwd $cwd -Root $root
if (-not $projectName) { Allow }

$asaRepo = Get-AsaRepoPath -ProjectsRoot $root
if (-not $asaRepo) { Allow }

$checkScript = Join-Path $asaRepo 'bin\check.dart'
if (-not (Test-Path -LiteralPath $checkScript)) { Allow }

try {
    $output = & dart run $checkScript $projectName 2>$null
    $code = $LASTEXITCODE
} catch {
    Allow
}

if ($code -eq 0) { Allow }

[Console]::Error.WriteLine("asa-check found something for $($projectName):")
foreach ($line in @($output)) { [Console]::Error.WriteLine("  $line") }
exit 2
