/// The append-only write log every write in this app goes through — ADR
/// 0007 guardrail 3: "every write is logged — what, when, which file. The
/// Log tab shows it." Rounds 8 and 9 shipped checkbox writes
/// (`task_writer.dart`) with no log of any kind; this closes that gap for
/// every writer in `core/`, not only the new field writes Round 19 adds.
///
/// Lives next to the settings store, in `%APPDATA%\Asa\` — Asa's own
/// operating record, not project content, so it never sits inside
/// `projects\` and never enters this repository.
library;

import 'dart:convert';
import 'dart:io';

/// One line: when, which file, which field, what it was, what it became.
class WriteLogEntry {
  const WriteLogEntry({
    required this.timestamp,
    required this.path,
    required this.field,
    required this.from,
    required this.to,
  });

  final DateTime timestamp;

  /// The file this write touched.
  final String path;

  /// What was written — a frontmatter field name (`status`, `deadline`,
  /// …) for a Round 19 write, or a description of the checkbox change
  /// (`task-done`, `task-parked`, `task-captured`, `task-added`,
  /// `task-removed`) for a retrofitted one. Free text, not a whitelist —
  /// the whitelist that matters is `project_writer.dart`'s, which gates
  /// what may be written, not what may be logged.
  final String field;

  final String from;
  final String to;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'path': path,
    'field': field,
    'from': from,
    'to': to,
  };
}

/// Where the write log lives, or null when `APPDATA` is not set — same
/// honest-absence handling as `settings.dart`'s own `settingsFilePath`.
String? writeLogFilePath() {
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return null;
  final sep = Platform.pathSeparator;
  return '$appData$sep'
      'Asa$sep'
      'write-log.jsonl';
}

/// Appends one entry — never rewrites or removes a line already there.
/// Creates the log file and its folder if neither exists yet.
///
/// Throws a [StateError] when neither [logPath] nor `APPDATA` resolves a
/// location — same choice `settings.dart`'s `writeSettings` makes for the
/// same situation: guardrail 3 is "every write is logged," not "every
/// write is logged when convenient."
Future<void> appendWriteLogEntry({
  required String path,
  required String field,
  required String from,
  required String to,
  DateTime? timestamp,
  String? logPath,
}) async {
  final resolved = logPath ?? writeLogFilePath();
  if (resolved == null) {
    throw StateError('APPDATA is not set — cannot write the write log');
  }

  final entry = WriteLogEntry(
    timestamp: timestamp ?? DateTime.now(),
    path: path,
    field: field,
    from: from,
    to: to,
  );

  final file = File(resolved);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${jsonEncode(entry.toJson())}\n',
    mode: FileMode.append,
  );
}

/// Reads every entry back, in the order they were appended — oldest
/// first, same as the file itself. An absent log file reads as no
/// entries yet, not an error; nothing has been written through it.
Future<List<WriteLogEntry>> readWriteLog({String? logPath}) async {
  final resolved = logPath ?? writeLogFilePath();
  if (resolved == null) return const [];

  final file = File(resolved);
  if (!file.existsSync()) return const [];

  final lines = await file.readAsLines();
  return [
    for (final line in lines)
      if (line.trim().isNotEmpty)
        _entryFromJson(jsonDecode(line) as Map<String, dynamic>),
  ];
}

WriteLogEntry _entryFromJson(Map<String, dynamic> json) {
  return WriteLogEntry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    path: json['path'] as String,
    field: json['field'] as String,
    from: json['from'] as String,
    to: json['to'] as String,
  );
}
