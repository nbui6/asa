/// Round 39 cp4 — `asa-check`: every write is in a shape Asa can read, in
/// plain words a person could act on. Pure Dart, no Flutter import;
/// `bin/check.dart` is the only thing that turns this into a command.
library;

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/change_history.dart';
import 'package:asa/core/decisions_reader.dart' show DiskFileAccess;
import 'package:asa/core/freshness.dart';
import 'package:asa/core/project_reader.dart';
import 'package:asa/core/session_file.dart';
import 'package:asa/core/session_log.dart';
import 'package:asa/core/status_words.dart';

/// One problem `asa-check` found, already in the words a person could read
/// and act on — never a stack trace, never a code.
class Finding {
  const Finding(this.message);
  final String message;

  @override
  String toString() => message;
}

/// `(waiting: Name, since YYYY-MM-DD)` on a task — the manual's own shape,
/// added 2026-09-14. A wait over 14 days is the thing worth a look.
final RegExp _waitingMarker = RegExp(
  r'\(waiting:\s*([^,]+),\s*since\s*(\d{4}-\d{2}-\d{2})\)',
  caseSensitive: false,
);

/// ADR 0036, in the new words — a project this quiet has no deadline left
/// to miss and no urgency left to flag; *note behind the work* and *over
/// budget* would only ever be noise for it.
const _inactiveStatuses = {'on-hold', 'done', 'canceled'};

/// Headings §13's move folds away — a note still carrying one of these is
/// the project the manual's own "getting a project into shape" is for.
const _oldShapeHeadings = [
  'who it is for',
  'open, needing a decision',
  'log',
  'related project',
  'where it stands',
];

/// Every check the manual's own §7/§13 ask for, against one real project
/// folder. An empty list is "OK" — never printed as a false "nothing to
/// report" when the project itself could not be read at all.
Future<List<Finding>> checkProject(
  String projectFolder, {
  DateTime? now,
  String? historyRoot,
}) async {
  final effectiveNow = now ?? DateTime.now();
  final findings = <Finding>[];
  final projectsRoot = Directory(projectFolder).parent.path;

  if (!File('$projectsRoot/.asa-setup.md').existsSync()) {
    findings.add(
      const Finding(
        r"Asa isn't set up here — projects\.asa-setup.md is missing.",
      ),
    );
  }

  final bossFile = File('$projectsRoot/BOSS.md');
  if (!bossFile.existsSync()) {
    findings.add(const Finding('BOSS.md is missing.'));
  } else if (isEmptyBossTemplate(await bossFile.readAsString())) {
    findings.add(const Finding('BOSS.md is still the empty template.'));
  }

  final readResult = await readProject(projectFolder);
  if (readResult.project == null) {
    findings.add(
      Finding(
        'Could not read the project: ${readResult.error ?? "unknown problem"}.',
      ),
    );
    return findings;
  }
  final project = readResult.project!;
  final canonical = canonicalStatus(project.status);
  final isKnownNewWord = statusWords.any((w) => w.stored == canonical);
  final isInactive = _inactiveStatuses.contains(canonical);

  if (isOldStatusWord(project.status)) {
    findings.add(
      Finding(
        'old status word "${project.status}" — write "$canonical" instead.',
      ),
    );
  } else if (project.status.isNotEmpty && !isKnownNewWord) {
    findings.add(Finding('unknown status word "${project.status}".'));
  }

  final rawNote = File(project.sourceFile).readAsStringSync().toLowerCase();
  final staleHeadings = _oldShapeHeadings.where(
    (h) => rawNote.contains('## $h'),
  );
  final hasTasksSection = rawNote.contains('## tasks');
  if (staleHeadings.isNotEmpty || !hasTasksSection) {
    final reasons = [
      ...staleHeadings.map((h) => 'still has "## ${_titleCase(h)}"'),
      if (!hasTasksSection) 'has no "## Tasks" section',
    ];
    findings.add(Finding("not in Asa's shape yet — ${reasons.join(', ')}."));
  }

  if (!isInactive) {
    final lastTouched = await lastTouchedOf(projectFolder, null);
    final updated = DateTime.tryParse(project.updated.trim());
    if (lastTouched != null &&
        updated != null &&
        lastTouched.difference(updated).inDays > 1) {
      findings.add(
        Finding(
          'note behind the work — the folder changed after '
          'updated: ${project.updated}.',
        ),
      );
    }

    final noteLines = File(project.sourceFile)
        .readAsStringSync()
        .split('\n')
        .length;
    final sessionLines = await _lineCount(
      File('$projectFolder/.asa-session.md'),
    );
    final total = noteLines + sessionLines;
    if (total > 300) {
      findings.add(
        Finding(
          'over budget — the note and session file add up to $total lines, '
          'over the ~300-line budget.',
        ),
      );
    }

    // ADR 0048 (2026-09-29) — the same "changed without a note" cp8
    // already gives asa-brief --since, now in asa-check and the
    // Instruction for AI screen's own Checks too, so the two agree.
    // Read-only, same as everything else here: nothing is recorded by
    // this command itself — only what asa-brief already captured.
    final history = await readChangeHistory(
      projectFolder,
      historyRoot: historyRoot,
    );
    if (history.isNotEmpty) {
      final log = await readSessionLog(projectFolder, const DiskFileAccess());
      for (final record in history) {
        if (record.before == null) continue; // first seen, not a change
        final match = isLoggedChange(record, log);
        if (match == LoggedMatch.yes) continue;
        final word = match == LoggedMatch.probably
            ? 'probably logged'
            : 'not logged';
        findings.add(Finding('${record.path} changed, $word.'));
      }
    }
  }

  final session = await _readSession(projectFolder);
  if (session != null && session.isCutOff(effectiveNow)) {
    findings.add(
      const Finding(
        'session probably cut off — .asa-session.md is open, not updated '
        'for over 2 hours.',
      ),
    );
  }

  final areas = await readAreas(projectFolder);
  final allTasks = [...project.tasks, for (final area in areas) ...area.tasks];
  for (final task in allTasks) {
    final match = _waitingMarker.firstMatch(task.rawLine);
    if (match == null) continue;
    final since = DateTime.tryParse(match.group(2)!);
    if (since == null) continue;
    if (effectiveNow.difference(since).inDays > 14) {
      findings.add(
        Finding(
          'waiting on ${match.group(1)!.trim()} since ${match.group(2)} — '
          'over 14 days.',
        ),
      );
    }
  }

  return findings;
}

