/// Product Hub — the Plan tab. Round 27, the visible half of Round 26.
///
/// Sketch: `sketches\asa-plan-v3.html`, the redraw. The first draft,
/// `asa-plan-v2.html`, was drawn straight from Round 26's data and Nico
/// found it overwhelming — *"the sections in Plan + derived links parts
/// are just very overwhelmed for me."* `persona-check` against
/// `PERSONA.md` agreed: BLOCK, not a new finding — this persona already
/// abandoned Obsidian for the same reason once. v3 fixes it by collapsing
/// everything by default and showing only what a real heading says,
/// never a paraphrase of it — v2's real defect was inventing summary text
/// for a section that had none.
///
/// **Read-only, all of it — ADR 0021 point 4.** Nothing here writes to
/// `PLAN.md`, a plan page, or anything else. Tapping a change entry, a
/// page, or a section opens that page's real `sourceFile` with
/// `open_url.dart`; nothing is ever pre-read or summarised for display.
library;

import 'package:asa/core/decision.dart';
import 'package:asa/core/markdown.dart';
import 'package:asa/core/open_url.dart';
import 'package:asa/core/plan.dart';
import 'package:flutter/material.dart';

class PlanView extends StatefulWidget {
  const PlanView({
    required this.plan,
    required this.decisions,
    required this.projectSourceFile,
    super.key,
  });

  final Plan plan;

  /// Already loaded by `ProjectScreen` for the Decisions tab — reused here
  /// so a "what changed" ADR chip can open the real decision file instead
  /// of `PLAN.md`, without this widget reading the file system itself.
  final List<DecisionReadResult> decisions;

  /// A Round has no file of its own — the project's own note is where its
  /// `## Roadmap` entry actually lives, so a Round chip opens this rather
  /// than `PLAN.md` too. Same fallback when an ADR chip's number cannot be
  /// found in [decisions].
  final String projectSourceFile;

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  // Every group starts collapsed — this round's own scope line, not an
  // oversight, and deliberately not persisted across a reload or a tab
  // switch: a fresh `PlanView` always starts from the same, predictable
  // "nothing open yet" state.
  // Membership means "expanded" — an empty set, the starting state, means
  // every group is collapsed by default without having to know every
  // group's id in advance.
  final Set<int> _expanded = {};
  bool _olderChangesShown = false;
  bool _moreGroupsShown = false;

  // Persona-check, re-run against this real screen: showing all ~24 of a
  // real project's top-level groups at once — even one line each,
  // collapsed — reproduces the row-count version of the overwhelm that
  // blocked `asa-plan-v2.html`, not just the per-row density it already
  // fixed. `asa-plan-v3.html` draws 4 before its own "+N more, collapsed"
  // line; 6 keeps that same shape with a little more room before the
  // fold — a bounded number, picked and named, same discipline this
  // project already asks of any other bounded list.
  static const _topLevelGroupCap = 6;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('What changed'),
        _whatChanged(),
        const SizedBox(height: 20),
        _label('The plan'),
        ..._outline(),
        const SizedBox(height: 16),
        _strategyPointer(),
        const SizedBox(height: 12),
        _readOnlyNote(),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // --- What changed --------------------------------------------------

