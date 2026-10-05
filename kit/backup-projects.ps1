# backup-projects.ps1 - automatic, local, dated snapshots of workspace\projects\.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\backup-projects.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\backup-projects.ps1 -SelfTest
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\backup-projects.ps1 -Schedule
#
# Spec: HANDOVER-ARCHIVE.md, 2026-09-14, "kit\backup-projects.ps1 - automatic,
# local, everything" - skipped that day (Nico: "skip the backup project"),
# then REOPENED and accepted 2026-09-28 (ADR 0037) after a real loss: the
# deciding session changed 111 files in `projects\` by mistake, and there was
# no copy to go back to. Built here, unchanged from the original spec, as
# Round 41's own checkpoint E.
#
# Finds the workspace by SHAPE - a folder holding `asa`, `projects` and
# `workshop` as siblings (ADR 0006) - never a hard-coded path, so this works
# on another laptop, a different username, nothing edited. Same function
# kit\hooks\orient.ps1 already uses, vendored rather than shared across a
# hooks/kit boundary that doesn't otherwise share code.
#
# **Dated snapshots, NEVER a mirror.** One `backup-<yyyy-MM-dd-HHmm>\` folder
# per run, under `%USERPROFILE%\workspace-backup\` - OUTSIDE `workspace\`
# itself, since a backup inside the folder it backs up is not a backup.
# Nothing inside an existing snapshot is ever deleted or rewritten: a
# mirroring backup (`robocopy /MIR`) would faithfully copy today's mistake
# over yesterday's good copy - the exact failure ADR 0037 records.
#
# **30 snapshots kept, oldest pruned beyond it.** `projects\` is markdown
# plus some sketch PNGs - a few MB per snapshot - so keeping a month of daily
# runs costs nothing, and the real failure this protects against (a mistake
# noticed days later, not immediately) needs more headroom than a week.
# Pruning removes whole old snapshot folders, never a file inside a kept one.
#
# No company-network path, no UNC path, anywhere in this script - that copy
# is Nico's own manual step (ADR 0013's amendment), never automated.

param(
    [switch]$SelfTest,
    [switch]$Schedule,
    [int]$KeepCount = 30
)

$ErrorActionPreference = 'Stop'

