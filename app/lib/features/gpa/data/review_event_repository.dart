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
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';

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
  ReviewEventRepository(this._db, {this.xp});

  final AppDatabase _db;

  /// Optional XP sink (M11 T11.2). When wired, a milestone earn appends a
  /// +10 review award in the SAME transaction as the review event — so a
  /// failed append rolls the award back too. Null in tests that don't care.
  final XpRepository? xp;

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

  /// Warmed Today + Tomorrow windows (T14.1). Loads every recording + its
  /// derived status, hands the candidate set to the pure [warmUpQueue]
  /// selector, then maps selections back to recordings. Today is a 2-week
  /// backlog (active milestone overdue 0..13 days), most-overdue first, capped
  /// at 4; Tomorrow is strict (overdue == -1 exactly). The canonical GPA
  /// intervals are untouched. Two queries regardless of recording count,
  /// grouped in Dart.
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
      // M11 T11.2: a real milestone earn awards +10 (canonical). A null
      // assignment is a bonus replay the catch-up rule already counted — no
      // XP, so rewatching a reviewed recording can't farm XP. Same tx as the
      // event insert (ambient), so a downstream failure rolls both back.
      if (assigned != null) {
        await xp?.record(
          source: XpSource.review,
          points: 10,
          recordingId: recordingId,
          at: completedAt,
        );
      }
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
      // M11 T11.2: a manual milestone assertion awards +10. The existing-event
      // guard above makes this fire once per milestone; same tx as the insert.
      await xp?.record(
        source: XpSource.review,
        points: 10,
        recordingId: recordingId,
        at: completedAt,
      );
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
