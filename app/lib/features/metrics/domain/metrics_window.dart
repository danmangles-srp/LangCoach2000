// Pure-Dart window + bucket arithmetic for the analytics feature (T6.2, FR-
// 1.5.1). All helpers are side-effect free and pinned to a caller-supplied
// "now" so the suite is deterministic. Local time throughout — metrics are
// day-grained and the user reads them in their own timezone.
//
// All day-stepping uses calendar arithmetic (`DateTime(y, m, d ± n)`) rather
// than absolute-millis `Duration` math, so bucket boundaries stay on local
// midnights across DST transitions. A `Duration(days: 1)` subtract/add crosses
// a 23- or 25-hour spring/fall day at the wrong local instant and pulls the
// bucket key off by a week near the boundary.
//
// Granularity:
//   daily   → bucket = [date 00:00, date+1 00:00)
//   weekly  → bucket = [weekStart 00:00, weekStart+7d 00:00), where weekStart
//             is the most recent occurrence of [weekStartWeekday] at or before
//             the instant. Default weekStartWeekday = Saturday.
//   monthly → bucket = [first-of-month 00:00, first-of-next-month 00:00)
//
// The half-open convention is load-bearing: an event exactly at [until] is
// excluded, so adjacent buckets partition time with no double-count.

/// The granularity a dashboard or report renders at.
enum MetricsGranularity { daily, weekly, monthly }

/// A half-open time range [from, until).
class MetricsWindow {
  const MetricsWindow({required this.from, required this.until});

  final DateTime from;
  final DateTime until;

  Duration get span => until.difference(from);

  /// True iff [instant] falls in [from, until).
  bool contains(DateTime instant) =>
      !instant.isBefore(from) && instant.isBefore(until);

  @override
  String toString() => 'MetricsWindow[$from, $until)';
}

/// Compute the start of the bucket containing [instant] at [granularity].
///
/// [weekStartWeekday] is only consulted for [MetricsGranularity.weekly]; it
/// follows Dart's [DateTime.weekday] convention (1=Monday … 7=Sunday). Default
/// [DateTime.saturday].
DateTime bucketStart(
  MetricsGranularity granularity,
  DateTime instant, {
  int weekStartWeekday = DateTime.saturday,
}) {
  assert(
    weekStartWeekday >= 1 && weekStartWeekday <= 7,
    'weekStartWeekday must be 1..7 (Mon..Sun), got $weekStartWeekday',
  );
  final localDay = DateTime(instant.year, instant.month, instant.day);
  switch (granularity) {
    case MetricsGranularity.daily:
      return localDay;
    case MetricsGranularity.monthly:
      return DateTime(instant.year, instant.month);
    case MetricsGranularity.weekly:
      // Walk back 0–6 days until the day matches the configured week start.
      // Calendar arithmetic (not Duration) keeps the cursor on a local
      // midnight across DST boundaries.
      var start = localDay;
      while (start.weekday != weekStartWeekday) {
        start = DateTime(start.year, start.month, start.day - 1);
      }
      return start;
  }
}

/// Enumerate every bucket start in [from, until) at [granularity].
///
/// [from] is itself aligned to a bucket boundary by the caller (the aggregation
/// service derives `from` from [bucketStart]); unaligned input still works but
/// yields the buckets that *contain* the range, which can stray past `from`.
/// Throws [ArgumentError] if [until] is before [from].
List<DateTime> bucketsInRange(
  MetricsGranularity granularity,
  DateTime from,
  DateTime until, {
  int weekStartWeekday = DateTime.saturday,
}) {
  if (until.isBefore(from)) {
    throw ArgumentError.value(
      until,
      'until',
      'must not be before from ($from)',
    );
  }
  final out = <DateTime>[];
  // Anchor the first bucket to the bucket *containing* `from` — that bucket
  // may start before `from` (e.g. a month bucket when `from` is mid-month),
  // and we keep it so the series shows the partial first bucket rather than
  // dropping it. Step forward one bucket width until we pass `until`.
  var cursor = bucketStart(
    granularity,
    from,
    weekStartWeekday: weekStartWeekday,
  );
  while (cursor.isBefore(until)) {
    out.add(cursor);
    cursor = _nextBucketStart(granularity, cursor);
  }
  return out;
}

/// Next bucket boundary after [current] at [granularity]. Calendar arithmetic
/// throughout — see file header.
DateTime _nextBucketStart(MetricsGranularity granularity, DateTime current) {
  switch (granularity) {
    case MetricsGranularity.daily:
      return DateTime(current.year, current.month, current.day + 1);
    case MetricsGranularity.weekly:
      return DateTime(current.year, current.month, current.day + 7);
    case MetricsGranularity.monthly:
      return DateTime(current.year, current.month + 1);
  }
}
