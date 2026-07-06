// MetricsRepository — append-only ledger + windowed sum (T6.1, FR-1.5.1).
// In-memory db. Covers record/sum round-trip, the half-open window boundary,
// kind isolation, the eventsFor ordering, and the empty-window zero.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/metrics/data/metrics_repository.dart';
import 'package:rivendell/features/metrics/domain/metric_kind.dart';

AppDatabase _db() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late MetricsRepository repo;

  setUp(() {
    db = _db();
    repo = MetricsRepository(db);
  });
  tearDown(() => db.close());

  test('record then sum returns the total across the window', () async {
    final day = DateTime(2026, 7);
    await repo.record(MetricKind.lessonDuration, 30_000, at: day);
    await repo.record(
      MetricKind.lessonDuration,
      45_000,
      at: day.add(const Duration(hours: 2)),
    );

    final total = await repo.sum(
      MetricKind.lessonDuration,
      day,
      day.add(const Duration(days: 1)),
    );
    expect(total, 75_000);
  });

  test('sum window is half-open: an event at `until` is excluded', () async {
    final start = DateTime(2026, 7);
    final end = start.add(const Duration(days: 1));
    await repo.record(MetricKind.flashcardsReviewed, 5, at: start);
    // Exactly at the boundary — belongs to the next bucket.
    await repo.record(MetricKind.flashcardsReviewed, 2, at: end);

    expect(await repo.sum(MetricKind.flashcardsReviewed, start, end), 5);
  });

  test(
    'sum isolates kinds: flashcards do not count as lesson duration',
    () async {
      final day = DateTime(2026, 7);
      await repo.record(MetricKind.lessonDuration, 1000, at: day);
      await repo.record(MetricKind.flashcardsReviewed, 8, at: day);

      expect(
        await repo.sum(
          MetricKind.lessonDuration,
          day,
          day.add(const Duration(days: 1)),
        ),
        1000,
      );
    },
  );

  test('sum is zero for a window with no events', () async {
    final day = DateTime(2026, 7);
    expect(
      await repo.sum(
        MetricKind.lessonDuration,
        day,
        day.add(const Duration(days: 1)),
      ),
      0,
    );
  });

  test('eventsFor returns increments oldest-first within the window', () async {
    final day = DateTime(2026, 7);
    await repo.record(
      MetricKind.flashcardsReviewed,
      1,
      at: day.add(const Duration(hours: 3)),
    );
    await repo.record(
      MetricKind.flashcardsReviewed,
      2,
      at: day.add(const Duration(hours: 1)),
    );
    await repo.record(
      MetricKind.lessonDuration,
      999,
      at: day.add(const Duration(hours: 2)),
    );

    final events = await repo.eventsFor(
      MetricKind.flashcardsReviewed,
      day,
      day.add(const Duration(days: 1)),
    );
    expect(events.map((e) => e.value), [2, 1]);
  });

  test('record defaults the timestamp to ~now when `at` is omitted', () async {
    await repo.record(MetricKind.lessonDuration, 500);

    final now = DateTime.now();
    final from = now.subtract(const Duration(seconds: 1));
    final until = now.add(const Duration(seconds: 1));
    expect(await repo.sum(MetricKind.lessonDuration, from, until), 500);
  });
}
