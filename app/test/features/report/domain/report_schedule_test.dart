// Report schedule + fire-time math (T6.6, FR-1.5.3). Pure calendar arithmetic
// — pinned to a caller-supplied "now" so every DST/week-boundary case is
// deterministic. Local time throughout (see metrics_window.dart for the same
// convention).
//
// The default-cadence fixture (Saturday 09:00) deliberately reuses the
// production defaults so the math tests assert the real shipped cadence.

import 'package:flutter_test/flutter_test.dart';

// The default-cadence fixture deliberately invokes the bare constructor so
// the suite asserts the shipped defaults end-to-end (ctor → fields → fire
// math), rather than comparing a constant to itself.
// ignore_for_file: avoid_redundant_argument_values, use_named_constants

import 'package:rivendell/features/report/domain/report_schedule.dart';

void main() {
  group('ReportSchedule defaults', () {
    test('Saturday 09:00 (product decision)', () {
      const s = ReportSchedule();
      expect(s.weekday, DateTime.saturday);
      expect(s.hour, 9);
      expect(s.minute, 0);
    });

    test('json round-trip', () {
      const s = ReportSchedule(weekday: DateTime.monday, hour: 18, minute: 30);
      final back = ReportSchedule.fromJson(s.toJson());
      expect(back, s);
    });

    test('json tolerates string-encoded ints (KV returns strings)', () {
      final s = ReportSchedule.fromJson(const {
        'weekday': '2',
        'hour': '7',
        'minute': '5',
      });
      expect(s.weekday, 2);
      expect(s.hour, 7);
      expect(s.minute, 5);
    });

    test('json falls back to defaults for missing/corrupt fields', () {
      final s = ReportSchedule.fromJson(const {});
      expect(s, const ReportSchedule());
    });

    test('out-of-range fields are clamped', () {
      final s = ReportSchedule.fromJson(const {
        'weekday': 99,
        'hour': 25,
        'minute': -1,
      });
      expect(s.weekday, 7);
      expect(s.hour, 23);
      expect(s.minute, 0);
    });
  });

  group('nextFireFrom', () {
    // Saturday 2025-06-07 09:00 is the target throughout.
    const schedule = ReportSchedule();

    test('same-day, before slot → today at slot', () {
      final now = DateTime(2025, 6, 7, 8, 0); // Saturday 08:00
      expect(nextFireFrom(schedule, now), DateTime(2025, 6, 7, 9, 0));
    });

    test('same-day, after slot → next week', () {
      final now = DateTime(2025, 6, 7, 10, 0); // Saturday 10:00
      expect(nextFireFrom(schedule, now), DateTime(2025, 6, 14, 9, 0));
    });

    test('mid-week → upcoming Saturday', () {
      final now = DateTime(2025, 6, 4, 12, 0); // Wednesday
      expect(nextFireFrom(schedule, now), DateTime(2025, 6, 7, 9, 0));
    });

    test('Sunday → next Saturday (6 days forward)', () {
      final now = DateTime(2025, 6, 8, 9, 0); // Sunday 09:00
      expect(nextFireFrom(schedule, now), DateTime(2025, 6, 14, 9, 0));
    });

    test('exactly at slot → next week (strict future)', () {
      final now = DateTime(2025, 6, 7, 9, 0); // exactly Saturday 09:00
      expect(nextFireFrom(schedule, now), DateTime(2025, 6, 14, 9, 0));
    });
  });

  group('scheduledInstantOnOrBefore', () {
    const schedule = ReportSchedule();

    test("after today's slot → today's slot", () {
      final now = DateTime(2025, 6, 7, 12, 0); // Saturday noon
      expect(
        scheduledInstantOnOrBefore(schedule, now),
        DateTime(2025, 6, 7, 9, 0),
      );
    });

    test("before today's slot → last week's slot", () {
      final now = DateTime(2025, 6, 7, 8, 0); // Saturday 08:00
      expect(
        scheduledInstantOnOrBefore(schedule, now),
        DateTime(2025, 5, 31, 9, 0),
      );
    });

    test('exactly at slot → slot itself (closed lower bound)', () {
      final now = DateTime(2025, 6, 7, 9, 0);
      expect(
        scheduledInstantOnOrBefore(schedule, now),
        DateTime(2025, 6, 7, 9, 0),
      );
    });
  });

  group('shouldFireNow', () {
    const schedule = ReportSchedule();

    test('never sent + due passed → fire', () {
      final now = DateTime(2025, 6, 7, 12, 0); // Saturday noon
      expect(shouldFireNow(schedule, now, null), isTrue);
    });

    test('never sent + before today slot → still fire (last week overdue)', () {
      // Saturday 08:00, never sent: the most recent passed slot was last
      // Saturday 09:00, which is overdue. The recipient-config gate (in the
      // dispatcher) decides whether anything actually enqueues.
      final now = DateTime(2025, 6, 7, 8, 0); // Saturday 08:00
      expect(shouldFireNow(schedule, now, null), isTrue);
    });

    test('sent this cycle → do not fire (idempotent within week)', () {
      final now = DateTime(2025, 6, 7, 12, 0);
      final lastSent = DateTime(2025, 6, 7, 9, 5); // sent earlier today
      expect(shouldFireNow(schedule, now, lastSent), isFalse);
    });

    test('sent last cycle → fire this cycle (weekly cadence)', () {
      final now = DateTime(2025, 6, 7, 12, 0);
      final lastSent = DateTime(2025, 5, 31, 9, 5); // last Saturday
      expect(shouldFireNow(schedule, now, lastSent), isTrue);
    });
  });
}
