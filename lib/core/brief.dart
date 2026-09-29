/// Round 39 cp3 — `asa-brief`: the same data Asa's own screens read,
/// printed as markdown so any AI (any account, any machine) can catch up
/// from it — the manual's own §4 table, turned into code instead of a
/// table a human has to follow by hand. Pure Dart, no Flutter import;
/// `bin/brief.dart` is the only thing that turns this into a runnable
/// command.
library;

import 'dart:io';

import 'package:asa/core/area.dart';
import 'package:asa/core/change_history.dart';
import 'package:asa/core/changes_file.dart';
import 'package:asa/core/charter.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_reader.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_file.dart';
import 'package:asa/core/session_file.dart';
import 'package:asa/core/session_log.dart';
import 'package:asa/core/status_words.dart';

const FileAccess _files = DiskFileAccess();

/// Round links live on the milestone's own title the same way
/// `round_state.dart` and `strategy_view.dart` already read it — a third
/// copy of the same pattern rather than a shared export, same tradeoff
/// those two already made.
final RegExp _roundNumberInTitle = RegExp(
  r'Round\s*(\d+)',
  caseSensitive: false,
);

bool _current(Decision d) => (d.supersededBy ?? '').isEmpty;

/// A project's own proposed decisions, and its `Scope: always` ones —
/// the manual's §4 row for `asa-brief "<project>"`. Superseded decisions
/// never appear here, per round-39.md cp3's own rule.
List<Decision> _decisionsWaitingOrAlways(List<Decision> decisions) {
  return decisions
      .where(_current)
      .where((d) => d.isProposed || d.links.scopeAlways)
      .toList();
}

Future<SessionFile?> _readSession(String projectFolder) async {
  final file = File('$projectFolder/.asa-session.md');
  if (!file.existsSync()) return null;
  return parseSessionFile(await file.readAsString());
}

/// `projects\BOSS.md`'s own *Read this first* and *Your rules* parts —
/// about 45 lines together, printed at the top of every briefing
/// (round-39.md, ADR 0043: "every AI reads its *Read this first* and
/// *Your rules* parts at step 1 of the loop"). Null when the file, or
/// neither section, is there — a fixture or a test never has the real
/// one, and that is not an error.
///
/// **Never printed into a repo file, a fixture or a screenshot** — the
/// real file holds health information about the user. This only ever
/// writes it to stdout, for the person or AI running the command to read.
Future<String?> _readBossIntro(String projectsRoot) async {
  final file = File('$projectsRoot/BOSS.md');
  if (!file.existsSync()) return null;
  final text = await file.readAsString();
  final readThisFirst = sectionTextContaining(text, 'read this first');
  final yourRules = sectionTextContaining(text, 'your rules');

  final buffer = StringBuffer();
  if (readThisFirst != null) buffer.writeln(readThisFirst);
  if (yourRules != null) {
    if (buffer.isNotEmpty) buffer.writeln();
    buffer.writeln(yourRules);
  }
  return buffer.isEmpty ? null : buffer.toString().trim();
}

/// Round 39 cp8 (ADR 0033) — "when Asa scans a project, it keeps a dated
/// copy of every watched file that changed." `asa-brief` is one of the
/// few things that actually looks at a project today, so it is one of
/// the places that scan happens from.
///
/// **Opt-in, not on by default** — deliberately unlike `write_log.dart`'s
/// own default-to-the-real-path convention: this fires on every single
/// read, which is exactly what the whole existing test suite already
/// does constantly. Defaulting it on would mean every test in this repo
/// that ever calls `briefProject`/`briefAll` starts writing real files
/// into the real `%APPDATA%\Asa\history\` the moment this function
/// exists — [recordHistory] must be true, which only `bin/brief.dart`'s
/// own CLI passes. Best-effort either way: no `APPDATA` (or any other
/// real-disk problem) ever breaks a briefing over a history nobody asked
/// to see this time.
Future<void> _recordScan(
  bool recordHistory,
  String projectFolder,
  String projectsRoot, {
  String? historyRoot,
  DateTime? now,
}) async {
  if (!recordHistory) return;
  try {
    await recordChanges(
      projectFolder,
      projectsRoot,
      historyRoot: historyRoot,
      now: now,
    );
  } on FileSystemException {
    // A locked or unreadable file this pass — try again next scan.
  }
}

