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
import 'package:asa/core/markdown.dart';

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

/// An extension on [FileAccess], not a third abstract method: every
/// implementation of it in this codebase uses `implements`, which does
/// not inherit a default method body, so a new interface member would
/// force every real and fake implementation to add one for a check that
/// only `SketchApprovalsSource` (Round 29) needs.
extension FileAccessExistence on FileAccess {
  /// Whether [path] exists. Derived from `listFiles` — not used for a
  /// `.md` file's contents, only for checking a referenced image or
  /// source file is really there, where reading a binary `.png` as text
  /// would wrongly fail either way.
  Future<bool> exists(String path) async {
    final separator = path.lastIndexOf(RegExp(r'[\\/]'));
    if (separator == -1) return false;
    final folder = path.substring(0, separator);
    final name = path.substring(separator + 1);
    return (await listFiles(folder)).contains(name);
  }
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

    // Every `## ` line starts a new decision — except `## Your call`
    // (Delivery v2 A1), `decision_writer.dart`'s own `appendVerdictInLog`
    // inserts that one *inside* an existing entry, same shape a lone ADR
    // file's `## Your call` already is; splitting on it too would read a
    // recorded verdict back as a bogus decision of its own. Text before
    // the first real heading — the log's own title and intro — is not a
    // decision and is dropped.
    final headings = RegExp(
      r'^##\s+(?!Your call\s*$)\S.*$',
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

/// `sketches\APPROVED.md` — ADR 0022 point 5: sketch and HTML approvals
/// become a third decision source. Round 29. Already a decision log in
/// everything but name: three tables, one row per yes or no, dated, with
/// who decided and their own words as the verdict.
///
/// **Status mapping, named rather than guessed** (Round 29's own
/// instruction to say the choice and why): a row only ever lands in the
/// *approved* table once a yes has already arrived — the file's own rule
/// 1 — so every row there maps to `accepted`. The *trial* table is
/// "authorised to build, not yet approved," which is the same thing
/// [Decision.isProposed] already means elsewhere in this app, so it maps
/// to `proposed` with no verdict yet. The *rejected* table maps to
/// `rejected`, verdict carrying that row's own reason.
///
/// **Read structurally, not by re-reading a row's own prose.** The
/// `asa-proc2` row sits in the approved table yet its own cell says *"Not
/// a clean approval... do not build against this row"* — real data,
/// checked against the actual file, not invented for a test. Reclassifying
/// it by parsing that sentence would be Asa deciding something instead of
/// showing it; it is left `accepted` by table membership, verbatim
/// warning text and all, the same "Asa does not think" line Round 25
/// drew. A human reading the row sees the warning itself, not a status
/// this parser tried to infer from it.
class SketchApprovalsSource implements DecisionSource {
  const SketchApprovalsSource();

  @override
  Future<List<DecisionReadResult>> readDecisions(
    String projectFolder,
    FileAccess files,
  ) async {
    final names = await files.listFiles('$projectFolder/sketches');
    if (!names.contains('APPROVED.md')) return [];

    final path = '$projectFolder/sketches/APPROVED.md';
    final contents = await files.readFile(path);
    return _parseApprovals(contents, path, projectFolder, files);
  }
}

Future<List<DecisionReadResult>> _parseApprovals(
  String contents,
  String sourceFile,
  String projectFolder,
  FileAccess files,
) async {
  final firstH2 = firstUnfencedMatch(
    RegExp(r'^##\s', multiLine: true),
    contents,
  );
  final approvedBlock = firstH2 == null
      ? contents
      : contents.substring(0, firstH2.start);
  final trialBlock = sectionTextByPrefix(contents, 'Trial builds') ?? '';
  final rejectedBlock = sectionTextByPrefix(contents, 'Rejected') ?? '';

  final results = <DecisionReadResult>[];

  for (final row in _tableRows(approvedBlock)) {
    if (row.cells.length < 6) continue;
    final date = row.cells[0];
    final image = row.cells[2];
    final source = row.cells[3];
    final covers = row.cells[4];
    final saidVerbatim = row.cells[5];
    if (date.isEmpty && image.isEmpty && source.isEmpty) {
      continue; // a continuation note attached to the row above, not a row
    }

    results.add(
      await _approvalResult(
        sourceFile: sourceFile,
        projectFolder: projectFolder,
        files: files,
        rawRow: row.raw,
        title: covers.isEmpty ? saidVerbatim : covers,
        date: date,
        status: 'accepted',
        verdict: Verdict(accepted: true, date: date, reason: saidVerbatim),
        decisionText: covers.isEmpty ? saidVerbatim : covers,
        image: image,
        source: source,
      ),
    );
  }

  for (final row in _tableRows(trialBlock)) {
    if (row.cells.length < 6) continue;
    final date = row.cells[0];
    final image = row.cells[1];
    final source = row.cells[2];
    final covers = row.cells[3];
    final whatHappensNext = row.cells[5];
    if (date.isEmpty && image.isEmpty && source.isEmpty) continue;

    results.add(
      await _approvalResult(
        sourceFile: sourceFile,
        projectFolder: projectFolder,
        files: files,
        rawRow: row.raw,
        title: covers.isEmpty ? whatHappensNext : covers,
        date: date,
        status: 'proposed',
        verdict: null,
        decisionText: whatHappensNext.isEmpty ? covers : whatHappensNext,
        image: image,
        source: source,
      ),
    );
  }

  for (final row in _tableRows(rejectedBlock)) {
    if (row.cells.length < 3) continue;
    final date = row.cells[0];
    final image = row.cells[1];
    final why = row.cells[2];
    if (date.isEmpty && image.isEmpty) continue;

    results.add(
      await _approvalResult(
        sourceFile: sourceFile,
        projectFolder: projectFolder,
        files: files,
        rawRow: row.raw,
        title: _stemOfImagePath(image),
        date: date,
        status: 'rejected',
        verdict: Verdict(accepted: false, date: date, reason: why),
        decisionText: why,
        image: image,
        source: null,
      ),
    );
  }

  return results;
}

/// Builds one row's [DecisionReadResult] — or, when an image or source
/// path does not resolve, an *unreadable* result instead (rule 6: "show
/// every failure with its reason," the same convention every other
/// source in this file already uses for a row that could not be trusted)
/// rather than a decision silently missing the evidence it names.
Future<DecisionReadResult> _approvalResult({
  required String sourceFile,
  required String projectFolder,
  required FileAccess files,
  required String rawRow,
  required String title,
  required String date,
  required String status,
  required Verdict? verdict,
  required String decisionText,
  required String image,
  required String? source,
}) async {
  final problems = <String>[];
  if (image.isNotEmpty && !await _resolves(image, projectFolder, files)) {
    problems.add('Image not found: ${_stripBackticks(image)}');
  }
  if (source != null &&
      source.isNotEmpty &&
      !await _resolves(source, projectFolder, files)) {
    problems.add('Source not found: ${_stripBackticks(source)}');
  }

  if (problems.isNotEmpty) {
    return DecisionReadResult(
      error: problems.join('; '),
      rawText: rawRow,
      sourceFile: sourceFile,
    );
  }

  return DecisionReadResult(
    decision: Decision(
      title: title,
      date: date.isEmpty ? null : date,
      status: status,
      why: '',
      decision: decisionText,
      whatWouldChangeThis: '',
      sourceFile: sourceFile,
      verdict: verdict,
    ),
    sourceFile: sourceFile,
    rawText: rawRow,
  );
}

/// A path as written in `APPROVED.md` is rooted at the workspace —
/// `projects\asa\sketches\x.png`, one level above both this repo and
/// `projects\` (rule 17). [projectFolder] is `workspace\projects\` plus
/// the project's own folder name, so the path resolves by stripping a
/// `projects\` prefix followed by that same folder name, then checking
/// what remains against [projectFolder] itself.
Future<bool> _resolves(
  String rawPath,
  String projectFolder,
  FileAccess files,
) async {
  final normalized = _stripBackticks(rawPath).replaceAll('/', r'\');
  final projectName = projectFolder.split(RegExp(r'[\\/]')).last;
  final prefix = 'projects\\$projectName\\';
  if (!normalized.toLowerCase().startsWith(prefix.toLowerCase())) {
    return false;
  }
  final relative = normalized.substring(prefix.length).replaceAll(r'\', '/');
  return files.exists('$projectFolder/$relative');
}

String _stripBackticks(String value) => value.replaceAll('`', '').trim();

String _stemOfImagePath(String rawPath) {
  final cleaned = _stripBackticks(rawPath);
  final name = cleaned.split(RegExp(r'[\\/]')).last;
  return name.endsWith('.png') ? name.substring(0, name.length - 4) : name;
}

/// One markdown table row: the trimmed cell values, and the line as
/// written, kept for [DecisionReadResult.rawText] when a row's own image
/// or source turns out not to resolve.
typedef _TableRow = ({String raw, List<String> cells});

/// A block of markdown text's table rows, header and separator skipped.
/// Not a general markdown-table parser — this project has exactly one
/// file with tables in it, and every row here is one physical line, so a
/// pipe-split is enough (see `_splitRow`).
List<_TableRow> _tableRows(String block) {
  final lines = block
      .split('\n')
      .where((line) => line.trim().startsWith('|'))
      .toList();
  if (lines.length < 2) return [];
  return [
    for (final line in lines.skip(2))
      (raw: line.trim(), cells: _splitRow(line)),
  ];
}

List<String> _splitRow(String line) {
  var trimmed = line.trim();
  if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
  if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
  return trimmed.split('|').map((cell) => cell.trim()).toList();
}

const List<DecisionSource> _sources = [
  AdrFolderSource(),
  DecisionLogSource(),
  SketchApprovalsSource(),
];

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

/// The two groups the trial Decisions-tab grouping sorts an already-sorted
/// list into. Order within each group is unchanged.
typedef ReviewGroups = ({
  List<DecisionReadResult> needsALook,
  List<DecisionReadResult> settled,
});

/// Splits decisions into "Needs a look" and "Settled" — 2026-09-07's trial
/// grouping (`asa-decisions-v2.png`).
///
/// **Narrower than the trial's own rule.** The full rule is: needs a look
/// when `proposed`, *or* when `accepted` with a fired condition. Only the
/// `proposed` half is built — an accepted decision with a fired condition
/// has no data source yet, and guessing one from `whatWouldChangeThis`'s
/// raw prose was already rejected once, for the row-7 flag this reuses
/// (`asa-v01b-NOT-IN-V0.1.md`). Confirmed with the user, 2026-09-07: ship the
/// half that is real; the other half waits for its own decision on how a
/// decision file states a fired condition in a form a parser can read.
///
/// An unreadable result — no [DecisionReadResult.decision] to read a
/// status from — goes to "Settled": it is not asking for a call, it is
/// already visible as unreadable in its row.
ReviewGroups groupForReview(List<DecisionReadResult> decisions) {
  final needsALook = <DecisionReadResult>[];
  final settled = <DecisionReadResult>[];

  for (final result in decisions) {
    if (result.decision?.isProposed ?? false) {
      needsALook.add(result);
    } else {
      settled.add(result);
    }
  }

  return (needsALook: needsALook, settled: settled);
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
