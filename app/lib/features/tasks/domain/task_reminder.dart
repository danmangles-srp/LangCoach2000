// Reminder fire-time for a task (T5.3, FR-1.4.2). Pure: no platform, no IO.
// A task reminds once, on the morning of its due day ([hour], local). Past or
// absent due dates return null — overdue tasks surface in-app via the Overdue
// pill (T5.2), so a notification for them would just be noise. [now] is
// injectable so the past/future boundary is testable without a device.

DateTime? reminderFireTimeFor(
  DateTime? dueDate, {
  required DateTime now,
  int hour = 9,
}) {
  if (dueDate == null) return null;
  final fire = DateTime(dueDate.year, dueDate.month, dueDate.day, hour);
  return fire.isAfter(now) ? fire : null;
}
