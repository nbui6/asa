// Tests for the frontmatter parser.
//
// Why these and not others: this is the only place in Round 1 with rules in it,
// and rules are where things go wrong quietly. See the first-test skill.
//
// Nothing here touches the file system or Flutter, which is why core/ does not
// import Flutter.

import 'package:asa/core/git_state.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/roadmap.dart';
import 'package:flutter_test/flutter_test.dart';

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
repo-path: C:\Users\test\workspace\asa
---
''';
      expect(
        parseFrontmatter(file)['repo-path'],
        r'C:\Users\test\workspace\asa',
      );
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

    test('ignores an indented line — it belongs to a nested block like '
        'links, not a flat key', () {
      const file = '---\nlinks:\n  - relates to: other\n---\n';
      final fields = parseFrontmatter(file);
      expect(fields.containsKey('links'), isTrue);
      expect(fields['links'], '');
      expect(fields.containsKey('- relates to'), isFalse);
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

    test('parent, priority, deadline and jira parse when present', () {
      final project = projectFromFields({
        'parent': 'other',
        'priority': 'medium',
        'deadline': 'Oct-Dec',
        'jira': 'ASA-12',
      }, 'asa.md');

      expect(project.parent, 'other');
      expect(project.priority, 'medium');
      expect(project.deadline, 'Oct-Dec');
      expect(project.jira, 'ASA-12');
    });

    test('parent, priority, deadline and jira are null, not "(not set)", '
        'when absent — real files leave them blank', () {
      final project = projectFromFields({'project': 'Asa'}, 'asa.md');

      expect(project.parent, isNull);
      expect(project.priority, isNull);
      expect(project.deadline, isNull);
      expect(project.jira, isNull);
    });

    test('links default to an empty list', () {
      final project = projectFromFields({}, 'asa.md');
      expect(project.links, isEmpty);
    });

    test('extra carries a frontmatter key none of the ten named fields '
        "reads — Round 7's fork seam, FOR-YOUR-FORK.md", () {
      final project = projectFromFields({
        'project': 'Asa',
        'owner': 'nico',
      }, 'asa.md');

      expect(project.extra['owner'], 'nico');
      expect(project.name, 'Asa');
    });

    test('a named field never leaks into extra', () {
      final project = projectFromFields({
        'project': 'Asa',
        'status': 'in progress',
        'milestone': 'Round 2',
        'next-step': 'Do the thing',
        'repo-path': r'C:\code',
        'updated': '2026-09-08',
        'parent': 'other',
        'priority': 'medium',
        'deadline': '2026-12',
        'jira': 'ASA-1',
      }, 'asa.md');

      expect(project.extra, isEmpty);
    });

    test('extra is empty, never null, when there is nothing extra — the '
        'common case, every real project today', () {
      final project = projectFromFields({}, 'asa.md');
      expect(project.extra, isEmpty);
      expect(project.extra, isNotNull);
    });

    test('links passed in are carried onto the project', () {
      final project = projectFromFields(
        {},
        'asa.md',
        links: const [ProjectLink(type: 'relates to', target: 'other')],
      );
      expect(project.links, hasLength(1));
      expect(project.links.first.type, 'relates to');
      expect(project.links.first.target, 'other');
    });

    test('roadmap defaults to an empty list', () {
      final project = projectFromFields({}, 'asa.md');
      expect(project.roadmap, isEmpty);
    });

    test('roadmap passed in is carried onto the project', () {
      final project = projectFromFields(
        {},
        'asa.md',
        roadmap: const [Milestone(title: 'Round 0', done: true)],
      );
      expect(project.roadmap, hasLength(1));
      expect(project.roadmap.first.title, 'Round 0');
    });

    test('description is null unless passed in', () {
      final project = projectFromFields({}, 'asa.md');
      expect(project.description, isNull);
    });

    test('description passed in is carried onto the project', () {
      final project = projectFromFields(
        {},
        'asa.md',
        description: 'A short summary.',
      );
      expect(project.description, 'A short summary.');
    });
  });

  group('deriveDescription', () {
    test('reads the paragraph before a blockquote callout — real shape', () {
      // asa.md's own note: one plain paragraph, then a blockquote aside.
      // The description is the paragraph, not the callout.
      const file = '''
---
project: Example
---

# Example

A short record of what this project is for.

> **Restored 2026-09-01.** Some longer aside that is not the description.
> More aside text.
''';
      expect(
        deriveDescription(file),
        'A short record of what this project is for.',
      );
    });

    test('stops at the first blank line — a second paragraph is not read', () {
      const file = '''
# Example

First paragraph, this is the description.

Second paragraph, never reached.
''';
      expect(
        deriveDescription(file),
        'First paragraph, this is the description.',
      );
    });

    test('joins a wrapped paragraph with a space', () {
      const file = '''
# Example

Line one of the paragraph
line two of the same paragraph.
''';
      expect(
        deriveDescription(file),
        'Line one of the paragraph line two of the same paragraph.',
      );
    });

    test('a blockquote with no paragraph before the next heading yields '
        'null — real shape (a note with no body written yet)', () {
      const file = '''
# Example

> **Written 2026-09-01.** Structural only; nobody has filled this in.

## What this is

<One paragraph.>
''';
      expect(deriveDescription(file), isNull);
    });

    test('no heading at all yields null', () {
      const file = 'Just some text, no heading.';
      expect(deriveDescription(file), isNull);
    });

    test('a heading with nothing after it yields null', () {
      const file = '# Example\n';
      expect(deriveDescription(file), isNull);
    });

    test('works with no frontmatter block', () {
      const file = '# Example\n\nA description with no frontmatter above it.\n';
      expect(
        deriveDescription(file),
        'A description with no frontmatter above it.',
      );
    });

    test('skips the frontmatter block when finding the heading', () {
      const file = '''
---
project: Example
next-step: "# not a heading"
---

# Example

The real description.
''';
      expect(deriveDescription(file), 'The real description.');
    });
  });

  group('parseLinks', () {
    test("reads a links block, per ADR 0008's shape", () {
      const file = '''
---
project: Asa
links:
  - relates to: example-policy
  - blocked by: example-integration
  - shares marketing with: example-process
---
''';
      final links = parseLinks(file);
      expect(links, hasLength(3));
      expect(links[0].type, 'relates to');
      expect(links[0].target, 'example-policy');
      expect(links[1].type, 'blocked by');
      expect(links[1].target, 'example-integration');
      expect(links[2].type, 'shares marketing with');
      expect(links[2].target, 'example-process');
    });

    test('no links key yields an empty list', () {
      const file = '---\nproject: Asa\n---\n';
      expect(parseLinks(file), isEmpty);
    });

    test('an empty links block yields an empty list, not an error', () {
      const file = '---\nproject: Asa\nlinks:\n---\n';
      expect(parseLinks(file), isEmpty);
    });

    test('stops at the closing frontmatter marker', () {
      const file = '---\nlinks:\n  - relates to: other\n---\nrelates to: bad\n';
      expect(parseLinks(file), hasLength(1));
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
