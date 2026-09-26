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

    test('round-36 §3, L10 — a real next task names itself and its own '
        'area page', () {
      final text = openerText(
        projectName: 'Northwind partnership',
        projectFolder: r'C:\projects\northwind',
        nextTaskText: 'Agree the shared account list',
        areaSourceFile: r'plan\sales.md',
      );
      expect(
        text,
        contains(
          'The next task: Agree the shared account list. Its own page: '
          r'plan\sales.md.',
        ),
      );
    });

    test('a next task with no area names just the task, no dangling '
        'sentence about a page that does not exist', () {
      final text = openerText(
        projectName: 'demo',
        projectFolder: 'projects/demo',
        nextTaskText: 'Home task',
      );
      expect(text, contains('The next task: Home task.'));
      expect(text, isNot(contains('Its own page')));
    });

    test('no next task at all leaves the opener exactly as before this '
        'round', () {
      final text = openerText(
        projectName: 'demo',
        projectFolder: 'projects/demo',
      );
      expect(text, isNot(contains('next task')));
    });
  });
}
