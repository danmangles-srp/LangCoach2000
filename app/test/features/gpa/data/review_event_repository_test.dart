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

  // Seed a recording at [created] and return its row id.
  Future<int> seed({String path = '/svr/lec.m4a'}) async {
    await recordings.upsertScanned([
      ScannedFile(
        path: path,
        name: 'lec.m4a',
        createdAt: created,
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
}
