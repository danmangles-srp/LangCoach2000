// coverage:ignore-file — production Riverpod wiring (http + path_provider +
// env), excluded from the coverage floor. Tests build [FalAiImageService] /
// [FakeAiImageService] directly against an in-memory DB + fake http client.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/core/queue/platform/queue_providers.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/fal_ai_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/platform/fal_ai_config.dart';

/// App-documents path for cached AI images. Defined here (not reused from
/// wordlog) so the ai_image feature has no feature→feature wiring dependency;
/// getApplicationDocumentsDirectory is idempotent so a second call is free.
final aiImageDocsDirProvider = FutureProvider<String>(
  (ref) async => (await getApplicationDocumentsDirectory()).path,
);

final aiImageCacheRepositoryProvider = FutureProvider<AiImageCacheRepository>((
  ref,
) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return AiImageCacheRepository(db);
});

/// The live AiImageService backed by Fal.ai. Override in tests / dev with a
/// FakeAiImageService.
final aiImageServiceProvider = FutureProvider<AiImageService>((ref) async {
  final cache = await ref.watch(aiImageCacheRepositoryProvider.future);
  final queue = await ref.watch(queueRepositoryProvider.future);
  final docsDir = await ref.watch(aiImageDocsDirProvider.future);
  return FalAiImageService(
    cache: cache,
    queue: queue,
    docsDir: Directory(docsDir),
    apiKey: falApiKey,
    client: http.Client(),
    logger: ref.watch(appLoggerProvider),
    baseUrl: falBaseUrl,
    modelId: falModelId,
  );
});

/// Register the `ai_image` queue handler on the shared worker. Call once from
/// app boot, BEFORE [bootOfflineQueue] starts the worker, so the initial drain
/// (if already online) sees the handler. Reads [aiImageServiceProvider], which
/// resolves the DB; awaiting here lets the native splash cover the open.
Future<void> registerAiImageHandler(ProviderContainer container) async {
  final service = await container.read(aiImageServiceProvider.future);
  final worker = await container.read(queueProcessorProvider.future);
  worker.registerHandler(aiImageQueueType, (payload) async {
    await service.generateNow(wordFromAiImagePayload(payload));
  });
}
