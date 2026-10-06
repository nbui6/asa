/// A project's strategy — ADR 0025: origin, who it's for, pain points, and
/// three to five objectives with their own evidence. Read from
/// `CHARTER.md`'s own fixed sections; nothing here is written by Asa.
library;

import 'dart:io';

import 'package:asa/core/markdown.dart';

/// One objective — ADR 0025 rule 2: evidence, never a metric target.
class Objective {
  const Objective({
    required this.title,
    required this.evidence,
    required this.sentence,
  });

  final String title;

  /// The "Would show:" line, verbatim — a sentence a person can check,
  /// not a number.
  final String evidence;

  /// This objective's own raw paragraph, verbatim — the string a caller
  /// runs `deriveLinks` (`plan.dart`, already takes any string) over to
  /// find the Rounds it claims, filtered to `PlanLinkKind.round`. Not
  /// parsed into a list here: an objective naming its own Rounds in prose
  /// is ADR 0024's "named by whoever points at it" rule, the same
  /// derivation Round 26 already built, not a second mechanism.
  final String sentence;
}

/// A project's whole strategy. [isEmpty] is true unless every one of the
/// four fixed sections is present — ADR 0025's own all-or-nothing rule,
/// same as `Plan` (Round 26): no partial screen built from a project that
/// only half-adopted the shape.
class Strategy {
  const Strategy({
    required this.fileExists,
    required this.origin,
    required this.whoItsFor,
    required this.painPoints,
    required this.objectives,
  });

  /// ADR 0050 — whether `CHARTER.md` itself exists, independent of
  /// [isEmpty]: a project can have the file with some sections filled and
  /// others not, which [isEmpty]'s own all-or-nothing reading can't tell
  /// apart from no file at all. The Strategy tab now uses this one, not
  /// [isEmpty], to decide whether there is a file to show sections of.
  final bool fileExists;

  final String? origin;
  final String? whoItsFor;

  /// From the first `N.` numbered line onward, trimmed — not the whole
  /// `## Pain points` section verbatim. Found 2026-09-14, real data:
  /// `CHARTER.md`'s own section carries an editorial preamble about when
  /// and why it was moved, before the three real pain points start.
  /// Showing that preamble under "Pain points" is what `sectionText`
  /// literally returns, but it is commentary about the section, not a
  /// pain point — dropping a leading paragraph before the first list
  /// item is the same structural rule [_parseObjectives] already applies
  /// to its own section, not a new judgment about what counts.
  final String? painPoints;
  final List<Objective> objectives;

  bool get isEmpty =>
      origin == null ||
      whoItsFor == null ||
      painPoints == null ||
      objectives.isEmpty;
}

final RegExp _objectiveMarker = RegExp(r'^(\d+)\.\s', multiLine: true);
final RegExp _titleSpan = RegExp(r'^\*\*(.+?)\*\*');
final RegExp _endOfList = RegExp(r'\n\s*\n(?=\S)');

/// Reads `CHARTER.md` inside [projectFolder]. No file, or a file missing
/// any of the four sections, comes back as `Strategy.isEmpty` — absent,
/// not a half-built screen.
Future<Strategy> readCharter(String projectFolder) async {
  final file = File('$projectFolder${Platform.pathSeparator}CHARTER.md');
  if (!file.existsSync()) {
    return const Strategy(
      fileExists: false,
      origin: null,
      whoItsFor: null,
      painPoints: null,
      objectives: [],
    );
  }
  final contents = await file.readAsString();

  return Strategy(
    fileExists: true,
    origin: sectionText(contents, 'Origin'),
    whoItsFor: sectionText(contents, "Who it's for"),
    painPoints: _numberedListIn(sectionText(contents, 'Pain points')),
    objectives: _parseObjectives(sectionText(contents, 'Objectives') ?? ''),
  );
}

List<Objective> _parseObjectives(String section) {
  final markers = _objectiveMarker.allMatches(section).toList();
  final objectives = <Objective>[];

  for (var i = 0; i < markers.length; i++) {
    final start = markers[i].end;
    int end;
    if (i + 1 < markers.length) {
      end = markers[i + 1].start;
    } else {
      final rest = section.substring(start);
      final closing = _endOfList.firstMatch(rest);
      end = closing != null ? start + closing.start : section.length;
    }

    final block = section.substring(start, end).trim();
    final titleMatch = _titleSpan.firstMatch(block);
    if (titleMatch == null) continue; // not a real objective item

    objectives.add(
      Objective(
        title: titleMatch.group(1)!.trim(),
        evidence: _evidenceIn(block),
        sentence: block,
      ),
    );
  }

  return objectives;
}

String _evidenceIn(String block) {
  final wouldShow = block.indexOf('Would show:');
  if (wouldShow == -1) return '';
  final start = wouldShow + 'Would show:'.length;

  final servedBy = block.indexOf('Served by', start);
  final end = servedBy == -1 ? block.length : servedBy;

  return _collapseWhitespace(block.substring(start, end));
}

/// Round 38 §D.1 — "anything else in `CHARTER.md` under that objective
/// shows only when the row is opened, under *Why*": whatever real
/// content sits after the *Would show:* line — most often "Served by
/// Round N, Round M…", a real objective's own sentence (asa's own
/// CHARTER.md) — collapsed to one paragraph, or null when there is
/// nothing past the evidence line at all.
String? objectiveWhy(Objective objective) {
  final block = objective.sentence;
  final wouldShow = block.indexOf('Would show:');
  if (wouldShow == -1) return null;

  final servedBy = block.indexOf('Served by', wouldShow);
  if (servedBy == -1) return null;

  final rest = _collapseWhitespace(block.substring(servedBy));
  return rest.isEmpty ? null : rest;
}

/// Round 37 cp6, §D5 — a markdown paragraph often wraps across physical
/// lines in the source file (`CHARTER.md`'s own 80-ish-column style);
/// `.trim()` alone only strips the ends, leaving the source's own line
/// break — and the next line's leading indent — literally inside the
/// string. Rendered, that reads as a hard line break with a stray
/// indent, not the single sentence it is. Every internal run of
/// whitespace, newlines included, becomes one space.
String _collapseWhitespace(String text) =>
    text.trim().replaceAll(RegExp(r'\s+'), ' ');

final RegExp _listMarker = RegExp(r'^\d+\.\s', multiLine: true);

/// [section] from its first numbered-list marker onward, trimmed — a
/// section that opens with ordinary prose before the list starts has
/// that prose dropped; a section that is nothing but the list, or has no
/// numbered list at all, is returned unchanged. Null stays null.
String? _numberedListIn(String? section) {
  if (section == null) return null;
  final marker = _listMarker.firstMatch(section);
  if (marker == null) return section;
  return section.substring(marker.start).trim();
}
