// Real files, real disk — same style as area_writer_test.dart.

import 'dart:io';

import 'package:asa/core/repo_remote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String repoPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-repo-remote-test-');
    repoPath = tempDir.path;
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  void writeConfig(String text) {
    final gitDir = Directory('$repoPath${Platform.pathSeparator}.git')
      ..createSync();
    File('${gitDir.path}${Platform.pathSeparator}config')
        .writeAsStringSync(text);
  }

  group('repoRemoteUrl', () {
    test("reads the origin remote's own URL, real shape", () {
      writeConfig('''
[core]
\trepositoryformatversion = 0
\tfilemode = false
[remote "origin"]
\turl = https://github.com/nbui6/asa.git
\tfetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
\tremote = origin
''');
      expect(repoRemoteUrl(repoPath), 'https://github.com/nbui6/asa.git');
    });

    test('an ssh-style remote is read the same way', () {
      writeConfig('''
[remote "origin"]
\turl = git@github.com:nbui6/asa.git
''');
      expect(repoRemoteUrl(repoPath), 'git@github.com:nbui6/asa.git');
    });

    test('no .git folder at all returns null, never a guess', () {
      expect(repoRemoteUrl(repoPath), isNull);
    });

    test('a .git/config with no origin remote returns null', () {
      writeConfig('[core]\n\tbare = false\n');
      expect(repoRemoteUrl(repoPath), isNull);
    });

    test("a different remote's own URL is never read as origin's", () {
      writeConfig('''
[remote "upstream"]
\turl = https://github.com/someone-else/asa.git
''');
      expect(repoRemoteUrl(repoPath), isNull);
    });
  });
}
