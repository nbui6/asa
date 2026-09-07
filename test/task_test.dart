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
  });
}
