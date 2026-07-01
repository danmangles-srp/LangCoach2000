// reminderFireTimeFor — pure boundary logic (T5.3, FR-1.4.2). The helper is
// the one unit-testable piece of the notification flow: it decides whether a
// reminder is scheduled at all and pins the wall time AlarmManager fires at.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/tasks/domain/task_reminder.dart';

void main() {
  // 2026-07-01 08:00 local — before the default 09:00 reminder hour.
  final now = DateTime(2026, 7, 1, 8);

  test('null due date schedules nothing', () {
    expect(reminderFireTimeFor(null, now: now), isNull);
  });

  test('a future due date fires at 09:00 of that day', () {
    final due = DateTime(2026, 7, 5);
    final fire = reminderFireTimeFor(due, now: now);
    expect(fire, DateTime(2026, 7, 5, 9));
  });

  test('today (still before 09:00) fires this morning', () {
    final fire = reminderFireTimeFor(DateTime(2026, 7), now: now);
    expect(fire, DateTime(2026, 7, 1, 9));
  });

  test('today after the reminder hour has passed schedules nothing', () {
    final later = DateTime(2026, 7, 1, 10);
    final fire = reminderFireTimeFor(DateTime(2026, 7), now: later);
    expect(fire, isNull);
  });

  test('a past due date schedules nothing (overdue surfaces in-app)', () {
    final fire = reminderFireTimeFor(DateTime(2026, 6), now: now);
    expect(fire, isNull);
  });

  test('a due date with a time component still fires at the day hour', () {
    final due = DateTime(2026, 7, 5, 18, 30);
    final fire = reminderFireTimeFor(due, now: now);
    expect(fire, DateTime(2026, 7, 5, 9));
  });
}
