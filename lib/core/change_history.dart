/// Round 39 cp8 (ADR 0033, accepted in full) — Asa's own local change
/// history. `projects\` isn't in git, so an edit an AI makes without
/// logging it is invisible; this keeps a dated copy of every watched file
/// whenever it changes, on this laptop only. Pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/session_log.dart';

/// One real change this recorded: [path] (relative to the projects root,
/// so it reads the same on any laptop), when it was captured, and the
/// file's own content just before and just after — kept whole, not
/// diffed, so a caller can show exactly what changed rather than a
/// derived summary that might mislead.
class ChangeRecord {
  const ChangeRecord({
    required this.path,
    required this.timestamp,
    required this.before,
    required this.after,
  });

  final String path;
  final DateTime timestamp;

  /// Null for the very first snapshot ever taken of a file — there is no
  /// "before" yet, and that is not the same as an empty file.
  final String? before;
  final String after;

  int get linesBefore => before == null ? 0 : before!.split('\n').length;
  int get linesAfter => after.split('\n').length;
}

/// Where Asa's own change history lives, or null when `APPDATA` is not
/// set — same honest-absence handling as `settings.dart`/`write_log.dart`.
/// Never in git, never sent anywhere: the same folder as the write log.
String? changeHistoryRootPath() {
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return null;
  final sep = Platform.pathSeparator;
  return '$appData${sep}Asa${sep}history';
}

/// The files cp8 watches inside one project folder — a home note,
/// `CHARTER.md`, every `plan\*.md` page, every `decisions\*.md` file,
/// `rounds\APPROVED.md` and `rounds\CHANGES.md`. Only the ones that
/// actually exist; a project with no `CHARTER.md` yet has nothing to
/// watch there, not a missing-file error.
Future<List<File>> _watchedFiles(String projectFolder) async {
  final dir = Directory(projectFolder);
  if (!dir.existsSync()) return const [];
  final sep = Platform.pathSeparator;
  final watched = <File>[];

  final name = dir.path.split(RegExp(r'[\\/]')).last;
  final homeNote = File('$projectFolder$sep$name.md');
  if (homeNote.existsSync()) watched.add(homeNote);

  final charter = File('$projectFolder${sep}CHARTER.md');
  if (charter.existsSync()) watched.add(charter);

  final planDir = Directory('$projectFolder${sep}plan');
  if (planDir.existsSync()) {
    for (final entity in planDir.listSync()) {
      if (entity is File && entity.path.endsWith('.md')) watched.add(entity);
    }
  }

  final decisionsDir = Directory('$projectFolder${sep}decisions');
  if (decisionsDir.existsSync()) {
    for (final entity in decisionsDir.listSync()) {
      if (entity is File && entity.path.endsWith('.md')) watched.add(entity);
    }
  }

  final approved = File('$projectFolder${sep}rounds${sep}APPROVED.md');
  if (approved.existsSync()) watched.add(approved);

  final changes = File('$projectFolder${sep}rounds${sep}CHANGES.md');
  if (changes.existsSync()) watched.add(changes);

  return watched;
}

/// The projects-root-level files cp8 also watches, per the deciding
/// session's own 2026-09-28 note: `BOSS.md` and `AGENTS.md` sit next to
/// every project, not inside one, and an unlogged edit to either is just
/// as invisible.
Future<List<File>> watchedRootFiles(String projectsRoot) async {
  final sep = Platform.pathSeparator;
  final watched = <File>[];
  for (final name in ['BOSS.md', 'AGENTS.md']) {
    final file = File('$projectsRoot$sep$name');
    if (file.existsSync()) watched.add(file);
  }
  return watched;
}

/// A safe, stable folder name for one real file's history — the relative
/// path under the projects root, with every path separator turned into
/// `_` so it is one flat folder name, never a nested folder a caller has
/// to create by hand.
String _historyKey(String projectsRoot, String filePath) {
  var relative = filePath;
  if (relative.startsWith(projectsRoot)) {
    relative = relative.substring(projectsRoot.length);
  }
  return relative
      .replaceAll(RegExp(r'^[\\/]+'), '')
      .replaceAll(RegExp(r'[\\/]+'), '_');
}

/// One snapshot file's own shape: the ISO timestamp on its first line, a
/// blank line, then the file's content verbatim — simple and fully
/// reversible, unlike trying to encode a timestamp into a Windows-legal
/// filename (`:` isn't one).
String _encodeSnapshot(DateTime timestamp, String content) =>
    '${timestamp.toIso8601String()}\n\n$content';

({DateTime timestamp, String content})? _decodeSnapshot(String raw) {
  final firstBreak = raw.indexOf('\n\n');
  if (firstBreak == -1) return null;
  final timestamp = DateTime.tryParse(raw.substring(0, firstBreak));
  if (timestamp == null) return null;
  return (timestamp: timestamp, content: raw.substring(firstBreak + 2));
}

