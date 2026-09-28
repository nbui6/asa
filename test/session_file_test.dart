// Round 39 cp3 — a project's own `.asa-session.md`.

import 'package:asa/core/session_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSessionFile', () {
    test('no frontmatter block at all reads as null, not a guess', () {
      expect(parseSessionFile('Just some text.\n'), isNull);
    });

    test('a real open session, every field present', () {
      const text = '''
---
status: open
opened: 2026-09-28T15:00:00
opened-by: claude-desktop
updated: 2026-09-28T15:40:00
---
Doing: cp3, asa-brief
Last done: cp2, the Links: line
Next: cp4, asa-check
''';
      final session = parseSessionFile(text)!;
      expect(session.status, 'open');
      expect(session.isOpen, isTrue);
      expect(session.openedBy, 'claude-desktop');
      expect(session.opened, DateTime.parse('2026-09-28T15:00:00'));
      expect(session.updated, DateTime.parse('2026-09-28T15:40:00'));
      expect(session.doing, 'cp3, asa-brief');
      expect(session.lastDone, 'cp2, the Links: line');
      expect(session.next, 'cp4, asa-check');
    });

    test('a closed session reads as closed, not open', () {
      const text = '''
---
status: closed
opened: 2026-09-27T10:00:00
---
Doing:
Last done: shipped Round 38
Next:
''';
      final session = parseSessionFile(text)!;
      expect(session.isOpen, isFalse);
      expect(session.lastDone, 'shipped Round 38');
      expect(session.doing, isNull, reason: 'a blank body line is absence');
    });

    test('anything other than exactly "open" reads as closed, the safe '
        'default', () {
      const text = '---\nstatus: something-else\n---\n';
      expect(parseSessionFile(text)!.isOpen, isFalse);
    });

    test('missing body lines are null, not empty strings', () {
      const text = '---\nstatus: open\n---\n';
      final session = parseSessionFile(text)!;
      expect(session.doing, isNull);
      expect(session.lastDone, isNull);
      expect(session.next, isNull);
    });
  });

  group("possiblyInProgress — the manual's own 2-hour rule", () {
    test('open and updated less than 2 hours ago — maybe still working', () {
      final session = SessionFile(
        status: 'open',
        updated: DateTime(2026, 9, 28, 14),
      );
      expect(session.possiblyInProgress(DateTime(2026, 9, 28, 15)), isTrue);
    });

    test('open but updated 2 hours ago or more — not in progress', () {
      final session = SessionFile(
        status: 'open',
        updated: DateTime(2026, 9, 28, 13),
      );
      expect(session.possiblyInProgress(DateTime(2026, 9, 28, 15)), isFalse);
    });

    test('closed sessions are never "possibly in progress"', () {
      final session = SessionFile(
        status: 'closed',
        updated: DateTime(2026, 9, 28, 14, 59),
      );
      expect(session.possiblyInProgress(DateTime(2026, 9, 28, 15)), isFalse);
    });

    test('no opened or updated timestamp at all — never in progress, never '
        'a guess', () {
      const session = SessionFile(status: 'open');
      expect(session.possiblyInProgress(DateTime(2026, 9, 28, 15)), isFalse);
    });

    test('falls back to opened when updated is missing', () {
      final session = SessionFile(
        status: 'open',
        opened: DateTime(2026, 9, 28, 14, 30),
      );
      expect(session.possiblyInProgress(DateTime(2026, 9, 28, 15)), isTrue);
    });
  });

  group('isCutOff — the drill\'s own "arrive after 3 days" case', () {
    test('open and silent for 2+ hours is cut off', () {
      final session = SessionFile(
        status: 'open',
        updated: DateTime(2026, 9, 25, 9),
      );
      expect(session.isCutOff(DateTime(2026, 9, 28, 9)), isTrue);
    });

    test('closed sessions are never cut off — that only means "left open"', () {
      final session = SessionFile(
        status: 'closed',
        updated: DateTime(2026, 9, 25, 9),
      );
      expect(session.isCutOff(DateTime(2026, 9, 28, 9)), isFalse);
    });

    test('open and recent is not cut off', () {
      final session = SessionFile(
        status: 'open',
        updated: DateTime(2026, 9, 28, 14, 30),
      );
      expect(session.isCutOff(DateTime(2026, 9, 28, 15)), isFalse);
    });
  });
}
