// Pure-Dart tests for the metric aggregator (T6.2): bucket raw event timestamps
// (count metrics) and timestamp+value pairs (sum metrics) into per-bucket
// series. No Flutter, no Drift — pinned timestamps for determinism.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';

void main() {
  final buckets = [
    DateTime(2026, 7),
    DateTime(2026, 7, 2),
    DateTime(2026, 7, 3),
  ];

  group('bucketizeCounts', () {
    test('counts events per daily bucket, dropping anything outside', () {
      final events = [
        DateTime(2026, 7, 1, 1),
        DateTime(2026, 7, 1, 23),
        DateTime(2026, 7, 2, 12),
        DateTime(2026, 6, 30, 12), // before range — dropped
        DateTime(2026, 7, 4), // after range — dropped
      ];
      expect(bucketizeCounts(buckets, events, MetricsGranularity.daily), [
        2,
        1,
        0,
      ]);
    });

    test('a bucket with no events stays at 0 (preserves x-axis gaps)', () {
      expect(bucketizeCounts(buckets, [], MetricsGranularity.daily), [0, 0, 0]);
    });

    test('weekly buckets: events land in the week containing them', () {
      final weekBuckets = [
        DateTime(2026, 6, 28), // Sun
        DateTime(2026, 7, 5), // next Sun
      ];
      final events = [
        DateTime(2026, 6, 28, 1), // week 1
        DateTime(2026, 7, 4, 23), // week 1 (Sat)
        DateTime(2026, 7, 5), // week 2
      ];
      expect(
        bucketizeCounts(
          weekBuckets,
          events,
          MetricsGranularity.weekly,
          weekStartWeekday: DateTime.sunday,
        ),
        [2, 1],
      );
    });
  });

  group('bucketizeSums', () {
    test('sums values per daily bucket', () {
      final events = [
        (at: DateTime(2026, 7, 1, 1), value: 1_000),
        (at: DateTime(2026, 7, 1, 23), value: 500),
        (at: DateTime(2026, 7, 3, 12), value: 2_000),
        (at: DateTime(2026, 7, 4), value: 9_999), // dropped
      ];
      expect(bucketizeSums(buckets, events, MetricsGranularity.daily), [
        1_500,
        0,
        2_000,
      ]);
    });

    test('empty events → all-zero series', () {
      expect(bucketizeSums(buckets, [], MetricsGranularity.daily), [0, 0, 0]);
    });
  });

  group('aggregateCounts / aggregateSums (full pipeline)', () {
    test(
      'aggregateCounts builds a MetricSeries aligned to the bucket list',
      () {
        final events = [
          DateTime(2026, 7, 1, 1),
          DateTime(2026, 7, 2, 1),
          DateTime(2026, 7, 2, 2),
        ];
        final series = aggregateCounts(
          buckets,
          events,
          MetricsGranularity.daily,
        );
        expect(series.points.map((p) => p.value), [1, 2, 0]);
        expect(series.points.map((p) => p.bucketStart), buckets);
        expect(series.total, 3);
      },
    );

    test('aggregateSums reports total + per-bucket values', () {
      final events = [
        (at: DateTime(2026, 7, 1, 1), value: 100),
        (at: DateTime(2026, 7, 3, 1), value: 200),
      ];
      final series = aggregateSums(buckets, events, MetricsGranularity.daily);
      expect(series.points.map((p) => p.value), [100, 0, 200]);
      expect(series.total, 300);
    });
  });
}
