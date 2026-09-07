/// Asa's own settings — never a project note.
///
/// The chosen projects folder is written to `%APPDATA%\Asa\settings.json`.
/// This is the only thing this version writes anywhere. ADR 0007, which
/// would let Asa write into a project's own notes, is proposed and not
/// accepted — nothing here touches `projects\`.
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