/// Same as [_recordScan], for the projects-root files (`BOSS.md`,
/// `AGENTS.md`) — called once per briefing, not once per project, since
/// every project would otherwise re-check the same two files.
Future<void> _recordRootScan(
  bool recordHistory,
  String projectsRoot, {
  String? historyRoot,
  DateTime? now,
}) async {
  if (!recordHistory) return;
  try {
    await recordChanges(
      projectsRoot,
      projectsRoot,
      isRoot: true,
      historyRoot: historyRoot,
      now: now,
    );
  } on FileSystemException {
    // A locked or unreadable file this pass — try again next scan.
  }
}

String _sessionLine(SessionFile? session, DateTime now) {
  if (session == null) return 'Session: none.';
  if (!session.isOpen) {
    return session.lastDone == null
        ? 'Session: closed.'
        : 'Session: closed — last done: ${session.lastDone}.';
  }
  final tag = session.isCutOff(now)
      ? ' — cut off, likely abandoned'
      : session.possiblyInProgress(now)
      ? ' — another AI may be mid-session right now, stop and ask'
      : '';
  final doing = session.doing == null ? '' : ' — doing: ${session.doing}';
  return 'Session: open$tag$doing';
}

/// `asa-brief "<project>"`, optionally narrowed to one area or one round.
/// Reads real files under [projectFolder] — the same real-disk contract
/// every other reader in `core/` already has.
Future<String> briefProject(
  String projectFolder, {
  String? area,
  String? round,
  DateTime? now,
  bool recordHistory = false,
  String? historyRoot,
}) async {
  final effectiveNow = now ?? DateTime.now();
  final buffer = StringBuffer();

  final projectsRoot = Directory(projectFolder).parent.path;
  await _recordScan(
    recordHistory,
    projectFolder,
    projectsRoot,
    historyRoot: historyRoot,
    now: effectiveNow,
  );
  await _recordRootScan(
    recordHistory,
    projectsRoot,
    historyRoot: historyRoot,
    now: effectiveNow,
  );
  final bossIntro = await _readBossIntro(projectsRoot);
  if (bossIntro != null) {
    buffer
      ..writeln('## Working with you')
      ..writeln()
      ..writeln(bossIntro)
      ..writeln();
  }

  final readResult = await readProject(projectFolder);
  if (readResult.project == null) {
    buffer
      ..writeln('# ${projectFolder.split(RegExp(r'[\\/]')).last}')
      ..writeln()
      ..writeln(readResult.error ?? 'Could not be read.');
    return buffer.toString();
  }
  final project = readResult.project!;

  buffer
    ..writeln('# ${project.name}')
    ..writeln()
    ..writeln('- Status: ${project.status.isEmpty ? "(none)" : project.status}')
    ..writeln(
      '- Next step: '
      '${project.nextStep.isEmpty ? "(none)" : project.nextStep}',
    );

  final session = await _readSession(projectFolder);
  buffer.writeln('- ${_sessionLine(session, effectiveNow)}');

  final changes = await readChangeRequests(projectFolder, _files);
  if (changes.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Newest change requests');
    for (final row in changes.take(3)) {
      buffer.writeln('- ${row.date} · Round ${row.round}: ${row.what}');
    }
  }

  final decisionResults = await readAllDecisions(projectFolder, _files);
  final decisions = decisionResults
      .map((r) => r.decision)
      .whereType<Decision>()
      .toList();
  final waitingOrAlways = _decisionsWaitingOrAlways(decisions);
  if (waitingOrAlways.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Decisions waiting, or always in scope');
    for (final d in waitingOrAlways) {
      final tag = d.isProposed ? 'proposed' : 'Scope: always';
      buffer.writeln('- ADR ${d.number ?? "?"} ($tag) — ${d.title}');
    }
  }

  final areas = await readAreas(projectFolder);
  if (area == null && round == null) {
    if (areas.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Areas, at a glance');
      for (final a in areas) {
        buffer.writeln(
          '- ${a.name}: ${a.doneCount}/${a.totalCount} tasks done',
        );
      }
    }
  }

  if (area != null) {
    buffer
      ..writeln()
      ..writeln(
        await _areaSlice(projectFolder, area, areas, decisions, project),
      );
  }

  if (round != null) {
    buffer
      ..writeln()
      ..writeln(await _roundSlice(projectFolder, round, decisions));
  }

  return buffer.toString();
}

