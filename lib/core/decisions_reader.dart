/// Finds and reads a project's decisions from either real format on disk.
///
/// Two shapes are live today, in two different real projects, and one
/// project switched from the first to the second in a single day — "too
/// much file overhead for a project this size." Neither is the right one.
/// Both are read. Neither is converted. A project with both yields one
/// merged list, each item still naming its own file.
library;

import 'dart:io';

import 'package:asa/core/decision.dart';

/// The two things a decision source needs from the file system — nothing
/// more. Production passes [DiskFileAccess]; every test passes an
/// in-memory fake and touches no disk.
abstract class FileAccess {
  /// Names of the files directly inside [folder] — not recursive, not full
  /// paths. An empty list when the folder does not exist or is empty.
  Future<List<String>> listFiles(String folder);

  /// Reads one file's contents as text.
  Future<String> readFile(String path);
}

/// One place decisions can be read from. [AdrFolderSource] and
/// [DecisionLogSource] are its two implementations; a third format is
/// addable without editing either of them.
///
/// One method is deliberate — HANDOVER.md asks for exactly this seam so a
/// third format is Open/Closed-addable — not an oversight the lint below
/// should collapse into a top-level function.
// ignore: one_member_abstracts
abstract class DecisionSource {
  Future<List<DecisionReadResult>> readDecisions(
    String projectFolder,
    FileAccess files,
  );
}

/// `decisions/0001-slug.md`, one file per decision.
class AdrFolderSource implements DecisionSource {
  const AdrFolderSource();

  @override
  Future<List<DecisionReadResult>> readDecisions(
    String projectFolder,
    FileAccess files,
  ) async {
    final folder = '$projectFolder/decisions';
    final names = await files.listFiles(folder);
    final mdNames =
        names.where((name) => name.toLowerCase().endsWith('.md')).toList()
          ..sort();

    final results = <DecisionReadResult>[];
    for (final name in mdNames) {
      final path = '$folder/$name';
      final contents = await files.readFile(path);
      results.add(parseDecision(contents, path));
    }
    return results;
  }
}

/// `decisions.md`, one `## NNNN - Title` section per decision.
class DecisionLogSource implements DecisionSource {
  const DecisionLogSource();

  @override
  Future<List<DecisionReadResult>> readDecisions(
    String projectFolder,
    FileAccess files,
  ) async {
    final names = await files.listFiles(projectFolder);
    if (!names.contains('decisions.md')) return [];

    final path = '$projectFolder/decisions.md';
    final contents = await files.readFile(path);

    // Every `## ` line starts a new decision. Text before the first one —
    // the log's own title and intro — is not a decision and is dropped.
    final headings = RegExp(
      r'^##\s+\S.*$',
      multiLine: true,
    ).allMatches(contents).toList();

    final results = <DecisionReadResult>[];
    for (var i = 0; i < headings.length; i++) {
      final start = headings[i].start;
      final end = i + 1 < headings.length
          ? headings[i + 1].start
          : contents.length;
      final chunk = contents.substring(start, end).trim();
      if (chunk.isEmpty) continue;
      results.add(parseDecision(chunk, path));
    }
    return results;
  }
}

const List<DecisionSource> _sources = [AdrFolderSource(), DecisionLogSource()];

/// Reads every decision for a project, from every source. The normal
/// result for a project with none of either is an empty list, not an
/// error — two of six real projects are in exactly that state.
Future<List<DecisionReadResult>> readAllDecisions(
  String projectFolder,
  FileAccess files,
) async {
  final results = <DecisionReadResult>[];
  for (final source in _sources) {
    results.addAll(await source.readDecisions(projectFolder, files));
  }
  return results;
}

/// Newest date first. A decision with no parseable date sorts after the
/// ones that have one; a file that could not be parsed at all — no date to
/// sort by — is kept, always last, in the order it was found. Never
/// dropped: an unreadable decision is a finding, not noise.
List<DecisionReadResult> sortDecisionsNewestFirst(
  List<DecisionReadResult> results,
) {
  final dated = <DecisionReadResult>[];
  final undated = <DecisionReadResult>[];
  final unreadable = <DecisionReadResult>[];

  for (final result in results) {
    final decision = result.decision;
    if (decision == null) {
      unreadable.add(result);
      continue;
    }
    if (DateTime.tryParse(decision.date ?? '') != null) {
      dated.add(result);
    } else {
      undated.add(result);
    }
  }

  dated.sort(
    (a, b) =>
        DateTime.parse(b.decision!.date!)
            .compareTo(DateTime.parse(a.decision!.date!)),
  );

  return [...dated, ...undated, ...unreadable];
}

/// The real file system. Every other implementation of [FileAccess] in
/// this codebase is a test fake — this is the only one that ever touches a
/// real disk.
class DiskFileAccess implements FileAccess {
  const DiskFileAccess();

  @override
  Future<List<String>> listFiles(String folder) async {
    final dir = Directory(folder);
    if (!dir.existsSync()) return [];

    final names = <String>[];
    await for (final entry in dir.list(followLinks: false)) {
      if (entry is File) {
        names.add(entry.path.split(Platform.pathSeparator).last);
      }
    }
    return names;
  }

  @override
  Future<String> readFile(String path) => File(path).readAsString();
}
