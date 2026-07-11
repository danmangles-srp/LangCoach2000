// Integration contract for the AI-image → queue → screen pipeline (M19, T19.1).
//
// M18 shipped with the foreground path broken: `enqueue` wrote a row but never
// poked the worker, so an already-online session never drained until a network
// edge or app restart fired one (the user's "didn't show until restart"). The
// unit suite passed because it tested `enqueue` and `generateNow` in isolation,
// never the enqueue → drain → generated chain.
//
// These tests boot the REAL provider graph — in-memory Drift DB, real
// QueueWorker + QueueRepository + AiImageCacheRepository + the real
// PollinationsImageService against a fake http client + FakeNetworkService
// online — and assert the end-to-end contract via the real `ai_image` handler
// registered on the worker. Driven with `Future.delayed` (real microtask
// scheduling), the same pattern as queue_worker_test.dart.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/pollinations_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';

void main() {
  late AppDatabase db;
  late Directory docsDir;
  late FakeNetworkService network;
  late List<http.Request> httpCalls;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    docsDir = await Directory.systemTemp.createTemp('ai_queue_integration');
    network = FakeNetworkService();
    httpCalls = <http.Request>[];
  });

  tearDown(() async {
    await db.close();
    if (docsDir.existsSync()) await docsDir.delete(recursive: true);
  });

  // Returns synthetic PNG bytes for every GET and records the request so the
  // prompt can be asserted (T19.3: the English gloss must reach Pollinations).
  http.Client pngClient() {
    return MockClient((request) async {
      if (request.method == 'GET') {
        httpCalls.add(request);
        return http.Response.bytes([1, 2, 3, 4], 200);
      }
      return http.Response.bytes(const [], 404);
    });
  }

  Future<ProviderContainer> bootContainer() async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async => db),
        networkServiceProvider.overrideWith((ref) {
          ref.onDispose(network.dispose);
          return network;
        }),
        aiImageDocsDirProvider.overrideWith((ref) async => docsDir.path),
        aiImageServiceProvider.overrideWith((ref) async {
          final cache = await ref.watch(aiImageCacheRepositoryProvider.future);
          final queue = await ref.watch(queueRepositoryProvider.future);
          return PollinationsImageService(
            cache: cache,
            queue: queue,
            docsDir: docsDir,
            client: pngClient(),
            logger: AppLogger(sink: RecordingSink()),
            baseUrl: 'https://image.pollinations.ai',
            model: 'flux',
          );
        }),
      ],
    );
    // Wire the ai_image handler exactly as app boot does, minus workmanager.
    await registerAiImageHandler(container);
    final worker = await container.read(queueProcessorProvider.future);
    worker.start();
    return container;
  }

  test('pendingChanges emits on enqueue (Drift watch sanity, T19.2)', () async {
    final repo = QueueRepository(db);
    final emits = <int>[];
    final sub = repo.pendingChanges().listen((_) => emits.add(1));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.enqueue(type: 'ai_image', payload: '{"word":"x"}');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    expect(emits, isNotEmpty, reason: 'Drift watch should emit on insert');
  });

  test('enqueue drains in-session: Pending → Generated with no manual retry '
      '(T19.1/T19.2 contract)', () async {
    final container = await bootContainer();
    addTearDown(container.dispose);
    final service = await container.read(aiImageServiceProvider.future);
    final queue = await container.read(queueRepositoryProvider.future);
    final cache = AiImageCacheRepository(db);

    // Clean slate.
    expect(await queue.pendingByType(aiImageQueueType), isEmpty);

    // User taps Send-to-Anki. No manual drain, no network flap, no retry.
    await service.enqueueGeneration('kurbaka');

    // Pending row appears immediately.
    final pending = await queue.pendingByType(aiImageQueueType);
    expect(pending, hasLength(1));
    expect(wordFromAiImagePayload(pending.single.payload), 'kurbaka');

    // Let the reactive drain fire on the queue-table change (T19.2) + the
    // download/write/cache chain complete.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // The image generated: GET happened, bytes landed, cache row present.
    expect(httpCalls, hasLength(1));
    expect(
      File('${docsDir.path}/${buildAiImagePath('kurbaka')}').existsSync(),
      isTrue,
    );
    final cached = await cache.pathFor('kurbaka');
    expect(cached, isNotNull);

    // The row left Pending (markDone) — the user-visible "stuck in queue"
    // symptom is gone without a restart.
    expect(await queue.pendingByType(aiImageQueueType), isEmpty);
  });
}