  Widget _whatChanged() {
    final entries = _changeEntries(widget.plan);
    if (entries.isEmpty) {
      return Text(
        'Nothing dated yet.',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    final shown = _olderChangesShown ? entries : entries.take(3).toList();
    final olderCount = entries.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in shown) _changeRow(entry),
        if (olderCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => setState(() => _olderChangesShown = true),
              child: Text(
                'older ($olderCount) ↓',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _changeRow(_ChangeEntry entry) {
    final links = _dedupeLinks(entry.links);
    return InkWell(
      onTap: () => openUrl(entry.sourceFile),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                _humanDate(entry.date),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(entry.text.isEmpty ? '(untitled)' : entry.text),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final link in links) _linkChip(link)],
            ),
          ],
        ),
      ),
    );
  }

  /// ADR 0021's revision #2: "a derived link is rendered as the sentence
  /// it came from — never as a bare 'related' row." The chip itself stays
  /// a two-word tag — persona-check, re-run against this real screen,
  /// found the sketch's own bare chips read fine collapsed but say
  /// nothing on their own once you look for the sentence the whole point
  /// of Round 26 was to keep. A tooltip costs nothing until asked for, so
  /// both are true at once: compact by default, the real sentence one
  /// hover away, never paraphrased.
  Widget _linkChip(PlanLink link) {
    final isAdr = link.kind == PlanLinkKind.adr;
    return Tooltip(
      message: link.sentence,
      child: InkWell(
        onTap: () => openUrl(_targetFor(link)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isAdr ? const Color(0xFFE6ECF7) : const Color(0xFFFAF0DA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            isAdr ? 'ADR ${link.target}' : 'Round ${link.target}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isAdr ? const Color(0xFF2F5FA6) : const Color(0xFF8A5A12),
            ),
          ),
        ),
      ),
    );
  }

  /// The real decision file for an ADR chip, when one is already loaded;
  /// the project's own note (never `PLAN.md`) for a Round chip, or for an
  /// ADR number that does not match anything in [PlanView.decisions] —
  /// still a real, more specific file than the plan, never a dead tap.
  String _targetFor(PlanLink link) {
    if (link.kind == PlanLinkKind.adr) {
      for (final result in widget.decisions) {
        if (result.decision?.number == link.target) {
          return result.decision!.sourceFile;
        }
      }
    }
    return widget.projectSourceFile;
  }

  // --- The outline -----------------------------------------------------

  /// The front page's own `##` sections sit directly at the top level —
  /// today's only real shape, and what `asa-plan-v3.html` draws. Any
  /// `plan\*.md` page (none exist on any real project yet) gets its own
  /// top-level group first, named by its aspect, so a real second page
  /// does not dump its sections in flat alongside the front page's own.
  ///
  /// Capped at [_topLevelGroupCap], same "older, collapsed" shape as
  /// "what changed" — every group is one line while collapsed, but a
  /// real project has enough of them that showing all of them at once is
  /// its own kind of overwhelm, independent of any one row's density.
  List<Widget> _outline() {
    final all = <Widget>[];
    for (final page in widget.plan.pages) {
      final roots = _sectionTree(page.sections);
      if (page.aspect == null) {
        for (final node in roots) {
          all.add(_sectionGroup(node, depth: 0, sourceFile: page.sourceFile));
        }
      } else {
        all.add(_pageGroup(page, roots));
      }
    }

    if (_moreGroupsShown || all.length <= _topLevelGroupCap) return all;

    final shown = all.take(_topLevelGroupCap).toList();
    final more = all.length - shown.length;
    shown.add(
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: InkWell(
          onTap: () => setState(() => _moreGroupsShown = true),
          child: Text(
            '+ $more more, collapsed ↓',
            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          ),
        ),
      ),
    );
    return shown;
  }

  Widget _pageGroup(PlanPage page, List<_SectionNode> roots) {
    final id = identityHashCode(page);
    final collapsed = !_expanded.contains(id);
    return _toggleGroup(
      label: _titleCase(page.aspect!),
      hasChildren: true, // a page is always worth opening, even with 0 sections
      collapsed: collapsed,
      onToggleCollapse: () => _flip(id),
      onOpen: () => openUrl(page.sourceFile),
      depth: 0,
      children: collapsed
          ? const []
          : [
              for (final node in roots)
                _sectionGroup(node, depth: 1, sourceFile: page.sourceFile),
            ],
    );
  }

  Widget _sectionGroup(
    _SectionNode node, {
    required int depth,
    required String sourceFile,
  }) {
    final id = identityHashCode(node.section);
    final collapsed = !_expanded.contains(id);
    final hasChildren = node.children.isNotEmpty;

    return _toggleGroup(
      label: node.section.heading,
      hasChildren: hasChildren,
      collapsed: collapsed,
      onToggleCollapse: () => _flip(id),
      onOpen: () => openUrl(sourceFile),
      depth: depth,
      children: (!hasChildren || collapsed)
          ? const []
          : [
              for (final child in node.children)
                _sectionGroup(child, depth: depth + 1, sourceFile: sourceFile),
            ],
    );
  }

  void _flip(int id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  Widget _toggleGroup({
    required String label,
    required bool hasChildren,
    required bool collapsed,
    required VoidCallback onToggleCollapse,
    required VoidCallback onOpen,
    required int depth,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                child: hasChildren
                    ? InkWell(
                        onTap: onToggleCollapse,
                        child: Icon(
                          collapsed ? Icons.chevron_right : Icons.expand_more,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: InkWell(
                  onTap: onOpen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(label),
                  ),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  // --- Strategy pointer and the read-only note ------------------------

  Widget _strategyPointer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'The two non-negotiable gates live one tab over',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ),
          Text(
            'Strategy →',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCDFE4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Read-only. Tapping anything opens the real file. Nothing here '
        'edits PLAN.md.',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
      ),
    );
  }
}

// --- Pure helpers, tested directly ------------------------------------

class _ChangeEntry {
  _ChangeEntry({
    required this.date,
    required this.text,
    required this.sourceFile,
    required this.links,
    required this.sequence,
  });

  final DateTime date;
  final String text;
  final String sourceFile;
  final List<PlanLink> links;

  /// Encounter order across every page, in file order — the tie-break
  /// for two entries dated the same day. `PLAN.md`'s own convention is
  /// append-at-the-end, so a later position in the file is a later entry.
  final int sequence;
}

final RegExp _isoDateHeading = RegExp(r'^(\d{4}-\d{2}-\d{2})\b\s*(.*)$');

/// Every dated heading across every page of [plan], newest first — same
/// date sorts by file position, later wins. Round 27's own instruction:
/// "newest means the latest date, and among equal dates the one that
/// appears later in the file."
List<_ChangeEntry> _changeEntries(Plan plan) {
  final entries = <_ChangeEntry>[];
  var sequence = 0;

  for (final page in plan.pages) {
    for (final section in page.sections) {
      final match = _isoDateHeading.firstMatch(section.heading);
      if (match == null) continue;
      final date = DateTime.tryParse(match.group(1)!);
      if (date == null) continue;

      entries.add(
        _ChangeEntry(
          date: date,
          text: match.group(2)!.replaceFirst(RegExp(r'^[\s—-]+'), '').trim(),
          sourceFile: page.sourceFile,
          links: deriveLinks(section.body)
              .where((l) => l.kind != PlanLinkKind.wikilink)
              .toList(),
          sequence: sequence++,
        ),
      );
    }
  }

  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.sequence.compareTo(a.sequence);
  });
  return entries;
}

