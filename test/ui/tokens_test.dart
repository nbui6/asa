import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('meaningForStatus', () {
    test('shipped is done', () {
      expect(meaningForStatus('shipped'), AsaMeaning.done);
    });
    test('building and ongoing are moving', () {
      expect(meaningForStatus('building'), AsaMeaning.moving);
      expect(meaningForStatus('ongoing'), AsaMeaning.moving);
    });
    test('idea, discovery-done, paused, dropped are quiet', () {
      for (final status in ['idea', 'discovery-done', 'paused', 'dropped']) {
        expect(meaningForStatus(status), AsaMeaning.quiet);
      }
    });
    test('is case-insensitive', () {
      expect(meaningForStatus('BUILDING'), AsaMeaning.moving);
    });
  });

  group('meaningForDecisionStatus', () {
    test('proposed needs a call', () {
      expect(meaningForDecisionStatus('proposed'), AsaMeaning.needsYou);
    });
    test('a written-in "waiting on" needs a call too', () {
      expect(
        meaningForDecisionStatus('waiting on the user'),
        AsaMeaning.needsYou,
      );
    });
    test('accepted, superseded and rejected are done', () {
      for (final status in [
        'accepted',
        'superseded by 0008',
        'accepted (supersedes 0005)',
      ]) {
        expect(meaningForDecisionStatus(status), AsaMeaning.done);
      }
    });
  });

  group('AsaMeaning colours', () {
    test('each meaning has a distinct foreground colour', () {
      final colours = AsaMeaning.values.map((m) => m.fg).toSet();
      expect(colours.length, AsaMeaning.values.length);
    });
  });

  group('date formatting', () {
    test('asaListDate reads today as "today"', () {
      final today = DateTime.now().toIso8601String();
      expect(asaListDate(today), 'today');
    });
    test('asaListDate formats a past date as "D Mon"', () {
      expect(asaListDate('2026-09-24'), '24 Sep');
    });
    test('asaDetailDate includes the year', () {
      expect(asaDetailDate('2026-09-24'), '24 Sep 2026');
    });
    test('both return null for a null or empty input', () {
      expect(asaListDate(null), isNull);
      expect(asaListDate(''), isNull);
      expect(asaDetailDate(null), isNull);
    });
    test('an unparseable string is returned as-is', () {
      expect(asaListDate('not a date'), 'not a date');
    });
  });

  group('decisionChipLabel', () {
    test('both show both: number and title together', () {
      expect(
        decisionChipLabel('0003', 'Deals go through the partner portal'),
        '0003 · Deals go through the partner portal',
      );
    });
    test('no number — just the (possibly cut) title', () {
      expect(decisionChipLabel(null, 'Short title'), 'Short title');
    });
    test('cuts a long title to about 40 characters', () {
      final label = decisionChipLabel(
        '0011',
        'A title so long it would widen or wrap the whole chip row',
      );
      expect(label, '0011 · A title so long it would widen or wrap t…');
    });
  });
}
