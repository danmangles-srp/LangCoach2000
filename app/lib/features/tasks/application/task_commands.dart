// TaskCommands — the mutation orchestrator for the tasks feature (T5.3,
// FR-1.4.2). Wraps [TaskRepository] so every create / edit / complete / delete
// keeps the scheduled reminder in sync: a future due date schedules (cancel-
// then-schedule, so an edit reschedules cleanly), completing or deleting
// cancels. The repository stays a pure data layer; notification scheduling
// lives here so no call site can forget it.
//
// [now] is injectable so the past/future boundary ([reminderFireTimeFor]) is
// deterministic in tests.

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/application/task_notification_gateway.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';
import 'package:rivendell/features/tasks/domain/task_reminder.dart';

class TaskCommands {
  TaskCommands(this._repo, this._notifications, this._now);

  final TaskRepository _repo;
  final TaskNotificationGateway _notifications;
  final DateTime Function() _now;
  bool _permissionsRequested = false;

  Future<Task> create({
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final task = await _repo.create(
      title: title,
      description: description,
      dueDate: dueDate,
    );
    await _sync(task);
    return task;
  }

  Future<Task> update(
    int id, {
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final task = await _repo.update(
      id,
      title: title,
      description: description,
      dueDate: dueDate,
    );
    await _sync(task);
    return task;
  }

  Future<Task> setCompleted(int id, {required bool completed}) async {
    final task = await _repo.setCompleted(id, completed: completed);
    // A completed task has no reminder; un-completing reschedules if still due.
    if (task.completed) {
      await _notifications.cancel(id);
    } else {
      await _sync(task);
    }
    return task;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _notifications.cancel(id);
  }

  Future<void> _sync(Task task) async {
    // Cancel first so an edit never stacks a second reminder for the same id.
    await _notifications.cancel(task.id);
    final fire = reminderFireTimeFor(task.dueDate, now: _now());
    if (fire == null) return;
    // Request the notification grant lazily, on the first reminder that's
    // actually scheduled — so the prompt lands in context (the user just set
    // a due date), not on first launch. The singleton keeps this
    // once-per-session.
    if (!_permissionsRequested) {
      _permissionsRequested = true;
      await _notifications.requestPermissions();
    }
    await _notifications.schedule(
      id: task.id,
      title: task.title,
      fireTime: fire,
    );
  }
}
