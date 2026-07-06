// In-memory [AiImageService] for tests and offline UI scaffolding (T4.3). No
// network, no files: a successful `generateNow` just records a synthetic path
// in the cache map, so queue-worker tests can drive the drain → cache-fill
// contract without a Fal.ai round-trip.

import 'package:rivendell/features/ai_image/application/ai_image_service.dart';

class FakeAiImageService implements AiImageService {
  FakeAiImageService({this.generateDelay = Duration.zero});

  final Duration generateDelay;

  /// Words whose `generateNow` has been called, in call order.
  final List<String> generated = <String>[];

  /// Words whose `enqueueGeneration` has been called, in call order.
  final List<String> enqueued = <String>[];

  /// The in-memory cache: word → synthetic relative path.
  final Map<String, String> _cache = {};

  @override
  Future<String?> cachedPath(String uzbekWord) async => _cache[uzbekWord];

  @override
  Future<void> enqueueGeneration(String uzbekWord) async {
    enqueued.add(uzbekWord);
  }

  @override
  Future<void> generateNow(String uzbekWord) async {
    // Honor the same per-word idempotency contract as FalAiImageService: once
    // generated, a second drain of the same word is a no-op.
    if (_cache.containsKey(uzbekWord)) return;
    if (generateDelay > Duration.zero) {
      await Future<void>.delayed(generateDelay);
    }
    generated.add(uzbekWord);
    _cache[uzbekWord] = 'ai_images/fake_$uzbekWord.png';
  }
}
