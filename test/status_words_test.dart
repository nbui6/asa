// Round 39 cp9b — ADR 0041's seven status words, and the four old ones
// they replace. One test per alias proves an old file still reads.

import 'package:asa/core/status_words.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalStatus — every old word reads as its new one', () {
    test('building -> in-progress', () {
      expect(canonicalStatus('building'), 'in-progress');
    });
    test('paused -> on-hold', () {
      expect(canonicalStatus('paused'), 'on-hold');
    });
    test('shipped -> done', () {
      expect(canonicalStatus('shipped'), 'done');
    });
    test('dropped -> canceled', () {
      expect(canonicalStatus('dropped'), 'canceled');
    });
    test("today's loose, unhyphenated shapes read the same way", () {
      expect(canonicalStatus('in progress'), 'in-progress');
      expect(canonicalStatus('on hold'), 'on-hold');
    });
    test('case and surrounding whitespace never matter', () {
      expect(canonicalStatus('  Building  '), 'in-progress');
      expect(canonicalStatus('PAUSED'), 'on-hold');
    });

    test('a new word passes through unchanged', () {
      for (final word in statusWords) {
        expect(canonicalStatus(word.stored), word.stored);
      }
    });

    test('an unknown status is never guessed at — kept exactly as written', () {
      expect(canonicalStatus('planning'), 'planning');
    });
  });

  group('isOldStatusWord', () {
    test('every old word and loose shape reads as old', () {
      for (final old in [
        'building',
        'paused',
        'shipped',
        'dropped',
        'in progress',
        'on hold',
      ]) {
        expect(isOldStatusWord(old), isTrue, reason: old);
      }
    });

    test('a new word is not old', () {
      for (final word in statusWords) {
        expect(isOldStatusWord(word.stored), isFalse, reason: word.stored);
      }
    });

    test('an unknown word is not old either — it is its own finding', () {
      expect(isOldStatusWord('planning'), isFalse);
    });
  });

  group("isHiddenStatus — ADR 0036's hiding set, in the new words", () {
    test('on-hold, done and canceled all hide — new word or old', () {
      for (final status in [
        'on-hold',
        'paused',
        'done',
        'shipped',
        'canceled',
        'dropped',
      ]) {
        expect(isHiddenStatus(status), isTrue, reason: status);
      }
    });

    test('idea, discovery-done, in-progress and ongoing never hide', () {
      for (final status in [
        'idea',
        'discovery-done',
        'in-progress',
        'building',
        'ongoing',
      ]) {
        expect(isHiddenStatus(status), isFalse, reason: status);
      }
    });
  });

  group('statusLabel', () {
    test('every stored word gets its own ADR 0041 label', () {
      expect(statusLabel('idea'), 'Idea');
      expect(statusLabel('discovery-done'), 'Discovery done');
      expect(statusLabel('in-progress'), 'In progress');
      expect(statusLabel('ongoing'), 'Ongoing');
      expect(statusLabel('on-hold'), 'On hold');
      expect(statusLabel('done'), 'Done');
      expect(statusLabel('canceled'), 'Canceled');
    });

    test('an old word shows its new label, not its own spelling', () {
      expect(statusLabel('building'), 'In progress');
      expect(statusLabel('paused'), 'On hold');
      expect(statusLabel('shipped'), 'Done');
      expect(statusLabel('dropped'), 'Canceled');
    });

    test('an unknown word is title-cased, not dropped', () {
      expect(statusLabel('planning'), 'Planning');
    });

    test('empty stays empty', () {
      expect(statusLabel(''), '');
    });
  });

  group('statusWords — the table itself', () {
    test("all seven, in ADR 0041's own order", () {
      expect(statusWords.map((w) => w.stored).toList(), [
        'idea',
        'discovery-done',
        'in-progress',
        'ongoing',
        'on-hold',
        'done',
        'canceled',
      ]);
    });

    test('every word carries a non-empty means hint', () {
      for (final word in statusWords) {
        expect(word.means, isNotEmpty, reason: word.stored);
      }
    });
  });
}
