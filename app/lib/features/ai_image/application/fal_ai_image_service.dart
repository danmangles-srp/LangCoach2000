// Fal.ai implementation of [AiImageService] (T4.3, FR-1.3.4, NFR-2.1.3).
//
// Style is locked to "language-neutral pictographic" — see
// [buildPictographPrompt]. Provider/model: fal-ai/flux/schnell (fast + cheap,
// and we explicitly forbid text in the image, so schnell's weaker text
// rendering is a non-issue). The API key is read fresh per generation via
// [readApiKey] (resolved from the SQLCipher KV store by the provider wiring);
// it never lives in the repo and a Settings change takes effect on the next
// drain without re-queueing pending items.
//
// The HTTP client + endpoint are constructor-injected so the request/response
// contract is unit-testable with a fake client — no network in tests.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

class FalAiImageService implements AiImageService {
  FalAiImageService({
    required this.cache,
    required this.queue,
    required this.docsDir,
    required this.readApiKey,
    required this.client,
    required this.logger,
    required this.baseUrl,
    required this.modelId,
  });

  final AiImageCacheRepository cache;
  final QueueRepository queue;
  final Directory docsDir;
  final Future<String> Function() readApiKey;
  final http.Client client;
  final AppLogger logger;
  final String baseUrl;
  final String modelId;

  @override
  Future<String?> cachedPath(String uzbekWord) => cache.pathFor(uzbekWord);

  @override
  Future<void> enqueueGeneration(String uzbekWord) async {
    // Already generated — nothing to do, ever, for this word.
    if (await cache.has(uzbekWord)) return;
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbekWord),
    );
    logger.i(LogTag.ai, 'enqueued image for "$uzbekWord"');
  }

  @override
  Future<void> generateNow(String uzbekWord) async {
    final word = uzbekWord.trim();
    if (await cache.has(word)) return;

    final apiKey = await readApiKey();
    if (apiKey.isEmpty) {
      // No key configured — the worker will mark this failed and retry on the
      // next reconnect, which won't help until a key is supplied in Settings.
      // That retry storm is bounded by queue-hardening (dead-letter after N
      // attempts, follow-up #16).
      throw StateError(
        'Fal.ai API key not configured; set it in Settings to generate '
        'image for "$word"',
      );
    }

    final imageUrl = await _requestImageUrl(word, apiKey);
    final bytes = await _download(imageUrl);
    final relativePath = buildAiImagePath(word);
    await _writeBytes(relativePath, bytes);
    await cache.remember(uzbekWord: word, relativePath: relativePath);
    logger.i(LogTag.ai, 'generated image for "$word" -> $relativePath');
  }

  Future<String> _requestImageUrl(String word, String apiKey) async {
    final response = await client.post(
      Uri.parse('$baseUrl/$modelId'),
      headers: {
        'Authorization': 'Key $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': buildPictographPrompt(word),
        'image_size': 'square_hd',
        'num_images': 1,
        'num_inference_steps': 4,
      }),
    );
    if (response.statusCode != 200) {
      throw HttpException(
        'fal.ai $modelId returned ${response.statusCode}: ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('fal.ai response not a JSON object');
    }
    final images = decoded['images'];
    if (images is! List || images.isEmpty) {
      throw const FormatException('fal.ai response has no images[]');
    }
    final first = images.first;
    if (first is! Map<String, Object?>) {
      throw const FormatException('fal.ai images[0] not a JSON object');
    }
    final url = first['url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('fal.ai images[0].url missing');
    }
    return url;
  }

  Future<List<int>> _download(String url) async {
    final response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw HttpException(
        'image download $url returned ${response.statusCode}',
      );
    }
    return response.bodyBytes;
  }

  Future<void> _writeBytes(String relativePath, List<int> bytes) async {
    final file = File('${docsDir.path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }
}
