import 'package:asa/core/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseTasks', () {
    test(
      'a flat checklist with no tags — real shape, data-deletion-policy',
      () {
        const body = '''
## Tasks

- [ ] Collect information from C
- [ ] Meeting with R
- [x] Pull all information together in 1 system pool
''';
        final tasks = parseTasks(body);

        expect(tasks, hasLength(3));
        expect(tasks[0].text, 'Collect information from C');
        expect(tasks[0].done, isFalse);
        expect(tasks[2].done, isTrue);
        expect(tasks.every((t) => t.isCode == false), isTrue);
        expect(tasks.every((t) => t.crossProjectRef == null), isTrue);
      },
    );

    test('no ## Tasks section yields an empty list, not an error — '
        'real shape, vibe-coding-kit', () {
      const body = '''
# Vibe Coding Kit

## Where it stands

v1.23.
''';
      expect(parseTasks(body), isEmpty);
    });

    test('a [[project]] reference is stripped from the text and captured — '
        'real shape, partner-trial-process', () {
      const body =
          '''
## Tasks

- [ ] Create the License object — needs the schema from '''
          '[[license-commerce-integration]]\n';
      final tasks = parseTasks(body);

      expect(tasks, hasLength(1));
      expect(tasks.single.text, 'Create the License object');
      expect(tasks.single.crossProjectRef, 'license-commerce-integration');
    });

    test('a reference with no em dash still strips at the bracket', () {
      const body = '## Tasks\n\n- [ ] Something [[other-project]]\n';
      final task = parseTasks(body).single;

      expect(task.text, 'Something');
      expect(task.crossProjectRef, 'other-project');
    });

    test('a trailing (Code) tag is stripped and marks the task as code, '
        'case-insensitively', () {
      const body = '## Tasks\n\n- [ ] Rebuild the .exe (code)\n';
      final task = parseTasks(body).single;

      expect(task.text, 'Rebuild the .exe');
      expect(task.isCode, isTrue);
    });

    test('the word "code" elsewhere in the text is not a tag — anchored to '
        'a trailing parenthetical, not a substring search', () {
      const body = '## Tasks\n\n- [ ] Review the code style guide\n';
      final task = parseTasks(body).single;

      expect(task.text, 'Review the code style guide');
      expect(task.isCode, isFalse);
    });

    test('rawLine is preserved verbatim, for the writer to find again', () {
      // A second line after it, so the section's own trailing trim (the
      // last line in a `## Tasks` section loses trailing whitespace to
      // sectionText's trim — harmless for the writer, see task_writer.dart,
      // but not what this test means to probe) does not affect the line
      // under test.
      const body = '## Tasks\n\n-   [ ]   Test forms  \n- [ ] Second\n';
      final task = parseTasks(body).first;

      expect(task.rawLine, '-   [ ]   Test forms  ');
    });

    test('a trailing (parked) tag is stripped and marks the task as '
        'parked, case-insensitively — PLAN.md v0.3', () {
      const body = '## Tasks\n\n- [ ] Redesign the onboarding flow (Parked)\n';
      final task = parseTasks(body).single;

      expect(task.text, 'Redesign the onboarding flow');
      expect(task.parked, isTrue);
      expect(task.done, isFalse);
    });

    test('(Code) and (parked) can sit on one line without fighting each '
        'other — parked is checked and stripped first', () {
      const body = '## Tasks\n\n- [ ] Ship the release (Code) (parked)\n';
      final task = parseTasks(body).single;

      expect(task.text, 'Ship the release');
      expect(task.isCode, isTrue);
      expect(task.parked, isTrue);
    });

    test('the word "parked" elsewhere in the text is not a tag — anchored '
        'to a trailing parenthetical, not a substring search', () {
      const body = '## Tasks\n\n- [ ] The car is parked outside\n';
      final task = parseTasks(body).single;

      expect(task.text, 'The car is parked outside');
      expect(task.parked, isFalse);
    });

    test('most tasks are not parked, and that reads as false, not an '
        'error', () {
      const body = '## Tasks\n\n- [ ] An ordinary task\n';
      expect(parseTasks(body).single.parked, isFalse);
    });

    test('a "## Tasks" example inside a fenced code block is not read as '
        'real tasks — the same fence-awareness decision.dart already '
        'needed, shared via markdown.dart', () {
      const body = '''
## Decision

Shape:

```
## Tasks

- [ ] not a real task
```

## Tasks

- [ ] the only real one
''';
      final tasks = parseTasks(body);
      expect(tasks, hasLength(1));
      expect(tasks.single.text, 'the only real one');
    });

    test('Round 42 §B — a line indented two spaces is a subtask, indent '
        '1; a plain line is indent 0', () {
      const body = '''
## Tasks

- [ ] Parent task
  - [ ] Subtask
- [ ] Another top-level task
''';
      final tasks = parseTasks(body);
      expect(tasks, hasLength(3));
      expect(tasks[0].indent, 0);
      expect(tasks[1].indent, 1);
      expect(tasks[1].text, 'Subtask');
      expect(tasks[2].indent, 0);
    });

    test('Round 42 §B — a done, tagged subtask keeps every other field '
        'once indent is derived', () {
      // A parent task first — `sectionText` trims the whole section, which
      // would otherwise strip a lone first line's own leading spaces too,
      // a fixture artefact rather than a real `## Tasks` shape (a subtask
      // always follows a real parent in practice).
      const body = '## Tasks\n\n- [ ] Parent\n  - [x] Done subtask (Code)\n';
      final task = parseTasks(body)[1];
      expect(task.indent, 1);
      expect(task.done, isTrue);
      expect(task.isCode, isTrue);
      expect(task.text, 'Done subtask');
    });
  });

  group('waitingOn — Round 38 §E / Round 42, shared with check.dart', () {
    const task = Task(
      rawLine: '- [ ] Ask legal (waiting: Legal, since 2026-09-01)',
      text: 'Ask legal',
      done: false,
    );

    test('parses the name and computes days from now', () {
      final result = waitingOn(task, DateTime(2026, 9, 15));
      expect(result?.name, 'Legal');
      expect(result?.days, 14);
      expect(result?.since, '2026-09-01');
    });

    test('is case-insensitive on the "waiting" keyword', () {
      const upper = Task(
        rawLine: '- [ ] Ask (Waiting: Tamara, since 2026-09-01)',
        text: 'Ask',
        done: false,
      );
      expect(waitingOn(upper, DateTime(2026, 9, 2))?.name, 'Tamara');
    });

    test('null when the line has no such marker at all', () {
      const plain = Task(
        rawLine: '- [ ] Plain task',
        text: 'Plain task',
        done: false,
      );
      expect(waitingOn(plain, DateTime.now()), isNull);
    });
  });
}