# workspace\ is a shape, not an address (ADR 0006): a folder holding exactly
# three siblings named asa, projects, and workshop. Walk upward from $From
# until that shape is found. Returns $null, never a guess, when the search
# reaches the drive root without finding it.
function Find-WorkspaceRoot {
    param([string]$From)

    $current = $From
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

function Copy-ProjectsSnapshot {
    param(
        [string]$ProjectsRoot,
        [string]$BackupRoot,
        [datetime]$Now = (Get-Date)
    )

    if (-not (Test-Path -LiteralPath $ProjectsRoot)) {
        throw "No projects folder at $ProjectsRoot - nothing to back up."
    }
    if (-not (Test-Path -LiteralPath $BackupRoot)) {
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    }

    $stamp = $Now.ToString('yyyy-MM-dd-HHmm')
    $snapshot = Join-Path $BackupRoot "backup-$stamp"
    if (Test-Path -LiteralPath $snapshot) {
        # Two runs in the same minute - never overwrite, add a counter.
        $i = 2
        while (Test-Path -LiteralPath "$snapshot-$i") { $i++ }
        $snapshot = "$snapshot-$i"
    }

    Copy-Item -LiteralPath $ProjectsRoot -Destination $snapshot -Recurse -Force
    $fileCount = (Get-ChildItem -LiteralPath $snapshot -Recurse -File).Count
    return @{ Snapshot = $snapshot; FileCount = $fileCount }
}

# Pruning removes whole old snapshot folders only - never touches a file
# inside one that's kept.
function Remove-OldSnapshots {
    param([string]$BackupRoot, [int]$KeepCount)

    if (-not (Test-Path -LiteralPath $BackupRoot)) { return @() }
    $snapshots = Get-ChildItem -LiteralPath $BackupRoot -Directory |
        Where-Object { $_.Name -match '^backup-\d{4}-\d{2}-\d{2}-\d{4}' } |
        Sort-Object Name -Descending
    $toRemove = $snapshots | Select-Object -Skip $KeepCount
    foreach ($old in $toRemove) {
        Remove-Item -LiteralPath $old.FullName -Recurse -Force
    }
    return $toRemove.Name
}

function Write-BackupLogLine {
    param([string]$LogPath, [string]$Line)
    Add-Content -LiteralPath $LogPath -Value $Line -Encoding UTF8
}

# --- self-test --------------------------------------------------------------

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-backup-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $ok = $true

    # --- workspace-by-shape search, from a different working directory -----
    $ws = Join-Path $sandbox 'workspace'
    New-Item -ItemType Directory -Path (Join-Path $ws 'asa') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ws 'projects') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $ws 'workshop') -Force | Out-Null
    $deepDir = Join-Path $ws 'projects\demo\plan'
    New-Item -ItemType Directory -Path $deepDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $ws 'projects\demo\demo.md') -Value 'A demo project.' -Encoding UTF8

    $found = Find-WorkspaceRoot -From $deepDir
    if ($found -eq $ws) { Write-Host '  PASS  workspace root found by shape from a deep working directory' }
    else { Write-Host "  FAIL  expected $ws, got $found"; $ok = $false }

    $notFound = Find-WorkspaceRoot -From (Join-Path $sandbox 'nowhere\near\it')
    if ($null -eq $notFound) { Write-Host '  PASS  no shape found returns null, never a guess' }
    else { Write-Host "  FAIL  expected null, got $notFound"; $ok = $false }

    # --- a snapshot is created and contains a known file --------------------
    $backupRoot = Join-Path $sandbox 'workspace-backup'
    $projectsRoot = Join-Path $ws 'projects'
    $now1 = [datetime]'2026-09-28 09:00'
    $r1 = Copy-ProjectsSnapshot -ProjectsRoot $projectsRoot -BackupRoot $backupRoot -Now $now1
    $knownFile = Join-Path $r1.Snapshot 'demo\demo.md'
    if ((Test-Path -LiteralPath $knownFile) -and ((Get-Content -LiteralPath $knownFile -Raw).Trim() -eq 'A demo project.')) {
        Write-Host '  PASS  a snapshot is created and contains a known file, unchanged'
    } else {
        Write-Host '  FAIL  the known file is missing or wrong in the new snapshot'; $ok = $false
    }

    # --- the test that proves the whole point: an old snapshot survives ----
    Set-Content -LiteralPath (Join-Path $projectsRoot 'demo\demo.md') -Value 'MISTAKENLY OVERWRITTEN' -Encoding UTF8
    $now2 = [datetime]'2026-09-28 10:00'
    $r2 = Copy-ProjectsSnapshot -ProjectsRoot $projectsRoot -BackupRoot $backupRoot -Now $now2

    $stillGood = (Get-Content -LiteralPath $knownFile -Raw).Trim()
    if ($stillGood -eq 'A demo project.') {
        Write-Host '  PASS  a second run, after a file was modified, leaves the first snapshot untouched'
    } else {
        Write-Host "  FAIL  the first snapshot changed: $stillGood"; $ok = $false
    }
    $newCopy = (Get-Content -LiteralPath (Join-Path $r2.Snapshot 'demo\demo.md') -Raw).Trim()
    if ($newCopy -eq 'MISTAKENLY OVERWRITTEN') {
        Write-Host '  PASS  the new snapshot carries the mistake - snapshots record, they do not judge'
    } else {
        Write-Host "  FAIL  the new snapshot should carry the mistake, got: $newCopy"; $ok = $false
    }

    # --- a missing destination is created -----------------------------------
    $freshBackupRoot = Join-Path $sandbox 'brand-new-backup-root'
    if (Test-Path -LiteralPath $freshBackupRoot) { Write-Host '  FAIL  test setup: destination already existed'; $ok = $false }
    Copy-ProjectsSnapshot -ProjectsRoot $projectsRoot -BackupRoot $freshBackupRoot -Now $now1 | Out-Null
    if (Test-Path -LiteralPath $freshBackupRoot) { Write-Host '  PASS  a missing destination is created' }
    else { Write-Host '  FAIL  the destination was not created'; $ok = $false }

    # --- an unreachable destination fails loudly, with its real reason -----
    try {
        Copy-ProjectsSnapshot -ProjectsRoot (Join-Path $sandbox 'does-not-exist') -BackupRoot $backupRoot -Now $now1 | Out-Null
        Write-Host '  FAIL  a missing projects folder should have thrown'; $ok = $false
    } catch {
        if ($_.Exception.Message -match 'No projects folder') {
            Write-Host '  PASS  a missing projects folder fails loudly with its real reason'
        } else {
            Write-Host "  FAIL  wrong error: $($_.Exception.Message)"; $ok = $false
        }
    }

    # --- pruning: a bounded number kept, whole snapshots only ---------------
    $pruneRoot = Join-Path $sandbox 'prune-backup'
    New-Item -ItemType Directory -Path $pruneRoot -Force | Out-Null
    for ($i = 1; $i -le 5; $i++) {
        $d = Join-Path $pruneRoot ('backup-2026-09-{0:D2}-0900' -f $i)
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $d 'kept.md') -Value 'x' -Encoding UTF8
    }
    $removed = Remove-OldSnapshots -BackupRoot $pruneRoot -KeepCount 3
    $remaining = Get-ChildItem -LiteralPath $pruneRoot -Directory | Sort-Object Name
    if ($remaining.Count -eq 3 -and $removed.Count -eq 2 -and
        $remaining[0].Name -eq 'backup-2026-09-03-0900') {
        Write-Host '  PASS  pruning keeps the newest N, removes whole old snapshots only'
    } else {
        Write-Host "  FAIL  expected 3 newest kept, got $($remaining.Name -join ', ')"; $ok = $false
    }
    # The kept ones' own files are untouched by pruning.
    if ((Get-Content -LiteralPath (Join-Path $remaining[0].FullName 'kept.md') -Raw).Trim() -eq 'x') {
        Write-Host '  PASS  a kept snapshot''s own files are untouched by pruning'
    } else {
        Write-Host '  FAIL  a kept snapshot was modified by pruning'; $ok = $false
    }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- scheduling, in the user's own context, no admin -------------------------
