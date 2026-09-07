/// One task, parsed from a project note's `## Tasks` section. Pure Dart,
/// no Flutter import — same rule as every other file in `core/`.
///
/// The contract below is taken from four real project notes, not invented:
/// `asa.md`, `partner-trial-process.md`, `data-deletion-policy.md` (a flat
/// checkbox list, no tags), and `vibe-coding-kit.md` (no `## Tasks` section
/// at all — absent is valid, an empty list, not an error).
library;

import 'package:asa/core/markdown.dart';

/// One `- [ ]` or `- [x]` line inside a `## Tasks` section.
class Task {
  const Task({
    required this.rawLine,
    required this.text,
    required this.done,
    this.isCode = false,
    this.crossProjectRef,
  });

  /// The exact original line this was parsed from, whitespace and all —
  /// used to find this exact task again when writing a change back to the
  /// file. Never shown on screen.
  final String rawLine;

  /// Display text, with the trailing `(Code)` tag and any `[[project]]`
  /// reference removed — both are rendered as their own small marker
  /// instead of being read as part of the sentence.
  final String text;

  final bool done;

  /// True when the line ends in a trailing `(Code)` marker — this task is
  /// not Nico's. Anchored to the end of the line on purpose: a task that
  /// merely mentions the word "code" elsewhere in its text is not this.
  final bool isCode;

  /// The slug of another project this task names — e.g.
  /// `license-commerce-integration` from `[[license-commerce-integration]]`
  /// — shown as a small chip. Not resolved against real projects in this
  /// version; static display is enough.
  final String? crossProjectRef;
}

final RegExp _checkboxLine = RegExp(r'^\s*-\s*\[([ xX])\]\s*(.*)$');
final RegExp _trailingCodeTag = RegExp(r'\(code\)\s*$', caseSensitive: false);
final RegExp _crossProjectPattern = RegExp(r'\[\[([^\]]+)\]\]');

/// Reads the `## Tasks` section of a project note as a flat list. No
/// nested indentation is parsed — no real project note has a real subtask
/// yet; when one does, that is its own round, not guessed here.
///
/// Returns an empty list, never an error, when there is no `## Tasks`
/// section — `vibe-coding-kit.md` is exactly that case today.
List<Task> parseTasks(String fileContents) {
  final section = sectionText(fileContents, 'Tasks');
  if (section == null) return const [];

  final tasks = <Task>[];
  for (final line in section.split('\n')) {
    final match = _checkboxLine.firstMatch(line);
    if (match == null) continue;

    final done = match.group(1)!.toLowerCase() == 'x';
    var text = match.group(2)!.trim();

    final isCode = _trailingCodeTag.hasMatch(text);
    if (isCode) {
      text = text.replaceFirst(_trailingCodeTag, '').trim();
    }

    String? crossProjectRef;
    final refMatch = _crossProjectPattern.firstMatch(text);
    if (refMatch != null) {
      crossProjectRef = refMatch.group(1);
      // Drop the whole trailing fragment naming the other project — the
      // em dash introducing it, if there is one, and the reference itself.
      final dashBefore = text.lastIndexOf('—', refMatch.start);
      final cutAt = dashBefore == -1 ? refMatch.start : dashBefore;
      text = text.substring(0, cutAt).trim();
    }

    tasks.add(
      Task(
        rawLine: line,
        text: text,
        done: done,
        isCode: isCode,
        crossProjectRef: crossProjectRef,
      ),
    );
  }
  return tasks;
}
