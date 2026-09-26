/// Round 32/A — the right-hand value on every project row: the deadline
/// when there is one, otherwise how long since the project was actually
/// touched. Replaces the `updated:` field as a freshness signal — that
/// field is typed, and several real notes already sit weeks behind the
/// files next to them (`CHARTER.md` §3.2: derived, not typed).
library;

import 'dart:io';

import 'package:asa/core/git_state.dart';

/// The most recent point [projectFolder] was actually touched: git's own
/// last-commit date when [git] is readable, otherwise the newest
/// modification time of any file inside the folder (recursive, skipping
/// `_`- and `.`-prefixed subfolders — a project's own `.git` or an
/// `_archive` folder never counts). Null only when neither source has an
/// answer — an empty, newly-created folder with no git repo.
Future<DateTime?> lastTouchedOf(String projectFolder, GitState? git) async {
  if (git != null && git.error == null && git.lastCommit != null) {
    return git.lastCommit;
  }
  return _newestModification(Directory(projectFolder));
}

Future<DateTime?> _newestModification(Directory dir) async {
  if (!dir.existsSync()) return null;

  DateTime? newest;
  await for (final entry in dir.list(followLinks: false)) {
    final name = entry.path.split(Platform.pathSeparator).last;

    if (entry is Directory) {
      if (name.startsWith('.') || name.startsWith('_')) continue;
      final sub = await _newestModification(entry);
      if (sub != null && (newest == null || sub.isAfter(newest))) {
        newest = sub;
      }
    } else if (entry is File) {
      // Round 35/A — the one file Asa's own onboarding process copies into
      // every folder, not something a real session touched. Every row read
      // "1 day" the day it was rewritten into all 13 folders at once,
      // answering nothing about which project is actually stuck.
      if (name == 'HOW-ASA-WORKS.md') continue;
      final modified = entry.statSync().modified;
      if (newest == null || modified.isAfter(newest)) newest = modified;
    }
  }
  return newest;
}

/// What the row's right-hand column actually shows: [humanizedDeadline]
/// when the project has one — `humanizeDeadline` from `project_row.dart`,
/// unchanged — otherwise the age since [lastTouched], as the signed
/// sketch draws it: `today`, `1 day`, `N days`. Null only when there is
/// neither a deadline nor any touch date at all.
String? freshnessText({
  required String? humanizedDeadline,
  required DateTime? lastTouched,
  required DateTime now,
}) {
  if (humanizedDeadline != null) return humanizedDeadline;
  if (lastTouched == null) return null;

  final today = DateTime(now.year, now.month, now.day);
  final touchedDay = DateTime(
    lastTouched.year,
    lastTouched.month,
    lastTouched.day,
  );
  final days = today.difference(touchedDay).inDays;

  if (days <= 0) return 'today';
  if (days == 1) return '1 day';
  return '$days days';
}