Future<String> _areaSlice(
  String projectFolder,
  String areaName,
  List<Area> areas,
  List<Decision> decisions,
  Project project,
) async {
  final buffer = StringBuffer('## Area: $areaName');
  final matches = areas.where(
    (a) => a.name.toLowerCase() == areaName.toLowerCase(),
  );
  if (matches.isEmpty) {
    buffer
      ..writeln()
      ..write('No area page found with that name.');
    return buffer.toString();
  }
  final a = matches.first;

  buffer
    ..writeln()
    ..writeln('- Goal: ${a.goal ?? "(none written)"}');

  final open = a.tasks.where((t) => !t.done).toList();
  if (open.isNotEmpty) {
    buffer.writeln('- Open tasks:');
    for (final t in open) {
      buffer.writeln('  - ${t.text}');
    }
  }

  if (a.results.isNotEmpty) {
    buffer.writeln('- Last results:');
    for (final r in a.results.take(3)) {
      final date = r.date?.toIso8601String().split('T').first ?? '(undated)';
      buffer.writeln('  - $date — ${r.text}');
    }
  }

  if (a.objectiveNumbers.isNotEmpty) {
    final strategy = await readCharter(projectFolder);
    final number = int.tryParse(a.objectiveNumbers.first);
    final inRange =
        number != null && number >= 1 && number <= strategy.objectives.length;
    if (inRange) {
      final objective = strategy.objectives[number - 1];
      buffer.writeln(
        '- Objective ${a.objectiveNumbers.first}: ${objective.title}',
      );
    }
  }

  final linked = decisions
      .where(_current)
      .where(
        (d) =>
            (d.number != null && a.decisionNumbers.contains(d.number)) ||
            (d.links.area ?? '').toLowerCase() == areaName.toLowerCase() ||
            d.links.objectives.any(a.objectiveNumbers.contains),
      )
      .toList();
  if (linked.isNotEmpty) {
    buffer.writeln('- Decisions linked here:');
    for (final d in linked) {
      buffer.writeln('  - ADR ${d.number ?? "?"} — ${d.title}');
    }
  }

  final waitingRounds = await _roundsWaitingFor(
    projectFolder,
    project,
    areaName,
  );
  if (waitingRounds.isNotEmpty) {
    buffer.writeln(
      '- Rounds waiting for approval: ${waitingRounds.join(", ")}',
    );
  }

  return buffer.toString();
}

/// Every round number whose milestone is done and whose own
/// `rounds\round-N.md` names [areaName] as its `**Area:**` — "its waiting
/// rounds", per the manual's §4 table. A milestone with no matching spec
/// file, or one naming a different area, is not this area's to report.
Future<List<String>> _roundsWaitingFor(
  String projectFolder,
  Project project,
  String areaName,
) async {
  final approvals = await readRoundApprovals(projectFolder, _files);
  final waiting = <String>[];
  for (final milestone in project.roadmap) {
    final number = _roundNumberInTitle.firstMatch(milestone.title)?.group(1);
    if (number == null) continue;
    if (!milestone.done) continue;
    if (approvals.hasApprovalFor(number)) continue;
    final text = await readRoundFileText(projectFolder, number, _files);
    if (text == null) continue;
    final roundArea = parseRoundArea(text);
    if (roundArea != null &&
        roundArea.toLowerCase() == areaName.toLowerCase()) {
      waiting.add(number);
    }
  }
  return waiting;
}

Future<String> _roundSlice(
  String projectFolder,
  String round,
  List<Decision> decisions,
) async {
  final buffer = StringBuffer('## Round $round');
  final text = await readRoundFileText(projectFolder, round, _files);
  if (text == null) {
    buffer
      ..writeln()
      ..write('No `rounds/round-$round.md` file found.');
    return buffer.toString();
  }

  buffer.writeln();
  final finishLine = parseRoundFinishLine(text);
  buffer.writeln('- Finish line: ${finishLine ?? "(not stated)"}');
  final test = parseRoundTest(text);
  buffer.writeln('- Test: ${test ?? "(not stated)"}');
  final roundArea = parseRoundArea(text);
  buffer.writeln('- Area: ${roundArea ?? "(none)"}');

  final linked = decisions
      .where(_current)
      .where((d) => d.links.rounds.contains(round))
      .toList();
  if (linked.isNotEmpty) {
    buffer.writeln('- Decisions:');
    for (final d in linked) {
      buffer.writeln('  - ADR ${d.number ?? "?"} — ${d.title}');
    }
  }

  return buffer.toString();
}

