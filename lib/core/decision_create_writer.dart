/// Round 43 §A/§C, ADR 0042 — creates a brand new decision, in whichever
/// of the two real shapes `decisions_reader.dart` already reads a project
/// might use: `decisions\NNNN-slug.md` (`AdrFolderSource`) or one more
/// `## NNNN - Title` section appended to `decisions.md`
/// (`DecisionLogSource`). Never edits an existing decision — that stays
/// `decision_writer.dart`'s own job (a verdict, append-only, ADR 0011).
/// Pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/slug.dart';
import 'package:asa/core/write_log.dart';

/// What creating a decision actually did — [sourceFile] and [number] on
/// success, a plain [error] a person could read when it didn't happen at
/// all (no file touched either way).
class DecisionCreateResult {
  const DecisionCreateResult({this.sourceFile, this.number, this.error});

  final String? sourceFile;
  final String? number;
  final String? error;

  bool get isSuccess => error == null;
}

final RegExp _adrFileNumber = RegExp(r'^(\d{3,5})-');
final RegExp _logHeadingNumber = RegExp(
  r'^##\s+(\d{3,5})\s*[-—]',
  multiLine: true,
);

/// Writes a new decision under [projectFolder] — a task's own "Decide…"
/// line (round-43.md §A), or the Log's own "＋ Decision" button (§C).
///
/// [decisionText] becomes the title, verbatim as typed. [why], [area],
/// [objectives], [tasks] and [files] are each optional and become the
/// file's own `## Why` paragraph and `**Links:**` segments — omitted
/// entirely when not given, never a guessed value. Always `**Decided
/// by:** the user` (ADR 0042: this writer exists so a human can move a
/// project forward without an AI in the room) and `**Status:** accepted`
/// — round-43.md names no "propose it instead" path for this entry
/// point; a decision typed by the user, by hand, is already their own
/// call, not a proposal waiting on one.
///
/// **Shape:** appends to `decisions.md` if the project already keeps one
/// (matching `DecisionLogSource`); otherwise writes a new
/// `decisions\NNNN-slug.md` (matching `AdrFolderSource`, and used for a
/// project with neither yet). The next number is the highest one already
/// used, in whichever shape is live, plus one.
Future<DecisionCreateResult> createDecision(
  String projectFolder, {
  required String decisionText,
  required DateTime date,
  String? why,
  String? area,
  List<String> objectives = const [],
  List<String> tasks = const [],
  List<String> files = const [],
  String? writeLogPath,
}) async {
  final trimmedText = decisionText.trim();
  if (trimmedText.isEmpty) {
    return const DecisionCreateResult(error: 'A decision needs some words.');
  }

  final sep = Platform.pathSeparator;
  final logFile = File('$projectFolder${sep}decisions.md');
  final usesLog = logFile.existsSync();

  final links = _buildLinks(
    area: area,
    objectives: objectives,
    tasks: tasks,
    files: files,
  );

  if (usesLog) {
    final existing = await logFile.readAsString();
    final number = (_highestNumber(_logHeadingNumber, existing) + 1)
        .toString()
        .padLeft(4, '0');
    final entry = _logEntry(
      number: number,
      title: trimmedText,
      date: date,
      why: why,
      links: links,
    );
    final prefix = existing.trimRight();
    final newContent = prefix.isEmpty ? '$entry\n' : '$prefix\n\n$entry\n';
    await _writeAtomically(logFile.path, newContent);
    await appendWriteLogEntry(
      path: logFile.path,
      field: 'decision-created',
      from: '',
      to: '$number — $trimmedText',
      logPath: writeLogPath,
    );
    return DecisionCreateResult(sourceFile: logFile.path, number: number);
  }

  final decisionsDir = Directory('$projectFolder${sep}decisions');
  final existingNames = decisionsDir.existsSync()
      ? decisionsDir
            .listSync()
            .whereType<File>()
            .map((f) => f.path.split(RegExp(r'[\\/]')).last)
            .toList()
      : <String>[];
  var highest = 0;
  for (final name in existingNames) {
    final match = _adrFileNumber.firstMatch(name);
    if (match == null) continue;
    final value = int.tryParse(match.group(1)!) ?? 0;
    if (value > highest) highest = value;
  }
  final number = (highest + 1).toString().padLeft(4, '0');

  final slug = _slugFor(trimmedText);
  if (slug.isEmpty) {
    return const DecisionCreateResult(
      error: 'That decision has no letters or numbers in it.',
    );
  }
  final targetPath = '${decisionsDir.path}$sep$number-$slug.md';
  if (File(targetPath).existsSync()) {
    return DecisionCreateResult(
      error:
          "ADR $number-$slug.md already exists — this shouldn't happen; "
          'check decisions$sep by hand.',
    );
  }

  final content = _adrFile(
    number: number,
    title: trimmedText,
    date: date,
    why: why,
    links: links,
  );

  await decisionsDir.create(recursive: true);
  await File(targetPath).writeAsString(content);
  await appendWriteLogEntry(
    path: targetPath,
    field: 'decision-created',
    from: '',
    to: '$number — $trimmedText',
    logPath: writeLogPath,
  );

  return DecisionCreateResult(sourceFile: targetPath, number: number);
}

