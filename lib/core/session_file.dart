/// Round 39 — a project's own `.asa-session.md` (the manual's §7.11): the
/// session open now, or the last one. Pure Dart, no Flutter import.
library;

/// One session, read from `.asa-session.md`. Every field but [status] may
/// be missing — a session file with none of the body lines still parses,
/// just with nothing to show for them.
class SessionFile {
  const SessionFile({
    required this.status,
    this.opened,
    this.openedBy,
    this.updated,
    this.doing,
    this.lastDone,
    this.next,
  });

  /// `open` or `closed` — anything else reads as `closed`, the safe
  /// default: never reported as "someone may be working" on a guess.
  final String status;
  final DateTime? opened;
  final String? openedBy;
  final DateTime? updated;
  final String? doing;
  final String? lastDone;
  final String? next;

  bool get isOpen => status.trim().toLowerCase() == 'open';

  /// The manual's own rule (§3, step 1): open, and touched less than 2
  /// hours ago, means another AI may be mid-session right now.
  bool possiblyInProgress(DateTime now) {
    if (!isOpen) return false;
    final last = updated ?? opened;
    if (last == null) return false;
    return now.difference(last).inHours < 2;
  }

  /// Open, but silent for a long stretch — the drill's own "arrive after
  /// 3 days" case, and `asa-brief --all`'s "cut-off sessions" column.
  /// Two hours is "maybe still working"; this is "clearly not."
  bool isCutOff(DateTime now) {
    if (!isOpen) return false;
    final last = updated ?? opened;
    if (last == null) return false;
    return now.difference(last).inHours >= 2;
  }
}

final RegExp _frontmatterBlock = RegExp(
  r'^---\r?\n(.*?)\r?\n---',
  dotAll: true,
);

/// Parses a `.asa-session.md` file's own text. Null when the file doesn't
/// even have the frontmatter block — never a guess at a status.
SessionFile? parseSessionFile(String text) {
  final match = _frontmatterBlock.firstMatch(text.trim());
  if (match == null) return null;

  final front = _parseFrontmatter(match.group(1)!);
  final body = text.substring(match.end);

  return SessionFile(
    status: front['status'] ?? 'closed',
    opened: _parseDateTime(front['opened']),
    openedBy: front['opened-by'],
    updated: _parseDateTime(front['updated']),
    doing: _bodyLine(body, 'Doing'),
    lastDone: _bodyLine(body, 'Last done'),
    next: _bodyLine(body, 'Next'),
  );
}

Map<String, String> _parseFrontmatter(String block) {
  final result = <String, String>{};
  for (final line in block.split('\n')) {
    final colon = line.indexOf(':');
    if (colon == -1) continue;
    final key = line.substring(0, colon).trim();
    final value = line.substring(colon + 1).trim();
    if (key.isNotEmpty && value.isNotEmpty) result[key] = value;
  }
  return result;
}

DateTime? _parseDateTime(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

String? _bodyLine(String body, String label) {
  // `[ \t]*`, not `\s*` — `\s` matches a newline too, so a blank
  // `Doing:` line would otherwise swallow the next labeled line whole.
  final pattern = RegExp('^$label:[ \\t]*(.*)\$', multiLine: true);
  final match = pattern.firstMatch(body);
  if (match == null) return null;
  final value = match.group(1)!.trim();
  return value.isEmpty ? null : value;
}
