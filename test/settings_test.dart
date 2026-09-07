// Tests for the settings round-trip: write, read, missing file.
//
// Settings is the one thing this version writes, and it writes to
// `%APPDATA%\Asa\settings.json` — never a project note. These tests point
// at a temp folder instead, via the optional `path` parameter, so they
// never touch the real settings file.

import 'dart:io';

import 'package:asa/core/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-settings-test-');
    path = '${tempDir.path}${Platform.pathSeparator}settings.json';
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test(
    'a missing file reads as no folder chosen — the normal first run',
    () async {
      final settings = await readSettings(path: path);
      expect(settings.projectsFolder, isNull);
    },
  );

  test('writes and reads back the chosen folder', () async {
    await writeSettings(
      const Settings(projectsFolder: r'C:\Users\test\workspace\projects'),
      path: path,
    );

    final settings = await readSettings(path: path);
    expect(settings.projectsFolder, r'C:\Users\test\workspace\projects');
  });

  test('creates the parent folder if it does not exist yet', () async {
    final sep = Platform.pathSeparator;
    final nestedPath =
        '${tempDir.path}$sep'
        'Asa$sep'
        'settings.json';

    await writeSettings(const Settings(projectsFolder: 'x'), path: nestedPath);

    expect(File(nestedPath).existsSync(), isTrue);
  });

  test('a file that is not valid JSON reads as no folder chosen', () async {
    await File(path).writeAsString('not json');
    final settings = await readSettings(path: path);
    expect(settings.projectsFolder, isNull);
  });

  test(r'settingsFilePath ends in Asa\settings.json under APPDATA', () {
    final resolved = settingsFilePath();
    if (Platform.environment['APPDATA'] == null) {
      expect(resolved, isNull);
    } else {
      expect(resolved, endsWith('Asa${Platform.pathSeparator}settings.json'));
    }
  });
}
