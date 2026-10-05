# package-app.ps1 - build the distributable app zip for a second laptop.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File kit\package-app.ps1
#
# Round 41 §A. Builds the release app, compiles asa-brief/asa-check to real
# .exe files (no Dart SDK needed on the other machine), and packs everything
# setup.ps1 needs into one zip: dist\asa-windows-<short commit>.zip. Exit 0 =
# a zip was written and verified. Exit 1 = it was not shipped.
#
# **Read the zip back, same discipline as package-for-tester.ps1** (hard
# rule 16's own reasoning: a security property that nothing verifies is a
# hope). This zip's audience is narrower - Nico's own second laptop, not a
# stranger - but round-41.md §A asks for the same guard anyway, and
# "Nico uploads it as a GitHub Release asset, by hand" is a wider exposure
# than the private repo itself, so the same three checks apply: a machine
# path, an email address, or the name, baked into any shipped text file.
#
# **The Visual C++ runtime is deliberately NOT bundled as raw DLLs.** Flutter's
# own Windows deployment docs list msvcp140.dll/vcruntime140.dll/
# vcruntime140_1.dll as what a release build needs if the target machine
# doesn't already have the redistributable - but copying them from this dev
# machine's own Visual Studio install risks shipping the wrong architecture
# or a version the Windows redistributable installer would refuse to
# reconcile later. setup.ps1 installs the real, Microsoft-signed
# redistributable via `winget install Microsoft.VCRedist.2015+.x64` instead -
# the approach Microsoft itself documents, not a raw file copy. Said here
# once, in the one place this decision is made, not silently.

param([string]$OutDir)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot   # kit\ -> repo root
if (-not $OutDir) { $OutDir = Join-Path $repoRoot 'dist' }

