// Round 39 cp2 — a round file's own **Area:** line.
//
// Round 38 §C adds parseRoundTitle and cutToLines below, for the "Your
// call" screen; sectionTextContaining, parseRoundFinishLine, parseRoundTest
// and readRoundFileText stay covered only indirectly, through
// brief_test.dart's own --round tests (the no-file case; not a real
// file's actual finish-line/test extraction) — a real, pre-existing gap,
// not introduced here, left named rather than silently assumed covered.

import 'package:asa/core/round_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the Area line near the top of a real-shaped round file', () {
    const text = '''
# Round 38 — Project tabs

**Date started:** — · **Status:** approved
**Area:** App

## Why
Something.
''';
    expect(parseRoundArea(text), 'App');
  });

  test('a round with no Area line reads as null, not an error', () {
    const text = '# Round 1 — Foundation\n\n## Why\nSomething.\n';
    expect(parseRoundArea(text), isNull);
  });

  test('only looks near the top - a mention of "**Area:**" deep in the body '
      "does not count as the round's own declaration", () {
    final filler = List.filled(25, 'Just filler prose.\n').join();
    final text = '# Round 2 — Something\n\n$filler\n**Area:** Sales\n';
    expect(parseRoundArea(text), isNull);
  });

  test('trims trailing whitespace and stops at the end of the line', () {
    const text = '# Round 3\n**Area:**   Marketing   \nMore text.\n';
    expect(parseRoundArea(text), 'Marketing');
  });

  group('parseRoundTitle', () {
    const roundText =
        '# Round 38 — Strategy first, areas as tabs\n\n**Area:** App\n';

    test('reads the # heading, markers kept for the caller to strip', () {
      expect(
        parseRoundTitle(roundText, fallback: 'Round 38'),
        'Round 38 — Strategy first, areas as tabs',
      );
    });

    test('falls back when there is no top-level heading at all', () {
      expect(
        parseRoundTitle('## Only a subheading', fallback: 'Round 9'),
        'Round 9',
      );
    });
  });

  group('cutToLines', () {
    test('leaves a short section untouched', () {
      expect(cutToLines('a\nb\nc', 5), 'a\nb\nc');
    });

    test('cuts a long section, naming how many lines are hidden', () {
      final result = cutToLines('a\nb\nc\nd\ne\nf\ng', 5);
      expect(result, startsWith('a\nb\nc\nd\ne\n'));
      expect(result, contains('2 more lines'));
    });

    test('null in, null out', () {
      expect(cutToLines(null, 5), isNull);
    });
  });
}
