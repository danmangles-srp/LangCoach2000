// Pure-Dart queue selector (T7.1, superseded by T10.1 / M10 AC4–5). Both
// windows are strict-only: Today holds active milestones due today or
// 1-day-stale; Tomorrow holds active milestones due tomorrow exactly. Nothing
// is topped up or shown early — a recording must be on or past its next review
// date to appear in either queue (per user feedback). The canonical GPA
// intervals are NEVER altered.
//
// Store-free (no Drift, no DateTime.now): the repository maps recording rows +
// their derived statuses into [WarmCandidate]s at the boundary; this layer only
// selects + orders. Fully unit-tested without a device.
//
// The stale math mirrors [classifyQueueEntry]'s stale window (FR-1.2.5) but is
// expressed directly via the active milestone's daysOverdue.

import 'package:flutter/foundation.dart';

import 'package:rivendell/features/gpa/domain/review_status.dart';

/// Store-free queue candidate: an identity the caller can map back to a row,
/// plus the derived status the selector keys on.
@immutable
class WarmCandidate {
  const WarmCandidate({required this.id, required this.status});

  final int id;
  final RecordingReviewStatus status;
}

/// One strict-due row of a queue window.
@immutable
class WarmSelection {
  const WarmSelection({required this.candidate, required this.isStale});

  final WarmCandidate candidate;

  /// True only for a today-row that is 1-day-stale. Always false for tomorrow.
  final bool isStale;
}

/// The strict Today + Tomorrow windows.
@immutable
class WarmQueue {
  const WarmQueue({required this.today, required this.tomorrow});

  final List<WarmSelection> today;
  final List<WarmSelection> tomorrow;
}

/// Build the strict Today + Tomorrow windows from the candidate set.
///
/// The candidate set splits into two buckets (everything else is excluded):
/// - **todayStrict** — active milestone due today or 1-day-stale (overdue ≥ 0
///   and < 2). Renders in Today, with the stale badge when overdue == 1.
/// - **dueTomorrow** — active milestone due tomorrow exactly (overdue == -1).
///   Renders in Tomorrow.
/// - Complete recordings (no active milestone) and ≥2-day-stale recordings
///   (overdue ≥ 2) are excluded entirely — the latter matches the FR-1.2.5
///   stale cutoff (the prompt fades on the 2nd stale day).
///
/// No top-up, no floor: if nothing qualifies, a window is empty. Today's order
/// is: stale first, then dueOn ascending, then candidate id descending
/// (newest-first proxy). Tomorrow is dueOn ascending, then id descending.
WarmQueue warmUpQueue({
  required List<WarmCandidate> all,
  required DateTime asOf,
}) {
  final todayStrict = <WarmSelection>[];
  final dueTomorrow = <WarmCandidate>[];

  for (final c in all) {
    final active = c.status.activeMilestone;
    if (active == null) continue; // every milestone reached — nothing to review
    final overdue = active.daysOverdue(asOf);
    if (overdue >= 2) {
      continue; // ≥2-day-stale: dropped (FR-1.2.5 stale cutoff)
    } else if (overdue >= 0) {
      todayStrict.add(WarmSelection(candidate: c, isStale: overdue == 1));
    } else if (overdue == -1) {
      dueTomorrow.add(c); // genuinely due tomorrow
    }
    // overdue < -1: further future — not shown in either strict window.
  }

  todayStrict.sort(_compareTodayStrict);
  dueTomorrow.sort(_compareByDueThenId);

  return WarmQueue(
    today: todayStrict,
    tomorrow: [
      for (final c in dueTomorrow) WarmSelection(candidate: c, isStale: false),
    ],
  );
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
