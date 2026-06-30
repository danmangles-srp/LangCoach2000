// Pure-Dart queue warm-up selector (T7.1, M7 AC 1). Keeps the Today + Tomorrow
// queues from looking empty on day one: when the strict due-set for a window is
// smaller than a floor (3), top it up from the soonest-next-due recordings and
// badge them "up next". The canonical GPA intervals are NEVER altered — top-ups
// are presented as reviewable-early, not rescheduled. Reviewing an up-next item
// early just lets the catch-up rule advance the ladder normally.
//
// Store-free (no Drift, no DateTime.now): the repository maps recording rows +
// their derived statuses into [WarmCandidate]s at the boundary; this layer only
// selects + orders. Fully unit-tested without a device.
//
// The branch math mirrors [classifyQueueEntry]'s stale window (FR-1.2.5) but is
// expressed directly via the active milestone's daysOverdue. Today's top-up
// draws from the FULL upcoming set (tomorrow + beyond), not just far-future
// items: on day one every fresh recording's first milestone (D+1) is due
// tomorrow, so restricting the pool to 2+ days out would leave today empty.
// Today consumes the soonest upcoming first; tomorrow gets the next share.

import 'package:flutter/foundation.dart';

import 'package:rivendell/features/gpa/domain/review_status.dart';

/// Default minimum row count for a warmed window (M7 AC 1: "at least 3").
const int kWarmFloor = 3;

/// How a candidate lands in a warmed window.
enum WarmPlacement {
  /// Genuinely due in this window — today (due / 1-day-stale) or tomorrow.
  due,

  /// Soonest-next-due filler shown early so a fresh library isn't an empty
  /// list. Not rescheduled; reviewing it early just advances the ladder.
  upNext,
}

/// Store-free queue candidate: an identity the caller can map back to a row,
/// plus the derived status the selector keys on.
@immutable
class WarmCandidate {
  const WarmCandidate({required this.id, required this.status});

  final int id;
  final RecordingReviewStatus status;
}

/// One row of a warmed window.
@immutable
class WarmSelection {
  const WarmSelection({
    required this.candidate,
    required this.placement,
    required this.isStale,
  });

  final WarmCandidate candidate;
  final WarmPlacement placement;

  /// True only for a [WarmPlacement.due] today-row that is 1-day-stale. Always
  /// false for [WarmPlacement.upNext] and for tomorrow rows.
  final bool isStale;
}

/// The warmed Today + Tomorrow windows.
@immutable
class WarmQueue {
  const WarmQueue({required this.today, required this.tomorrow});

  final List<WarmSelection> today;
  final List<WarmSelection> tomorrow;
}

/// Build the warmed Today + Tomorrow windows from the full candidate set.
///
/// The candidate set splits into two buckets:
/// - **todayStrict** — active milestone due today or 1-day-stale (overdue ≥ 0
///   and < 2). These always render in Today with the stale badge when overdue.
/// - **upcoming** — every active milestone still in the future (overdue < 0).
///   This is a single shared top-up pool; today has priority, tomorrow gets
///   the remaining share. Today's top-ups are always "up next"; a tomorrow
///   top-up is "due" when its milestone is genuinely due tomorrow (overdue
///   == -1) and "up next" otherwise.
///
/// Today is filled to [floor] by drawing the soonest upcoming first. Then
/// tomorrow is filled to [floor] from whatever upcoming is left. A candidate
/// is consumed once, so a recording never appears in both windows. Complete
/// recordings and ≥2-day-stale recordings are excluded entirely (the latter
/// matches the FR-1.2.5 stale cutoff — the prompt fades on the 2nd stale day).
///
/// Today's order is: stale first, then dueOn ascending, then candidate id
/// descending (newest-first proxy). Upcoming is dueOn ascending, then id
/// descending.
WarmQueue warmUpQueue({
  required List<WarmCandidate> all,
  required DateTime asOf,
  int floor = kWarmFloor,
}) {
  final todayStrict = <WarmSelection>[];
  final upcoming = <WarmCandidate>[];

  for (final c in all) {
    final active = c.status.activeMilestone;
    if (active == null) continue; // every milestone reached — nothing to review
    final overdue = active.daysOverdue(asOf);
    if (overdue >= 2) {
      continue; // ≥2-day-stale: dropped (FR-1.2.5 stale cutoff)
    } else if (overdue >= 0) {
      todayStrict.add(
        WarmSelection(
          candidate: c,
          placement: WarmPlacement.due,
          isStale: overdue == 1,
        ),
      );
    } else {
      upcoming.add(c); // future (tomorrow + beyond) → shared top-up pool
    }
  }

  todayStrict.sort(_compareTodayStrict);
  upcoming.sort(_compareByDueThenId);

  final today = <WarmSelection>[...todayStrict];
  final tomorrow = <WarmSelection>[];

  // Today draws the soonest upcoming first; tomorrow takes the next share.
  var i = 0;
  while (today.length < floor && i < upcoming.length) {
    today.add(
      WarmSelection(
        candidate: upcoming[i],
        placement: WarmPlacement.upNext,
        isStale: false,
      ),
    );
    i++;
  }
  while (tomorrow.length < floor && i < upcoming.length) {
    final c = upcoming[i];
    final active = c.status.activeMilestone;
    final dueTomorrow = active != null && active.daysOverdue(asOf) == -1;
    tomorrow.add(
      WarmSelection(
        candidate: c,
        placement: dueTomorrow ? WarmPlacement.due : WarmPlacement.upNext,
        isStale: false,
      ),
    );
    i++;
  }

  return WarmQueue(today: today, tomorrow: tomorrow);
}

int _compareTodayStrict(WarmSelection a, WarmSelection b) {
  if (a.isStale != b.isStale) return a.isStale ? -1 : 1;
  return _compareByDueThenId(a.candidate, b.candidate);
}

int _compareByDueThenId(WarmCandidate a, WarmCandidate b) {
  final da = a.status.activeMilestone?.dueOn;
  final db = b.status.activeMilestone?.dueOn;
  if (da != null && db != null && da != db) return da.compareTo(db);
  return b.id.compareTo(a.id); // id desc — newest-first tiebreak
}
