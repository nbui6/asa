/// Reads when a repository last changed.
///
/// This is the one thing Obsidian cannot do, and therefore Asa's whole reason
/// to exist. See decisions/0001-ui-platform.md.
library;

import 'dart:io';

/// The outcome of asking git when the last commit was.
///
/// Carries the raw command output so the screen can show exactly what git said.
/// PLAYBOOK.md section 7, rule 5: show the raw data at every boundary.
class GitState {
  const GitState({
    required this.command,
    required this.rawOutput,
    this.lastCommit,
    this.error,
  });

  final DateTime? lastCommit;
  final String? error;
  final String command;
  final String rawOutput;

  /// Whole days between the last commit and [now]. Null if there is no commit.
  int? daysSinceLastCommit(DateTime now) {
    final commit = lastCommit;
    if (commit == null) return null;
    return now.difference(commit).inDays;
  }
}

/// Runs `git log -1` in [repoPath] and returns when the last commit was made.
///
/// `-C` tells git which folder to work in, so nothing here changes the
/// working directory. `%cI` asks for the committer date in ISO 8601, which
/// DateTime.parse understands directly.
Future<GitState> readGitState(String repoPath) async {
  const args = ['log', '-1', '--format=%cI'];

  if (repoPath.trim().isEmpty) {
    return const GitState(
      error: 'No repo-path in the project note — nothing to ask git about',
      command: '(not run)',
      rawOutput: '',
    );
  }

  final command = 'git -C $repoPath ${args.join(' ')}';

  if (!Directory(repoPath).existsSync()) {
    return GitState(
      error: 'repo-path does not exist: $repoPath',
      command: command,
      rawOutput: '',
    );
  }

  final ProcessResult result;
  try {
    result = await Process.run('git', ['-C', repoPath, ...args]);
  } on ProcessException catch (e) {
    // git itself is missing or not on PATH. Say so plainly.
    return GitState(
      error: 'Could not run git: ${e.message}',
      command: command,
      rawOutput: '',
    );
  }

  final output = (result.stdout as String).trim();
  final errorOutput = (result.stderr as String).trim();

  if (result.exitCode != 0) {
    return GitState(
      error: 'git exited with code ${result.exitCode}',
      command: command,
      rawOutput: errorOutput.isEmpty ? output : errorOutput,
    );
  }

  if (output.isEmpty) {
    return GitState(
      error: 'git returned nothing — is this a repository with any commits?',
      command: command,
      rawOutput: output,
    );
  }

  final parsed = DateTime.tryParse(output);
  if (parsed == null) {
    return GitState(
      error: 'Could not read a date from git output',
      command: command,
      rawOutput: output,
    );
  }

  return GitState(lastCommit: parsed, command: command, rawOutput: output);
}
