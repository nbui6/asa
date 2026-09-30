/// A name → a filename-safe slug: lowercase, dashes, nothing else.
/// `Finance` → `finance`, `Q4 Ops & Runway` → `q4-ops-runway`. A name that
/// reduces to nothing (all punctuation, or empty) slugs to `''` — every
/// caller refuses to write a file with no real name in it rather than
/// treating that as a valid, empty slug.
///
/// Shared by `area_writer.dart` (an area's own filename), the decision
/// writer (`decisions\NNNN-slug.md`) and the new-project writer
/// (`projects\<slug>\`) — one rule, not three copies that could drift.
library;

final RegExp _notSlugChar = RegExp('[^a-z0-9]+');
final RegExp _edgeDashes = RegExp(r'^-+|-+$');

String slugify(String name) {
  final lower = name.trim().toLowerCase().replaceAll(_notSlugChar, '-');
  return lower.replaceAll(_edgeDashes, '');
}
