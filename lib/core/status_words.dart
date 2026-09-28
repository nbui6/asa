/// Round 39 cp9b — ADR 0041's seven status words, replacing four of ADR
/// 0017's original seven. Pure Dart, no Flutter import.
///
/// The old words stay readable, forever — a note on another laptop, an
/// older fixture, a file nobody has opened since before this round. Asa
/// reads them as the new ones; it never writes them again.
library;

/// One of ADR 0041's seven stored words, with its on-screen label and its
/// grey hint (the ADR's own *Means* column) — enough for a status picker
/// to show without a UI file re-deriving any of it.
class StatusWord {
  const StatusWord({
    required this.stored,
    required this.label,
    required this.means,
  });

  /// What `status:` holds in the file, from now on.
  final String stored;

  /// What the picker and the pill show.
  final String label;

  /// The grey hint next to the label — the fact that tells two similar
  /// words apart (*In progress* vs *Ongoing*: will this ever be finished?).
  final String means;
}

/// ADR 0041's own table, in its own order.
const List<StatusWord> statusWords = [
  StatusWord(stored: 'idea', label: 'Idea', means: 'not started'),
  StatusWord(
    stored: 'discovery-done',
    label: 'Discovery done',
    means: 'understood, not started',
  ),
  StatusWord(
    stored: 'in-progress',
    label: 'In progress',
    means: 'being worked on, has a finish line',
  ),
  StatusWord(
    stored: 'ongoing',
    label: 'Ongoing',
    means: 'runs on, no finish line (e.g. building reports)',
  ),
  StatusWord(
    stored: 'on-hold',
    label: 'On hold',
    means: 'not now; leaves the list',
  ),
  StatusWord(stored: 'done', label: 'Done', means: 'finished; leaves the list'),
  StatusWord(
    stored: 'canceled',
    label: 'Canceled',
    means: 'not doing it; leaves the list',
  ),
];

/// ADR 0017's old words (and today's loose, unhyphenated shapes), each
/// mapped to the new word it means. Every key is already lowercase and
/// trimmed — [canonicalStatus] does the same to its own input before
/// looking here.
const Map<String, String> _aliases = {
  'building': 'in-progress',
  'in progress': 'in-progress',
  'paused': 'on-hold',
  'on hold': 'on-hold',
  'shipped': 'done',
  'dropped': 'canceled',
};

/// [raw] as ADR 0041 would store it: an old word or its loose shape reads
/// as the new one it means; a new word, or anything this doesn't
/// recognize (an unknown status, a typo), passes through unchanged so a
/// real finding stays visible rather than being silently absorbed.
String canonicalStatus(String raw) {
  final key = raw.toLowerCase().trim();
  return _aliases[key] ?? raw;
}

/// Whether [raw] is one of ADR 0017's old words — the thing `asa-check`
/// (cp4) reports as *old status word — write the new one instead*, never
/// an error, since Asa keeps reading it correctly either way.
bool isOldStatusWord(String raw) =>
    _aliases.containsKey(raw.toLowerCase().trim());

/// ADR 0036's hiding set, in the new words: a project this true for is
/// the kind that "leaves the list" — no code reads this yet (the list
/// itself isn't built), but the words it means are decided, here, once.
bool isHiddenStatus(String raw) {
  const hidden = {'on-hold', 'done', 'canceled'};
  return hidden.contains(canonicalStatus(raw).toLowerCase().trim());
}

/// The picker/pill label for [raw] — an old word's own new label (`Done`
/// for `shipped`), or [raw] itself, title-cased, when nothing recognizes
/// it, so a real unknown status still reads as something rather than
/// vanishing.
String statusLabel(String raw) {
  final canonical = canonicalStatus(raw);
  for (final word in statusWords) {
    if (word.stored == canonical) return word.label;
  }
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}
