/// Round 39 cp6 §2 — the Instruction for AI screen's own *Instructions*
/// part: does the installed manual match its source, and when did the
/// source last change. Pure Dart, no Flutter import.
library;

import 'dart:io';

/// Every `## Heading` (top-level section) in [text], in order — used to
/// find which sections differ between two versions of the same manual,
/// not to render the manual itself.
List<String> _sectionHeadings(String text) {
  final pattern = RegExp(r'^##\s+(.+)$', multiLine: true);
  return [for (final m in pattern.allMatches(text)) m.group(1)!.trim()];
}

/// Whether `templates\AGENTS.md` (the source, in the asa repo) and
/// `projects\AGENTS.md` (the installed copy) are byte-identical, and, if
/// not, which of the source's own top-level sections changed — a rename
/// or a reordering shows every heading as "differing" rather than
/// guessing which ones really moved; that is honest, not a bug.
class ManualSyncStatus {
  const ManualSyncStatus({
    required this.matches,
    required this.differingSections,
  });

  final bool matches;
  final List<String> differingSections;
}

Future<ManualSyncStatus> manualSyncStatus(
  String asaRepoPath,
  String projectsRoot,
) async {
  final sep = Platform.pathSeparator;
  final source = File('$asaRepoPath${sep}templates${sep}AGENTS.md');
  final installed = File('$projectsRoot${sep}AGENTS.md');

  if (!source.existsSync() || !installed.existsSync()) {
    return const ManualSyncStatus(matches: false, differingSections: []);
  }

  final sourceText = source.readAsStringSync();
  final installedText = installed.readAsStringSync();
  if (sourceText == installedText) {
    return const ManualSyncStatus(matches: true, differingSections: []);
  }

  final sourceHeadings = _sectionHeadings(sourceText);
  final installedHeadings = _sectionHeadings(installedText);
  final differing = <String>[];
  for (var i = 0; i < sourceHeadings.length; i++) {
    final heading = sourceHeadings[i];
    final sourceSection = _sectionBody(sourceText, heading);
    final installedSection = i < installedHeadings.length
        ? _sectionBody(installedText, installedHeadings[i])
        : null;
    if (heading !=
            (i < installedHeadings.length ? installedHeadings[i] : null) ||
        sourceSection != installedSection) {
      differing.add(heading);
    }
  }

  return ManualSyncStatus(matches: false, differingSections: differing);
}

String _sectionBody(String text, String heading) {
  final pattern = RegExp(
    '^##\\s+${RegExp.escape(heading)}\\s*\$',
    multiLine: true,
  );
  final match = pattern.firstMatch(text);
  if (match == null) return '';
  final rest = text.substring(match.end);
  final next = RegExp(r'^##\s', multiLine: true).firstMatch(rest);
  return (next == null ? rest : rest.substring(0, next.start)).trim();
}

/// `templates\AGENTS.md`'s own last commit — date and one-line message —
/// from the asa repo's real git history, same command shape
/// `git_state.dart`'s own `readGitState` already uses for a whole repo.
/// Null fields when git can't answer (no repo, no commits touching the
/// file, git missing) — shown as "unknown", never guessed.
Future<({DateTime? date, String? message})> manualLastChanged(
  String asaRepoPath,
) async {
  const args = ['log', '-1', '--format=%cI%x1f%s', '--', 'templates/AGENTS.md'];

  if (!Directory(asaRepoPath).existsSync()) return (date: null, message: null);

  final ProcessResult result;
  try {
    result = await Process.run('git', ['-C', asaRepoPath, ...args]);
  } on ProcessException {
    return (date: null, message: null);
  }
  if (result.exitCode != 0) return (date: null, message: null);

  final output = (result.stdout as String).trim();
  if (output.isEmpty) return (date: null, message: null);

  final parts = output.split('\u001f');
  if (parts.length < 2) return (date: null, message: null);

  return (date: DateTime.tryParse(parts[0]), message: parts[1]);
}
