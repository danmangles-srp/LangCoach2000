// Catch-up milestone assignment for a single review event (T2.2, FR-1.2.3).
//
// Pure Dart over the [gpaTimelineFor] engine — no store, no device — so the
// rule is unit-tested directly. The repository calls this when appending a
// review event; derivation ("reviewed for milestone N", reached, count) lives
// in T2.3 and reads the stored events back.

import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';

/// Catch-up rule: a single 80%-play satisfies the HIGHEST milestone due as of
/// [completedAt] (day-granularity) that isn't already reached. Earlier missed
/// milestones are skipped, not made up — matches how spaced repetition actually
/// behaves (you don't repay every missed day).
///
/// Returns `null` when no milestone is due yet (an early, pre-D+1 review) or
/// when every due milestone is already at or below [reachedPrior] (a bonus
/// re-review of material already covered). The caller still logs the event
/// with a null milestone index so FR-1.2.4's review count reflects real
/// engagement rather than collapsing into "milestones reached".
///
/// [reachedPrior] is the highest non-null milestone index already logged for
/// this recording, or `-1` when none has been earned yet.
int? milestoneIndexForReview({
  required DateTime createdAt,
  required DateTime completedAt,
  required int reachedPrior,
  List<int> intervals = gpaIntervalsInDays,
}) {
  final asOfDay = dayOnly(completedAt);
  // Walk the ladder high-index-first; the first due milestone is the highest
  // due one (intervals are strictly increasing, so the due set is always a
  // prefix [0..k]).
  for (final m in gpaTimelineFor(
    createdAt: createdAt,
    intervals: intervals,
  ).reversed) {
    if (m.isDueOn(asOfDay)) {
      return m.index > reachedPrior ? m.index : null;
    }
  }
  return null;
}
