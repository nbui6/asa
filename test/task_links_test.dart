// Round 43 §B — "derived both ways": a task shows its own result or
// decision, a result or decision shows its own task. Invented data
// throughout (Gate 2).

import 'package:asa/core/area.dart';
import 'package:asa/core/decision.dart';
import 'package:asa/core/task.dart';
import 'package:asa/core/task_links.dart';
import 'package:flutter_test/flutter_test.dart';

const _task = Task(
  rawLine: '- [x] Ask legal the RC-16 question',
  text: 'Ask legal the RC-16 question',
  done: true,
);

void main() {
  group('resultForTask', () {
    test('finds the result naming this task', () {
      const result = AreaResult(
        date: null,
        text: 'A copy keeps its own period, 24 months',
        task: 'Ask legal the RC-16 question',
      );
      expect(resultForTask(_task, [result]), same(result));
    });

    test('null when nothing names it', () {
      const result = AreaResult(date: null, text: 'Unrelated');
      expect(resultForTask(_task, [result]), isNull);
    });

    test('null on an empty list', () {
      expect(resultForTask(_task, const []), isNull);
    });
  });

  group('decisionsForTask', () {
    Decision decisionNaming(List<String> tasks) => Decision(
      title: 'x',
      why: '',
      decision: 'x',
      whatWouldChangeThis: '',
      sourceFile: 'x.md',
      links: DecisionLinks(tasks: tasks),
    );

    test('finds every decision naming this task, not just the first', () {
      final a = decisionNaming(['Ask legal the RC-16 question']);
      final b = decisionNaming(['Something else']);
      final c = decisionNaming(['Ask legal the RC-16 question', 'Other']);
      expect(decisionsForTask(_task, [a, b, c]), [a, c]);
    });

    test('empty when none name it', () {
      final a = decisionNaming(['Something else']);
      expect(decisionsForTask(_task, [a]), isEmpty);
    });
  });

  group('resultTaskExists / decisionTaskExists — "task (gone)"', () {
    test('true when the named task is still in the list', () {
      const result = AreaResult(
        date: null,
        text: 'x',
        task: 'Ask legal the RC-16 question',
      );
      expect(resultTaskExists(result, [_task]), isTrue);
    });

    test('false when the result names no task at all', () {
      const result = AreaResult(date: null, text: 'x');
      expect(resultTaskExists(result, [_task]), isFalse);
    });

    test('false when the named task is gone — "task (gone)", not hidden', () {
      const result = AreaResult(date: null, text: 'x', task: 'Vanished');
      expect(resultTaskExists(result, [_task]), isFalse);
    });

    test('decisionTaskExists mirrors the same check for one Task: link', () {
      expect(
        decisionTaskExists('Ask legal the RC-16 question', [_task]),
        isTrue,
      );
      expect(decisionTaskExists('Vanished', [_task]), isFalse);
    });
  });
}