Push-Location $repoRoot
try {
    $commit = (git rev-parse --short HEAD).Trim()
    if (-not $commit) { throw 'Could not read the current commit - is this a git repository?' }

    Write-Host "Packaging asa app, commit $commit"
    Write-Host ''

    # --- 1. the release build --------------------------------------------
    Write-Host '[1/4] flutter build windows --release'
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows --release failed.' }

    $releaseDir = Join-Path $repoRoot 'build\windows\x64\runner\Release'
    if (-not (Test-Path (Join-Path $releaseDir 'asa.exe'))) {
        throw "Expected asa.exe at $releaseDir - the build did not produce it."
    }

    # --- 2. the CLI tools, compiled - no Dart SDK needed on the other machine
    Write-Host '[2/4] dart compile exe (asa-brief, asa-check)'
    $binDir = Join-Path $repoRoot 'bin'
    $briefExe = Join-Path $binDir 'asa-brief.exe'
    $checkExe = Join-Path $binDir 'asa-check.exe'
    dart compile exe (Join-Path $binDir 'brief.dart') -o $briefExe
    if ($LASTEXITCODE -ne 0) { throw 'dart compile exe brief.dart failed.' }
    dart compile exe (Join-Path $binDir 'check.dart') -o $checkExe
    if ($LASTEXITCODE -ne 0) { throw 'dart compile exe check.dart failed.' }

    # --- 3. stage and pack -------------------------------------------------
    Write-Host '[3/4] staging and packing'
    $staging = Join-Path ([System.IO.Path]::GetTempPath()) ("asa-package-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $payload = Join-Path $staging 'asa-windows'
    New-Item -ItemType Directory -Path (Join-Path $payload 'app') -Force | Out-Null

    Copy-Item -Path (Join-Path $releaseDir '*') -Destination (Join-Path $payload 'app') -Recurse -Force
    Copy-Item -Path $briefExe -Destination $payload -Force
    Copy-Item -Path $checkExe -Destination $payload -Force
    Copy-Item -Path (Join-Path $repoRoot 'templates') -Destination (Join-Path $payload 'templates') -Recurse -Force
    Copy-Item -Path (Join-Path $repoRoot 'kit') -Destination (Join-Path $payload 'kit') -Recurse -Force
    # The zip's own kit\ copy never ships this script's own staging
    # artefacts, package-for-tester.ps1 (a different distribution, a
    # different audience), or the kit's own development narrative - the
    # running history of how the kit itself was built, not anything a
    # working install needs, and the one place Nico's own name legitimately
    # appears throughout (`$neverShip` in package-for-tester.ps1 excludes
    # the same two files for the same reason, for its own audience).
    $neverShip = @(
        'kit\package-app.ps1', 'kit\package-for-tester.ps1',
        'kit\CHANGELOG.md', 'kit\KIT-LOG.md', 'kit\PLAYBOOK.md',
        'kit\ROADMAP.md', 'kit\HANDOVER.md', 'kit\FEEDBACK.md',
        'kit\2026-09-22-changelog-draft-v1.27.md'
    )
    foreach ($f in $neverShip) {
        Remove-Item -LiteralPath (Join-Path $payload $f) -Force -ErrorAction SilentlyContinue
    }
    # Repo-root scripts setup.ps1 itself needs once unpacked - onboard-
    # projects.ps1 looks for kit\sync-manual.ps1 as its own sibling, so both
    # have to land at the zip's top level together, same shape as the repo
    # root itself.
    foreach ($rootScript in @('setup.ps1', 'onboard-projects.ps1')) {
        $src = Join-Path $repoRoot $rootScript
        if (Test-Path $src) { Copy-Item -Path $src -Destination $payload -Force }
    }

    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    $zip = Join-Path (Resolve-Path $OutDir) "asa-windows-$commit.zip"
    if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path $payload -DestinationPath $zip -CompressionLevel Optimal
    Write-Host "  packed    $zip"

    Remove-Item -LiteralPath $briefExe -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $checkExe -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue

    # --- 4. verify the ARCHIVE, not the folder -----------------------------
    Write-Host '[4/4] reading the zip back'
    # `C:\Users\test\...` / `C:\Users\someone\...` are this codebase's own
    # deliberate placeholder convention (CLAUDE.md's rule 16 note on it,
    # check-refs.ps1's own fixtures) - excluded here the same way, not a
    # leak. A word boundary, not a literal trailing backslash: check-refs.ps1
    # itself mentions the same placeholder in plain prose ("C:\Users\test
    # fixtures are skipped"), with a space after "test," not a path
    # separator - found on this script's own first run against the real kit.
    $mustNotAppear = @(
        @{ Why = 'a machine path'; Pattern = 'C:\\Users\\(?!test\b|someone\b)[A-Za-z0-9._-]+' },
        @{ Why = 'an email address'; Pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' },
        @{ Why = 'the name'; Pattern = '(^|[^A-Za-z])Nico([^A-Za-z]|$)' }
    )
    # A REAL project's own home-note shape (workspace\projects\<slug>\
    # <slug>.md) - not just any mention of "workspace\projects\", which
    # plenty of this kit's own generic documentation makes (a skill
    # describing where it fires, a `<name>` placeholder). This script never
    # copies anything from projects\ itself, so a match here is defense in
    # depth, not the primary guard.
    $projectsMarker = 'workspace\\projects\\[a-z0-9][a-z0-9_-]*\\[a-z0-9][a-z0-9_-]*\.(md|json)'

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
    $hits = New-Object System.Collections.Generic.List[string]
    $checked = 0
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.Name -notmatch '\.(md|ps1|json|txt|dart|yaml|yml)$') { continue }
            $reader = New-Object System.IO.StreamReader($entry.Open())
            $text = $reader.ReadToEnd(); $reader.Close()
            $checked++
            foreach ($check in $mustNotAppear) {
                if ($text -match $check.Pattern) { $hits.Add("$($entry.FullName)  -> $($check.Why)") }
            }
            if ($text -match $projectsMarker) { $hits.Add("$($entry.FullName)  -> a real projects\ path") }
        }
    } finally { $archive.Dispose() }
    Write-Host "  verified  $checked text file(s) read back out of the zip"
    Write-Host ''

    if ($hits.Count -gt 0) {
        Write-Host "NOT SHIPPABLE - $($hits.Count) thing(s) that must not be in the archive:"
        foreach ($h in ($hits | Select-Object -Unique)) { Write-Host "  $h" }
        Remove-Item -LiteralPath $zip -Force
        Write-Host ''
        Write-Host '  The zip has been deleted so it cannot be sent by accident.'
        exit 1
    }

    Write-Host "Clean. Upload as a GitHub Release asset by hand:  $zip"
    exit 0
} finally {
    Pop-Location
}
