// Review-history derivation (T2.3, FR-1.2.4). Pure Dart over a recording's
// event log — no Drift, no device — so the rule is unit-tested directly. The
// repository maps stored review-event rows into [ReviewLogEntry]s at the
// boundary, keeping this layer store-free.
//
// Consumed by T2.4 (today's due-set via [RecordingReviewStatus.activeMilestone]
// + activeMilestoneDue) and T2.6 (the detail-screen milestone timeline +
// last-reviewed / count).

import 'package:flutter/foundation.dart';

import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';

/// Store-free projection of a single review-event row: just the bits the
/// derivation needs. Decouples this domain layer from the Drift store.
@immutable
class ReviewLogEntry {
  const ReviewLogEntry({required this.completedAt, this.milestoneIndex});

  final int? milestoneIndex;
  final DateTime completedAt;
}

/// Derived review state for one recording — everything FR-1.2.4 surfaces on
/// the detail screen, plus the next-unreached milestone the queue (FR-1.2.5)
/// keys on.
@immutable
class RecordingReviewStatus {
  const RecordingReviewStatus({
    required this.milestoneReached,
    required this.reviewCount,
    required this.lastReviewed,
    required this.activeMilestone,
    required this.activeMilestoneDue,
    required this.isComplete,
  });

  /// Highest non-null milestone index logged, or `-1` when none has been
  /// earned. The catch-up rule treats every milestone at or below this
  /// high-water mark as reached/skipped (see gpa_review).
  final int milestoneReached;

  /// Total review-event rows for the recording (incl. bonus / null-milestone
  /// plays) — FR-1.2.4's "total review count", distinct from reached.
  final int reviewCount;

  /// The most recent event timestamp, or null when the recording was never
  /// reviewed — FR-1.2.4's "last reviewed date".
  final DateTime? lastReviewed;

  /// The next milestone above [milestoneReached] the recording is working
  /// toward, or null when every milestone is reached.
  final GpaMilestone? activeMilestone;

  /// True when [activeMilestone] is due as of the status's as-of day — the
  /// queue (T2.4) uses this to decide membership + the stale rule.
  final bool activeMilestoneDue;

  /// True when every milestone on the ladder has been reached.
  final bool isComplete;
}

/// Roll up a recording's event log into its derived review status.
///
/// [asOf] drives "is the active milestone due today" — pass the current day
/// (or a fixed day in tests). Day-granularity: time-of-day is ignored.
RecordingReviewStatus computeReviewStatus({
  required DateTime createdAt,
  required List<ReviewLogEntry> events,
  required DateTime asOf,
  List<int> intervals = gpaIntervalsInDays,
}) {
  final timeline = gpaTimelineFor(createdAt: createdAt, intervals: intervals);

  var reached = -1;
  DateTime? last;
  for (final e in events) {
    final idx = e.milestoneIndex;
    if (idx != null && idx > reached) reached = idx;
    final at = e.completedAt;
    if (last == null || at.isAfter(last)) last = at;
  }

  final lastIndex = timeline.length - 1;
  final active = reached < lastIndex ? timeline[reached + 1] : null;

  return RecordingReviewStatus(
    milestoneReached: reached,
    reviewCount: events.length,
    lastReviewed: last,
    activeMilestone: active,
    activeMilestoneDue: active?.isDueOn(asOf) ?? false,
    isComplete: reached >= lastIndex,
  );
}

/// Where a recording sits relative to today's review queue (FR-1.2.5).
enum QueueEntryKind {
  /// Active milestone is due today (0 days overdue).
  dueToday,

  /// Active milestone became due yesterday — still presented, marked stale
  /// (1-day grace window).
  stale,

  /// Not in today's queue: not yet due, complete, or ≥2 days overdue (the
  /// stale prompt disappears on the 2nd stale day).
  excluded,
}

/// Classify a recording's derived status against today's queue (FR-1.2.5).
/// Day-granularity: time-of-day is ignored.
QueueEntryKind classifyQueueEntry(
  RecordingReviewStatus status, {
  required DateTime asOf,
}) {
  final active = status.activeMilestone;
  if (active == null) return QueueEntryKind.excluded; // complete
  if (!active.isDueOn(asOf)) return QueueEntryKind.excluded; // not yet due
  final overdue = active.daysOverdue(asOf);
  if (overdue <= 0) return QueueEntryKind.dueToday;
  if (overdue == 1) return QueueEntryKind.stale;
  return QueueEntryKind.excluded; // ≥2 days stale
}