Future<int> _lineCount(File file) async {
  if (!file.existsSync()) return 0;
  return (await file.readAsString()).split('\n').length;
}

Future<SessionFile?> _readSession(String projectFolder) async {
  final file = File('$projectFolder/.asa-session.md');
  if (!file.existsSync()) return null;
  return parseSessionFile(await file.readAsString());
}

/// `templates\BOSS.md`'s own five *Read this first* questions, each ending
/// in a bare colon with nothing after it — the shape a fresh, never-filled
/// copy has. One real answer anywhere is enough to call it filled in.
bool isEmptyBossTemplate(String text) {
  final section = RegExp(
    r'^#{2,3}\s*Read this first.*$',
    multiLine: true,
    caseSensitive: false,
  );
  final match = section.firstMatch(text);
  // No such section at all - not this check's problem.
  if (match == null) return false;
  final rest = text.substring(match.end);
  final nextHeading = RegExp(r'^#{2,3}\s', multiLine: true).firstMatch(rest);
  final body = nextHeading == null
      ? rest
      : rest.substring(0, nextHeading.start);

  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    // A numbered line like "1. **How I like to get information:**" with
    // nothing after the final colon is still the blank template — and a
    // parenthetical after it, like "(how often, how long...)", is the
    // template's own hint, not a real answer.
    final afterColon = trimmed.split(':').last.trim();
    final stripped = afterColon.replaceAll(RegExp(r'\*|\(.*?\)'), '').trim();
    if (stripped.isNotEmpty) return false;
  }
  return true;
}

String _titleCase(String words) => words
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// `templates\BOSS.md`'s own quoted prompt — *"Write my BOSS.md for
/// Asa..."* — for the Instruction for AI screen's *Fill with your AI*
/// button, which copies exactly this to the clipboard. Null when the
/// template's own shape isn't there to find (an edited or missing
/// template), never a guess at what the prompt might be.
String? bossFillPrompt(String templateText) {
  final match = RegExp(r'\*"(.+?)"\*', dotAll: true).firstMatch(templateText);
  if (match == null) return null;
  final raw = match.group(1)!;
  return raw
      .split('\n')
      .map((line) => line.replaceFirst(RegExp(r'^>\s?'), '').trim())
      .join(' ')
      .trim();
}
