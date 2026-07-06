// Pure unit tests for the GPA interval engine (T2.1, FR-1.2.1 / FR-1.2.2).
// Pins the canonical intervals, the day-granularity due-date math (creation
// time-of-day must not shift which day a milestone is due), the due/overdue
// evaluation, and the boundary edge cases (month rollover, full ladder
// elapsed). No DateTime.now() inside the engine, so all "now"s are passed in.
//
// Dates are expressed off a non-January / non-1st base via Duration offsets —
// DateTime's ctor defaults month/day to 1, so literal January or 1st-of-month
// dates trip avoid_redundant_argument_values, and offset math is more robust
// than hand-computed calendars anyway.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/gpa/domain/gpa_intervals.dart';

DateTime _day(int year, int month, int day) => DateTime(year, month, day);

void main() {
  // 2026-03-15 — neither January nor the 1st, so it never collides with the
  // DateTime ctor defaults the linter flags.
  final base = _day(2026, 3, 15);

  group('canonical intervals', () {
    test('match the GPA sequence in order', () {
      expect(gpaIntervalsInDays, const [1, 2, 4, 7, 30, 90, 180, 365]);
    });
  });

  group('gpaTimelineFor', () {
    test('builds one rung per interval with index, days, and due date', () {
      final timeline = gpaTimelineFor(
        createdAt: DateTime(2026, 3, 15, 9, 30), // time-of-day must be ignored
      );

      expect(timeline, hasLength(8));
      for (var i = 0; i < gpaIntervalsInDays.length; i++) {
        expect(timeline[i].index, i);
        expect(timeline[i].intervalDays, gpaIntervalsInDays[i]);
        expect(
          timeline[i].dueOn,
          base.add(Duration(days: gpaIntervalsInDays[i])),
        );
      }
    });

    test('due dates are midnight regardless of creation time-of-day', () {
      final first = gpaTimelineFor(
        createdAt: DateTime(2026, 3, 15, 23, 59),
      ).first;
      expect(first.dueOn, base.add(const Duration(days: 1))); // D+1, midnight
    });

    test('honors a custom interval set (incl. empty)', () {
      expect(gpaTimelineFor(createdAt: base, intervals: const []), isEmpty);
      final two = gpaTimelineFor(createdAt: base, intervals: const [3, 10]);
      expect(two.map((m) => m.intervalDays), const [3, 10]);
      expect(two.last.dueOn, base.add(const Duration(days: 10)));
    });

    test('rolls month boundaries correctly', () {
      // Feb 28 + 1 day = Mar 1 (2026 is not a leap year); +30 = Mar 30.
      final feb28 = _day(2026, 2, 28);
      final m1 = gpaTimelineFor(createdAt: feb28, intervals: const [1, 30]);
      expect(m1[0].dueOn, feb28.add(const Duration(days: 1)));
      expect(m1[1].dueOn, feb28.add(const Duration(days: 30)));
    });
  });

  group('isDueOn / daysOverdue', () {
    final created = base;
    final d1 = gpaTimelineFor(createdAt: created).first; // due base+1

    test('nothing is due on the creation day', () {
      expect(d1.isDueOn(created), isFalse);
      expect(d1.daysOverdue(created), -1);
    });

    test('D+1 becomes due on its due day and counts overdue from there', () {
      final dueDay = created.add(const Duration(days: 1));
      final staleDay = created.add(const Duration(days: 2));
      // The day BEFORE the due day is the creation day itself (dueDay - 1).
      expect(d1.isDueOn(dueDay), isTrue); // due day
      expect(d1.daysOverdue(dueDay), 0);
      expect(d1.isDueOn(staleDay), isTrue); // one-day stale
      expect(d1.daysOverdue(staleDay), 1);
      expect(d1.isDueOn(created), isFalse); // day before due
      expect(d1.daysOverdue(created), -1);
    });

    test('day boundary: 23:59 -> 00:01 does not split the day', () {
      final lateCreated = DateTime(2026, 3, 15, 23, 59);
      final d1Late = gpaTimelineFor(createdAt: lateCreated).first;
      // One minute past midnight on the due day: still "due today".
      final justPastMidnight = DateTime(2026, 3, 16, 0, 1);
      expect(d1Late.isDueOn(justPastMidnight), isTrue);
      expect(d1Late.daysOverdue(justPastMidnight), 0);
    });
  });

  group('dueMilestonesFor', () {
    test('returns only elapsed rungs, in interval order', () {
      // 7 days in -> D+1, D+2, D+4, D+7 due; D+30+ not yet.
      final due = dueMilestonesFor(
        createdAt: base,
        asOf: base.add(const Duration(days: 7)),
      );
      expect(due.map((m) => m.intervalDays), const [1, 2, 4, 7]);
    });

    test('returns the full ladder once a year+ has elapsed', () {
      final due = dueMilestonesFor(
        createdAt: base,
        asOf: base.add(const Duration(days: 366)),
      );
      expect(due, hasLength(8));
    });
  });

  group('nextUpcomingMilestone', () {
    test('is the first not-yet-due rung', () {
      final next = nextUpcomingMilestone(
        createdAt: base,
        asOf: base.add(const Duration(days: 7)),
      );
      expect(next?.intervalDays, 30);
    });

    test('returns null once every interval has elapsed', () {
      final next = nextUpcomingMilestone(
        createdAt: base,
        asOf: base.add(const Duration(days: 400)),
      );
      expect(next, isNull);
    });

    test('on the creation day the first upcoming is D+1', () {
      final next = nextUpcomingMilestone(createdAt: base, asOf: base);
      expect(next?.intervalDays, 1);
    });
  });

  group('GpaMilestone value equality', () {
    test('equal when index, days, and dueOn match', () {
      final a = gpaTimelineFor(createdAt: base).first;
      final b = gpaTimelineFor(createdAt: base).first;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('day helpers', () {
    test('dayOnly truncates to midnight', () {
      expect(dayOnly(DateTime(2026, 3, 4, 17, 45)), _day(2026, 3, 4));
    });

    test('sameDay ignores time-of-day', () {
      expect(
        sameDay(DateTime(2026, 3, 15), DateTime(2026, 3, 15, 23, 59)),
        isTrue,
      );
      expect(
        sameDay(DateTime(2026, 3, 15, 23, 59), DateTime(2026, 3, 16, 0, 1)),
        isFalse,
      );
    });
  });
}
