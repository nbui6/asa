# setup.ps1 - set up Asa on this laptop, one command.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -ProjectsFolder <path>
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup.ps1 -SelfTest
#
# Round 41 §B. Asks at most one question - the projects folder, with a
# default, Enter accepts it. Safe to run more than once: nothing already
# done is undone or overwritten; re-running just confirms everything is
# still in place.
#
# Admin rights are used ONLY to install git and the Visual C++ runtime with
# winget, when either is missing, and only ever asks for elevation that one
# time. Everything else - the app, the projects folder, settings, PATH,
# BOSS.md, skills, the setup record - stays in the user's own folders, so
# this also works with no admin at all, minus those two installs (which it
# then names, rather than silently skipping).
#
# Finds its own app zip next to itself, or in dist\ - from kit\package-app.ps1
# - and unpacks it to %LOCALAPPDATA%\Asa\app\.

param(
    [string]$ProjectsFolder,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# --- step 1: the app zip -----------------------------------------------------

function Find-AppZip {
    param([string]$Root)

    $direct = Get-ChildItem -LiteralPath $Root -Filter 'asa-windows-*.zip' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($direct) { return $direct.FullName }

    $distDir = Join-Path $Root 'dist'
    if (Test-Path -LiteralPath $distDir) {
        $inDist = Get-ChildItem -LiteralPath $distDir -Filter 'asa-windows-*.zip' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($inDist) { return $inDist.FullName }
    }
    return $null
}

function Install-App {
    param([string]$ZipPath, [string]$AppDir)

    if (Test-Path -LiteralPath $AppDir) { Remove-Item -LiteralPath $AppDir -Recurse -Force }
    New-Item -ItemType Directory -Path $AppDir -Force | Out-Null
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $AppDir -Force
    # Compress-Archive (package-app.ps1) wraps everything in one top-level
    # "asa-windows\" folder - flatten it so $AppDir\app\asa.exe is a fixed
    # path regardless of the zip's own commit-stamped name.
    $inner = Join-Path $AppDir 'asa-windows'
    if (Test-Path -LiteralPath $inner) {
        Get-ChildItem -LiteralPath $inner -Force | Move-Item -Destination $AppDir -Force
        Remove-Item -LiteralPath $inner -Recurse -Force
    }
}

function New-AppShortcut {
    param([string]$ExePath, [string]$ShortcutPath)

    try {
        $shortcutDir = Split-Path -Parent $ShortcutPath
        if (-not (Test-Path -LiteralPath $shortcutDir)) {
            New-Item -ItemType Directory -Path $shortcutDir -Force | Out-Null
        }
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $ExePath
        $shortcut.WorkingDirectory = Split-Path -Parent $ExePath
        $shortcut.Save()
        return $true
    } catch {
        return $false
    }
}

# --- step 2: the projects folder, settings.json ------------------------------

function Set-AsaSettings {
    param([string]$SettingsPath, [string]$ProjectsFolderPath)

    $dir = Split-Path -Parent $SettingsPath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    # Same shape lib\core\settings.dart's own writeSettings writes - one flat
    # object, UTF-8 with NO BOM (Dart's jsonDecode chokes on a leading BOM
    # character, unlike Get-Content - PowerShell 5.1's own Set-Content/
    # Out-File default to UTF-8 WITH a BOM, so this writes the bytes
    # directly instead).
    $json = "{`"projectsFolder`":`"$($ProjectsFolderPath.Replace('\', '\\'))`"}"
    [System.IO.File]::WriteAllText($SettingsPath, $json, $utf8NoBom)
}

# --- step 3: the commands on PATH --------------------------------------------

