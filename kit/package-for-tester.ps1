# package-for-tester.ps1 - build the copy of this kit that goes to someone else.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File package-for-tester.ps1
#
# Exit 0 = a zip was written and verified.  Exit 1 = it was not shipped.
#
# Why this exists: on 2026-08-26 a package was hand-assembled and declared
# clean. It contained the kit author's first name 18 times, his products, and
# his roadmap. The sweep that cleared it had read the FOLDER; what ships is the
# ARCHIVE, and the two were not the same thing.
#
# So this script does three jobs in order, and the third is the one that
# matters: sanitise, pack, then READ EVERY FILE BACK OUT OF THE ZIP and fail if
# anything private is still in there.

param(
    [string]$OutDir = '..',
    [switch]$KeepStaging
)

$ErrorActionPreference = 'Stop'
$kitRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- what must never leave -----------------------------------------------
#
# Edit these three lists. They are the whole configuration of this script, and
# an empty list means that check covers nothing.

# Files that are the author's own and are never shipped.
$neverShip = @('KIT-LOG.md', 'ROADMAP.md')

# Replaced everywhere, in order. Longest first, or "Jane Smith" leaves "Smith".
$replace = [ordered]@{
    'Nico Bui'                = 'the Boss'
    "Nico's"                  = "the Boss's"
    'Nico'                    = 'the Boss'
    'the German memory layer' = 'the product'
    'German memory layer'     = 'the product'
    "Asa's"                   = "the second project's"
    'Asa'                     = 'the second project'
    'der/die/das'             = 'one topic'
    'Konjunktiv II'           = 'a second topic'
    'ASA-HUB'                 = 'PROJECT-HUB'
    'the German app'          = 'the first project'
    'German app'              = 'the first project'
    'the assistant app'       = 'the first project'
    'assistant app'           = 'the first project'
}

# After packing, every text file in the ZIP is read back and searched for
# these. One hit and nothing ships.
$mustNotAppear = @('Nico', 'maxqda', 'VERBI', 'German memory', 'German app', 'C:\Users\')

# -------------------------------------------------------------------------

$version = (Get-Content -LiteralPath (Join-Path $kitRoot 'VERSION') -Raw).Trim()
$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("kit-package-" + [guid]::NewGuid().ToString('N').Substring(0,8))
$payload = Join-Path $staging 'vibe-coding-kit'

Write-Host "Packaging kit v$version for a tester"
Write-Host ''

# --- 1. copy, minus the things that never ship ---------------------------
New-Item -ItemType Directory -Path $payload -Force | Out-Null
Copy-Item -Path (Join-Path $kitRoot '*') -Destination $payload -Recurse -Force
Remove-Item -LiteralPath (Join-Path $payload '_to_delete') -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $payload 'package-for-tester.ps1') -Force -ErrorAction SilentlyContinue

foreach ($f in $neverShip) {
    $p = Join-Path $payload $f
    if (Test-Path $p) { Remove-Item -LiteralPath $p -Force; Write-Host "  excluded  $f" }
}

# --- 2. sanitise ----------------------------------------------------------
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$touched = 0
foreach ($file in (Get-ChildItem -LiteralPath $payload -Recurse -File -Include '*.md','*.ps1')) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $before = $text
    foreach ($key in $replace.Keys) { $text = $text.Replace($key, $replace[$key]) }
    # Deliberately NO blanket annotation of the excluded filenames. The first
    # version welded "(not shipped)" onto all 38 mentions, including inside
    # templates/ROADMAP.md itself and the roadmap skill whose whole job is to
    # write one - documents that then contradicted themselves in one sentence.
    # HANDOVER.md explains the absence once, which is where a reader needs it.
    if ($text -ne $before) { [System.IO.File]::WriteAllText($file.FullName, $text, $utf8NoBom); $touched++ }
}
Write-Host "  sanitised $touched file(s)"

# The checker's product list ships blank - a blank to fill in, not a default.
$checker = Join-Path $payload 'check-boundaries.ps1'
if (Test-Path $checker) {
    $c = [System.IO.File]::ReadAllText($checker)
    $blank = @"
`$hard = @(
    # Put YOUR product names here, one per line, lower case.
    # Empty means this check covers nothing - it is not a default, it is a
    # blank you are meant to fill in on day one.
)
"@
    $c = [regex]::Replace($c, '(?s)\$hard = @\(.*?\r?\n\)\r?\n', $blank)
    [System.IO.File]::WriteAllText($checker, $c, $utf8NoBom)
    Write-Host '  blanked   check-boundaries.ps1 product list'
}

# --- 3. pack --------------------------------------------------------------
$zip = Join-Path (Resolve-Path $OutDir) "vibe-coding-kit-v$version-tester.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path $payload -DestinationPath $zip -CompressionLevel Optimal
Write-Host "  packed    $zip"

# --- 4. verify the ARCHIVE, not the folder --------------------------------
#
# The step the hand-assembled version skipped, and the only one that would
# have caught what it missed.

$payloadName = [System.IO.Path]::GetFileName($payload)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
$hits = New-Object System.Collections.Generic.List[string]
$checked = 0
try {
    foreach ($entry in $archive.Entries) {
        if ($entry.Name -notmatch '\.(md|ps1|json|txt)$') { continue }
        $reader = New-Object System.IO.StreamReader($entry.Open())
        $text = $reader.ReadToEnd(); $reader.Close()
        $checked++
        foreach ($term in $mustNotAppear) {
            if ($text -like "*$term*") { $hits.Add("$($entry.FullName)  ->  $term") }
        }
        # Top level only. templates/ROADMAP.md is a TEMPLATE, not the author's
        # roadmap - matching the name anywhere in the tree flagged it on this
        # script's first run and deleted a perfectly good archive.
        foreach ($f in $neverShip) {
            if ($entry.FullName -eq "$payloadName/$f") { $hits.Add("$($entry.FullName)  ->  should never ship") }
        }
    }
} finally { $archive.Dispose() }

Write-Host "  verified  $checked text file(s) read back out of the zip"
Write-Host ''

if (-not $KeepStaging) { Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue }

if ($hits.Count -gt 0) {
    Write-Host "NOT SHIPPABLE - $($hits.Count) thing(s) that must not be in the archive:"
    foreach ($h in $hits) { Write-Host "  $h" }
    Write-Host ''
    Write-Host '  Add the term to $replace or the file to $neverShip, then run this again.'
    Remove-Item -LiteralPath $zip -Force
    Write-Host '  The zip has been deleted so it cannot be sent by accident.'
    exit 1
}

Write-Host "Clean. Send:  $zip"
exit 0
