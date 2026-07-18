// Pollinations implementation of [AiImageService] (FR-1.3.4, NFR-2.1.3).
//
// Style is locked to "language-neutral pictographic" — the no-text/no-letters
// guard in [defaultAiImagePrompt] is load-bearing. Pollinations generates
// directly from a prompt encoded in the GET path, so a single GET returns the
// image bytes — no auth, no JSON, no separate download hop. A deterministic
// per-word seed (fold of the code units) keeps a regenerated word reproducible.
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

/// Paces Pollinations GETs so a tight drain loop over N queued words doesn't
/// trip the keyless tier's rate limiter. Without it, the first GET succeeds and
/// every rapid successor 429s — so only the first image in a multi-word batch
/// ever generated. Injected into [PollinationsImageService.gate]; pass a no-op
/// in tests.
typedef AiImageRequestGate = Future<void> Function();

/// A gate enforcing a minimum gap between successive calls. The keyless tier
/// recovers from a single request but rejects a burst; ~1.2s clears the common
/// 429 storm during a foreground drain of a multi-pair word log.
AiImageRequestGate pollinationsRateGate({
  Duration gap = const Duration(milliseconds: 1200),
}) {
  var last = DateTime.fromMillisecondsSinceEpoch(0);
  return () async {
    final wait = gap - DateTime.now().difference(last);
    if (!wait.isNegative) {
      await Future<void>.delayed(wait);
    }
    last = DateTime.now();
  };
}

class PollinationsImageService implements AiImageService {
  PollinationsImageService({
    required this.cache,
    required this.queue,
    required this.docsDir,
    required this.client,
    required this.logger,
    required this.baseUrl,
    required this.model,
    required this.gate,
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

  /// Invoked before each network GET to enforce the rate-limit gap. The drain
  /// loop dispatches one [generateNow] per queued word back-to-back; without a
  /// gate, the burst 429s and only the first word renders.
  final AiImageRequestGate gate;

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
  Future<void> enqueueGeneration({
    required String uzbek,
    required String english,
  }) async {
    // Already generated — nothing to do for this word.
    if (await cachedPath(uzbek) != null) return;
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbek: uzbek, english: english),
    );
    logger.i(LogTag.ai, 'enqueued image for "$uzbek" (prompt "$english")');
  }

  @override
  Future<void> generateNow({
    required String uzbek,
    required String english,
  }) async {
    // Cache + on-disk path are keyed by UZBEK — the Anki card first field +
    // the regeneration seed all hang off it. The prompt runs on ENGLISH.
    final key = uzbek.trim();
    if (await cachedPath(key) != null) return;

    // Pace before the GET so a tight drain loop over N queued words can't
    // burst past the keyless tier's rate limit. Cached no-ops skip the gate.
    await gate();
    final bytes = await _downloadWithRetry(
      _buildUrl(uzbek: key, english: english),
    );
    final relativePath = buildAiImagePath(key);
    await _writeBytes(relativePath, bytes);
    await cache.remember(uzbekWord: key, relativePath: relativePath);
    logger.i(
      LogTag.ai,
      'generated image for "$key" (prompt "$english") -> $relativePath',
    );
  }

  String _buildUrl({required String uzbek, required String english}) {
    // Prompt runs on the ENGLISH gloss (T19.3); the user-tunable template
    // wraps it (T19.6). Seed stays keyed by UZBEK so the card's image is
    // reproducible across regenerations of the same word.
    final prompt = Uri.encodeComponent(
      buildAiImagePrompt(english, promptTemplate()),
    );
    final seed = _stableSeed(uzbek);
    return '$baseUrl/prompt/$prompt'
        '?width=512&height=512&nologo=true&model=$model&seed=$seed';
  }

  /// Stable, run-to-run hash of [word] so the same word yields the same seed
  /// (and thus the same image on regeneration). 31× fold keeps it within a
  /// signed-31-bit range Pollinations accepts as a seed.
  int _stableSeed(String word) =>
      word.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);

  /// Download with bounded retries on a transient failure (T18.5). The keyless
  /// Pollinations tier regularly returns 429/5xx at network handovers and
  /// throws socket/timeout on a half-open radio. A single 500ms retry wasn't
  /// enough for the free tier's cool-down during a multi-word drain: the second
  /// attempt 429'd too and the whole batch (minus the first word)
  /// dead-lettered.
  /// Three attempts with growing backoff (800ms, 1.6s) lets the tier recover
  /// before the queue-level backoff takes over for repeated failures.
  Future<List<int>> _downloadWithRetry(String url) async {
    const backoff = [Duration(milliseconds: 800), Duration(milliseconds: 1600)];
    for (var attempt = 0; attempt <= backoff.length; attempt++) {
      try {
        return await _download(url);
      } on Object catch (e) {
        if (attempt == backoff.length || !_isTransient(e)) rethrow;
        await Future<void>.delayed(backoff[attempt]);
      }
    }
    // Unreachable: the loop either returns or rethrows on the final attempt.
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