function Add-ToUserPath {
    param([string]$Dir)

    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $current) { $current = '' }
    $parts = $current -split ';' | Where-Object { $_ -ne '' }
    $already = $parts | Where-Object { $_.TrimEnd('\') -ieq $Dir.TrimEnd('\') }
    if ($already) { return $false }
    $new = if ($current -eq '') { $Dir } else { "$current;$Dir" }
    [Environment]::SetEnvironmentVariable('Path', $new, 'User')
    return $true
}

# --- step 5: BOSS.md, never overwritten --------------------------------------

function Install-BossMd {
    param([string]$ProjectsFolderPath, [string]$TemplatePath)

    $dest = Join-Path $ProjectsFolderPath 'BOSS.md'
    if (Test-Path -LiteralPath $dest) { return $false }
    Copy-Item -LiteralPath $TemplatePath -Destination $dest -Force
    return $true
}

# --- step 7: the setup record -------------------------------------------------

function Write-SetupRecord {
    param([string]$ProjectsFolderPath, [string]$Commit, [datetime]$Now, [string]$StatusLine)

    $path = Join-Path $ProjectsFolderPath '.asa-setup.md'
    $date = $Now.ToString('yyyy-MM-dd')
    if (-not (Test-Path -LiteralPath $path)) {
        $body = "---`nset-up: $date`nasa-version: $Commit`n$StatusLine`n---`n- $date -- set up on this laptop`n"
        [System.IO.File]::WriteAllText($path, $body, $utf8NoBom)
        return
    }
    # Re-running setup.ps1 appends one more line rather than rewriting the
    # record - "safe to repeat" means a visible history of every run, never
    # silently losing the first one.
    Add-Content -LiteralPath $path -Value "- $date -- setup.ps1 run again" -Encoding UTF8
}

# --- admin-only installs: git, the VC++ runtime ------------------------------

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-VCRedistInstalled {
    # The x64 runtime's own registry marker, same key the redistributable
    # installer itself writes - checked on both the native and the WOW6432
    # view since either can hold it depending on how PowerShell was
    # launched. Not winget's own job to no-op quietly: checking first means
    # the elevation prompt below is skipped entirely on a machine that
    # already has everything, which found the real gap this had at first -
    # every run used to ask for elevation regardless.
    foreach ($key in @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\X64'
    )) {
        $v = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($v -and $v.Installed -eq 1) { return $true }
    }
    return $false
}

function Install-MissingTools {
    $needGit = -not (Get-Command git -ErrorAction SilentlyContinue)
    $needVCRedist = -not (Test-VCRedistInstalled)

    if (-not $needGit -and -not $needVCRedist) {
        Write-Host '  git and the Visual C++ runtime are both already present - nothing to install.'
        return
    }

    $wingetIds = @()
    if ($needGit) { $wingetIds += 'Git.Git' }
    if ($needVCRedist) { $wingetIds += 'Microsoft.VCRedist.2015+.x64' }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  winget is not on this machine - install by hand if needed: $($wingetIds -join ', ')"
        return
    }

    $what = $wingetIds -join ', '
    if (Test-IsAdmin) {
        foreach ($id in $wingetIds) {
            Write-Host "  winget install $id"
            winget install --id $id --accept-source-agreements --accept-package-agreements -e 2>&1 | Out-Null
        }
        Write-Host "  installed: $what"
        return
    }

    Write-Host "  Asking once for elevation to install with winget: $what..."
    $idList = ($wingetIds -join ',')
    $inner = "foreach (`$id in '$idList'.Split(',')) { winget install --id `$id --accept-source-agreements --accept-package-agreements -e }"
    try {
        $proc = Start-Process powershell -Verb RunAs -ArgumentList @('-NoProfile', '-Command', $inner) -Wait -PassThru
        if ($proc.ExitCode -eq 0) { Write-Host "  installed: $what" }
        else { Write-Host "  the elevated install step exited $($proc.ExitCode) - check by hand: $what" }
    } catch {
        Write-Host "  elevation was declined or failed - install by hand if needed: $what"
    }
}

# --- self-test ----------------------------------------------------------------

