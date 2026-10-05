/// Round 41 §C — the setup sentence's own "clone this address" needs the
/// real repo address, read from the repo itself rather than typed by hand
/// (which goes stale the moment the remote changes, and would have to
/// name a path on this machine). Reads `.git/config` as text, the same
/// reasoning `check-shareable.ps1`'s own `Get-RemoteSlug` already gives:
/// this works with no `git` on PATH and never takes `.git/index.lock`.
/// Pure Dart, no Flutter import.
library;

import 'dart:io';

/// The `origin` remote's own URL from `<repoPath>\.git\config`, or null
/// when there is no git repository there, no `origin` remote, or the
/// config can't be read. Never guessed, never a hard-coded fallback.
String? repoRemoteUrl(String repoPath) {
  final sep = Platform.pathSeparator;
  final configFile = File('$repoPath$sep.git${sep}config');
  if (!configFile.existsSync()) return null;

  String text;
  try {
    text = configFile.readAsStringSync();
  } on Object {
    return null;
  }

  final remoteHeading = RegExp(r'^\[remote\s+"origin"\]\s*$', multiLine: true);
  final headingMatch = remoteHeading.firstMatch(text);
  if (headingMatch == null) return null;

  final afterHeading = text.substring(headingMatch.end);
  final nextSection = RegExp(r'^\[', multiLine: true).firstMatch(afterHeading);
  final section = nextSection == null
      ? afterHeading
      : afterHeading.substring(0, nextSection.start);

  final urlLine = RegExp(
    r'^\s*url\s*=\s*(\S.*?)\s*$',
    multiLine: true,
  ).firstMatch(section);
  if (urlLine == null) return null;
  return urlLine.group(1);
}
