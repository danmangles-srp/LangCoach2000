// Pure-Dart tests for the metric-window + bucket helpers (T6.2). No Flutter,
// no Drift — just date arithmetic. Pinned to a fixed `DateTime` so the bucket
// boundaries are deterministic regardless of when the suite runs.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/metrics/domain/metrics_window.dart';

void main() {
  // A Saturday at 09:00 local — exercises the default week-start (Saturday)
  // and proves the report-time bucket math.
  final saturdayMorning = DateTime(2026, 7, 4, 9); // 2026-07-04 is a Sat
  // Tuesday mid-month for monthly bucket checks.
  final tuesdayJuly14 = DateTime(2026, 7, 14, 15, 30);

  group('bucketStart', () {
    test('daily: snaps to the instant local midnight', () {
      expect(
        bucketStart(MetricsGranularity.daily, saturdayMorning),
        DateTime(2026, 7, 4),
      );
    });

    test('monthly: snaps to the first of the instant month', () {
      expect(
        bucketStart(MetricsGranularity.monthly, tuesdayJuly14),
        DateTime(2026, 7),
      );
    });

    test(
      'weekly (default Sat start): a Saturday instant is its own bucket start',
      () {
        // 2026-07-04 is Saturday → bucket starts at 2026-07-04.
        expect(
          bucketStart(MetricsGranularity.weekly, saturdayMorning),
          DateTime(2026, 7, 4),
        );
      },
    );

    test('weekly (default Sat start): a Sunday instant falls in prior Sat', () {
      // 2026-06-28 is Sunday → most recent Saturday is 2026-06-27.
      final sunday = DateTime(2026, 6, 28, 10);
      expect(
        bucketStart(MetricsGranularity.weekly, sunday),
        DateTime(2026, 6, 27),
      );
    });

    test('weekly: custom week start (Monday) snaps back to Monday', () {
      // 2026-07-04 is Saturday → most recent Monday is 2026-06-29.
      expect(
        bucketStart(
          MetricsGranularity.weekly,
          saturdayMorning,
          weekStartWeekday: DateTime.monday,
        ),
        DateTime(2026, 6, 29),
      );
    });
  });

  group('bucketsInRange', () {
    test('daily: enumerates every midnight in [from, until)', () {
      final from = DateTime(2026, 7);
      final until = DateTime(2026, 7, 4); // 3-day span
      expect(bucketsInRange(MetricsGranularity.daily, from, until), [
        DateTime(2026, 7),
        DateTime(2026, 7, 2),
        DateTime(2026, 7, 3),
      ]);
    });

    test('daily: empty list when until == from', () {
      final t = DateTime(2026, 7);
      expect(bucketsInRange(MetricsGranularity.daily, t, t), isEmpty);
    });

    test('weekly: partitions a 14-day span into 2 Sat-anchored buckets', () {
      // 2026-06-27 (Sat) → 2026-07-11 (Sat) = 14 days, 2 full weeks.
      final from = DateTime(2026, 6, 27);
      final until = DateTime(2026, 7, 11);
      expect(bucketsInRange(MetricsGranularity.weekly, from, until), [
        DateTime(2026, 6, 27),
        DateTime(2026, 7, 4),
      ]);
    });

    test('monthly: enumerates first-of-month for a multi-month span', () {
      final from = DateTime(2026, 6, 15);
      final until = DateTime(2026, 8, 20);
      expect(bucketsInRange(MetricsGranularity.monthly, from, until), [
        DateTime(2026, 6),
        DateTime(2026, 7),
        DateTime(2026, 8),
      ]);
    });

    test('throws on an inverted range (until before from)', () {
      final from = DateTime(2026, 7, 4);
      final until = DateTime(2026, 7);
      expect(
        () => bucketsInRange(MetricsGranularity.daily, from, until),
        throwsArgumentError,
      );
    });
  });
}
