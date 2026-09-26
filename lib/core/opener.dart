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
String openerText({
  required String projectName,
  required String projectFolder,
}) {
  final slug = projectFolder
      .split(RegExp(r'[\\/]'))
      .where((segment) => segment.isNotEmpty)
      .last;

  return 'Working on $projectName. Project folder: $projectFolder.\n'
      'Read $slug.md and HOW-ASA-WORKS.md there first. Before you finish, '
      'update the note the way\nHOW-ASA-WORKS.md says.';
}
