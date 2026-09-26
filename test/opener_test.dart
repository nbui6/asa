// Round 32/D — the clipboard text "Start → Copy opener" builds.

import 'package:asa/core/opener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('openerText', () {
    test('the exact real shape from the round spec', () {
      final text = openerText(
        projectName: 'Asa',
        projectFolder: r'C:\Users\nico.bui\workspace\projects\asa',
      );
      expect(
        text,
        'Working on Asa. Project folder: '
        r'C:\Users\nico.bui\workspace\projects\asa.'
        '\nRead asa.md and HOW-ASA-WORKS.md there first. Before you '
        'finish, update the note the way\nHOW-ASA-WORKS.md says.',
      );
    });

    test("the folder slug comes from the folder's own last segment, not "
        'the human-readable project name', () {
      final text = openerText(
        projectName: 'A Human-Readable Name',
        projectFolder: r'C:\Users\test\workspace\projects\some-slug',
      );
      expect(text, contains('Read some-slug.md'));
      expect(text, contains('Working on A Human-Readable Name.'));
    });

    test('a forward-slash folder path still finds the right slug', () {
      final text = openerText(
        projectName: 'demo',
        projectFolder: 'projects/demo',
      );
      expect(text, contains('Read demo.md'));
    });
  });
}
