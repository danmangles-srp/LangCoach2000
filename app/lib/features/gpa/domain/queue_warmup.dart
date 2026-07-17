// Pure-Dart queue selector (T14.1, amending M10 AC4–5). Today is a forgiving
// 2-week backlog: any recording whose active milestone became due in the last
// 14 days (overdue 0..13 inclusive), most-overdue first, capped at 4. The
// stale distinction is dropped — every Today row is simply "due". Tomorrow
// stays strict-only (overdue == -1 exactly); the cap + backlog window apply to
// Today only. The canonical GPA intervals are NEVER altered; this only widens
// which due-rows Today surfaces.
//
// Store-free (no Drift, no DateTime.now): the repository maps recording rows +
// their derived statuses into [WarmCandidate]s at the boundary; this layer only
// selects + orders. Fully unit-tested without a device.

import 'package:flutter/foundation.dart';

import 'package:rivendell/features/gpa/domain/review_status.dart';

/// Today's backlog window: an active milestone up to this many days overdue is
/// still surfaced in Today (inclusive). 13 = "became due in the last 14 days".
const int kTodayBacklogWindowDays = 13;

/// Today's backlog cap: at most this many rows surface, most-overdue first.
const int kTodayBacklogCap = 4;

/// Store-free queue candidate: an identity the caller can map back to a row,
/// plus the derived status the selector keys on.
@immutable
class WarmCandidate {
  const WarmCandidate({required this.id, required this.status});

  final int id;
  final RecordingReviewStatus status;
}

/// One row of a queue window.
@immutable
class WarmSelection {
  const WarmSelection({required this.candidate, required this.isStale});

  final WarmCandidate candidate;

  /// Always false post-T14.1 (the stale distinction was dropped from Today;
  /// Tomorrow was never stale). Retained on the shape so the presentation layer
  /// and the repository mapping don't churn — a T15.x cleanup removes it.
  final bool isStale;
}

/// The Today (2-week backlog, cap 4) + Tomorrow (strict) windows.
@immutable
class WarmQueue {
  const WarmQueue({required this.today, required this.tomorrow});

  final List<WarmSelection> today;
  final List<WarmSelection> tomorrow;
}

/// Build the Today + Tomorrow windows from the candidate set.
///
/// The candidate set splits into two buckets (everything else is excluded):
/// - **todayBacklog** — active milestone overdue 0..13 days inclusive (became
///   due in the last 2 weeks). Sorted most-overdue first (dueOn ascending, then
///   candidate id descending for a stable tiebreak), then capped at
///   [kTodayBacklogCap]. Every row is simply "due" — no stale badge.
/// - **dueTomorrow** — active milestone due tomorrow exactly (overdue == -1).
///   Renders in Tomorrow, uncapped.
/// - Complete recordings (no active milestone), far-future recordings
///   (overdue < -1), and recordings >13 days overdue are excluded.
///
/// No top-up, no floor: if nothing qualifies, a window is empty.
WarmQueue warmUpQueue({
  required List<WarmCandidate> all,
  required DateTime asOf,
}) {
  final todayBacklog = <WarmCandidate>[];
  final dueTomorrow = <WarmCandidate>[];

  for (final c in all) {
    final active = c.status.activeMilestone;
    if (active == null) continue; // every milestone reached — nothing to review
    final overdue = active.daysOverdue(asOf);
    if (overdue >= 0 && overdue <= kTodayBacklogWindowDays) {
      todayBacklog.add(c); // due today or up to 13 days overdue
    } else if (overdue == -1) {
      dueTomorrow.add(c); // genuinely due tomorrow
    }
    // overdue < -1 (further future) and overdue > 13 (too far gone): excluded.
  }

  todayBacklog.sort(_compareByDueThenId);
  final cappedToday = todayBacklog.length > kTodayBacklogCap
      ? todayBacklog.sublist(0, kTodayBacklogCap)
      : todayBacklog;
  dueTomorrow.sort(_compareByDueThenId);

  return WarmQueue(
    today: [
      for (final c in cappedToday) WarmSelection(candidate: c, isStale: false),
    ],
    tomorrow: [
      for (final c in dueTomorrow) WarmSelection(candidate: c, isStale: false),
    ],
  );
}

/// Most-overdue first: active-milestone dueOn ascending (older dueOn = more
/// overdue), then candidate id descending (newest-first tiebreak).
int _compareByDueThenId(WarmCandidate a, WarmCandidate b) {
  final da = a.status.activeMilestone?.dueOn;
  final db = b.status.activeMilestone?.dueOn;
  if (da != null && db != null && da != db) return da.compareTo(db);
  return b.id.compareTo(a.id);
}
