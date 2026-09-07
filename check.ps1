# check.ps1 - the code-quality gate for this repository.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File check.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File check.ps1 -Fresh
#
# -Fresh adds `flutter clean` first. Use it after moving the repository,
# after adding or removing a dependency, or when the build behaves oddly.
# It costs a minute or two of rebuild and it is the fix for the CMake
# error about a CMakeCache.txt from a different directory.
#
# `flutter pub get` runs every time. It is a second when nothing changed,
# and without it a cold clone fails in step 2 with an error about the
# analyser rather than about its missing dependencies.
#
# Four checks, in this order - the order is load-bearing (HANDOVER.md):
# formatting, then analysis, then unit tests, then the feature test.
# Analysis runs before tests because a sibling project once had 25 green
# tests over code that could not compile - a green suite is not proof the
# app builds.
#
# "Mostly passing" is failing. Nothing here lowers the bar to reach PASS.
#
# TWO THINGS THAT SURPRISE PEOPLE, BOTH ON PURPOSE
#
# 1. `dart format --set-exit-if-changed` REWRITES the files it is unhappy
#    with and THEN fails. So a first run on unformatted code fails and a
#    second run passes with no further work. That is not a flaky check.
#
# 2. It stops at the first failure. Nothing after that line ran, and the
#    script says so by name - added 2026-09-03, after a run stopped at
#    step 1 and the remaining three were then typed out by hand.
#
# The feature test names its device (-d windows). Without that, flutter
# asks which device to use and the gate sits waiting for a keystroke -
# PLAYBOOK.md section 15: prefer a command that fails loudly over one
# that can silently wait for input.

param([switch]$Fresh)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Stop-Here {
    param([int]$Step, [string]$What)
    Write-Host ''
    Write-Host ("FAILED at step {0} of 4 - {1}" -f $Step, $What)
    Write-Host '  Nothing after this step ran. Fix this, then run the whole script again.'
    exit 1
}

if ($Fresh) {
    Write-Host '[0/4] flutter clean'
    flutter clean
    if ($LASTEXITCODE) { Stop-Here 0 'flutter clean' }
    Write-Host ''
}

Write-Host '[0/4] flutter pub get'
flutter pub get
if ($LASTEXITCODE) { Stop-Here 0 'resolving dependencies. Nothing was checked.' }

Write-Host ''
Write-Host '[1/4] dart format --set-exit-if-changed .'
dart format --set-exit-if-changed .
if ($LASTEXITCODE) { Stop-Here 1 'formatting. The files above have just been rewritten - run this script again and step 1 will pass.' }

Write-Host ''
Write-Host '[2/4] flutter analyze --fatal-infos'
flutter analyze --fatal-infos
if ($LASTEXITCODE) { Stop-Here 2 'static analysis' }

Write-Host ''
Write-Host '[3/4] flutter test --coverage'
flutter test --coverage
if ($LASTEXITCODE) { Stop-Here 3 'unit tests' }

Write-Host ''
Write-Host '[4/4] flutter test integration_test -d windows'
flutter test integration_test -d windows
if ($LASTEXITCODE) { Stop-Here 4 'the feature test. If this is a CMake error about a different CMakeCache.txt directory, run `flutter clean` - the build cache is from the folder this repository used to live in.' }

Write-Host ''
Write-Host 'PASS - all four.'
