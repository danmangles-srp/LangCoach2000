// MetricsAggregationService — T6.2 (FR-1.5.1). The impure facade over the four
// metric sources: pulls raw rows from the metrics ledger, word_logs, and
// review_events, then buckets them via the pure aggregator. In-memory Drift;
// no device. Proves the four series are independently correct + aligned to the
// shared bucket list.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/data/metrics_repository.dart';
import 'package:rivendell/features/metrics/domain/metric_kind.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';

void main() {
  late AppDatabase db;
  late RecordingRepository recordings;
  late MetricsRepository metrics;
  late WordLogRepository wordLogs;
  late ReviewEventRepository reviews;
  late MetricsAggregationService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordings = RecordingRepository(db);
    metrics = MetricsRepository(db);
    wordLogs = WordLogRepository(db);
    reviews = ReviewEventRepository(db);
    service = MetricsAggregationService(metrics, wordLogs, reviews);
  });

  tearDown(() => db.close());

  // Seed a recording + return its id. Pin a fixed createdAt so review-event
  // derivation doesn't trip on real now.
  Future<int> seed() async {
    await recordings.upsertScanned([
      ScannedFile(
        path: '/svr/lec.m4a',
        name: 'lec.m4a',
        createdAt: DateTime(2026, 7),
        sizeBytes: 1,
        format: AudioFormat.m4a,
      ),
    ]);
    final row = await recordings.findByPath('/svr/lec.m4a');
    if (row == null) fail('seed recording not found');
    return row.id;
  }

  test(
    'empty store -> all four series zero, bucket list still populated',
    () async {
      final snapshot = await service.snapshot(
        window: MetricsWindow(
          from: DateTime(2026, 7),
          until: DateTime(2026, 7, 4),
        ),
        granularity: MetricsGranularity.daily,
      );
      expect(snapshot.lessonDuration.total, 0);
      expect(snapshot.flashcardsReviewed.total, 0);
      expect(snapshot.journalingOutput.total, 0);
      expect(snapshot.completedQueueItems.total, 0);
      // 3 daily buckets (Jul 1, 2, 3) — x-axis present even with no data.
      expect(snapshot.lessonDuration.points, hasLength(3));
    },
  );

  test('lesson duration sums per-day ledger increments', () async {
    await metrics.record(
      MetricKind.lessonDuration,
      60_000,
      at: DateTime(2026, 7, 1, 9),
    );
    await metrics.record(
      MetricKind.lessonDuration,
      30_000,
      at: DateTime(2026, 7, 1, 18),
    );
    await metrics.record(
      MetricKind.lessonDuration,
      45_000,
      at: DateTime(2026, 7, 3, 12),
    );

    final snapshot = await service.snapshot(
      window: MetricsWindow(
        from: DateTime(2026, 7),
        until: DateTime(2026, 7, 4),
      ),
      granularity: MetricsGranularity.daily,
    );
    expect(snapshot.lessonDuration.points.map((p) => p.value), [
      90_000,
      0,
      45_000,
    ]);
    expect(snapshot.lessonDuration.total, 135_000);
  });

  test('flashcards reviewed sums per-day card-count increments', () async {
    await metrics.record(
      MetricKind.flashcardsReviewed,
      10,
      at: DateTime(2026, 7, 2, 8),
    );
    await metrics.record(
      MetricKind.flashcardsReviewed,
      5,
      at: DateTime(2026, 7, 2, 20),
    );

    final snapshot = await service.snapshot(
      window: MetricsWindow(
        from: DateTime(2026, 7),
        until: DateTime(2026, 7, 4),
      ),
      granularity: MetricsGranularity.daily,
    );
    expect(snapshot.flashcardsReviewed.points.map((p) => p.value), [0, 15, 0]);
    expect(snapshot.flashcardsReviewed.total, 15);
  });

  test('journaling output counts text logs per day (images ignored)', () async {
    final id = await seed();
    await wordLogs.setTextLog(id, body: 'a: a'); // stamped real now
    // The single text log lives at real now (after 2026-07-04 in this suite).
    // Use a wide window so it lands in a bucket regardless of today.
    final snapshot = await service.snapshot(
      window: MetricsWindow(from: DateTime(2020), until: DateTime(2030)),
      granularity: MetricsGranularity.monthly,
    );
    // Exactly one text log -> total 1; image logs don't count.
    await wordLogs.addImage(id, path: 'images/n.jpg');
    final snapshot2 = await service.snapshot(
      window: MetricsWindow(from: DateTime(2020), until: DateTime(2030)),
      granularity: MetricsGranularity.monthly,
    );
    expect(snapshot.journalingOutput.total, 1);
    expect(snapshot2.journalingOutput.total, 1);
  });

  test('completed queue items counts review events per day', () async {
    final id = await seed();
    // created 2026-07-01: D+1 due 07-02, D+2 due 07-03, D+4 due 07-05.
    await reviews.markReviewed(
      id,
      milestoneIndex: 0,
      completedAt: DateTime(2026, 7, 2, 10),
    );
    await reviews.markReviewed(
      id,
      milestoneIndex: 1,
      completedAt: DateTime(2026, 7, 3, 10),
    );

    final snapshot = await service.snapshot(
      window: MetricsWindow(
        from: DateTime(2026, 7),
        until: DateTime(2026, 7, 4),
      ),
      granularity: MetricsGranularity.daily,
    );
    expect(snapshot.completedQueueItems.points.map((p) => p.value), [0, 1, 1]);
    expect(snapshot.completedQueueItems.total, 2);
  });

  test(
    'half-open window boundary: a `until`-stamped event is excluded',
    () async {
      await metrics.record(
        MetricKind.lessonDuration,
        1_000,
        at: DateTime(2026, 7, 4),
      );
      final snapshot = await service.snapshot(
        window: MetricsWindow(
          from: DateTime(2026, 7),
          until: DateTime(2026, 7, 4),
        ),
        granularity: MetricsGranularity.daily,
      );
      expect(snapshot.lessonDuration.total, 0);
    },
  );

  test('weekly granularity buckets across a 14-day span (2 weeks)', () async {
    // Default Sat-anchored weeks: [06-27, 07-04), [07-04, 07-11).
    await metrics.record(
      MetricKind.lessonDuration,
      10_000,
      at: DateTime(2026, 6, 29, 12), // week 1 (Sun after Sat start)
    );
    await metrics.record(
      MetricKind.lessonDuration,
      20_000,
      at: DateTime(2026, 7, 6, 12), // week 2 (Mon after Sat start)
    );
    final snapshot = await service.snapshot(
      window: MetricsWindow(
        from: DateTime(2026, 6, 27),
        until: DateTime(2026, 7, 11),
      ),
      granularity: MetricsGranularity.weekly,
    );
    expect(snapshot.lessonDuration.points.map((p) => p.bucketStart), [
      DateTime(2026, 6, 27),
      DateTime(2026, 7, 4),
    ]);
    expect(snapshot.lessonDuration.points.map((p) => p.value), [
      10_000,
      20_000,
    ]);
  });
}
