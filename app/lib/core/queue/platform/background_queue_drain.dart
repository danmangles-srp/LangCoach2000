// coverage:ignore-file — runs in the workmanager background isolate, which
// needs the platform plugins (flutter_secure_storage, path_provider,
// connectivity_plus, the native SQLCipher lib). Verified on-device, not in a
// unit test. The drain loop itself is covered by queue_worker_test.dart; this
// file only constructs the same deps the foreground builds and runs one pass.

// T18.2 — drain the offline queue from the workmanager background isolate so
// AI-image generation (FR-1.3.4) progresses while the app is closed. The
// foreground QueueWorker (T19.1/T19.2) covers the common case; this is the
// closed-app backstop registered as a periodic task in workmanager_init.dart.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_connection.dart';
import 'package:rivendell/core/database/platform/secure_database_key_store.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/platform/connectivity_network_service.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/core/queue/queue_worker.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/pollinations_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/platform/pollinations_config.dart';

/// Drain pending queue items from the workmanager background isolate (T18.2).
///
/// Returns `true` on completion (success or a clean no-op), `false` only if a
/// drain attempt threw — so workmanager applies its own backoff retry. Every
/// platform dep is constructed + torn down inside this call: the background
/// isolate owns no long-lived state.
///
/// Key ownership (T0.3): READS the SQLCipher key via [SecureDatabaseKeyStore]
/// and never creates. The periodic task is registered from main-isolate boot
/// AFTER [openAppDatabase] has created the key (see main.dart's
/// registerAiImageHandler → bootOfflineQueue ordering), so by the time this
/// fires the key is present. If it is somehow absent (a pre-boot fire), the
/// drain no-ops — the foreground path owns creation and will drain on the next
/// open.
///
/// Only the `ai_image` handler is registered here. Email items (the weekly
/// report, enqueued by T6.5) are left pending if present; they are rare and
/// drain on the next foreground session. Wiring the email handler into the
/// background isolate is T6.6's scope.
Future<bool> drainQueueFromBackground(AppLogger logger) async {
  final key = await SecureDatabaseKeyStore().read();
  if (key == null) {
    logger.i(
      LogTag.task,
      'background drain: db key absent; skipping (foreground owns create)',
    );
    return true;
  }

  final docsDir = await getApplicationDocumentsDirectory();
  final db = await openAppDatabaseWithKey(
    key: key,
    dbPath: () => p.join(docsDir.path, 'rivendell.sqlite'),
  );
  // Close the DB on every exit path so a thrown handler can't leak the
  // connection (the background isolate re-opens on the next fire).
  try {
    final network = ConnectivityNetworkService();
    try {
      final queue = QueueRepository(db);
      final worker = QueueWorker(
        repository: queue,
        network: network,
        logger: logger,
      );
      await _registerAiImageHandler(
        worker: worker,
        queue: queue,
        db: db,
        logger: logger,
      );
      // One-shot drain (worker.start is NOT called) so there is no autonomous
      // retry timer surviving past the isolate. Foreground resume + the next
      // periodic fire cover retries.
      await worker.drain();
    } finally {
      await network.dispose();
    }
  } finally {
    await db.close();
  }
  return true;
}

Future<void> _registerAiImageHandler({
  required QueueWorker worker,
  required QueueRepository queue,
  required AppDatabase db,
  required AppLogger logger,
}) async {
  final supportDir = await getApplicationSupportDirectory();
  final service = PollinationsImageService(
    cache: AiImageCacheRepository(db),
    queue: queue,
    docsDir: Directory(supportDir.path),
    client: http.Client(),
    logger: logger,
    baseUrl: pollinationsBaseUrl,
    model: pollinationsModel,
    gate: pollinationsRateGate(),
    // Custom prompt template (T19.6) is a foreground-only nicety: it lives in
    // riverpod state hydrated from the KV store, which the background isolate
    // does not build. Background uses the default pictographic prompt; the next
    // foreground drain re-applies a custom template to subsequent words.
  );
  worker.registerHandler(aiImageQueueType, (payload) async {
    final pair = pairFromAiImagePayload(payload);
    await service.generateNow(uzbek: pair.uzbek, english: pair.english);
  });
}