if ($SelfTest) {
    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-setup-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $ok = $true

    # --- Find-AppZip: next to the script, or in dist\, or fails with the real reason
    $noZipRoot = Join-Path $sandbox 'no-zip'
    New-Item -ItemType Directory -Path $noZipRoot -Force | Out-Null
    if ($null -eq (Find-AppZip -Root $noZipRoot)) { Write-Host '  PASS  a missing zip returns null, not a guess' }
    else { Write-Host '  FAIL  expected null when no zip exists'; $ok = $false }

    $nextToScript = Join-Path $sandbox 'next-to-script'
    New-Item -ItemType Directory -Path $nextToScript -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $nextToScript 'asa-windows-abc1234.zip') -Value 'x' -Encoding UTF8
    if ((Find-AppZip -Root $nextToScript) -eq (Join-Path $nextToScript 'asa-windows-abc1234.zip')) {
        Write-Host '  PASS  a zip next to the script is found'
    } else { Write-Host '  FAIL  zip-next-to-script not found'; $ok = $false }

    $inDistRoot = Join-Path $sandbox 'in-dist'
    New-Item -ItemType Directory -Path (Join-Path $inDistRoot 'dist') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $inDistRoot 'dist\asa-windows-def5678.zip') -Value 'x' -Encoding UTF8
    if ((Find-AppZip -Root $inDistRoot) -eq (Join-Path $inDistRoot 'dist\asa-windows-def5678.zip')) {
        Write-Host '  PASS  a zip in dist\ is found when none sits next to the script'
    } else { Write-Host '  FAIL  zip-in-dist not found'; $ok = $false }

    # --- Install-App: unpacks and flattens the zip's own top-level folder
    $zipStage = Join-Path $sandbox 'zip-stage'
    New-Item -ItemType Directory -Path (Join-Path $zipStage 'asa-windows\app') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $zipStage 'asa-windows\app\asa.exe') -Value 'fake exe' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $zipStage 'asa-windows\asa-brief.exe') -Value 'fake' -Encoding UTF8
    $testZip = Join-Path $sandbox 'test-app.zip'
    Compress-Archive -Path (Join-Path $zipStage 'asa-windows') -DestinationPath $testZip
    $appDir = Join-Path $sandbox 'installed-app'
    Install-App -ZipPath $testZip -AppDir $appDir
    if ((Test-Path (Join-Path $appDir 'app\asa.exe')) -and (Test-Path (Join-Path $appDir 'asa-brief.exe')) -and
        -not (Test-Path (Join-Path $appDir 'asa-windows'))) {
        Write-Host '  PASS  the zip unpacks and its own top-level folder is flattened away'
    } else { Write-Host '  FAIL  unpack/flatten did not produce the expected layout'; $ok = $false }

    # --- a second run (re-install) changes nothing it shouldn't -------------
    Install-App -ZipPath $testZip -AppDir $appDir
    if (Test-Path (Join-Path $appDir 'app\asa.exe')) {
        Write-Host '  PASS  a second install run leaves the app usable, not half-removed'
    } else { Write-Host '  FAIL  a second run broke the install'; $ok = $false }

    # --- Set-AsaSettings: real shape, no BOM, readable by Dart's own reader
    $settingsPath = Join-Path $sandbox 'settings.json'
    $chosenFolder = Join-Path $sandbox 'workspace\projects'
    Set-AsaSettings -SettingsPath $settingsPath -ProjectsFolderPath $chosenFolder
    $bytes = [System.IO.File]::ReadAllBytes($settingsPath)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $decoded = (Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json)
    if (-not $hasBom -and $decoded.projectsFolder -eq $chosenFolder) {
        Write-Host '  PASS  settings.json is written with no BOM, matching the real shape'
    } else { Write-Host '  FAIL  settings.json has a BOM or the wrong shape'; $ok = $false }

    # --- Install-BossMd: never overwrites one already there -----------------
    $projRoot = Join-Path $sandbox 'projects-for-boss'
    New-Item -ItemType Directory -Path $projRoot -Force | Out-Null
    $templateBoss = Join-Path $scriptRoot 'templates\BOSS.md'
    $copied = Install-BossMd -ProjectsFolderPath $projRoot -TemplatePath $templateBoss
    if ($copied -and (Test-Path (Join-Path $projRoot 'BOSS.md'))) {
        Write-Host '  PASS  a missing BOSS.md is copied from the template'
    } else { Write-Host '  FAIL  BOSS.md was not copied when missing'; $ok = $false }

    Set-Content -LiteralPath (Join-Path $projRoot 'BOSS.md') -Value 'The real answers already here.' -Encoding UTF8
    $copiedAgain = Install-BossMd -ProjectsFolderPath $projRoot -TemplatePath $templateBoss
    $stillReal = (Get-Content -LiteralPath (Join-Path $projRoot 'BOSS.md') -Raw).Trim()
    if (-not $copiedAgain -and $stillReal -eq 'The real answers already here.') {
        Write-Host '  PASS  an existing BOSS.md is never overwritten, a second run changes nothing'
    } else { Write-Host '  FAIL  an existing BOSS.md was touched'; $ok = $false }

    # --- Add-ToUserPath: idempotent, a real re-run adds nothing twice -------
    $savedPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    try {
        $fakeDir = Join-Path $sandbox 'fake-bin'
        $added1 = Add-ToUserPath -Dir $fakeDir
        $added2 = Add-ToUserPath -Dir $fakeDir
        $onPathNow = ([Environment]::GetEnvironmentVariable('Path', 'User') -split ';') -contains $fakeDir
        if ($added1 -and -not $added2 -and $onPathNow) {
            Write-Host '  PASS  PATH gains the folder once, a second call is a no-op'
        } else { Write-Host '  FAIL  PATH add/idempotence did not behave as expected'; $ok = $false }
    } finally {
        [Environment]::SetEnvironmentVariable('Path', $savedPath, 'User')
    }

    # --- Write-SetupRecord: created once, appended after ---------------------
    $setupProjRoot = Join-Path $sandbox 'projects-for-setup-record'
    New-Item -ItemType Directory -Path $setupProjRoot -Force | Out-Null
    $statusLine = 'app: installed - commands: on PATH - skills: installed for Claude Code, packaged for accounts'
    Write-SetupRecord -ProjectsFolderPath $setupProjRoot -Commit 'abc1234' -Now ([datetime]'2026-09-28') -StatusLine $statusLine
    $firstWrite = Get-Content -LiteralPath (Join-Path $setupProjRoot '.asa-setup.md') -Raw
    Write-SetupRecord -ProjectsFolderPath $setupProjRoot -Commit 'abc1234' -Now ([datetime]'2026-09-29') -StatusLine $statusLine
    $secondWrite = Get-Content -LiteralPath (Join-Path $setupProjRoot '.asa-setup.md') -Raw
    if ($secondWrite.StartsWith($firstWrite) -and $secondWrite.Length -gt $firstWrite.Length -and
        $secondWrite -match 'set up on this laptop' -and $secondWrite -match 'run again') {
        Write-Host '  PASS  the setup record is created once, then appended to on a later run'
    } else { Write-Host '  FAIL  the setup record was rewritten instead of appended'; $ok = $false }

    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ''
    if ($ok) { Write-Host 'Self-test passed.'; exit 0 } else { Write-Host 'SELF-TEST FAILED'; exit 1 }
}

