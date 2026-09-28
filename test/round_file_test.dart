// Round 39 cp2 — a round file's own **Area:** line.

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
}
