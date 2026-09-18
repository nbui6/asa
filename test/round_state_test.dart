// Round 16 — ADR 0026's five states, derived from a Milestone's real body
// text, never typed.

import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/roadmap.dart';
import 'package:asa/core/round_approvals.dart';
import 'package:asa/core/round_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileAccess implements FileAccess {
  FakeFileAccess({this.folders = const {}, this.files = const {}});

  final Map<String, List<String>> folders;
  final Map<String, String> files;

  @override
  Future<List<String>> listFiles(String folder) async => folders[folder] ?? [];

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    if (contents == null) throw StateError('No fake file at $path');
    return contents;
  }
}

Milestone _milestone({
  required bool done,
  String title = 'Round 26 — read the plan',
  List<String> body = const [],
}) {
  return Milestone(title: title, done: done, bodyLines: body);
}

void main() {
  group('roundStateOf — the five states', () {
    test('not done, nothing in the body yet — planned', () {
      final state = roundStateOf(
        _milestone(done: false),
        const RoundApprovals({}),
      );
      expect(state, RoundState.planned);
    });

    test('not done, a commit hash already in the body — in progress', () {
      final state = roundStateOf(
        _milestone(done: false, body: ['built `22a1c26`, not yet checked off']),
        const RoundApprovals({}),
      );
      expect(state, RoundState.inProgress);
    });

    test('not done, the word "specced" in the body — in progress', () {
      final state = roundStateOf(
        _milestone(done: false, body: ['Specced for Code, 2026-09-14.']),
        const RoundApprovals({}),
      );
      expect(state, RoundState.inProgress);
    });

    test('not done, "respecced" also counts — it contains "specced"', () {
      final state = roundStateOf(
        _milestone(done: false, body: ['respecced for Code, 2026-09-14.']),
        const RoundApprovals({}),
      );
      expect(state, RoundState.inProgress);
    });

    test('done, no matching row in the ledger — waiting for approval', () {
      final state = roundStateOf(
        _milestone(done: true, body: ['built and committed `80fa9e8`.']),
        const RoundApprovals({}),
      );
      expect(state, RoundState.waitingForApproval);
    });

    test('done, a matching row exists — completed', () {
      const approvals = RoundApprovals({
        '26': (date: '2026-09-15', words: 'yes it works', result: 'shipped'),
      });
      final state = roundStateOf(
        _milestone(done: true, body: ['built `22a1c26`.']),
        approvals,
      );
      expect(state, RoundState.completed);
    });

    test('the (no approval needed) tag overrides done and everything else', () {
      final doneState = roundStateOf(
        _milestone(done: true, body: ['(no approval needed) — a refactor.']),
        const RoundApprovals({}),
      );
      final notDoneState = roundStateOf(
        _milestone(done: false, body: ['(no approval needed) — a script.']),
        const RoundApprovals({}),
      );
      expect(doneState, RoundState.noApprovalNeeded);
      expect(notDoneState, RoundState.noApprovalNeeded);
    });

    test('a round number is read from the title, not the body', () {
      const approvals = RoundApprovals({
        '29': (date: '2026-09-15', words: 'yes', result: 'done'),
      });
      final state = roundStateOf(
        _milestone(done: true, title: '**Round 29 — sketches**', body: []),
        approvals,
      );
      expect(state, RoundState.completed);
    });
  });

  group('readRoundApprovals — the ledger', () {
    test('an empty ledger approves nothing', () {
      const approvals = RoundApprovals({});
      expect(approvals.hasApprovalFor('26'), isFalse);
      expect(approvals.approvalFor('26'), isNull);
    });

    test('a null round number never matches, even in a non-empty ledger', () {
      const approvals = RoundApprovals({
        '26': (date: '2026-09-15', words: 'yes', result: 'done'),
      });
      expect(approvals.hasApprovalFor(null), isFalse);
    });

    test(
      'no rounds/APPROVED.md yields an empty ledger, not an error',
      () async {
        final approvals = await readRoundApprovals('proj', FakeFileAccess());
        expect(approvals.hasApprovalFor('26'), isFalse);
      },
    );

    test("the empty placeholder row (today's real state) is skipped", () async {
      final files = FakeFileAccess(
        folders: {
          'proj/rounds': ['APPROVED.md'],
        },
        files: {
          'proj/rounds/APPROVED.md':
              "| Date | Round | Nico's words | The result, one line |\n"
              '|---|---|---|---|\n'
              '| | | | |\n',
        },
      );
      final approvals = await readRoundApprovals('proj', files);
      expect(approvals.hasApprovalFor('26'), isFalse);
    });

    test(
      'a real row approves the round number found in its Round column',
      () async {
        final files = FakeFileAccess(
          folders: {
            'proj/rounds': ['APPROVED.md'],
          },
          files: {
            'proj/rounds/APPROVED.md':
                "| Date | Round | Nico's words | The result, one line |\n"
                '|---|---|---|---|\n'
                '| 2026-09-15 | Round 26 | yes it works | The plan reads real '
                'data |\n',
          },
        );
        final approvals = await readRoundApprovals('proj', files);
        expect(approvals.hasApprovalFor('26'), isTrue);
        expect(approvals.approvalFor('26')!.words, 'yes it works');
      },
    );
  });
}
