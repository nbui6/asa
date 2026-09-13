/// Asa's own settings — never a project note.
///
/// The chosen projects folder is written to `%APPDATA%\Asa\settings.json`.
///
/// **Corrected 2026-09-13:** this used to say settings were the only
/// thing Asa writes, and that ADR 0007 (writing into a project's own
/// notes) was proposed and not accepted. Both were stale — ADR 0007 was
/// accepted 2026-09-01, and `task_writer.dart`/`project_writer.dart` now
/// write checkbox lines and the five whitelisted frontmatter fields.
/// `write_log.dart`'s write log lives in this same `%APPDATA%\Asa\`
/// folder, next to this file, for the same reason: Asa's own operating
/// state, never `projects\`.
///
/// No new package: `dart:convert`, part of the Dart SDK, is enough for one
/// flat JSON object.
library;

import 'dart:convert';
import 'dart:io';

class Settings {
  const Settings({this.projectsFolder});

  final String? projectsFolder;
}

/// Where the settings file lives, or null when `APPDATA` is not set — which
/// should not happen on Windows, but a missing environment variable is a
/// fact to report, not a reason to crash.
String? settingsFilePath() {
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return null;
  final sep = Platform.pathSeparator;
  return '$appData$sep'
      'Asa$sep'
      'settings.json';
}

/// Reads the saved settings from [path], or from the real settings file
/// when [path] is omitted. A missing or unreadable file is not an error —
/// it means nobody has chosen a folder yet, which is the normal first run.
Future<Settings> readSettings({String? path}) async {
  final resolved = path ?? settingsFilePath();
  if (resolved == null) return const Settings();

  final file = File(resolved);
  if (!file.existsSync()) return const Settings();

  try {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return const Settings();
    final folder = decoded['projectsFolder'];
    return Settings(projectsFolder: folder is String ? folder : null);
  } on FormatException {
    // A settings file that cannot be parsed is treated like no settings at
    // all — the picker asks again, rather than the app failing to start.
    return const Settings();
  }
}

/// Writes [settings] to [path], or to the real settings file when [path]
/// is omitted. Creates `%APPDATA%\Asa\` if it does not exist yet.
Future<void> writeSettings(Settings settings, {String? path}) async {
  final resolved = path ?? settingsFilePath();
  if (resolved == null) {
    throw StateError('APPDATA is not set — cannot save settings');
  }

  final file = File(resolved);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode({'projectsFolder': settings.projectsFolder}),
  );
}
