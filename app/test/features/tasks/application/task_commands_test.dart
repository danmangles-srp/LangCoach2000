// TaskCommands — reminder sync over mutations (T5.3, FR-1.4.2). The one
// testable assertion: every mutation lands the right schedule/cancel on the
// gateway. Uses a real [TaskRepository] on an in-memory db so the create /
// update / complete / delete round-trip is exercised, and a recording fake so
// no plugin is touched.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/application/fake_task_notification_gateway.dart';
import 'package:rivendell/features/tasks/application/task_commands.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';

AppDatabase _db() => AppDatabase.forTesting(NativeDatabase.memory());

// 2026-07-01 08:00 — before the 09:00 reminder hour, so a same-day or later
// due date is "future" and schedules.
final DateTime _now = DateTime(2026, 7, 1, 8);

void main() {
  late AppDatabase db;
  late FakeTaskNotificationGateway gateway;
  late TaskCommands commands;

  setUp(() {
    db = _db();
    gateway = FakeTaskNotificationGateway();
    commands = TaskCommands(TaskRepository(db), gateway, () => _now);
  });
  tearDown(() => db.close());

  test(
    'create with a future due date schedules at 09:00 of that day',
    () async {
      await commands.create(
        title: 'Review verbs',
        dueDate: DateTime(2026, 7, 5),
      );

      final r = gateway.lastFor(1);
      expect(r, isNotNull);
      expect(r!.title, 'Review verbs');
      expect(r.fireTime, DateTime(2026, 7, 5, 9));
    },
  );

  test(
    'create with no due date cancels (clears) and schedules nothing',
    () async {
      await commands.create(title: 'someday');

      expect(gateway.scheduled, isEmpty);
      // One cancel issued for the new task id — harmless, keeps state clean.
      expect(gateway.canceled, [1]);
    },
  );

  test(
    'create with a past due date schedules nothing (overdue is in-app)',
    () async {
      await commands.create(title: 'old', dueDate: DateTime(2020, 1, 2));

      expect(gateway.scheduled, isEmpty);
    },
  );

  test(
    'update with a new due date reschedules (cancel-then-schedule)',
    () async {
      final task = await commands.create(title: 'task');
      gateway.scheduled.clear();
      gateway.canceled.clear();

      await commands.update(
        task.id,
        title: 'task',
        dueDate: DateTime(2026, 7, 9),
      );

      expect(gateway.canceled, [task.id]);
      final r = gateway.lastFor(task.id);
      expect(r, isNotNull);
      expect(r!.fireTime, DateTime(2026, 7, 9, 9));
    },
  );

  test(
    'update that clears the due date cancels and does not reschedule',
    () async {
      final task = await commands.create(
        title: 'task',
        dueDate: DateTime(2026, 7, 5),
      );
      gateway.scheduled.clear();
      gateway.canceled.clear();

      await commands.update(task.id, title: 'task');

      expect(gateway.scheduled, isEmpty);
      expect(gateway.canceled, [task.id]);
    },
  );

  test('setCompleted(true) cancels the reminder', () async {
    final task = await commands.create(
      title: 'task',
      dueDate: DateTime(2026, 7, 5),
    );
    gateway.scheduled.clear();
    gateway.canceled.clear();

    await commands.setCompleted(task.id, completed: true);

    expect(gateway.scheduled, isEmpty);
    expect(gateway.canceled, [task.id]);
  });

  test('un-completing a still-due task reschedules', () async {
    final task = await commands.create(
      title: 'task',
      dueDate: DateTime(2026, 7, 5),
    );
    await commands.setCompleted(task.id, completed: true);
    gateway.scheduled.clear();
    gateway.canceled.clear();

    await commands.setCompleted(task.id, completed: false);

    final r = gateway.lastFor(task.id);
    expect(r, isNotNull);
    expect(r!.fireTime, DateTime(2026, 7, 5, 9));
  });

  test('delete cancels the reminder', () async {
    final task = await commands.create(
      title: 'task',
      dueDate: DateTime(2026, 7, 5),
    );
    gateway.scheduled.clear();
    gateway.canceled.clear();

    await commands.delete(task.id);

    expect(gateway.canceled, [task.id]);
  });
}
