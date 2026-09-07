// Tests for the sorting, which is the only new logic with rules in it.
//
// Scanning the disk is not tested here — it has no rules, and a test that
// needs real folders is a test that breaks for the wrong reasons.

import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/projects_scan.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 8, 24, 12);

ProjectSummary summary(String name, {int? daysAgo}) {
  final git = daysAgo == null
      ? const GitState(error: 'no repo', command: 'test', rawOutput: '')
      : GitState(
          lastCommit: now.subtract(Duration(days: daysAgo)),
          command: 'test',
          rawOutput: 'test',
        );

  return ProjectSummary(
    project: projectFromFields({'project': name}, '$name.md'),
    git: git,
    folder: name,
  );
}

void main() {
  group('sortByStaleness', () {
    test('puts the most stale first', () {
      final sorted = sortByStaleness([
        summary('fresh', daysAgo: 0),
        summary('ancient', daysAgo: 40),
        summary('middling', daysAgo: 7),
      ], now);

      expect(sorted.map((s) => s.project.name), [
        'ancient',
        'middling',
        'fresh',
      ]);
    });

    test('puts unknown last, whatever the others are', () {
      final sorted = sortByStaleness([
        summary('unknown'),
        summary('ancient', daysAgo: 40),
      ], now);

      expect(sorted.map((s) => s.project.name), ['ancient', 'unknown']);
    });

    test('sorts several unknowns by name so the order is stable', () {
      final sorted = sortByStaleness([summary('zeta'), summary('alpha')], now);

      expect(sorted.map((s) => s.project.name), ['alpha', 'zeta']);
    });

    test('handles an empty list', () {
      expect(sortByStaleness([], now), isEmpty);
    });

    test('does not change the input list', () {
      final input = [summary('a', daysAgo: 1), summary('b', daysAgo: 9)];
      sortByStaleness(input, now);
      expect(input.map((s) => s.project.name), ['a', 'b']);
    });
  });

  group('stalenessLabel', () {
    test('says today for zero days', () {
      expect(stalenessLabel(summary('x', daysAgo: 0), now), 'today');
    });

    test('uses the singular for one day', () {
      expect(stalenessLabel(summary('x', daysAgo: 1), now), '1 day ago');
    });

    test('uses the plural beyond one day', () {
      expect(stalenessLabel(summary('x', daysAgo: 12), now), '12 days ago');
    });

    test('says unknown when git could not answer', () {
      expect(stalenessLabel(summary('x'), now), 'unknown');
    });
  });
}
