// Riverpod wiring for the tasks feature (M5, T5.2). The repository wraps the
// Drift store; `tasksProvider` is the ordered read the screen binds to.
// Mutations invalidate `tasksProvider` so the list refreshes atomically.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';

/// Singleton [TaskRepository] over the local store.
final taskRepositoryProvider = FutureProvider<TaskRepository>(
  (ref) async => TaskRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Every task, ordered (see [TaskRepository.all]). Drives the tasks screen.
/// Invalidate after any mutation so the list refreshes.
final tasksProvider = FutureProvider<List<Task>>(
  (ref) async => (await ref.watch(taskRepositoryProvider.future)).all(),
);
