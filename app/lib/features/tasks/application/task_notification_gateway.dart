// Abstract seam over scheduled task reminders (T5.3, FR-1.4.2). The platform
// impl wraps flutter_local_notifications (AlarmManager-backed scheduling that
// fires even when the app is fully closed); tests swap in a recording fake.
//
// [schedule] takes an absolute local [fireTime]; the caller (TaskCommands) has
// already decided a reminder is warranted (future due date, task incomplete).
// [id] is the task id — one reminder per task, so cancel-by-id is exact.

abstract class TaskNotificationGateway {
  /// One-time plugin + timezone bootstrap. Idempotent; safe to call on every
  /// mutation path or once at startup.
  Future<void> init();

  /// Request the runtime grants the platform needs (Android 13+
  /// POST_NOTIFICATIONS, Android 12+ exact-alarm). Returns whether the
  /// platform is ready to schedule. Idempotent.
  Future<bool> requestPermissions();

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime fireTime,
    String? body,
  });

  Future<void> cancel(int id);
}
