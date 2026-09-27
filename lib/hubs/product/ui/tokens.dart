/// Round 37, ADR 0029 — the only place a colour, text size, spacing value
/// or date format lives. Every other file under `lib/hubs/product/`
/// (everything except this folder) composes these and nothing else;
/// `test/one_look_test.dart` fails the build if a page file sets its own
/// instead. Exact values taken from `sketches\asa-one-look-v1.html`'s own
/// `:root`, never approximated.
library;

import 'package:flutter/material.dart';

/// Every named colour this app draws with. A page never writes
/// `Color(0x…)` itself — it picks a meaning ([AsaMeaning]) or, for plain
/// structural lines, one of these directly.
class AsaColors {
  const AsaColors._();

  static const ground = Color(0xFFF4F5F7);
  static const panel = Color(0xFFFFFFFF);
  static const ink = Color(0xFF16181D);
  static const ink2 = Color(0xFF5B6069);
  static const ink3 = Color(0xFF8C9199);
  static const line = Color(0xFFDCDFE4);
  static const soft = Color(0xFFEDEEF1);

  static const green = Color(0xFF2A7355);
  static const greenBg = Color(0xFFE8F2EC);
  static const blue = Color(0xFF2F5FA6);
  static const blueBg = Color(0xFFE6ECF7);
  static const amber = Color(0xFF8A5A12);
  static const amberBg = Color(0xFFFBF0DC);
  static const violet = Color(0xFF5B4A9C);
  static const violetBg = Color(0xFFEEEAF8);
  static const grey = Color(0xFF6B7079);
  static const greyBg = Color(0xFFEEF0F3);

  /// Round-36 §3, L3/L9 — a task row briefly highlighted on arrival.
  /// Not one of the five meanings: it marks "you just landed here", not
  /// a status.
  static const highlight = Color(0xFFFFF3CD);
}

/// ADR 0029 §2 — each colour means exactly one thing, never picked by
/// itself. `Pill` and `AreaChip` take one of these, never a raw colour.
enum AsaMeaning { done, needsYou, moving, area, quiet }

extension AsaMeaningColors on AsaMeaning {
  Color get fg => switch (this) {
    AsaMeaning.done => AsaColors.green,
    AsaMeaning.needsYou => AsaColors.amber,
    AsaMeaning.moving => AsaColors.blue,
    AsaMeaning.area => AsaColors.violet,
    AsaMeaning.quiet => AsaColors.grey,
  };

  Color get bg => switch (this) {
    AsaMeaning.done => AsaColors.greenBg,
    AsaMeaning.needsYou => AsaColors.amberBg,
    AsaMeaning.moving => AsaColors.blueBg,
    AsaMeaning.area => AsaColors.violetBg,
    AsaMeaning.quiet => AsaColors.greyBg,
  };
}

/// ADR 0017's seven statuses (`idea · discovery-done · building · ongoing
/// · shipped · paused · dropped`), mapped onto one meaning each. Never
/// [AsaMeaning.needsYou] (reserved for a decision waiting on a call) or
/// [AsaMeaning.area] (reserved for an area's own identity) — a project's
/// status is only ever done, moving, or quiet.
AsaMeaning meaningForStatus(String status) {
  switch (status.toLowerCase().trim()) {
    case 'shipped':
      return AsaMeaning.done;
    case 'building':
    case 'ongoing':
      return AsaMeaning.moving;
    default: // idea, discovery-done, paused, dropped, or anything unknown
      return AsaMeaning.quiet;
  }
}

/// A decision's own status. `proposed` (and a written-in-prose "waiting
/// on someone") still needs a call; anything already recorded — accepted,
/// superseded, rejected — is done.
AsaMeaning meaningForDecisionStatus(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('proposed') || lower.contains('waiting')) {
    return AsaMeaning.needsYou;
  }
  return AsaMeaning.done;
}

/// Five sizes, two weights, no others.
class AsaText {
  const AsaText._();

  static const pageName = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AsaColors.ink,
  );
  static const header = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AsaColors.ink,
  );
  static const rowName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AsaColors.ink,
  );
  static const body = TextStyle(fontSize: 14, color: AsaColors.ink);
  static const meta = TextStyle(fontSize: 12, color: AsaColors.ink3);
  static const sectionLabel = TextStyle(
    fontSize: 10.5,
    letterSpacing: 1.1,
    fontWeight: FontWeight.bold,
    color: AsaColors.ink3,
  );
}

/// Steps of 4 only — 4 · 8 · 12 · 16 · 24.
class AsaSpace {
  const AsaSpace._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}

/// Every page is one centred column, at most this wide.
const double asaContentWidth = 960;

/// One formatter per kind of date this app shows — round-37 §A.
///
/// - [asaListDate] — a list row: "24 Sep" (or "today").
/// - [asaDetailDate] — a single record's own detail view: "24 Sep 2026".
/// - A deadline stays `humanizeDeadline`'s own job ("Nov 2026") and a
///   freshness age stays `freshnessText`'s — both already one formatter
///   each in `lib/core/`, not duplicated here.
String? asaListDate(String? isoDate) => _formatted(isoDate, includeYear: false);

String? asaDetailDate(String? isoDate) =>
    _formatted(isoDate, includeYear: true);

const _months = [
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

String? _formatted(String? isoDate, {required bool includeYear}) {
  if (isoDate == null || isoDate.isEmpty) return null;
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;

  if (!includeYear) {
    final now = DateTime.now();
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return 'today';
    }
  }

  final monthDay = '${parsed.day} ${_months[parsed.month - 1]}';
  return includeYear ? '$monthDay ${parsed.year}' : monthDay;
}

/// Round 37 §D3 — "both show both": a decision's own number with its
/// title, the title cut to about 40 characters so a long one never
/// widens or wraps a chip. Used wherever a decision shows as a link
/// rather than its own full row (Plan tab, Strategy tab).
String decisionChipLabel(String? number, String title, {int maxLength = 40}) {
  final cut = title.length <= maxLength
      ? title
      : '${title.substring(0, maxLength).trimRight()}…';
  return number == null ? cut : '$number · $cut';
}

/// The only place a page's own lower-case word becomes a capitalised one
/// — `.toUpperCase()` itself is banned from a page file, so this one
/// letter's worth of case-changing lives here instead. Never full-caps: a
/// page name like "sales" becomes "Sales", not "SALES".
String titleCaseFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
