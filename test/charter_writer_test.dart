// ADR 0050 — the single ＋ a project with no CHARTER.md at all gets. Real
// files, real disk, same style as area_section_writer_test.dart.

import 'dart:io';

import 'package:asa/core/charter.dart';
import 'package:asa/core/charter_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectFolder;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-charter-writer-test-');
    projectFolder = tempDir.path;
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('createCharterFile', () {
    test('writes the four fixed headings, each empty', () async {
      await createCharterFile(projectFolder, writeLogPath: logPath);

      final path = '$projectFolder${Platform.pathSeparator}CHARTER.md';
      expect(File(path).existsSync(), isTrue);
      expect(
        File(path).readAsStringSync(),
        '## Origin\n\n'
        "## Who it's for\n\n"
        '## Pain points\n\n'
        '## Objectives\n',
      );
    });

    test('readCharter reads the new file back as present but empty — the '
        "per-section ＋ places have something to attach to, nothing's "
        'invented yet', () async {
      await createCharterFile(projectFolder, writeLogPath: logPath);

      final strategy = await readCharter(projectFolder);
      expect(strategy.fileExists, isTrue);
      expect(strategy.isEmpty, isTrue);
      // An empty body between two headings reads as '', the same "no
      // real value" `_sectionField`'s own `hasValue` check already
      // treats like null — not the literal `isNull` a missing section
      // (or a missing file) reads as.
      expect(strategy.whoItsFor, '');
      expect(strategy.objectives, isEmpty);
    });

    test('refuses, unchanged, when CHARTER.md already exists', () async {
      final path = '$projectFolder${Platform.pathSeparator}CHARTER.md';
      const original = '## Origin\n\nReal content already here.\n';
      File(path).writeAsStringSync(original);

      await expectLater(
        () => createCharterFile(projectFolder, writeLogPath: logPath),
        throwsStateError,
      );
      expect(File(path).readAsStringSync(), original);
    });

    test('logs the creation', () async {
      await createCharterFile(projectFolder, writeLogPath: logPath);

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'charter-created');
      expect(entry.from, '');
      expect(entry.to, contains("Who it's for"));
    });
  });
}
