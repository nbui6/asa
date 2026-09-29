// Real files, real disk — same style as task_writer_test.dart.

import 'dart:io';

import 'package:asa/core/area_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectFolder;
  late String templatePath;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-area-writer-test-');
    projectFolder = '${tempDir.path}${Platform.pathSeparator}demo';
    Directory(projectFolder).createSync(recursive: true);
    templatePath = '${tempDir.path}${Platform.pathSeparator}area.md';
    File(templatePath).writeAsStringSync(
      '# Name\n\n## Goal\n\n## Plan\n\n## Tasks\n\n## Results\n\n'
      '## Decisions\n',
    );
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('slugifyAreaName', () {
    test('lowercases and dashes', () {
      expect(slugifyAreaName('Finance'), 'finance');
      expect(slugifyAreaName('Q4 Ops & Runway'), 'q4-ops-runway');
    });

    test('trims leading and trailing dashes', () {
      expect(slugifyAreaName('  -Finance-  '), 'finance');
    });

    test('a name with no letters or numbers slugs to empty', () {
      expect(slugifyAreaName('---'), '');
      expect(slugifyAreaName(''), '');
    });
  });

  group('createArea', () {
    test(r'writes plan\<slug>.md from the template, title filled in', () async {
      final result = await createArea(
        projectFolder,
        'Finance',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      expect(result.isSuccess, isTrue);
      final written = File(result.sourceFile!);
      expect(written.existsSync(), isTrue);
      expect(written.path, endsWith('${Platform.pathSeparator}finance.md'));
      final text = written.readAsStringSync();
      expect(text, startsWith('# Finance\n'));
      expect(text, contains('## Goal'));
      expect(text, contains('## Decisions'));
    });

    test('refuses a name that already exists, and says so', () async {
      await createArea(
        projectFolder,
        'Finance',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      final second = await createArea(
        projectFolder,
        'finance',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      expect(second.isSuccess, isFalse);
      expect(second.error, contains('already exists'));
    });

    test('never touches an existing area page', () async {
      final planDir = Directory('$projectFolder${Platform.pathSeparator}plan')
        ..createSync(recursive: true);
      final existing = File(
        '${planDir.path}${Platform.pathSeparator}finance.md',
      );
      const originalText = '# Finance\n\nSomething real, already here.\n';
      existing.writeAsStringSync(originalText);

      final result = await createArea(
        projectFolder,
        'Finance',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      expect(result.isSuccess, isFalse);
      expect(existing.readAsStringSync(), originalText);
    });

    test('refuses a name with no letters or numbers, writes nothing', () async {
      final result = await createArea(
        projectFolder,
        '---',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      expect(result.isSuccess, isFalse);
      expect(
        Directory('$projectFolder${Platform.pathSeparator}plan').existsSync(),
        isFalse,
      );
    });

    test('logs the write', () async {
      await createArea(
        projectFolder,
        'Finance',
        templatePath: templatePath,
        writeLogPath: logPath,
      );

      final log = await readWriteLog(logPath: logPath);
      expect(log, hasLength(1));
      expect(log.first.field, 'area-created');
      expect(log.first.to, 'Finance');
    });
  });
}