# --- the real run ---------------------------------------------------------

Write-Host 'Setting up Asa'
Write-Host ''

Write-Host '[1/9] The app'
$zip = Find-AppZip -Root $scriptRoot
if (-not $zip) {
    Write-Host '  No asa-windows-*.zip found next to this script or in dist\.'
    Write-Host '  Build one first: powershell -NoProfile -ExecutionPolicy Bypass -File kit\package-app.ps1'
    exit 1
}
$appDir = Join-Path $env:LOCALAPPDATA 'Asa\app'
Install-App -ZipPath $zip -AppDir $appDir
Write-Host "  unpacked $zip -> $appDir"
$exePath = Join-Path $appDir 'app\asa.exe'
$startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$shortcutOk = New-AppShortcut -ExePath $exePath -ShortcutPath (Join-Path $startMenu 'Asa.lnk')
if ($shortcutOk) { Write-Host '  Start-menu shortcut: Asa' }
else { Write-Host "  could not create a Start-menu shortcut - start it directly: $exePath" }

Write-Host '[2/9] The projects folder'
if (-not $ProjectsFolder) {
    $default = Join-Path $env:USERPROFILE 'workspace\projects'
    $typed = Read-Host "  Projects folder [$default]"
    $ProjectsFolder = if ($typed) { $typed } else { $default }
}
if (-not (Test-Path -LiteralPath $ProjectsFolder)) {
    New-Item -ItemType Directory -Path $ProjectsFolder -Force | Out-Null
    Write-Host "  created $ProjectsFolder"
} else {
    Write-Host "  using $ProjectsFolder"
}
$settingsPath = Join-Path $env:APPDATA 'Asa\settings.json'
Set-AsaSettings -SettingsPath $settingsPath -ProjectsFolderPath $ProjectsFolder
Write-Host "  saved: $settingsPath"

