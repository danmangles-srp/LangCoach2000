// GPA spaced-repetition interval engine (T2.1, FR-1.2.1 / FR-1.2.2). Pure
// Dart — no DateTime.now(), no I/O — so the day-math + due-status logic is
// fully unit-testable. Callers pass `asOf` (the "now") in; the queue (T2.4)
// and review-history derivation (T2.3) compose this with the review-event log.
//
// All comparisons are DAY-granularity: a milestone is due on the calendar day
// its interval elapses, regardless of the recording's creation time-of-day.
// Times are normalized to local midnight before any arithmetic or comparison
// so a 23:59 recording and a 00:01 playback agree on which day it is.

import 'package:flutter/foundation.dart';

/// Canonical GPA review intervals in days (FR-1.2.2). Milestone index = the
/// position in this list; downstream tables/log read it back by index. Order
/// is load-bearing — don't reorder or append without a schema migration.
const List<int> gpaIntervalsInDays = <int>[1, 2, 4, 7, 30, 90, 180, 365];

/// One rung on a recording's review ladder (FR-1.2.1). `dueOn` is local
/// midnight of the day the interval elapses; `isDueOn` / `daysOverdue` evaluate
/// it against a caller-supplied "now" so the engine stays deterministic.
@immutable
class GpaMilestone {
  const GpaMilestone({
    required this.index,
    required this.intervalDays,
    required this.dueOn,
  });

  /// 0-based position within [gpaIntervalsInDays]. Stored on review events
  /// (FR-1.2.3) as the milestone a play crossed 80% on.
  final int index;

  /// The interval in days (1, 2, 4, …). Carried for display so callers don't
  /// re-index the canonical list.
  final int intervalDays;

  /// Local midnight of the due day (creation date + intervalDays).
  final DateTime dueOn;

  /// True on/after the due day. Day-granularity: the due day itself counts, so
  /// a 23:59 creation and a 00:01 check agree on which day it is.
  bool isDueOn(DateTime asOf) => !dayOnly(asOf).isBefore(dueOn);

  /// Whole days the milestone is overdue at [asOf] (0 = due today, 1 = one-day
  /// stale, …); negative when still in the future. Drives the T2.4 stale rule.
  int daysOverdue(DateTime asOf) => dayOnly(asOf).difference(dueOn).inDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpaMilestone &&
          other.index == index &&
          other.intervalDays == intervalDays &&
          other.dueOn == dueOn;

  @override
  int get hashCode => Object.hash(index, intervalDays, dueOn);
}

/// Truncate a [DateTime] to local midnight (date only), dropping time-of-day.
DateTime dayOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// True when two instants fall on the same calendar day.
bool sameDay(DateTime a, DateTime b) {
  final da = dayOnly(a);
  final db = dayOnly(b);
  return da.year == db.year && da.month == db.month && da.day == db.day;
}

/// Build the full 8-rung timeline for a recording created at [createdAt]
/// (FR-1.2.1). `createdAt`'s time-of-day is ignored — intervals count in whole
/// days from the creation date. Pass [intervals] to override the canonical set
/// (tests / future tuning); defaults to [gpaIntervalsInDays].
List<GpaMilestone> gpaTimelineFor({
  required DateTime createdAt,
  List<int> intervals = gpaIntervalsInDays,
}) {
  final origin = dayOnly(createdAt);
  return [
    for (var i = 0; i < intervals.length; i++)
      GpaMilestone(
        index: i,
        intervalDays: intervals[i],
        dueOn: origin.add(Duration(days: intervals[i])),
      ),
  ];
}

/// The milestones due on/ before [asOf], in interval order.
List<GpaMilestone> dueMilestonesFor({
  required DateTime createdAt,
  required DateTime asOf,
  List<int> intervals = gpaIntervalsInDays,
}) {
  final reference = dayOnly(asOf);
  return gpaTimelineFor(
    createdAt: createdAt,
    intervals: intervals,
  ).where((m) => m.isDueOn(reference)).toList(growable: false);
}

/// The first milestone NOT yet due at [asOf] (the next review coming up), or
/// `null` once every interval has elapsed. Note: this is calendar-due, not
/// "reviewed" — folding in the review-event log to find the active (next-
/// unreached) milestone is T2.3's job.
GpaMilestone? nextUpcomingMilestone({
  required DateTime createdAt,
  required DateTime asOf,
  List<int> intervals = gpaIntervalsInDays,
}) {
  final reference = dayOnly(asOf);
  for (final m in gpaTimelineFor(createdAt: createdAt, intervals: intervals)) {
    if (!m.isDueOn(reference)) return m;
  }
  return null;
}
