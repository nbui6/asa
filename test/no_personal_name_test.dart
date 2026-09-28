// Round 39 cp9 — "the tool is neutral: no personal name in what ships."
// Same shape as `one_look_test.dart`: reads real files as plain text and
// fails the moment the one banned word reappears, rather than trusting
// that a one-time sweep stays true.
//
// Scanned: `lib\`, `bin\`, `test\`, `templates\`, `kit\` — exactly the five
// round-39.md cp9 names. Whole word, any case, per its own instruction.
//
// **The allowlist below is not a loophole — every entry is a place the
// name has to appear, named so it can be checked, same discipline
// `check-shareable.ps1`'s own waiver already uses:**
// - `kit\package-for-tester.ps1` is the tool that scrubs the name out of a
//   packaged copy — its own source has to contain the word to search for.
// - Four lines quote something verbatim: a rule exactly as it was written
//   at the time (`kit\PLAYBOOK.md`, `kit\CHANGELOG.md`, `kit\KIT-LOG.md`),
//   and a historical bug capture showing exactly what a file really said
//   (`kit\KIT-LOG.md`). Rewriting a quotation to sanitize it is the thing
//   hard rule 9 ("fix the encoding, never the assertion") already exists
//   to stop.
//
// This file's own path is under `test\` too, and its source necessarily
// contains the word inside the regex pattern below — excluded from the
// scan by name, not by accident.
//
// The four exact-line quotes below can't be wrapped without changing the
// string they have to match byte-for-byte, so line length is off file-wide.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _wholeWord = RegExp(r'\bnico\b', caseSensitive: false);

const _scannedDirs = ['lib', 'bin', 'test', 'templates', 'kit'];

const _wholeFileExceptions = {
  'kit/package-for-tester.ps1',
  'test/no_personal_name_test.dart',
};

/// Every other line the guard would otherwise flag — matched by its own
/// trimmed content, not a line number, so a later edit that moves the line
/// doesn't silently stop checking it.
const _lineExceptions = {
  "A rule read: *\"Nico runs every `git` and `flutter` command himself. Never through an assistant's",
  '> *"Nico runs every `git` and `flutter` command himself, in Windows PowerShell. Never through an',
  'first implementation - it captured `"accepted - **Decided by:** Nico"` as the status), the inline',
  "Any. And the project's own `CLAUDE.md` already carried the finding — *\"Nico often lacks admin",
};

void main() {
  test('the five scanned folders really exist — a self-check against a '
      'rename silently emptying what this test polices', () {
    for (final dir in _scannedDirs) {
      expect(Directory(dir).existsSync(), isTrue, reason: '$dir is missing');
    }
  });

  test('no personal name in what ships', () {
    final violations = <String>[];

    for (final dirName in _scannedDirs) {
      final dir = Directory(dirName);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        // `Directory(dirName).listSync()` returns paths already prefixed
        // with `dirName` itself — just normalize the separator.
        final scopedPath = entity.path.replaceAll(r'\', '/');
        if (_wholeFileExceptions.contains(scopedPath)) continue;

        String content;
        try {
          content = entity.readAsStringSync();
        } on FormatException {
          continue; // a binary file (e.g. a packaged .zip) — nothing to read as text
        }

        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (!_wholeWord.hasMatch(line)) continue;
          if (_lineExceptions.contains(line.trim())) continue;
          violations.add('$scopedPath:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'the tool must stay neutral — every line below either names the '
          "person or needs adding to this test's own allowlist, with a "
          'reason:\n${violations.join('\n')}',
    );
  });
}
