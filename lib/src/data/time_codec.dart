/// Time conventions for صرفتي storage and calendar math.
///
/// ## date-only vs instant
///
/// **date-only** — calendar day the user intends (expense picker). Only
/// year/month/day in the device local zone matter. Never read UTC Y/M/D for
/// these values (that causes day shifts near midnight / across offsets).
/// - SQLite: UTC epoch ms of that **local** day's midnight.
/// - JSON: `YYYY-MM-DD` (legacy ISO without `Z` still accepted on import).
///
/// **instant** — a point on the timeline (payment recorded-at, `exportedAt`).
/// - SQLite: UTC epoch milliseconds.
/// - JSON: ISO-8601 with explicit `Z` (UTC).
///
/// Convert to local wall time only for display and calendar calculations
/// (month membership, due dates, period filters).
library;

final _dateOnlyPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Local calendar date at midnight (time discarded; UTC input converted first).
DateTime localDateOnly(DateTime value) {
  final local = value.isUtc ? value.toLocal() : value;
  return DateTime(local.year, local.month, local.day);
}

/// True when [a] and [b] fall on the same local calendar month.
bool isSameLocalMonth(DateTime a, DateTime b) {
  final left = localDateOnly(a);
  final right = localDateOnly(b);
  return left.year == right.year && left.month == right.month;
}

/// Encodes a **date-only** value as UTC ms of local midnight for that day.
int encodeLocalDateToUtcMs(DateTime date) =>
    localDateOnly(date).toUtc().millisecondsSinceEpoch;

/// Decodes SQLite ms back to a local **date-only** [DateTime].
DateTime decodeLocalDateFromUtcMs(int utcMs) =>
    localDateOnly(DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true));

/// Encodes an **instant** as UTC epoch milliseconds.
int encodeInstantToUtcMs(DateTime instant) =>
    instant.toUtc().millisecondsSinceEpoch;

/// Decodes SQLite ms to a UTC **instant** ([DateTime.isUtc] is true).
DateTime decodeInstantFromUtcMs(int utcMs) =>
    DateTime.fromMillisecondsSinceEpoch(utcMs, isUtc: true);

/// JSON for a **date-only** field: `YYYY-MM-DD`.
String encodeLocalDateToJson(DateTime date) {
  final local = localDateOnly(date);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a **date-only** JSON value without shifting the intended local day.
///
/// Accepts `YYYY-MM-DD`, legacy local ISO without zone, and zoned/UTC ISO
/// (uses the local calendar day of that instant).
DateTime decodeLocalDateFromJson(String raw) {
  final trimmed = raw.trim();
  final dateOnly = _dateOnlyPattern.firstMatch(trimmed);
  if (dateOnly != null) {
    return DateTime(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    );
  }
  return localDateOnly(DateTime.parse(trimmed));
}

/// JSON for an **instant**: ISO-8601 UTC with `Z`.
String encodeInstantToUtcIso(DateTime instant) =>
    instant.toUtc().toIso8601String();

/// Parses an **instant** JSON value into a UTC [DateTime].
DateTime decodeInstantFromJson(String raw) {
  final parsed = DateTime.parse(raw.trim());
  return parsed.isUtc ? parsed : parsed.toUtc();
}

/// Next statement/due calendar date on or after [today] for [dayOfMonth].
///
/// [today] and the result are local date-only values. Uses Dart's local
/// [DateTime] constructor so month length and DST transitions stay correct.
DateTime nextLocalDueDate(DateTime today, int dayOfMonth) {
  final localToday = localDateOnly(today);
  var due = DateTime(localToday.year, localToday.month, dayOfMonth);
  if (due.isBefore(localToday)) {
    due = DateTime(localToday.year, localToday.month + 1, dayOfMonth);
  }
  return due;
}

/// Inclusive local-day distance from [from] to [to] used for "days until due".
int localCalendarDaysUntil(DateTime from, DateTime to) =>
    localDateOnly(to).difference(localDateOnly(from)).inDays + 1;