/// Snapshots every watched file that actually changed since the last
/// snapshot, for one project's own files (pass its folder as
/// [projectFolder]) or, with [watchedRootFiles]'s own files instead
/// (pass the projects root as [projectFolder] and [isRoot]: true).
/// Returns one [ChangeRecord] per file that changed; a file identical to
/// its own last snapshot is silently skipped — recording nothing is the
/// normal case on a second look.
///
/// **Never stores a file from outside the projects root** — every path
/// this reads comes from inside [projectFolder], itself always somewhere
/// under [projectsRoot]; nothing here ever takes an arbitrary path from
/// a caller.
Future<List<ChangeRecord>> recordChanges(
  String projectFolder,
  String projectsRoot, {
  bool isRoot = false,
  String? historyRoot,
  DateTime? now,
}) async {
  final root = historyRoot ?? changeHistoryRootPath();
  if (root == null) {
    throw StateError('APPDATA is not set — cannot record change history');
  }
  final effectiveNow = now ?? DateTime.now();
  final files = isRoot
      ? await watchedRootFiles(projectFolder)
      : await _watchedFiles(projectFolder);

  final projectName = isRoot
      ? '_root'
      : projectFolder.split(RegExp(r'[\\/]')).last;
  final projectHistoryDir = '$root${Platform.pathSeparator}$projectName';

  final records = <ChangeRecord>[];

  for (final file in files) {
    final key = _historyKey(projectsRoot, file.path);
    final fileHistoryDir = Directory(
      '$projectHistoryDir${Platform.pathSeparator}$key',
    );
    final after = await file.readAsString();

    String? before;
    var existing = const <File>[];
    if (fileHistoryDir.existsSync()) {
      existing = fileHistoryDir.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (existing.isNotEmpty) {
        final decoded = _decodeSnapshot(await existing.last.readAsString());
        before = decoded?.content;
        if (before == after) continue; // unchanged since last look
      }
    }

    await fileHistoryDir.create(recursive: true);
    final index = existing.length + 1;
    final fileName = index.toString().padLeft(6, '0');
    await File(
      '${fileHistoryDir.path}${Platform.pathSeparator}$fileName.snapshot',
    ).writeAsString(_encodeSnapshot(effectiveNow, after));

    records.add(
      ChangeRecord(
        path: key.replaceAll('_', Platform.pathSeparator),
        timestamp: effectiveNow,
        before: before,
        after: after,
      ),
    );
  }

  return records;
}

/// Reads back every change recorded for one project (or, with [isRoot],
/// the projects-root files), oldest first — straight from the snapshots
/// [recordChanges] already wrote; no file is re-read to produce this.
Future<List<ChangeRecord>> readChangeHistory(
  String projectFolder, {
  bool isRoot = false,
  String? historyRoot,
}) async {
  final root = historyRoot ?? changeHistoryRootPath();
  if (root == null) return const [];

  final projectName = isRoot
      ? '_root'
      : projectFolder.split(RegExp(r'[\\/]')).last;
  final projectHistoryDir = Directory(
    '$root${Platform.pathSeparator}$projectName',
  );
  if (!projectHistoryDir.existsSync()) return const [];

  final records = <ChangeRecord>[];
  for (final entity in projectHistoryDir.listSync()) {
    if (entity is! Directory) continue;
    final key = entity.path.split(Platform.pathSeparator).last;
    final snapshots = entity.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    String? before;
    for (final snapshot in snapshots) {
      final decoded = _decodeSnapshot(await snapshot.readAsString());
      if (decoded == null) continue;
      records.add(
        ChangeRecord(
          path: key.replaceAll('_', Platform.pathSeparator),
          timestamp: decoded.timestamp,
          before: before,
          after: decoded.content,
        ),
      );
      before = decoded.content;
    }
  }

  records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return records;
}

/// [isLoggedChange]'s own answer — three states, never collapsed to a
/// bool: a real match is not the same claim as a fallback guess, and
/// showing them the same way is exactly the gap ADR 0048 (2026-09-29)
/// found. [probably] is the whole reason this is not a bool.
enum LoggedMatch { yes, no, probably }

/// A same-day log line that never names a single file at all — the
/// shape a line had before §7.11's own convention (or one that dropped
/// it) — vs. one that does name at least one, in the current shape or
/// not. Deliberately loose (any `word.ext`-shaped token), matching this
/// file's own general policy of reading a real line's shape rather than
/// re-parsing it into fields that don't always apply.
final RegExp _looksLikeAFileName = RegExp(r'\S+\.\w{1,6}\b');

/// Whether [record] has a matching `.asa-log.md` line. **Corrected**
/// (ADR 0048, 2026-09-29, after the drill's own step 6 found the gap): a
/// change counts as logged when a same-day line actually **names that
/// file** — §7.11's own line shape ends with the files written — not
/// merely when *something* was logged that day. Two edits to different
/// files on the same day used to read as identically "logged" either
/// way; only the specifically named one does now. Day alone survives as
/// a fallback only for a same-day line that names no file at all (an
/// older line, before this convention, or one that dropped it) —
/// [LoggedMatch.probably], never claimed with the same certainty as a
/// real name match.
LoggedMatch isLoggedChange(ChangeRecord record, List<SessionLogEntry> log) {
  final sameDay = log.where(
    (entry) =>
        entry.date.year == record.timestamp.year &&
        entry.date.month == record.timestamp.month &&
        entry.date.day == record.timestamp.day,
  );
  if (sameDay.isEmpty) return LoggedMatch.no;

  final fileName = record.path.split(RegExp(r'[\\/]')).last;
  if (sameDay.any((entry) => entry.text.contains(fileName))) {
    return LoggedMatch.yes;
  }

  final anyLineNamesFiles = sameDay.any(
    (entry) => _looksLikeAFileName.hasMatch(entry.text),
  );
  return anyLineNamesFiles ? LoggedMatch.no : LoggedMatch.probably;
}
