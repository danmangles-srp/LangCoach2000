// Riverpod wiring for the offline queue. Under platform/ so the coverage gate
// excludes it (production wiring pulls in connectivity_plus + workmanager).
//
// Tests build [QueueProcessor] directly against an in-memory AppDatabase +
// [FakeNetworkService] (see queue_processor_test.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/connectivity_network_service.dart';
import 'package:rivendell/core/queue/platform/workmanager_init.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/core/queue/queue_worker.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = ConnectivityNetworkService();
  ref.onDispose(service.dispose);
  return service;
});

final queueRepositoryProvider = FutureProvider<QueueRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return QueueRepository(db);
});

final queueProcessorProvider = FutureProvider<QueueWorker>((ref) async {
  final repo = await ref.watch(queueRepositoryProvider.future);
  final worker = QueueWorker(
    repository: repo,
    network: ref.watch(networkServiceProvider),
    logger: ref.watch(appLoggerProvider),
  );
  // Features register handlers (ai_image @ M4, email @ M6) before start.
  ref.onDispose(worker.stop);
  return worker;
});

/// Boot the offline queue: init workmanager, then start draining on reconnect.
/// Call once from app bootstrap (main), after the DB has resolved.
Future<void> bootOfflineQueue(ProviderContainer container) async {
  await initWorkmanager();
  final worker = await container.read(queueProcessorProvider.future);
  worker.start();
}
