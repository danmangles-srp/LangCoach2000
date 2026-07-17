// In-memory [AiImageService] for tests and offline UI scaffolding (T4.3). No
// network, no files: a successful `generateNow` just records a synthetic path
// in the cache map, so queue-worker tests can drive the drain → cache-fill
// contract without a Pollinations round-trip.

import 'package:rivendell/features/ai_image/application/ai_image_service.dart';

/// A recorded (uzbek, english) pair — the fake remembers the english it was
/// asked to prompt so tests can assert "the prompt used English, not Uzbek"
/// (T19.3).
typedef RecordedAiWord = ({String uzbek, String english});

class FakeAiImageService implements AiImageService {
  FakeAiImageService({this.generateDelay = Duration.zero});

  final Duration generateDelay;

  /// Pairs whose `generateNow` has been called, in call order.
  final List<RecordedAiWord> generated = <RecordedAiWord>[];

  /// Pairs whose `enqueueGeneration` has been called, in call order.
  final List<RecordedAiWord> enqueued = <RecordedAiWord>[];

  /// The in-memory cache: uzbek → synthetic relative path.
  final Map<String, String> _cache = {};

  @override
  Future<String?> cachedPath(String uzbekWord) async => _cache[uzbekWord];

  @override
  Future<void> enqueueGeneration({
    required String uzbek,
    required String english,
  }) async {
    enqueued.add((uzbek: uzbek, english: english));
  }

  @override
  Future<void> generateNow({
    required String uzbek,
    required String english,
  }) async {
    // Honor the same per-word idempotency contract as
    // PollinationsImageService: once generated, a second drain of the same
    // uzbek is a no-op.
    if (_cache.containsKey(uzbek)) return;
    if (generateDelay > Duration.zero) {
      await Future<void>.delayed(generateDelay);
    }
    generated.add((uzbek: uzbek, english: english));
    _cache[uzbek] = 'ai_images/fake_$uzbek.png';
  }
}
