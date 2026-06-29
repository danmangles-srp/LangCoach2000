// ReviewEventRepository — T2.2 (FR-1.2.3). In-memory Drift; no device.
// Covers the auto catch-up append, the manual correction API, ordering,
// idempotency, the gone-recording no-op, and FK cascade on recording delete.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';

void main() {
  late AppDatabase db;
  late RecordingRepository recordings;
  late ReviewEventRepository reviews;

  // 2026-03-15 — non-Jan/non-1st base keeps Duration offsets off the
  // avoid_redundant_argument_values tripwire.
  final created = DateTime(2026, 3, 15);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordings = RecordingRepository(db);
    reviews = ReviewEventRepository(db);
  });

  tearDown(() => db.close());

  // Seed a recording at [createdAt] and return its row id.
  Future<int> seed({
    String path = '/svr/lec.m4a',
    String name = 'lec.m4a',
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? created;
    await recordings.upsertScanned([
      ScannedFile(
        path: path,
        name: name,
        createdAt: at,
        sizeBytes: 1,
        format: AudioFormat.m4a,
      ),
    ]);
    final row = await recordings.findByPath(path);
    if (row == null) fail('seed recording not found at $path');
    return row.id;
  }

  group('recordReview (auto, catch-up)', () {
    test('a 30-day play satisfies milestone 4 (highest due)', () async {
      final id = await seed();
      await reviews.recordReview(
        id,
        completedAt: created.add(const Duration(days: 30)),
      );
      final events = await reviews.eventsFor(id);
      expect(events, hasLength(1));
      expect(events.single.milestoneIndex, 4);
    });

    test('an early same-day play logs a null-milestone event', () async {
      final id = await seed();
      await reviews.recordReview(id, completedAt: created);
      final events = await reviews.eventsFor(id);
      expect(events, hasLength(1));
      expect(events.single.milestoneIndex, isNull);
    });

    test(
      'a second play at the same day is a bonus (null), not a duplicate 4',
      () async {
        final id = await seed();
        final day30 = created.add(const Duration(days: 30));
        await reviews.recordReview(id, completedAt: day30);
        await reviews.recordReview(id, completedAt: day30);
        final events = await reviews.eventsFor(id);
        expect(events, hasLength(2));
        expect(events.first.milestoneIndex, 4);
        expect(events.last.milestoneIndex, isNull);
      },
    );

    test('advances to the next rung once the latest due is reached', () async {
      final id = await seed();
      await reviews.recordReview(
        id,
        completedAt: created.add(const Duration(days: 30)),
      );
      await reviews.recordReview(
        id,
        completedAt: created.add(const Duration(days: 90)),
      );
      final events = await reviews.eventsFor(id);
      expect(events.map((e) => e.milestoneIndex), [4, 5]);
    });

    test('no-op when the recording no longer exists', () async {
      await reviews.recordReview(999, completedAt: created);
      expect(await reviews.eventsFor(999), isEmpty);
    });
  });

  group('markReviewed (manual correction)', () {
    test('inserts an event for the explicit milestone', () async {
      final id = await seed();
      await reviews.markReviewed(
        id,
        milestoneIndex: 3,
        completedAt: created.add(const Duration(days: 7)),
      );
      final events = await reviews.eventsFor(id);
      expect(events, hasLength(1));
      expect(events.single.milestoneIndex, 3);
    });

    test(
      'is idempotent: marking the same milestone twice yields one event',
      () async {
        final id = await seed();
        final at = created.add(const Duration(days: 7));
        await reviews.markReviewed(id, milestoneIndex: 3, completedAt: at);
        await reviews.markReviewed(id, milestoneIndex: 3, completedAt: at);
        expect(await reviews.eventsFor(id), hasLength(1));
      },
    );

    test('no-op when the recording no longer exists', () async {
      await reviews.markReviewed(999, milestoneIndex: 0, completedAt: created);
      expect(await reviews.eventsFor(999), isEmpty);
    });
  });

  group('deleteEvent (un-review)', () {
    test('removes the single event, leaving siblings intact', () async {
      final id = await seed();
      final day30 = created.add(const Duration(days: 30));
      await reviews.recordReview(id, completedAt: day30);
      await reviews.recordReview(id, completedAt: day30); // bonus
      final events = await reviews.eventsFor(id);
      expect(events, hasLength(2));

      await reviews.deleteEvent(events.first.id); // drop the milestone-4 one
      final remaining = await reviews.eventsFor(id);
      expect(remaining, hasLength(1));
      expect(remaining.single.milestoneIndex, isNull);
    });
  });

  group('eventsFor', () {
    test(
      'orders by completedAt ascending regardless of insert order',
      () async {
        final id = await seed();
        final day90 = created.add(const Duration(days: 90));
        final day30 = created.add(const Duration(days: 30));
        // Insert late-then-early.
        await reviews.recordReview(id, completedAt: day90);
        await reviews.recordReview(id, completedAt: day30);
        final events = await reviews.eventsFor(id);
        expect(events.map((e) => e.completedAt), [day30, day90]);
      },
    );
  });

  group('cascade', () {
    test('events are removed when the recording row is deleted', () async {
      final id = await seed();
      await reviews.recordReview(
        id,
        completedAt: created.add(const Duration(days: 30)),
      );
      expect(await reviews.eventsFor(id), hasLength(1));

      await (db.delete(db.recordings)..where((t) => t.id.equals(id))).go();
      expect(await reviews.eventsFor(id), isEmpty);
    });
  });

  group('statusFor (derivation, T2.3)', () {
    test('returns null when the recording is gone', () async {
      expect(await reviews.statusFor(999, asOf: created), isNull);
    });

    test(
      'no events -> reached -1, active first milestone, not due on day 0',
      () async {
        final id = await seed();
        final status = await reviews.statusFor(id, asOf: created);
        if (status == null) fail('expected a status');
        expect(status.milestoneReached, -1);
        expect(status.reviewCount, 0);
        expect(status.activeMilestone?.index, 0);
        expect(status.activeMilestoneDue, isFalse);
      },
    );

    test(
      'milestone-4 event -> reached 4, active 5 not due on day 30, due day 90',
      () async {
        final id = await seed();
        await reviews.recordReview(
          id,
          completedAt: created.add(const Duration(days: 30)),
        );
        final at30 = await reviews.statusFor(
          id,
          asOf: created.add(const Duration(days: 30)),
        );
        expect(at30?.milestoneReached, 4);
        expect(at30?.activeMilestone?.index, 5);
        expect(at30?.activeMilestoneDue, isFalse);

        final at90 = await reviews.statusFor(
          id,
          asOf: created.add(const Duration(days: 90)),
        );
        expect(at90?.activeMilestoneDue, isTrue);
      },
    );
  });

  group('todayQueue (FR-1.2.5)', () {
    // Created 2026-03-15: D+1 due 03-16, D+2 due 03-17, D+4 due 03-19.
    test('empty store -> empty queue', () async {
      expect(await reviews.todayQueue(asOf: created), isEmpty);
    });

    test('active milestone due today -> included, not stale', () async {
      await seed();
      // asOf 03-16: D+1 due today.
      final q = await reviews.todayQueue(
        asOf: created.add(const Duration(days: 1)),
      );
      expect(q, hasLength(1));
      expect(q.single.isStale, isFalse);
      expect(q.single.status.activeMilestone?.index, 0);
    });

    test('not yet due (creation day) -> excluded', () async {
      await seed();
      expect(await reviews.todayQueue(asOf: created), isEmpty);
    });

    test('1 day overdue -> included + stale', () async {
      await seed();
      // asOf 03-17: D+1 is 1 day overdue.
      final q = await reviews.todayQueue(
        asOf: created.add(const Duration(days: 2)),
      );
      expect(q, hasLength(1));
      expect(q.single.isStale, isTrue);
    });

    test('2 days overdue -> excluded (active milestone is still D+1 until '
        'reviewed; the stale prompt disappears on day 2)', () async {
      await seed();
      // asOf 03-18: active milestone is D+1 (03-16), now 2-day stale.
      // No review has advanced it, so it falls out of the queue entirely.
      final q = await reviews.todayQueue(
        asOf: created.add(const Duration(days: 3)),
      );
      expect(q, isEmpty);
    });

    test('complete recording -> excluded', () async {
      final id = await seed();
      await reviews.markReviewed(
        id,
        milestoneIndex: 7,
        completedAt: created.add(const Duration(days: 365)),
      );
      expect(
        await reviews.todayQueue(asOf: created.add(const Duration(days: 400))),
        isEmpty,
      );
    });

    test(
      'marking the active milestone reviewed drops it from the queue',
      () async {
        final id = await seed();
        final dueDay = created.add(const Duration(days: 1)); // D+1 due
        // Review D+1 on its due day: next active is D+2, not due yet.
        await reviews.recordReview(id, completedAt: dueDay);
        expect(await reviews.todayQueue(asOf: dueDay), isEmpty);
      },
    );

    test(
      'stale entries tiebreak by recording createdAt desc for stable order',
      () async {
        // Two recordings, both created 03-15, asOf 03-17: each D+1 is 1-day
        // stale (same active milestone 0, due 03-16). Tiebreak createdAt desc.
        await seed(path: '/a.m4a', name: 'a', createdAt: created);
        await seed(path: '/b.m4a', name: 'b', createdAt: created);
        final q = await reviews.todayQueue(
          asOf: created.add(const Duration(days: 2)),
        );
        expect(q, hasLength(2));
        for (final item in q) {
          expect(item.isStale, isTrue);
        }
        expect(q.first.recording.name, 'b'); // seeded last -> createdAt desc
        expect(q.last.recording.name, 'a');
      },
    );

    test('mixed due-today and stale: stale sorted first', () async {
      // rec A created 03-15, asOf 03-16: D+1 due today (not stale).
      // rec B created 03-14, asOf 03-16: D+1 (03-15) is 1-day stale.
      await seed(path: '/a.m4a', name: 'a', createdAt: created);
      await seed(
        path: '/b.m4a',
        name: 'b',
        createdAt: created.subtract(const Duration(days: 1)),
      );
      final q = await reviews.todayQueue(
        asOf: created.add(const Duration(days: 1)),
      );
      expect(q, hasLength(2));
      expect(q.first.isStale, isTrue); // b first
      expect(q.first.recording.name, 'b');
      expect(q.last.isStale, isFalse); // a
      expect(q.last.recording.name, 'a');
    });
  });
}