/// `asa-brief --all` — every project's status, next step, freshness, what
/// waits for the user, and any cut-off session.
Future<String> briefAll(
  String projectsRoot, {
  DateTime? now,
  bool recordHistory = false,
  String? historyRoot,
}) async {
  final effectiveNow = now ?? DateTime.now();
  final scan = await scanProjects(projectsRoot);
  final buffer = StringBuffer('# asa-brief --all\n');

  await _recordRootScan(
    recordHistory,
    projectsRoot,
    historyRoot: historyRoot,
    now: effectiveNow,
  );
  final bossIntro = await _readBossIntro(projectsRoot);
  if (bossIntro != null) {
    buffer
      ..writeln()
      ..writeln('## Working with you')
      ..writeln()
      ..writeln(bossIntro);
  }

  if (scan.error != null) {
    buffer
      ..writeln()
      ..write(scan.error);
    return buffer.toString();
  }

  // Round 38 §F, ADR 0036 — on-hold/done/canceled collapse to one summary
  // line each, same as the overview's own folded line, instead of a full
  // section per project; keeps this reading from growing the way the
  // overview no longer does.
  final hiddenCounts = <String, int>{};

  for (final summary in scan.projects) {
    await _recordScan(
      recordHistory,
      summary.folder,
      projectsRoot,
      historyRoot: historyRoot,
      now: effectiveNow,
    );

    final project = summary.project;

    if (isHiddenStatus(project.status)) {
      final canonical = canonicalStatus(project.status);
      hiddenCounts[canonical] = (hiddenCounts[canonical] ?? 0) + 1;
      continue;
    }

    final days = summary.daysStale(effectiveNow);
    final freshness = days == null
        ? 'unknown'
        : '$days day(s) since last commit';
    buffer
      ..writeln()
      ..writeln('## ${project.name}')
      ..writeln(
        '- Status: ${project.status.isEmpty ? "(none)" : project.status}',
      )
      ..writeln(
        '- Next step: '
        '${project.nextStep.isEmpty ? "(none)" : project.nextStep}',
      )
      ..writeln('- Freshness: $freshness');

    final session = await _readSession(summary.folder);
    if (session != null && session.isOpen) {
      final tag = session.isCutOff(effectiveNow)
          ? ' (cut off)'
          : session.possiblyInProgress(effectiveNow)
          ? ' (in progress)'
          : '';
      buffer.writeln('- Session: open$tag');
    }

    final decisionResults = await readAllDecisions(summary.folder, _files);
    final waiting = decisionResults
        .map((r) => r.decision)
        .whereType<Decision>()
        .where(_current)
        .where((d) => d.isProposed)
        .length;
    if (waiting > 0) {
      buffer.writeln('- Waiting for the user: $waiting decision(s)');
    }
  }

  if (hiddenCounts.isNotEmpty) {
    final parts = <String>[];
    for (final word in const ['on-hold', 'done', 'canceled']) {
      final count = hiddenCounts[word];
      if (count != null) parts.add('${statusLabel(word)} $count');
    }
    buffer
      ..writeln()
      ..writeln('## Out of sight')
      ..writeln(parts.join(' · '));
  }

  for (final skip in scan.skipped) {
    buffer
      ..writeln()
      ..writeln('## ${skip.folder} — could not be read')
      ..write(skip.reason);
  }

  return buffer.toString();
}

