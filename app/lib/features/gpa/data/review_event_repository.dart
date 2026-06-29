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