/// One mention deduplicated to one chip — a section that names "Round 26"
/// three times shows one "Round 26" chip, not three.
List<PlanLink> _dedupeLinks(List<PlanLink> links) {
  final seen = <String>{};
  final result = <PlanLink>[];
  for (final link in links) {
    final key = '${link.kind}:${link.target}';
    if (seen.add(key)) result.add(link);
  }
  return result;
}

/// One heading and its own nested headings — `###` under the `##` it
/// physically follows, and so on. [Section] itself is a flat, file-order
/// list; this is the one place that turns it into the tree the outline
/// actually renders, built from the same [Section]s Round 26 already
/// parsed rather than re-reading anything.
class _SectionNode {
  _SectionNode(this.section, this.children);

  final Section section;
  final List<_SectionNode> children;
}

/// [sections] filtered to level 2+ (a page's own `#` title is not a
/// section a human toggles) and nested by heading level.
List<_SectionNode> _sectionTree(List<Section> sections) {
  final roots = <_SectionNode>[];
  final stack = <_SectionNode>[];

  for (final section in sections) {
    if (section.level < 2) continue;
    final node = _SectionNode(section, []);
    while (stack.isNotEmpty && stack.last.section.level >= section.level) {
      stack.removeLast();
    }
    if (stack.isEmpty) {
      roots.add(node);
    } else {
      stack.last.children.add(node);
    }
    stack.add(node);
  }
  return roots;
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

/// `today` / `yesterday` / `14 Sep` — the same convention
/// `project_screen.dart`'s own `_humanDate` already uses for a decision's
/// date, duplicated rather than shared: that one is private to a
/// different file and this round is scoped to the Plan tab, not a
/// refactor of it.
String _humanDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'yesterday';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
