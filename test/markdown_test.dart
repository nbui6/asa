import 'package:asa/core/markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sectionText — a sub-heading does not end its own parent section', () {
    test('a ### inside a ## section stays part of it; the next ## ends it — '
        "real shape once roadmap.dart's phases exist inside ## Roadmap", () {
      const body = '''
## Roadmap

### Foundation

- [ ] Round 0

## Tasks

- [ ] Something else
''';
      final section = sectionText(body, 'Roadmap');
      expect(section, contains('### Foundation'));
      expect(section, contains('Round 0'));
      expect(section, isNot(contains('Something else')));
    });

    test('a heading of the same level still ends the section, unchanged', () {
      const body = '## One\n\nBody.\n\n## Two\n\nOther.\n';
      expect(sectionText(body, 'One'), 'Body.');
    });
  });

  group('sectionTextByPrefix', () {
    test('a heading with a trailing qualifier still matches — real shape, '
        'ADR 0012: "## Decision — proposed, three parts, in this order"', () {
      const body = '''
## Decision — proposed, three parts, in this order

**1. Build the doorman.** Real content here.

## What this does NOT decide

Something else.
''';
      final section = sectionTextByPrefix(body, 'Decision');
      expect(section, contains('Build the doorman'));
      expect(section, isNot(contains('What this does NOT decide')));
    });

    test(
      'an exact heading with no qualifier still matches, same as before',
      () {
        const body = '## Decision\n\nPlain content.\n';
        expect(sectionTextByPrefix(body, 'Decision'), 'Plain content.');
      },
    );

    test('does not cross-match a heading that merely starts with the same '
        'word — "Decisions" is not "Decision"', () {
      const body = '## Decisions\n\nA whole different section.\n';
      expect(sectionTextByPrefix(body, 'Decision'), isNull);
    });

    test('null when the heading is not present at all', () {
      expect(sectionTextByPrefix('# Title\n\nBody.\n', 'Decision'), isNull);
    });
  });

  group('stripEmphasisMarkers', () {
    test('removes ** markers, keeping the text — real shape, ADR 0012', () {
      const raw =
          '- **The doorman ships and the retrieval failures continue** → '
          'the diagnosis was wrong.';
      expect(
        stripEmphasisMarkers(raw),
        '- The doorman ships and the retrieval failures continue → '
        'the diagnosis was wrong.',
      );
    });

    test('removes __ markers too', () {
      expect(stripEmphasisMarkers('__bold__'), 'bold');
    });

    test('handles more than one emphasized span in the same text', () {
      expect(stripEmphasisMarkers('**one** and **two**'), 'one and two');
    });

    test('text with no markers at all is returned unchanged', () {
      expect(stripEmphasisMarkers('plain text'), 'plain text');
    });
  });

  group('stripCodeSpanMarkers', () {
    test('removes single backtick markers, keeping the text — real shape, '
        "asa.md's own ## Tasks section", () {
      expect(
        stripCodeSpanMarkers(
          "Fix `decision_detail_screen_test.dart`'s flakiness -- done "
          '`2026-09-09` (`b1394a2`)',
        ),
        "Fix decision_detail_screen_test.dart's flakiness -- done "
        '2026-09-09 (b1394a2)',
      );
    });

    test('handles more than one code span in the same text', () {
      expect(stripCodeSpanMarkers('`one` and `two`'), 'one and two');
    });

    test('text with no backticks at all is returned unchanged', () {
      expect(stripCodeSpanMarkers('plain text'), 'plain text');
    });
  });
}
