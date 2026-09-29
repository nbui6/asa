/// An area — Round 34, ADR 0024: an area is the unit of a project's plan,
/// one page per area, `plan\<area>.md`. Its progress is derived from its
/// own tasks, never typed. **This round builds pages only** — ADR 0024's
/// 2026-09-26 revision: a `##`-section area inside `PLAN.md` is allowed by
/// the ADR and can come later if a real project asks for one (the rule of
/// two), but is not read here.
///
/// **Read-only, same as `plan.dart`.** Nothing in this file writes a byte
/// anywhere — Round 34 F's checkbox-ticking lives in `task_writer.dart`,
/// reusing its existing `setTaskDone`, not here.
library;

import 'dart:io';

import 'package:asa/core/decision.dart';
import 'package:asa/core/decisions_reader.dart' show FileAccess;
import 'package:asa/core/markdown.dart';
import 'package:asa/core/plan.dart';
import 'package:asa/core/project.dart';
import 'package:asa/core/task.dart';

/// One dated line from an area's `## Results` section — `- YYYY-MM-DD —
/// text`, newest first. A line that doesn't match that shape is kept too,
/// [date] null, [text] verbatim — "anything else in the section is shown
/// verbatim, undated, and never dropped."
class AreaResult {
  const AreaResult({required this.date, required this.text});

  final DateTime? date;
  final String text;
}

/// One area, read from its own `plan\<area>.md` page. Every field but
/// [name] and [sourceFile] is honest absence — "No goal yet," "Nothing yet"
/// — never invented, same discipline as [Project].
class Area {
  const Area({
    required this.name,
    required this.sourceFile,
    required this.tasks,
    required this.results,
    required this.decisionNumbers,
    required this.objectiveNumbers,
    this.summary,
    this.goal,
    this.planText,
  });

  final String name;
  final String sourceFile;
  final String? summary;
  final String? goal;
  final String? planText;

  /// The area's own `## Tasks` — the only part of this page Round 34 F may
  /// ever write to (checkbox state only, via `task_writer.dart`).
  final List<Task> tasks;

  final List<AreaResult> results;

  /// Every ADR named anywhere on the page — an area's own `## Decisions`
  /// section names them, but a mention anywhere else on the page counts
  /// too, same as `deriveLinks` reads everywhere else in this app.
  final List<String> decisionNumbers;

  /// Every `Objective N` named in the Goal section specifically — not the
  /// whole page. A different section naming an objective in passing is not
  /// this area's own claim on it.
  final List<String> objectiveNumbers;

  /// Done vs. total of every checkbox anywhere on the page, not only
  /// `## Tasks` — round-34.md's own note: "on `asa`, Round checkboxes named
  /// in the page count too, because they're checkboxes like any other."
  int get doneCount => tasks.where((t) => t.done).length;
  int get totalCount => tasks.length;
}

/// The order an area sorts in: its own leading number prefix
/// (`1-sales.md`) first, numerically: unprefixed areas follow, sorted by
/// [Area.name]. `readAreas` applies this; `parseArea` never sorts anything
/// on its own, one page at a time.
final RegExp _numberPrefix = RegExp(r'^(\d+)-(.+)$');