/// `asa-brief --since <date>` — everything any AI recorded across every
/// project since [since]: new change requests, proposed/`Scope: always`
/// decisions dated on or after it, and — from cp8's own local-change
/// history (ADR 0033) — every watched file that changed, flagged
/// *"changed, not logged"* when `isLoggedChange` finds no `.asa-log.md`
/// line on the same calendar day. Corrected 2026-09-29 — this comment
/// used to say cp8 "is not built yet," which stopped being true once cp8
/// landed and was never updated here; the drift-check drove past this
/// exact comment before catching that it, not the code, was stale.
Future<String> briefSince(
  String projectsRoot,
  DateTime since, {
  String? historyRoot,
}) async {
  final scan = await scanProjects(projectsRoot);
  final buffer = StringBuffer(
    '# asa-brief --since ${since.toIso8601String().split("T").first}\n',
  );

  final bossIntro = await _readBossIntro(projectsRoot);
  if (bossIntro != null) {
    buffer
      ..writeln()
      ..writeln('## Working with you')
      ..writeln()
      ..writeln(bossIntro);
  }

  var foundAnything = false;

  void writeHistoryLines(
    List<ChangeRecord> history,
    List<SessionLogEntry>? log,
  ) {
    for (final record in history.where((r) => !r.timestamp.isBefore(since))) {
      // A first-ever snapshot has nothing to compare against — that is
      // Asa noticing the file, not a change to it, so "changed, not
      // logged" (a real edit with no log line) doesn't apply to it.
      final logged = record.before == null || log == null
          ? ''
          : switch (isLoggedChange(record, log)) {
              LoggedMatch.yes => '',
              LoggedMatch.no => ' — changed, not logged',
              LoggedMatch.probably => ' — changed, probably logged',
            };
      final date = record.timestamp.toIso8601String().split('T').first;
      final verb = record.before == null ? 'first seen' : 'changed';
      final lineCounts = record.before == null
          ? '${record.linesAfter} line(s)'
          : '${record.linesBefore} line(s) before, ${record.linesAfter} after';
      buffer.writeln('- ${record.path} $verb ($date) — $lineCounts$logged');
    }
  }

  final rootHistory = await readChangeHistory(
    projectsRoot,
    isRoot: true,
    historyRoot: historyRoot,
  );
  final rootRecent = rootHistory.where((r) => !r.timestamp.isBefore(since));
  if (rootRecent.isNotEmpty) {
    foundAnything = true;
    buffer
      ..writeln()
      ..writeln('## BOSS.md / AGENTS.md');
    // No .asa-log.md to check these against — they sit next to every
    // project, not inside one, so "changed, not logged" doesn't apply.
    writeHistoryLines(rootHistory, null);
  }

  for (final summary in scan.projects) {
    final changes = await readChangeRequests(summary.folder, _files);
    final recentChanges = changes.where((c) => _onOrAfter(c.date, since));

    final decisionResults = await readAllDecisions(summary.folder, _files);
    final decisions = decisionResults
        .map((r) => r.decision)
        .whereType<Decision>();
    final recentDecisions = decisions.where(
      (d) =>
          _onOrAfter(d.date ?? '', since) &&
          (d.isProposed || d.links.scopeAlways),
    );

    final logEntries = await readSessionLog(summary.folder, _files);
    final recentLog = logEntries.where((e) => !e.date.isBefore(since));

    final history = await readChangeHistory(
      summary.folder,
      historyRoot: historyRoot,
    );
    final recentHistory = history.where((r) => !r.timestamp.isBefore(since));

    if (recentChanges.isEmpty &&
        recentDecisions.isEmpty &&
        recentLog.isEmpty &&
        recentHistory.isEmpty) {
      continue;
    }
    foundAnything = true;

    buffer
      ..writeln()
      ..writeln('## ${summary.project.name}');
    for (final c in recentChanges) {
      buffer.writeln(
        '- ${c.date} · change request, Round ${c.round}: ${c.what}',
      );
    }
    for (final d in recentDecisions) {
      buffer.writeln(
        '- ${d.date} · decision ADR ${d.number ?? "?"}: ${d.title}',
      );
    }
    for (final e in recentLog.toList().reversed) {
      buffer.writeln(
        '- ${e.date.toIso8601String().split("T").first} · ${e.text}',
      );
    }
    writeHistoryLines(history, logEntries);
  }

  if (!foundAnything) {
    buffer
      ..writeln()
      ..write('Nothing recorded since then.');
  }

  return buffer.toString();
}

bool _onOrAfter(String dateText, DateTime since) {
  final date = DateTime.tryParse(dateText.trim());
  if (date == null) return false;
  return !date.isBefore(since);
}
