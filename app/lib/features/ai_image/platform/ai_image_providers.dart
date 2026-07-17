// coverage:ignore-file — production Riverpod wiring (http + path_provider +
// env), excluded from the coverage floor. Tests build
// [PollinationsImageService] / [FakeAiImageService] directly against an
// in-memory DB + fake http client.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/pollinations_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/platform/pollinations_config.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';

/// Base dir for cached AI images. MUST resolve to the same directory the
/// Kotlin side reads in `addMediaToAnki` (`File(filesDir, relativePath)`) and
/// that the FileProvider exposes (`file_paths.xml`'s `<files-path>`). On
/// Android, `getApplicationSupportDirectory()` == `Context.getFilesDir()`;
/// `getApplicationDocumentsDirectory()` is `getDir("flutter")` = `app_flutter`,
/// a *different* dir — writing there made every `addMedia` return null (file
/// not found) and orphaned the cache. Defined here (not reused from wordlog)
/// so the ai_image feature has no feature→feature wiring dependency.
final aiImageDocsDirProvider = FutureProvider<String>(
  (ref) async => (await getApplicationSupportDirectory()).path,
);

final aiImageCacheRepositoryProvider = FutureProvider<AiImageCacheRepository>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return AiImageCacheRepository(db);
});

/// The live AiImageService backed by Pollinations (keyless free tier). Override
/// in tests / dev with a FakeAiImageService.
final aiImageServiceProvider = FutureProvider<AiImageService>((ref) async {
  final cache = await ref.watch(aiImageCacheRepositoryProvider.future);
  final queue = await ref.watch(queueRepositoryProvider.future);
  final docsDir = await ref.watch(aiImageDocsDirProvider.future);
  return PollinationsImageService(
    cache: cache,
    queue: queue,
    docsDir: Directory(docsDir),
    client: http.Client(),
    logger: ref.watch(appLoggerProvider),
    baseUrl: pollinationsBaseUrl,
    model: pollinationsModel,
    // Read fresh per generate (T19.6): a Settings edit applies on the next
    // drain without re-queueing existing pending items.
    promptTemplate: () => ref.read(appSettingsProvider).aiImagePromptTemplate,
    // Pace successive GETs so a multi-word drain can't burst past the keyless
    // tier's rate limit (only the first word would render otherwise).
    gate: pollinationsRateGate(),
  );
});

/// A read model for the AI-image queue-review screen: pending generation
/// attempts (with their failure history) + the recently generated words.
class AiImageQueueSnapshot {
  const AiImageQueueSnapshot({required this.pending, required this.generated});
  final List<QueueItem> pending;
  final List<AiImageCacheEntry> generated;
}

/// The current queue-review snapshot, kept LIVE (T19.2). Re-fetches whenever
/// the pending set changes — the reactive source of truth from
/// [QueueRepository.pendingChanges]. A row enqueued, drained (markDone), or
/// failed (attempts bumped) emits here, so the UI moves Pending → Generated
/// without a manual refresh and without depending on a drain having fired.
final aiImageQueueSnapshotProvider = StreamProvider<AiImageQueueSnapshot>((
  ref,
) async* {
  final queue = await ref.watch(queueRepositoryProvider.future);
  final cache = await ref.watch(aiImageCacheRepositoryProvider.future);

  Future<AiImageQueueSnapshot> fetch() async {
    final pending = await queue.pendingByType(aiImageQueueType);
    final generated = await cache.recent();
    return AiImageQueueSnapshot(pending: pending, generated: generated);
  }

  // First read renders immediately; subsequent reads are driven by table
  // change — independent of whether a worker drain has run yet.
  yield await fetch();
  await for (final _ in queue.pendingChanges()) {
    yield await fetch();
  }
});

/// Register the `ai_image` queue handler on the shared worker. Call once from
/// app boot, BEFORE [bootOfflineQueue] starts the worker, so the initial drain
/// (if already online) sees the handler. Reads [aiImageServiceProvider], which
/// resolves the DB; awaiting here lets the native splash cover the open.
///
/// [onGenerated] is an optional best-effort hook fired after each image
/// finishes generating. The orchestrator (main.dart) uses it to attach the
/// Type 2 Anki card whose image was missing at export time — closing the gap
/// where the first Export deferred every Type 2 card as pending and nothing
/// re-exported once images landed. The hook MUST NOT throw: it runs inside the
/// queue handler, and a throw would mark the image-generation item failed
/// despite a successful generation. Failures are swallowed + logged here.
Future<void> registerAiImageHandler(
  ProviderContainer container, {
  Future<void> Function(String word)? onGenerated,
}) async {
  final service = await container.read(aiImageServiceProvider.future);
  final worker = await container.read(queueProcessorProvider.future);
  worker.registerHandler(aiImageQueueType, (payload) async {
    final word = wordFromAiImagePayload(payload);
    await service.generateNow(word);
    final hook = onGenerated;
    if (hook == null) return;
    try {
      await hook(word);
    } on Object catch (e) {
      // Image generation (the queue's actual job) succeeded — a downstream
      // card-attach miss must not roll that back or mark the item failed.
      container
          .read(appLoggerProvider)
          .w(LogTag.ai, 'post-generation hook for "$word" skipped: $e');
    }
  });
}
