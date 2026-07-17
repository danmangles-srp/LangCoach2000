// Recording [TaskNotificationGateway] for tests (T5.3). Captures every
// schedule/cancel in order so TaskCommands wiring can assert the right calls
// land — and never touches the real plugin, so widget tests don't need a
// device. [init] / [requestPermissions] are no-ops that succeed.

import 'package:rivendell/features/tasks/application/task_notification_gateway.dart';

class FakeTaskNotificationGateway implements TaskNotificationGateway {
  final List<ScheduledReminder> scheduled = [];
  final List<int> canceled = [];
  bool permissionsGranted = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => permissionsGranted;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime fireTime,
    String? body,
  }) async {
    scheduled.add(
      ScheduledReminder(id: id, title: title, body: body, fireTime: fireTime),
    );
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  /// The single reminder scheduled for [id], if any. TaskCommands cancels
  /// before re-scheduling, so at most one survives per id.
  ScheduledReminder? lastFor(int id) {
    for (final r in scheduled.reversed) {
      if (r.id == id) return r;
    }
    return null;
  }
}

class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.fireTime,
  });

  final int id;
  final String title;
  final String? body;
  final DateTime fireTime;
}
