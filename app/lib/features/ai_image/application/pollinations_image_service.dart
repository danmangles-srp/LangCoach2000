// Pollinations implementation of [AiImageService] (FR-1.3.4, NFR-2.1.3).
//
// Style is locked to "language-neutral pictographic" — see
// [buildPictographPrompt]. Pollinations generates directly from a prompt
// encoded in the GET path, so a single GET returns the image bytes — no auth,
// no JSON, no separate download hop. A deterministic per-word seed (fold of the
// code units) keeps a regenerated word reproducible.
//
// The HTTP client + endpoint are constructor-injected so the request/response
// contract is unit-testable with a fake client — no network in tests.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

class PollinationsImageService implements AiImageService {
  PollinationsImageService({
    required this.cache,
    required this.queue,
    required this.docsDir,
    required this.client,
    required this.logger,
    required this.baseUrl,
    required this.model,
    String Function()? promptTemplate,
  }) : promptTemplate = promptTemplate ?? (() => defaultAiImagePrompt);

  final AiImageCacheRepository cache;
  final QueueRepository queue;
  final Directory docsDir;
  final http.Client client;
  final AppLogger logger;
  final String baseUrl;
  final String model;

  /// Reads the current prompt template (T19.6). Read fresh per generate so a
  /// Settings change takes effect on the next drain without re-queueing.
  final String Function() promptTemplate;

  @override
  Future<String?> cachedPath(String uzbekWord) async {
    // A cache row is necessary but not sufficient — verify the bytes are on
    // disk. A row whose file is missing (e.g. after the app_flutter → filesDir
    // path fix, or any future cache/file drift) is treated as uncached so the
    // word regenerates instead of pinning a missing file.
    final relative = await cache.pathFor(uzbekWord);
    if (relative == null) return null;
    if (!File('${docsDir.path}/$relative').existsSync()) return null;
    return relative;
  }

  @override
  Future<void> enqueueGeneration(String uzbekWord) async {
    // Already generated — nothing to do for this word.
    if (await cachedPath(uzbekWord) != null) return;
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbekWord),
    );
    logger.i(LogTag.ai, 'enqueued image for "$uzbekWord"');
  }

  @override
  Future<void> generateNow(String uzbekWord) async {
    final word = uzbekWord.trim();
    if (await cachedPath(word) != null) return;

    final bytes = await _downloadWithRetry(_buildUrl(word));
    final relativePath = buildAiImagePath(word);
    await _writeBytes(relativePath, bytes);
    await cache.remember(uzbekWord: word, relativePath: relativePath);
    logger.i(LogTag.ai, 'generated image for "$word" -> $relativePath');
  }

  String _buildUrl(String word) {
    final prompt = Uri.encodeComponent(
      buildAiImagePrompt(word, promptTemplate()),
    );
    final seed = _stableSeed(word);
    return '$baseUrl/prompt/$prompt'
        '?width=512&height=512&nologo=true&model=$model&seed=$seed';
  }

  /// Stable, run-to-run hash of [word] so the same word yields the same seed
  /// (and thus the same image on regeneration). 31× fold keeps it within a
  /// signed-31-bit range Pollinations accepts as a seed.
  int _stableSeed(String word) =>
      word.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);

  /// Download with a single immediate retry on a transient failure (T18.5).
  /// The keyless Pollinations tier regularly returns 429/5xx at network
  /// handovers and throws socket/timeout on a half-open radio; retrying once
  /// in-handler clears the common blip without surfacing a failure (and the
  /// queue-level backoff still covers repeated failures).
  Future<List<int>> _downloadWithRetry(String url) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _download(url);
      } on Object catch (e) {
        if (attempt == 1 || !_isTransient(e)) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    // Unreachable: the loop either returns or rethrows on attempt 1.
    throw StateError('download retry loop exhausted without a result');
  }

  /// A transient failure is one where the request never produced a durable
  /// image: a flaky radio (socket/timeout/DNS), or a server-side hiccup the
  /// free tier recovers from (429, 5xx). A 404/401/400 is permanent — retrying
  /// would just waste the round trip.
  bool _isTransient(Object e) {
    if (e is SocketException || e is TimeoutException) return true;
    if (e is HttpException) {
      final m = e.message;
      // _download formats non-200s as "... returned <status>: ...".
      final match = RegExp(r'returned (\d{3})').firstMatch(m);
      final status = match == null ? null : int.tryParse(match.group(1)!);
      if (status == null) return false;
      return status == 408 || status == 429 || (status >= 500 && status < 600);
    }
    return false;
  }

  Future<List<int>> _download(String url) async {
    final response = await client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      // Trim the body: a 5xx from a CDN carries a full HTML page that bloats
      // lastError + logs. The status is the actionable part.
      final body = response.body;
      final snippet = body.length > 120 ? '${body.substring(0, 120)}…' : body;
      throw HttpException(
        'pollinations $model returned ${response.statusCode}: $snippet',
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
