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
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';
import 'package:rivendell/features/tasks/application/task_notification_gateway.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';
import 'package:rivendell/features/tasks/domain/task_reminder.dart';

class TaskCommands {
  TaskCommands(this._repo, this._notifications, this._now, {this.xp});

  final TaskRepository _repo;
  final TaskNotificationGateway _notifications;
  final DateTime Function() _now;

  /// Optional XP sink (M11 T11.2). When wired, completing a task awards +8.
  final XpRepository? xp;
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
    final prior = await _repo.getById(id);
    final task = await _repo.setCompleted(id, completed: completed);
    // A completed task has no reminder; un-completing reschedules if still due.
    if (task.completed) {
      await _notifications.cancel(id);
      // M11 T11.2: award +8 only on the not-done → done transition. A no-op
      // setCompleted(true) on an already-done task doesn't re-award; a
      // deliberate toggle off-then-on does (each completion is a real event;
      // XP is informational, nothing is gated on it). Prior null = the task
      // was deleted concurrently → no award.
      if (prior != null && !prior.completed) {
        await xp?.record(source: XpSource.task, points: 8, taskId: id);
      }
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
