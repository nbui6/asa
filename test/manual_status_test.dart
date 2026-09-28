// Round 39 cp6 §2 — the manual's own sync status and git history,
// checked against the real repo.

import 'dart:io';

import 'package:asa/core/manual_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current.path;
  final sourcePath =
      '$repoRoot${Platform.pathSeparator}templates${Platform.pathSeparator}'
      'AGENTS.md';

  group('manualSyncStatus', () {
    test('matches when the installed copy is byte-identical', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'asa-manual-status-test-',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));
      final sourceText = File(sourcePath).readAsStringSync();
      File('${tempRoot.path}${Platform.pathSeparator}AGENTS.md')
          .writeAsStringSync(sourceText);

      final status = await manualSyncStatus(repoRoot, tempRoot.path);
      expect(status.matches, isTrue);
      expect(status.differingSections, isEmpty);
    });

    test('names the differing section when one changed', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'asa-manual-status-test-',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));
      final sourceText = File(sourcePath).readAsStringSync();
      final edited = sourceText.replaceFirst(
        '## 0. Your job',
        '## 0. Your job (edited for this test)',
      );
      File('${tempRoot.path}${Platform.pathSeparator}AGENTS.md')
          .writeAsStringSync(edited);

      final status = await manualSyncStatus(repoRoot, tempRoot.path);
      expect(status.matches, isFalse);
      expect(status.differingSections, isNotEmpty);
    });

    test('no installed copy at all is not a match', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'asa-manual-status-test-',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));
      final status = await manualSyncStatus(repoRoot, tempRoot.path);
      expect(status.matches, isFalse);
    });
  });

  group('manualLastChanged — against the real repo', () {
    test(
      'finds a real commit date and message for templates/AGENTS.md',
      () async {
        final result = await manualLastChanged(repoRoot);
        expect(result.date, isNotNull);
        expect(result.message, isNotNull);
        expect(result.message, isNotEmpty);
      },
    );

    test('no repo at that path reads as unknown, not an error', () async {
      final tempRoot = Directory.systemTemp.createTempSync(
        'asa-manual-status-test-',
      );
      addTearDown(() => tempRoot.deleteSync(recursive: true));
      final result = await manualLastChanged(tempRoot.path);
      expect(result.date, isNull);
      expect(result.message, isNull);
    });
  });
}
