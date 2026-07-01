// Riverpod wiring for the tasks feature (M5, T5.2 + T5.3). The repository
// wraps the Drift store; `tasksProvider` is the ordered read the screen binds
// to. Mutations go through [TaskCommands] (T5.3) which keeps reminders in sync,
// then invalidate `tasksProvider` so the list refreshes atomically.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/tasks/application/task_commands.dart';
import 'package:rivendell/features/tasks/application/task_notification_gateway.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';
import 'package:rivendell/features/tasks/platform/flutter_task_notification_gateway.dart';

/// Singleton [TaskRepository] over the local store.
final taskRepositoryProvider = FutureProvider<TaskRepository>(
  (ref) async => TaskRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Singleton [TaskNotificationGateway] over flutter_local_notifications. Tests
/// override this with the recording fake so the plugin is never touched.
final taskNotificationGatewayProvider = Provider<TaskNotificationGateway>(
  (_) => FlutterTaskNotificationGateway(),
);

/// Mutation orchestrator: repo + reminder sync. [DateTime.now] is the default
/// clock; tests construct [TaskCommands] directly with a fixed `now`.
final taskCommandsProvider = FutureProvider<TaskCommands>(
  (ref) async => TaskCommands(
    await ref.watch(taskRepositoryProvider.future),
    ref.watch(taskNotificationGatewayProvider),
    DateTime.now,
  ),
);

/// Every task, ordered (see [TaskRepository.all]). Drives the tasks screen.
/// Invalidate after any mutation so the list refreshes.
final tasksProvider = FutureProvider<List<Task>>(
  (ref) async => (await ref.watch(taskRepositoryProvider.future)).all(),
);
