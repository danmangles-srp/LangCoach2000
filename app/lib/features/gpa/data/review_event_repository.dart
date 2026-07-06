// Repository over [ReviewEvents] (T2.2, FR-1.2.3). Owns the append contract:
// the auto path ([recordReview]) applies the catch-up rule from the GPA engine;
// the manual path ([markReviewed] / [deleteEvent]) lets a reviewer correct a
// missed or mistaken review. All mutating calls run in a transaction so the
// read-compute-write over a recording's prior events is atomic — two near-
// simultaneous 80%-crossings can't both observe the same `reachedPrior` and
// double-assign the same milestone.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/gpa/domain/gpa_review.dart';
import 'package:rivendell/features/gpa/domain/queue_warmup.dart';
import 'package:rivendell/features/gpa/domain/review_status.dart';

/// One row of today's review queue (FR-1.2.5): the recording, its derived
/// status, and whether it's 1-day-stale. Inclusion implies membership.
class QueueItem {
  const QueueItem({
    required this.recording,
    required this.status,
    required this.isStale,
  });

  final Recording recording;
  final RecordingReviewStatus status;
  final bool isStale;
}

/// One row of a queue window (T7.1, T14.1): the recording, its derived status,
/// and the stale flag (always false post-T14.1 — the Today backlog dropped the
/// stale distinction; Tomorrow was never stale).
class WarmedItem {
  const WarmedItem({
    required this.recording,
    required this.status,
    required this.isStale,
  });

  final Recording recording;
  final RecordingReviewStatus status;
  final bool isStale;
}

/// Today (2-week backlog, cap 4 — T14.1) + Tomorrow (strict) windows.
class WarmedQueue {
  const WarmedQueue({required this.today, required this.tomorrow});

  final List<WarmedItem> today;
  final List<WarmedItem> tomorrow;
}

class ReviewEventRepository {
  ReviewEventRepository(this._db);

  final AppDatabase _db;

