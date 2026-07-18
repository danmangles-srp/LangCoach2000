// StreakService — M11 T11.3 (AC 3). In-memory Drift; no device. Exercises the
// impure glue over the pure engine: the review-ledger derivation, the KV freeze
// bank consume, and the once-per-ISO-week auto-grant persistence.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/progress/application/streak_service.dart';
import 'package:rivendell/features/progress/domain/streak_engine.dart';

// 2026-07-15 (Wed) — ISO week 29 of 2026.
final DateTime _asOf = DateTime(2026, 7, 15);

void main() {
  late AppDatabase db;
  late KvRepository kv;
  late ReviewEventRepository reviews;
  late StreakService streak;
  late int recId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    kv = KvRepository(db);
    reviews = ReviewEventRepository(db);
    streak = StreakService(kv: kv, reviews: reviews, now: () => _asOf);
    recId = await db
        .into(db.recordings)
        .insert(
          RecordingsCompanion.insert(
            filePath: '/svr/lec.m4a',
            name: 'lec.m4a',
            createdAt: DateTime(2026, 3, 15),
            sizeBytes: 1,
            format: 'm4a',
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> reviewOn(DateTime day) async {
    await db
        .into(db.reviewEvents)
        .insert(
          ReviewEventsCompanion.insert(
            recordingId: recId,
            milestoneIndex: const Value(0),
            completedAt: DateTime(day.year, day.month, day.day, 12),
          ),
        );
  }

  Future<int> banked() async =>
      int.parse((await kv.read('progress.streak_freezes_banked')) ?? '0');

  test(
    'empty ledger -> streak 0 (the first-snapshot grant still fires)',
    () async {
      // No reviews, but the once-per-week auto-grant has no review
      // precondition, so a fresh install banks one freeze immediately.
      // Count is still 0.
      final snap = await streak.snapshot();
      expect(snap.count, 0);
      expect(snap.freezesBanked, 1);
    },
  );

  test('a 3-day run derives count 3 (no counter to drift)', () async {
    await reviewOn(_asOf);
    await reviewOn(_asOf.subtract(const Duration(days: 1)));
    await reviewOn(_asOf.subtract(const Duration(days: 2)));

    final snap = await streak.snapshot();
    expect(snap.count, 3);
  });

  test('today unreviewed: streak continues from yesterday', () async {
    await reviewOn(_asOf.subtract(const Duration(days: 1)));
    await reviewOn(_asOf.subtract(const Duration(days: 2)));

    final snap = await streak.snapshot();
    expect(snap.count, 2);
  });

  test('a 1-day gap consumes a banked freeze and continues', () async {
    await kv.write('progress.streak_freezes_banked', '1');
    await reviewOn(_asOf); // today
    await reviewOn(_asOf.subtract(const Duration(days: 2))); // gap yesterday

    final snap = await streak.snapshot();
    expect(snap.count, 3);
    expect(snap.freezesBanked, 0); // consumed
    expect(await banked(), 0); // persisted
  });

  test('a 1-day gap with no banked freeze breaks at today', () async {
    await reviewOn(_asOf);
    await reviewOn(_asOf.subtract(const Duration(days: 2)));
    // No freeze banked, and the auto-grant only fires in a NEW ISO week — but
    // last-grant defaults to 0, so the FIRST snapshot grants one. To test the
    // no-freeze break cleanly, pre-stamp last-grant to THIS week so no grant
    // fires, leaving the bank at 0.
    await kv.write(
      'progress.streak_freezes_last_grant_week',
      isoWeekId(_asOf).toString(),
    );

    final snap = await streak.snapshot();
    expect(snap.count, 1);
    expect(snap.freezesBanked, 0);
  });

  group('auto-grant (once per ISO week, cap 1)', () {
    test('first snapshot in a week grants exactly one freeze', () async {
      final snap = await streak.snapshot();
      expect(snap.freezesBanked, 1);
      expect(await banked(), 1);
      expect(
        await kv.read('progress.streak_freezes_last_grant_week'),
        isoWeekId(_asOf).toString(),
      );
      expect(snap.count, 0); // no reviews -> streak 0, grant unrelated
    });

    test('a second snapshot in the same week does NOT re-grant', () async {
      await streak.snapshot(); // grants 1
      await reviewOn(_asOf);
      await reviewOn(_asOf.subtract(const Duration(days: 1)));

      final snap = await streak.snapshot();
      expect(snap.count, 2);
      expect(snap.freezesBanked, 1); // unchanged — no second grant
    });

    test('a granted freeze is spendable on a later gap', () async {
      // Week 1: grant fires, banked=1. No reviews yet.
      await streak.snapshot();
      // Later (same asOf for determinism): two reviews with a 1-day gap.
      await reviewOn(_asOf);
      await reviewOn(_asOf.subtract(const Duration(days: 2)));

      final snap = await streak.snapshot();
      expect(snap.count, 3); // gap bridged by the banked freeze
      expect(snap.freezesBanked, 0); // spent
    });
  });
}