/// `plan\1-sales.md` → area name `Sales`; `plan\sales.md` → `Sales` too —
/// the number prefix sets sort order only and is never shown. Multi-word
/// slugs title-case: `customer-success` → `Customer Success`.
String _nameFromAspect(String aspect) {
  final withoutPrefix = _numberPrefix.firstMatch(aspect)?.group(2) ?? aspect;
  return withoutPrefix
      .split('-')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

int? _sortNumber(String aspect) {
  final match = _numberPrefix.firstMatch(aspect);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Parses one area page's raw text — pure, no disk access, so a fixture
/// string tests exactly what a real file would produce. [aspect] is the
/// filename stem (`plan\1-sales.md` → `1-sales`), the one place the sort
/// number and the display name both come from.
Area parseArea(
  String pageText, {
  required String sourceFile,
  required String aspect,
}) {
  final goal = sectionText(pageText, 'Goal');

  final objectiveNumbers = goal == null
      ? const <String>[]
      : _dedupe(
          deriveLinks(goal)
              .where((l) => l.kind == PlanLinkKind.objective)
              .map((l) => l.target),
        );

  // Every ADR anywhere on the page, not only ## Decisions — the sentence
  // this reference sits in still matters elsewhere (the Plan tab's own
  // chip), so this reads the whole page, same as deriveLinks always does.
  final decisionNumbers = _dedupe(
    deriveLinks(pageText)
        .where((l) => l.kind == PlanLinkKind.adr)
        .map((l) => l.target),
  );

  return Area(
    name: _nameFromAspect(aspect),
    sourceFile: sourceFile,
    summary: deriveDescription(pageText),
    goal: goal,
    planText: sectionText(pageText, 'Plan'),
    tasks: parseTasks(pageText),
    results: _parseResults(sectionText(pageText, 'Results')),
    decisionNumbers: decisionNumbers,
    objectiveNumbers: objectiveNumbers,
  );
}

List<String> _dedupe(Iterable<String> values) {
  final seen = <String>{};
  return [
    for (final value in values)
      if (seen.add(value)) value,
  ];
}

final RegExp _datedResultLine = RegExp(
  r'^-\s*(\d{4}-\d{2}-\d{2})\s*[—-]\s*(.*)$',
);

List<AreaResult> _parseResults(String? sectionBody) {
  if (sectionBody == null) return const [];

  final dated = <AreaResult>[];
  final undated = <AreaResult>[];

  for (final rawLine in sectionBody.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final match = _datedResultLine.firstMatch(line);
    if (match != null) {
      dated.add(
        AreaResult(
          date: DateTime.tryParse(match.group(1)!),
          text: match.group(2)!.trim(),
        ),
      );
    } else {
      // Not the dated shape — kept verbatim rather than dropped, only the
      // leading bullet marker (list formatting, not the result's own text)
      // stripped, if there is one.
      undated.add(
        AreaResult(date: null, text: line.replaceFirst(RegExp(r'^-\s*'), '')),
      );
    }
  }

  dated.sort((a, b) => b.date!.compareTo(a.date!));
  return [...dated, ...undated];
}

/// Every area under [projectFolder]'s `plan\` folder — empty when there is
/// no such folder, not an error. Sorted by each area's own number prefix,
/// then by name — [parseArea] itself never sorts.
Future<List<Area>> readAreas(String projectFolder) async {
  final planDir = Directory('$projectFolder${Platform.pathSeparator}plan');
  if (!planDir.existsSync()) return const [];

  final files = <File>[];
  await for (final entry in planDir.list(followLinks: false)) {
    if (entry is File && entry.path.toLowerCase().endsWith('.md')) {
      files.add(entry);
    }
  }

  // Sorted by each file's own aspect (number prefix first, numerically;
  // then by name) before parsing — parseArea itself never sorts anything.
  files.sort((a, b) => _compareAspects(_stemOf(a.path), _stemOf(b.path)));

  return [
    for (final file in files)
      parseArea(
        await file.readAsString(),
        sourceFile: file.path,
        aspect: _stemOf(file.path),
      ),
  ];
}

/// Same contract as [readAreas], through [FileAccess] instead of raw
/// `dart:io` — for a caller (`tasks_board.dart`'s
/// `buildProjectTasksSnapshots`) that already takes a [FileAccess] so its
/// own tests can fake the disk rather than touch it. `/` throughout, not
/// `Platform.pathSeparator` — the same convention every other
/// `FileAccess`-based reader in this codebase already uses, real and fake
/// alike.
Future<List<Area>> readAreasVia(String projectFolder, FileAccess files) async {
  // `Platform.pathSeparator`, not a literal `/` — found via a real-disk
  // link test (round-36 §3, L6): `readAreas`' own `sourceFile` comes back
  // from `dart:io`'s `Directory.list()`, which reports Windows paths with
  // `\`, never `/`. A caller comparing this `sourceFile` against that one
  // (`PlanView.areaToOpen`, matching by exact string) silently never
  // matched on Windows, even though both named the same real file.
  final sep = Platform.pathSeparator;
  final planDir = '$projectFolder${sep}plan';
  final names =
      (await files.listFiles(planDir))
          .where((name) => name.toLowerCase().endsWith('.md'))
          .toList()
        ..sort((a, b) => _compareAspects(_stemOf(a), _stemOf(b)));

  return [
    for (final name in names)
      parseArea(
        await files.readFile('$planDir$sep$name'),
        sourceFile: '$planDir$sep$name',
        aspect: _stemOf(name),
      ),
  ];
}

/// Round 39 cp2 — "an area knows its decisions: the ones it names, plus
/// the ones that name it." Every area whose own `## Decisions` mentions
/// [decision]'s number (the existing, forward direction: `area.dart`'s
/// own `decisionNumbers`), **or** whose name matches [decision]'s own
/// `**Links:** Area:` line (the new, reverse direction — a decision can
/// declare its area without that area's page needing to mention it back).
/// The one shared rule three view files each used to duplicate.
List<Area> areasNamingDecision(Decision? decision, List<Area> areas) {
  if (decision == null) return const [];
  final number = decision.number;
  final linkedArea = decision.links.area?.trim().toLowerCase();

  return [
    for (final area in areas)
      if ((number != null && area.decisionNumbers.contains(number)) ||
          (linkedArea != null && area.name.toLowerCase() == linkedArea))
        area,
  ];
}

int _compareAspects(String aspectA, String aspectB) {
  final numberA = _sortNumber(aspectA);
  final numberB = _sortNumber(aspectB);
  if (numberA != null && numberB != null) return numberA.compareTo(numberB);
  if (numberA != null) return -1;
  if (numberB != null) return 1;
  return _nameFromAspect(aspectA).compareTo(_nameFromAspect(aspectB));
}

String _stemOf(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}
