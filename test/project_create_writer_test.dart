// Real files, real disk — same style as area_writer_test.dart.

import 'dart:io';

import 'package:asa/core/project_create_writer.dart';
import 'package:asa/core/write_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String projectsRoot;
  late String noteTemplatePath;
  late String howAsaWorksTemplatePath;
  late String logPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-project-create-test-');
    projectsRoot = '${tempDir.path}${Platform.pathSeparator}projects';
    Directory(projectsRoot).createSync(recursive: true);
    noteTemplatePath = '${tempDir.path}${Platform.pathSeparator}note.md';
    File(noteTemplatePath).writeAsStringSync(
      '---\nproject: \nstatus: idea\npriority: \nparent: \ndeadline: \n'
      'jira: \nnext-step: \nrepo-path: \nupdated: \n---\n\n# \n\n'
      '## Tasks\n',
    );
    howAsaWorksTemplatePath =
        '${tempDir.path}${Platform.pathSeparator}'
        'HOW-ASA-WORKS.md';
    File(howAsaWorksTemplatePath)
        .writeAsStringSync('# How Asa works\n\nRead AGENTS.md.\n');
    logPath = '${tempDir.path}${Platform.pathSeparator}write-log.jsonl';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('createProject', () {
    test(
      r'writes projects\<slug>\<slug>.md from the template, name and '
      "status: idea filled in, plus the project's own HOW-ASA-WORKS.md",
      () async {
        final result = await createProject(
          projectsRoot,
          'Data Retention',
          projectNoteTemplatePath: noteTemplatePath,
          howAsaWorksTemplatePath: howAsaWorksTemplatePath,
          writeLogPath: logPath,
        );

        expect(result.isSuccess, isTrue);
        expect(
          result.folder,
          '$projectsRoot${Platform.pathSeparator}data-retention',
        );
        final note = File(result.sourceFile!);
        expect(note.existsSync(), isTrue);
        expect(
          note.path,
          endsWith(
            '${Platform.pathSeparator}data-retention'
            '${Platform.pathSeparator}data-retention.md',
          ),
        );
        final text = note.readAsStringSync();
        expect(text, contains('project: Data Retention'));
        expect(text, contains('status: idea'));
        expect(text, contains('# Data Retention'));
        expect(text, contains('## Tasks'));

        final howAsaWorks = File(
          '${result.folder}${Platform.pathSeparator}HOW-ASA-WORKS.md',
        );
        expect(howAsaWorks.existsSync(), isTrue);
        expect(howAsaWorks.readAsStringSync(), contains('How Asa works'));
      },
    );

    test('refuses an empty name, writes nothing', () async {
      final result = await createProject(
        projectsRoot,
        '   ',
        projectNoteTemplatePath: noteTemplatePath,
        howAsaWorksTemplatePath: howAsaWorksTemplatePath,
      );
      expect(result.isSuccess, isFalse);
      expect(Directory(projectsRoot).listSync(), isEmpty);
    });

    test('refuses a name with a forbidden path character, naming it', () async {
      final result = await createProject(
        projectsRoot,
        'Data/Retention',
        projectNoteTemplatePath: noteTemplatePath,
        howAsaWorksTemplatePath: howAsaWorksTemplatePath,
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('/'));
      expect(Directory(projectsRoot).listSync(), isEmpty);
    });

    test('refuses a Windows reserved name, case-insensitively', () async {
      final result = await createProject(
        projectsRoot,
        'con',
        projectNoteTemplatePath: noteTemplatePath,
        howAsaWorksTemplatePath: howAsaWorksTemplatePath,
      );
      expect(result.isSuccess, isFalse);
      expect(Directory(projectsRoot).listSync(), isEmpty);
    });

    test('refuses when the slug already exists, writes nothing new', () async {
      Directory('$projectsRoot${Platform.pathSeparator}data-retention')
          .createSync();

      final result = await createProject(
        projectsRoot,
        'Data Retention',
        projectNoteTemplatePath: noteTemplatePath,
        howAsaWorksTemplatePath: howAsaWorksTemplatePath,
      );
      expect(result.isSuccess, isFalse);
      expect(
        Directory('$projectsRoot${Platform.pathSeparator}data-retention')
            .listSync(),
        isEmpty,
      );
    });

    test('logs the write', () async {
      final result = await createProject(
        projectsRoot,
        'Data Retention',
        projectNoteTemplatePath: noteTemplatePath,
        howAsaWorksTemplatePath: howAsaWorksTemplatePath,
        writeLogPath: logPath,
      );

      final entry = (await readWriteLog(logPath: logPath)).single;
      expect(entry.field, 'project-created');
      expect(entry.from, '');
      expect(entry.to, 'Data Retention');
      expect(entry.path, result.sourceFile);
    });
  });
}