Write-Host '[3/9] The commands'
$added = Add-ToUserPath -Dir $appDir
if ($added) { Write-Host "  added to PATH: $appDir (open a new terminal for it to take effect)" }
else { Write-Host "  already on PATH: $appDir" }

Write-Host '[4/9] The instruction'
$onboard = Join-Path $appDir 'onboard-projects.ps1'
if (Test-Path -LiteralPath $onboard) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $onboard -ProjectsFolder $ProjectsFolder -Yes
} else {
    Write-Host '  onboard-projects.ps1 was not in the app zip - skipping (the manual will still install below).'
}

Write-Host '[5/9] BOSS.md'
$templateBoss = Join-Path $appDir 'templates\BOSS.md'
if (Install-BossMd -ProjectsFolderPath $ProjectsFolder -TemplatePath $templateBoss) {
    Write-Host '  copied the template in: projects\BOSS.md'
    Write-Host "  Ask the AI you've worked with most to fill it: the prompt is at the top of BOSS.md."
} else {
    Write-Host '  projects\BOSS.md already exists - left untouched.'
}

Write-Host '[6/9] Skills'
$installSkills = Join-Path $appDir 'kit\install-skills.ps1'
$syncSkills = Join-Path $appDir 'kit\sync-skills.ps1'
if (Test-Path -LiteralPath $installSkills) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $installSkills | Out-Null
    Write-Host '  installed for Claude Code (this account, every project).'
}
if (Test-Path -LiteralPath $syncSkills) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $syncSkills | Out-Null
    Write-Host "  packaged for other accounts: $appDir\dist\skills\"
    Write-Host '  Upload asa.zip to your Claude account (Settings -> Skills); the others are optional.'
    Write-Host '  Asa cannot upload to an account itself - this step is yours.'
}

Write-Host '[7/9] Admin-only installs (git, the Visual C++ runtime)'
Install-MissingTools

Write-Host '[8/9] The automatic local backup'
$backupScript = Join-Path $appDir 'kit\backup-projects.ps1'
if (Test-Path -LiteralPath $backupScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $backupScript -Schedule
} else {
    Write-Host '  kit\backup-projects.ps1 was not in the app zip - skipping.'
}

Write-Host '[9/9] The setup record'
$commit = 'unknown'
$versionFile = Join-Path $appDir 'kit\VERSION'
if (Test-Path -LiteralPath $versionFile) { $commit = (Get-Content -LiteralPath $versionFile -Raw).Trim() }
$statusLine = 'app: installed - commands: on PATH - skills: installed for Claude Code, packaged for accounts'
Write-SetupRecord -ProjectsFolderPath $ProjectsFolder -Commit $commit -Now (Get-Date) -StatusLine $statusLine
Write-Host "  wrote $ProjectsFolder\.asa-setup.md"

Write-Host ''
Write-Host 'Done. Open Claude in projects\ and say: set up is done, start.'