/// A decision's own title, cut down to a filename — the first six words,
/// same shape `slugify` already applies everywhere else. A judgement
/// call, named rather than silent: round-43.md specifies the file shape
/// (`decisions\NNNN-short-slug.md`) but not how long "short" is; six
/// words keeps a typed sentence from becoming an unreadable filename
/// without a hard character cut landing mid-word.
String _slugFor(String text) {
  final words = text.trim().split(RegExp(r'\s+')).take(6).join(' ');
  return slugify(words);
}

int _highestNumber(RegExp pattern, String haystack) {
  var highest = 0;
  for (final match in pattern.allMatches(haystack)) {
    final value = int.tryParse(match.group(1)!) ?? 0;
    if (value > highest) highest = value;
  }
  return highest;
}

class _Links {
  const _Links({
    this.area,
    this.objectives = const [],
    this.tasks = const [],
    this.files = const [],
  });
  final String? area;
  final List<String> objectives;
  final List<String> tasks;
  final List<String> files;

  bool get isEmpty =>
      area == null && objectives.isEmpty && tasks.isEmpty && files.isEmpty;

  String toLine() {
    final segments = <String>[
      if (area != null) 'Area: $area',
      for (final o in objectives) 'Serves: Objective $o',
      for (final t in tasks) 'Task: $t',
      for (final f in files) 'File: $f',
    ];
    return segments.join(' · ');
  }
}

_Links _buildLinks({
  String? area,
  List<String> objectives = const [],
  List<String> tasks = const [],
  List<String> files = const [],
}) => _Links(area: area, objectives: objectives, tasks: tasks, files: files);

String _adrFile({
  required String number,
  required String title,
  required DateTime date,
  required _Links links,
  String? why,
}) {
  final buffer = StringBuffer()
    ..writeln('# ADR $number — $title')
    ..writeln()
    ..write('**Date:** ${_isoDate(date)} · **Status:** accepted')
    ..writeln()
    ..write('**Decided by:** the user');
  if (!links.isEmpty) {
    buffer
      ..writeln()
      ..write('**Links:** ${links.toLine()}');
  }
  buffer.writeln();
  if (why != null && why.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('## Why')
      ..writeln(why.trim());
  }
  buffer
    ..writeln()
    ..writeln('## Decision')
    ..writeln(title);
  return buffer.toString();
}

String _logEntry({
  required String number,
  required String title,
  required DateTime date,
  required _Links links,
  String? why,
}) {
  final buffer = StringBuffer()
    ..writeln('## $number - $title')
    ..writeln()
    ..write('**Date:** ${_isoDate(date)} · **Status:** accepted')
    ..writeln()
    ..write('**Decided by:** the user');
  if (!links.isEmpty) {
    buffer
      ..writeln()
      ..write('**Links:** ${links.toLine()}');
  }
  buffer.writeln();
  if (why != null && why.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('**Why:** ${why.trim()}');
  }
  return buffer.toString().trimRight();
}

Future<void> _writeAtomically(String path, String content) async {
  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(content);
  await tempFile.rename(path);
}

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