#
# Verified, not assumed: schtasks against the CURRENT user (no /RU, no
# elevation) is itself the proof this needs no admin rights - if it fails,
# that failure is the honest answer, not something to paper over with a
# silent fallback that might also be wrong.

if ($Schedule) {
    $thisScript = $MyInvocation.MyCommand.Path
    $taskName = 'AsaProjectsBackup'
    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$thisScript`""
    $created = $false
    try {
        schtasks /create /tn $taskName /tr $cmd /sc DAILY /st 09:00 /f 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Scheduled: '$taskName' runs daily at 09:00, in your own account - no admin used."
            $created = $true
        }
    } catch { }

    if (-not $created) {
        Write-Host 'Could not register a daily scheduled task (this often needs admin on a locked-down'
        Write-Host 'machine - workshop\MACHINE.md: "Nico often lacks admin rights here"). Falling back'
        Write-Host 'to run-at-logon instead:'
        try {
            schtasks /create /tn $taskName /tr $cmd /sc ONLOGON /f 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Scheduled: '$taskName' runs once each time you log on."
                $created = $true
            }
        } catch { }
    }

    if (-not $created) {
        Write-Host 'Could not register any scheduled task, even run-at-logon. Run this script by hand'
        Write-Host "occasionally instead: powershell -NoProfile -ExecutionPolicy Bypass -File `"$thisScript`""
        exit 1
    }
    exit 0
}

# --- the real run -------------------------------------------------------------

$workspaceRoot = Find-WorkspaceRoot -From $PSScriptRoot
if (-not $workspaceRoot) {
    Write-Host 'Could not find the workspace (a folder with asa, projects and workshop as siblings) -'
    Write-Host 'skipping rather than guessing a path.'
    exit 1
}

$projectsRoot = Join-Path $workspaceRoot 'projects'
$backupRoot = Join-Path (Split-Path -Parent $workspaceRoot) 'workspace-backup'
$logPath = Join-Path $backupRoot 'backup.log'
$now = Get-Date

try {
    if (-not (Test-Path -LiteralPath $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null }
    $result = Copy-ProjectsSnapshot -ProjectsRoot $projectsRoot -BackupRoot $backupRoot -Now $now
    $removed = Remove-OldSnapshots -BackupRoot $backupRoot -KeepCount $KeepCount
    $line = "{0:yyyy-MM-dd HH:mm} OK  {1}  {2} files" -f $now, $result.Snapshot, $result.FileCount
    if ($removed.Count -gt 0) { $line += "  (pruned: $($removed -join ', '))" }
    Write-BackupLogLine -LogPath $logPath -Line $line
    Write-Host $line
    exit 0
} catch {
    $line = "{0:yyyy-MM-dd HH:mm} FAILED  {1}" -f $now, $_.Exception.Message
    try { Write-BackupLogLine -LogPath $logPath -Line $line } catch { }
    Write-Host $line
    exit 1
}
