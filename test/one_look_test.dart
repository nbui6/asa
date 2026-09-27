// Round 37, ADR 0029, finish line 2 — the mechanical half of "one look
// everywhere." Every file under `lib/hubs/product/` except `ui/` itself
// composes tokens.dart and the shared parts and writes none of its own:
// no literal colour, no literal text size, no `Card`, no shouting caps
// outside `SectionLabel`, no drop shadow. This test reads every such file
// as plain text and fails the build the moment one of those patterns
// reappears — the same shape as `check-boundaries.ps1`'s own `-SelfTest`,
// proving the gate still catches what it says it catches.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _bannedPatterns = [
  'Color(0x',
  'fontSize:',
  'Card(',
  '.toUpperCase()',
  'BoxShadow',
];

void main() {
  final allDartFiles =
      Directory('lib/hubs/product')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final pageFiles = allDartFiles
      .where((f) => !f.path.replaceAll(r'\', '/').contains('/hubs/product/ui/'))
      .toList();

  test(
    'the page files this round moved onto the shared parts really exist',
    () {
      // A self-check against a rename or reorganisation silently emptying
      // the very set this test is meant to police.
      expect(pageFiles, isNotEmpty);
      expect(
        pageFiles.map((f) => f.path.replaceAll(r'\', '/')),
        contains(contains('plan_view.dart')),
      );
    },
  );

  for (final file in pageFiles) {
    final relative = file.path.replaceAll(r'\', '/');

    test('$relative has none of the banned patterns', () {
      final content = file.readAsStringSync();
      final found = [
        for (final pattern in _bannedPatterns)
          if (content.contains(pattern)) pattern,
      ];
      expect(
        found,
        isEmpty,
        reason:
            '$relative still writes its own style directly: $found. '
            'Compose lib/hubs/product/ui/ instead — see tokens.dart.',
      );
    });
  }

  // Round 37 cp6 — a bare Checkbox takes the Theme's own seed colour
  // (found as a real purple leak against a real screenshot); the one
  // task_row.dart's own Checkbox sets its own activeColor, so nothing
  // else may build one of its own, ui/ included.
  for (final file in allDartFiles) {
    final relative = file.path.replaceAll(r'\', '/');
    if (relative.endsWith('ui/task_row.dart')) continue;

    test('$relative builds no Checkbox of its own', () {
      final content = file.readAsStringSync();
      expect(
        content.contains('Checkbox('),
        isFalse,
        reason:
            '$relative builds its own Checkbox — every checkbox is '
            'TaskRow (lib/hubs/product/ui/task_row.dart), so done always '
            'means the same green everywhere.',
      );
    });
  }

  test('ui/ itself is exempt — it is the one place these patterns belong', () {
    final uiDir = Directory('lib/hubs/product/ui');
    expect(uiDir.existsSync(), isTrue);
    final uiHasAnyStyle = uiDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .any((f) {
          final content = f.readAsStringSync();
          return _bannedPatterns.any(content.contains);
        });
    expect(uiHasAnyStyle, isTrue);
  });
}
