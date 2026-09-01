// Tests for the frontmatter parser.
//
// Why these and not others: this is the only place in Round 1 with rules in it,
// and rules are where things go wrong quietly. See the first-test skill.
//
// Nothing here touches the file system or Flutter, which is why core/ does not
// import Flutter.

import 'package:flutter_test/flutter_test.dart';

import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';

void main() {
  group('parseFrontmatter', () {
    test('reads plain key and value pairs', () {
      const file = '''
---
project: Asa
status: building
---

# Asa
Some prose.
''';
      final fields = parseFrontmatter(file);
      expect(fields['project'], 'Asa');
      expect(fields['status'], 'building');
    });

    test('returns nothing when there is no frontmatter', () {
      const file = '# Asa\n\nJust a heading.';
      expect(parseFrontmatter(file), isEmpty);
    });

    test('returns nothing when the block does not start on line one', () {
      const file = 'A stray line\n---\nproject: Asa\n---\n';
      expect(parseFrontmatter(file), isEmpty);
    });

    test('removes surrounding quotes', () {
      const file = '---\nnext-step: "Accept ADR 0001"\n---\n';
      expect(parseFrontmatter(file)['next-step'], 'Accept ADR 0001');
    });

    test('keeps colons that appear inside a value', () {
      const file = '---\nnext-step: "Round 1: read one project"\n---\n';
      expect(parseFrontmatter(file)['next-step'], 'Round 1: read one project');
    });

    test('keeps a Windows path with its drive colon', () {
      const file = r'''
---
repo-path: C:\Users\nico.bui\workspace\asa
---
''';
      expect(parseFrontmatter(file)['repo-path'], r'C:\Users\nico.bui\workspace\asa');
    });

    test('ignores lines that are not key and value', () {
      const file = '---\nproject: Asa\njust a comment\n---\n';
      final fields = parseFrontmatter(file);
      expect(fields.length, 1);
      expect(fields['project'], 'Asa');
    });

    test('stops at the closing marker', () {
      const file = '---\nproject: Asa\n---\nstatus: not-frontmatter\n';
      expect(parseFrontmatter(file).containsKey('status'), isFalse);
    });

    test('treats an empty value as empty, not missing', () {
      const file = '---\nrepo-path:\n---\n';
      expect(parseFrontmatter(file)['repo-path'], '');
    });
  });

  group('projectFromFields', () {
    test('shows a placeholder for a missing field', () {
      final project = projectFromFields({'project': 'Asa'}, 'asa.md');
      expect(project.name, 'Asa');
      expect(project.status, '(not set)');
    });

    test('leaves repo-path genuinely empty when there is no code yet', () {
      final project = projectFromFields({'repo-path': ''}, 'asa.md');
      expect(project.repoPath, '');
    });

    test('remembers which file it came from', () {
      final project = projectFromFields({}, r'C:\vault\asa\asa.md');
      expect(project.sourceFile, r'C:\vault\asa\asa.md');
    });
  });

  group('extractRawFrontmatter', () {
    test('returns the block including both markers', () {
      const file = '---\nproject: Asa\n---\n# heading\n';
      expect(extractRawFrontmatter(file), '---\nproject: Asa\n---');
    });

    test('returns empty when there is no block', () {
      expect(extractRawFrontmatter('# heading'), '');
    });
  });

  group('GitState.daysSinceLastCommit', () {
    test('counts whole days', () {
      final state = GitStateFixture.at(DateTime(2026, 8, 20, 10));
      expect(state.daysSinceLastCommit(DateTime(2026, 8, 23, 10)), 3);
    });

    test('is null when there is no commit', () {
      final state = GitStateFixture.none();
      expect(state.daysSinceLastCommit(DateTime(2026, 8, 23)), isNull);
    });
  });
}

/// Small helpers so the git tests do not need to run git.
class GitStateFixture {
  static GitState at(DateTime when) =>
      GitState(lastCommit: when, command: 'test', rawOutput: when.toString());

  static GitState none() =>
      const GitState(error: 'no repo', command: 'test', rawOutput: '');
}