  /// All events for a recording, oldest first. Drives derivation (T2.3) and
  /// the detail-screen review history (T2.6).
  Future<List<ReviewEvent>> eventsFor(int recordingId) {
    return (_db.select(_db.reviewEvents)
          ..where((t) => t.recordingId.equals(recordingId))
          ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]))
        .get();
  }

  /// completedAts of every review event in [from, until), oldest first (T6.2
  /// metric source for "Completed Queue items"). Half-open: an event stamped
  /// exactly at [until] belongs to the next bucket. Includes null-milestone
  /// bonus plays — they still represent real engagement.
  Future<List<DateTime>> eventTimestamps(DateTime from, DateTime until) {
    final rows =
        (_db.selectOnly(_db.reviewEvents)
              ..addColumns([_db.reviewEvents.completedAt])
              ..where(
                _db.reviewEvents.completedAt.isBiggerOrEqualValue(from) &
                    _db.reviewEvents.completedAt.isSmallerThanValue(until),
              )
              ..orderBy([OrderingTerm.asc(_db.reviewEvents.completedAt)]))
            .get();
    return rows.then((r) {
      return [
        for (final e in r)
          if (e.read(_db.reviewEvents.completedAt) case final DateTime v) v,
      ];
    });
  }

  /// Derived review state for a recording (FR-1.2.4): reached milestone,
  /// count, last-reviewed, and the active (next-unreached) milestone with its
  /// due-ness. Returns null when the recording no longer exists. [asOf] is
  /// usually today.
  Future<RecordingReviewStatus?> statusFor(
    int recordingId, {
    required DateTime asOf,
  }) async {
    final createdAt = await _recordingCreatedAt(recordingId);
    if (createdAt == null) return null;
    final events = await eventsFor(recordingId);
    return computeReviewStatus(
      createdAt: createdAt,
      events: [
        for (final e in events)
          ReviewLogEntry(
            milestoneIndex: e.milestoneIndex,
            completedAt: e.completedAt,
          ),
      ],
      asOf: asOf,
    );
  }

  /// Today's review queue (FR-1.2.5): recordings whose active milestone is due
  /// today or 1-day-stale, sorted most-overdue first. Recordings that are not
  /// yet due, complete, or ≥2 days stale are excluded. Two queries regardless
  /// of recording count (recordings + all events), grouped in Dart.
  Future<List<QueueItem>> todayQueue({required DateTime asOf}) async {
    final recordings =
        await (_db.select(_db.recordings)..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
            .get();
    if (recordings.isEmpty) return const [];

    final events = await (_db.select(
      _db.reviewEvents,
    )..orderBy([(t) => OrderingTerm.asc(t.completedAt)])).get();
    final byRecording = <int, List<ReviewLogEntry>>{};
    for (final e in events) {
      (byRecording[e.recordingId] ??= <ReviewLogEntry>[]).add(
        ReviewLogEntry(
          milestoneIndex: e.milestoneIndex,
          completedAt: e.completedAt,
        ),
      );
    }

    final out = <QueueItem>[];
    for (final rec in recordings) {
      final status = computeReviewStatus(
        createdAt: rec.createdAt,
        events: byRecording[rec.id] ?? const <ReviewLogEntry>[],
        asOf: asOf,
      );
      final kind = classifyQueueEntry(status, asOf: asOf);
      if (kind == QueueEntryKind.excluded) continue;
      out.add(
        QueueItem(
          recording: rec,
          status: status,
          isStale: kind == QueueEntryKind.stale,
        ),
      );
    }

    // Stale (1-day) first, then by active-milestone dueOn ascending (most
    // overdue first), then recording createdAt desc for a stable tiebreak.
    out.sort((a, b) {
      if (a.isStale != b.isStale) return a.isStale ? -1 : 1;
      final da = a.status.activeMilestone?.dueOn;
      final db = b.status.activeMilestone?.dueOn;
      if (da != null && db != null && da != db) return da.compareTo(db);
      return b.recording.createdAt.compareTo(a.recording.createdAt);
    });
    return out;
  }

  /// Warmed Today + Tomorrow windows (T14.1). Loads every recording + its
  /// derived status, hands the candidate set to the pure [warmUpQueue]
  /// selector, then maps selections back to recordings. Today is a 2-week
  /// backlog (active milestone overdue 0..13 days), most-overdue first, capped
  /// at 4; Tomorrow is strict (overdue == -1 exactly). The canonical GPA
  /// intervals are untouched. Two queries regardless of recording count,
  /// grouped in Dart (same shape as [todayQueue]).
  Future<WarmedQueue> warmedQueue({required DateTime asOf}) async {
    final recordings =
        await (_db.select(_db.recordings)..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
            .get();
    if (recordings.isEmpty) {
      return const WarmedQueue(today: [], tomorrow: []);
    }

    final events = await (_db.select(
      _db.reviewEvents,
    )..orderBy([(t) => OrderingTerm.asc(t.completedAt)])).get();
    final byRecording = <int, List<ReviewLogEntry>>{};
    for (final e in events) {
      (byRecording[e.recordingId] ??= <ReviewLogEntry>[]).add(
        ReviewLogEntry(
          milestoneIndex: e.milestoneIndex,
          completedAt: e.completedAt,
        ),
      );
    }

    final candidates = <WarmCandidate>[
      for (final rec in recordings)
        WarmCandidate(
          id: rec.id,
          status: computeReviewStatus(
            createdAt: rec.createdAt,
            events: byRecording[rec.id] ?? const <ReviewLogEntry>[],
            asOf: asOf,
          ),
        ),
    ];
    final warm = warmUpQueue(all: candidates, asOf: asOf);

    final byId = <int, Recording>{for (final r in recordings) r.id: r};
    WarmedItem? toItem(WarmSelection s) {
      final rec = byId[s.candidate.id];
      if (rec == null) return null; // candidate ids derive from recordings
      return WarmedItem(
        recording: rec,
        status: s.candidate.status,
        isStale: s.isStale,
      );
    }

    return WarmedQueue(
      today: warm.today.map(toItem).whereType<WarmedItem>().toList(),
      tomorrow: warm.tomorrow.map(toItem).whereType<WarmedItem>().toList(),
    );
  }

  /// Auto-append a review event for an 80%-crossing (called by the playback
  /// watcher). Assigns the milestone via the catch-up rule against the
  /// recording's prior events; logs a null milestone index when the play
  /// earned no milestone (early / bonus review) so the count still reflects
  /// engagement. No-op if the recording no longer exists.
  Future<void> recordReview(int recordingId, {required DateTime completedAt}) {
    return _db.transaction(() async {
      final createdAt = await _recordingCreatedAt(recordingId);
      if (createdAt == null) return;
      final reachedPrior = await _reachedPrior(recordingId);
      final assigned = milestoneIndexForReview(
        createdAt: createdAt,
        completedAt: completedAt,
        reachedPrior: reachedPrior,
      );
      await _insert(recordingId, assigned, completedAt);
    });
  }

  /// Manually mark [milestoneIndex] reviewed for a recording (correction — the
  /// app missed a review, or the reviewer is asserting one ahead of the
  /// engine). Idempotent: if an event already exists for this recording +
  /// milestone, this is a no-op (a milestone is either reviewed or not; there
  /// is no concept of reviewing it twice). No-op if the recording is gone.
  Future<void> markReviewed(
    int recordingId, {
    required int milestoneIndex,
    required DateTime completedAt,
  }) {
    return _db.transaction(() async {
      if (await _recordingCreatedAt(recordingId) == null) return;
      final existing =
          await (_db.select(_db.reviewEvents)..where(
                (t) =>
                    t.recordingId.equals(recordingId) &
                    t.milestoneIndex.equals(milestoneIndex),
              ))
              .get();
      if (existing.isNotEmpty) return;
      await _insert(recordingId, milestoneIndex, completedAt);
    });
  }

  /// Remove a single review event (un-review correction). Used by the manual
  /// "undo" affordance on the milestone timeline (T2.6). A deliberate,
  /// user-initiated exception to the auto log's append-only nature.
  Future<void> deleteEvent(int eventId) {
    return (_db.delete(
      _db.reviewEvents,
    )..where((t) => t.id.equals(eventId))).go();
  }

  /// Undo the review of [milestoneIndex] for a recording (correction — the
  /// reviewer tapped "mark reviewed" by mistake, or the engine logged a play
  /// that didn't really count). Deletes the single milestone-keyed event if one
  /// exists; no-op otherwise (e.g. bonus / null-milestone plays are left alone,
  /// and so are events for other milestones). Runs in a transaction so the
  /// find-then-delete can't race a concurrent append.
  Future<void> unreviewMilestone(
    int recordingId, {
    required int milestoneIndex,
  }) {
    return _db.transaction(() async {
      await (_db.delete(_db.reviewEvents)..where(
            (t) =>
                t.recordingId.equals(recordingId) &
                t.milestoneIndex.equals(milestoneIndex),
          ))
          .go();
    });
  }

  Future<DateTime?> _recordingCreatedAt(int recordingId) async {
    final row = await (_db.select(
      _db.recordings,
    )..where((t) => t.id.equals(recordingId))).getSingleOrNull();
    return row?.createdAt;
  }

  /// Highest non-null milestone index logged for [recordingId], or `-1` when
  /// none has been earned. The catch-up rule treats everything at or below
  /// this high-water mark as reached/skipped.
  Future<int> _reachedPrior(int recordingId) async {
    final events = await eventsFor(recordingId);
    var max = -1;
    for (final e in events) {
      final idx = e.milestoneIndex;
      if (idx != null && idx > max) max = idx;
    }
    return max;
  }

  Future<void> _insert(int recordingId, int? milestoneIndex, DateTime at) {
    return _db
        .into(_db.reviewEvents)
        .insert(
          ReviewEventsCompanion.insert(
            recordingId: recordingId,
            milestoneIndex: milestoneIndex == null
                ? const Value.absent()
                : Value(milestoneIndex),
            completedAt: at,
          ),
        );
  }
}
