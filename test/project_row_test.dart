import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/project_row.dart';
import 'package:asa/core/project_tree.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:asa/core/task.dart';
import 'package:flutter_test/flutter_test.dart';

const _emptyGit = GitState(command: '', rawOutput: '');

ProjectSummary _summary({
  required String folder,
  required String name,
  String? parent,
  String status = 'in progress',
}) {
  return ProjectSummary(
    project: Project(
      name: name,
      status: status,
      milestone: '',
      nextStep: '',
      repoPath: '',
      updated: '2026-09-07',
      sourceFile: '$folder/$name.md',
      parent: parent,
    ),
    git: _emptyGit,
    folder: folder,
  );
}

void main() {
  group('jiraLabel', () {
    test('the one real Jira URL in use — partner-trial-process', () {
      expect(
        jiraLabel('https://verbi.atlassian.net/browse/CRM-557'),
        'CRM-557',
      );
    });

    test('null when there is no Jira value', () {
      expect(jiraLabel(null), isNull);
      expect(jiraLabel(''), isNull);
      expect(jiraLabel('   '), isNull);
    });
  });

  group('humanizeDeadline', () {
    test("the real shape — bare YYYY-MM, e.g. learning's 2027-09", () {
      expect(humanizeDeadline('2027-09'), 'Sep 2027');
    });

    test('every month renders, not just the one real example', () {
      expect(humanizeDeadline('2026-01'), 'Jan 2026');
      expect(humanizeDeadline('2026-12'), 'Dec 2026');
    });

    test('null or blank returns null — the row shows an em dash for that', () {
      expect(humanizeDeadline(null), isNull);
      expect(humanizeDeadline(''), isNull);
      expect(humanizeDeadline('   '), isNull);
    });

    test('a shape that is not bare YYYY-MM is returned verbatim, not '
        'mangled', () {
      expect(humanizeDeadline('Q3 2026'), 'Q3 2026');
    });
  });

  group('statusEmphasis — the five real words, plus one unrecognized', () {
    test('in progress and building are active', () {
      expect(statusEmphasis('in progress'), StatusEmphasis.active);
      expect(statusEmphasis('building'), StatusEmphasis.active);
    });

    test('on hold, planning, and idea are neutral', () {
      expect(statusEmphasis('on hold'), StatusEmphasis.neutral);
      expect(statusEmphasis('planning'), StatusEmphasis.neutral);
      expect(statusEmphasis('idea'), StatusEmphasis.neutral);
    });

    test('a status word never seen before falls back to neutral, rather '
        'than throwing', () {
      expect(statusEmphasis('archived'), StatusEmphasis.neutral);
    });

    test('Round 32/C — ongoing gets the same active emphasis as building, '
        "closing the gap this file's own comment already named", () {
      expect(statusEmphasis('ongoing'), StatusEmphasis.active);
    });
  });

  group('effectiveNextStep — Round 32/B, ADR 0020', () {
    Task task({required String text, bool done = false, bool parked = false}) {
      return Task(
        rawLine: '- [ ] $text',
        text: text,
        done: done,
        parked: parked,
      );
    }

    test('the first open, unparked task wins over the typed field', () {
      final tasks = [
        task(text: 'Already done', done: true),
        task(text: 'Parked one', parked: true),
        task(text: 'Real next step'),
        task(text: 'A later one'),
      ];
      expect(effectiveNextStep(tasks, 'Typed field value'), 'Real next step');
    });

    test('a parked task is skipped even though it is not done', () {
      final tasks = [task(text: 'Parked', parked: true), task(text: 'Real')];
      expect(effectiveNextStep(tasks, ''), 'Real');
    });

    test('every task done falls back to the typed field', () {
      final tasks = [
        task(text: 'One', done: true),
        task(text: 'Two', done: true),
      ];
      expect(effectiveNextStep(tasks, 'Typed fallback'), 'Typed fallback');
    });

    test('no tasks at all falls back to the typed field', () {
      expect(effectiveNextStep(const [], 'Typed fallback'), 'Typed fallback');
    });

    test('neither a real task nor a real typed value — null, for the '
        'caller to show "no next step"', () {
      expect(effectiveNextStep(const [], ''), isNull);
      expect(effectiveNextStep(const [], '(not set)'), isNull);
      final allDone = [task(text: 'Done', done: true)];
      expect(effectiveNextStep(allDone, ''), isNull);
    });

    test('markdown markers are stripped from whichever source is used', () {
      final tasks = [task(text: 'Fix `the_bug.dart`')];
      expect(effectiveNextStep(tasks, ''), 'Fix the_bug.dart');
      expect(effectiveNextStep(const [], '**Typed** value'), 'Typed value');
    });
  });

  group('splitByBucket — real chain, other -> asa -> vibe-coding-kit', () {
    test(
      'other and its whole subtree are separated from the flat work list',
      () {
        final other = _summary(folder: 'projects/other', name: 'other');
        final asa = _summary(
          folder: 'projects/asa',
          name: 'asa',
          parent: 'other',
        );
        final vibe = _summary(
          folder: 'projects/vibe-coding-kit',
          name: 'vibe-coding-kit',
          parent: 'asa',
        );
        final kundenakte = _summary(
          folder: 'projects/kundenakte',
          name: 'kundenakte',
        );

        final forest = buildProjectForest([other, asa, vibe, kundenakte]);
        final split = splitByBucket(forest);

        expect(split.work, hasLength(1));
        expect(split.work.single.project.name, 'kundenakte');
        expect(split.other, isNotNull);
        expect(split.other!.project.name, 'other');
        expect(countDescendants(split.other!), 2); // asa + vibe-coding-kit
      },
    );

    test(
      'no "other" project in this scan at all yields a null other bucket',
      () {
        final standalone = _summary(
          folder: 'projects/kundenakte',
          name: 'kundenakte',
        );
        final split = splitByBucket(buildProjectForest([standalone]));

        expect(split.other, isNull);
        expect(split.work, hasLength(1));
      },
    );
  });

  group('isPastDeadline — an overdue signal', () {
    final now = DateTime(2026, 9, 13);

    test('a deadline month strictly before now is overdue', () {
      expect(isPastDeadline('2026-08', 'building', now), isTrue);
    });

    test('a deadline month after now is not overdue', () {
      expect(isPastDeadline('2026-10', 'building', now), isFalse);
    });

    test("now's own month is not yet overdue — the month itself must be "
        'over, not merely reached', () {
      expect(isPastDeadline('2026-09', 'building', now), isFalse);
    });

    test('null, blank, or a shape that is not bare YYYY-MM is never '
        'overdue — same honest-absence handling as humanizeDeadline', () {
      expect(isPastDeadline(null, 'building', now), isFalse);
      expect(isPastDeadline('', 'building', now), isFalse);
      expect(isPastDeadline('Q3 2026', 'building', now), isFalse);
    });

    test('suppressed for shipped and dropped, whatever the date says', () {
      expect(isPastDeadline('2020-01', 'shipped', now), isFalse);
      expect(isPastDeadline('2020-01', 'dropped', now), isFalse);
      expect(isPastDeadline('2020-01', 'Shipped', now), isFalse);
    });

    test('every other real status still gets the signal, paused '
        'included — a paused project past its deadline is exactly what '
        'this is for', () {
      for (final status in [
        'idea',
        'discovery-done',
        'building',
        'paused',
        'ongoing',
      ]) {
        expect(isPastDeadline('2020-01', status, now), isTrue);
      }
    });
  });

  group('countParked — PLAN.md v0.3, "the rule of two"', () {
    const parked = Task(rawLine: '', text: 'Parked', done: false, parked: true);
    const open = Task(rawLine: '', text: 'Open', done: false);
    const doneAndParked = Task(
      rawLine: '',
      text: 'Done but still parked',
      done: true,
      parked: true,
    );

    test('counts only the parked ones, done or not', () {
      expect(countParked([parked, open, doneAndParked]), 2);
    });

    test('a project with nothing parked counts zero, not absent from the '
        'list — the caller decides what zero means on screen', () {
      expect(countParked([open]), 0);
    });

    test('no tasks at all counts zero, not an error', () {
      expect(countParked(const []), 0);
    });
  });
}
