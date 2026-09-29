/// Round 38 §E — "a *since you were last here* line." Asa keeps, per
/// project, when the user last opened its Log, in `%APPDATA%\Asa\` — on
/// this laptop only, same as `settings.dart`'s own folder choice and
/// `write_log.dart`'s own write log. One flat JSON object, keyed by the
/// project's own folder path.
library;

import 'dart:convert';
import 'dart:io';

/// Where the log-visit file lives, or null when `APPDATA` is not set —
/// same honest-absence handling as `settingsFilePath`/`writeLogFilePath`.
String? logVisitFilePath() {
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return null;
  final sep = Platform.pathSeparator;
  return '$appData$sep' 'Asa$sep' 'log-visits.json';
}

/// When [projectFolder]'s Log was last opened, or null — never opened
/// yet, same as any project the first time it's seen. [path] overrides
/// the file for a test; production never passes it.
Future<DateTime?> lastLogVisit(String projectFolder, {String? path}) async {
  final resolved = path ?? logVisitFilePath();
  if (resolved == null) return null;

  final file = File(resolved);
  if (!file.existsSync()) return null;

  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;
    final value = decoded[projectFolder];
    if (value is! String) return null;
    return DateTime.tryParse(value);
  } on FormatException {
    return null;
  }
}

/// Records that [projectFolder]'s Log was just opened — merges into
/// whatever the file already holds for every other project, never
/// overwrites the whole file. [now] and [path] are for a test;
/// production never passes either.
Future<void> recordLogVisit(
  String projectFolder, {
  DateTime? now,
  String? path,
}) async {
  final resolved = path ?? logVisitFilePath();
  if (resolved == null) return;

  final file = File(resolved);
  var existing = <String, Object?>{};
  if (file.existsSync()) {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) existing = Map<String, Object?>.from(decoded);
    } on FormatException {
      existing = {};
    }
  }

  existing[projectFolder] = (now ?? DateTime.now()).toIso8601String();
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(existing));
}
