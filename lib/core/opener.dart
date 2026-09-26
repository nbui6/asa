/// Round 32/D — Round 3, the handoff, finally built. The text
/// "Start → Copy opener" puts on the clipboard, so a fresh Claude session
/// anywhere Nico works (desktop included, not only a terminal) can pick a
/// project up without him typing the same four sentences by hand every
/// time. Pure text-building; the clipboard write itself lives in
/// `hubs/product/start_menu.dart`.
library;

/// [projectFolder]'s own name — `asa` from `...\projects\asa` — is the
/// project note's own filename stem (`HOW-ASA-WORKS.md`'s own frontmatter
/// convention: `<folder>\<folder>.md`), not the human-readable
/// [projectName] a `project:` field may hold instead.
///
/// **[nextTaskText] and [areaSourceFile] — round-36 §3, L10.** Set only
/// by the Plan tab's own Next line, and only when there is a real task to
/// name (never the typed field or honest absence) — naming the next task
/// and its own area page means the AI opens the right page first, not
/// just the project folder. Both null keeps the opener exactly as it was
/// before this round, for every other caller (a project row, the header).
String openerText({
  required String projectName,
  required String projectFolder,
  String? nextTaskText,
  String? areaSourceFile,
}) {
  final slug = projectFolder
      .split(RegExp(r'[\\/]'))
      .where((segment) => segment.isNotEmpty)
      .last;

  final buffer = StringBuffer(
    'Working on $projectName. Project folder: $projectFolder.\n'
    'Read $slug.md and HOW-ASA-WORKS.md there first. Before you finish, '
    'update the note the way\nHOW-ASA-WORKS.md says.',
  );

  if (nextTaskText != null) {
    buffer.write('\nThe next task: $nextTaskText.');
    if (areaSourceFile != null) {
      buffer.write(' Its own page: $areaSourceFile.');
    }
  }

  return buffer.toString();
}
