// dashboardWindow (T6.3) — rolling window ending today. Pure function; pin
// `now` so the window is deterministic regardless of when the suite runs.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/metrics/application/metrics_providers.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';

void main() {
  // Wednesday 2026-07-15 14:30 local.
  final now = DateTime(2026, 7, 15, 14, 30);

  test('daily: 14-bucket window ending at tomorrow midnight', () {
    final w = dashboardWindow(MetricsGranularity.daily, now: now);
    // from = today - 13 days = 2026-07-02; until = 2026-07-16 (tomorrow).
    expect(w.from, DateTime(2026, 7, 2));
    expect(w.until, DateTime(2026, 7, 16));
  });

  test('weekly: 8-bucket window (49-day span) ending at tomorrow midnight', () {
    final w = dashboardWindow(MetricsGranularity.weekly, now: now);
    // from = today - 7*(8-1) days = 2026-05-27; until = 2026-07-16.
    expect(w.from, DateTime(2026, 5, 27));
    expect(w.until, DateTime(2026, 7, 16));
  });

  test('monthly: 6-bucket window ending at first of next month', () {
    final w = dashboardWindow(MetricsGranularity.monthly, now: now);
    // from = first-of-month 6 months back = 2026-02-01; until = 2026-08-01.
    expect(w.from, DateTime(2026, 2));
    expect(w.until, DateTime(2026, 8));
  });

  test('until is always strictly after from', () {
    for (final g in MetricsGranularity.values) {
      final w = dashboardWindow(g, now: now);
      expect(w.until.isAfter(w.from), isTrue);
    }
  });
}
