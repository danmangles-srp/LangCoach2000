// AI concept-image service seam (T4.3, FR-1.3.4, NFR-2.1.3). Abstract so the
// pipeline — enqueue when offline, drain on reconnect, render a placeholder
// while pending — is unit-testable against a fake, and the Fal.ai HTTP impl is
// the only part that touches the network.
//
// Per-word caching (FR-1.3.4 "generated at most once"): every method is a
// no-op once a word's image exists, so re-saving a word log, re-enqueuing, or a
// duplicate drain never pays for a second render of the same word.

/// The offline queue `type` for AI image generation. The QueueWorker handler
/// registered under this key decodes a JSON `{"word": "..."}` payload and calls
/// [AiImageService.generateNow].
const aiImageQueueType = 'ai_image';

abstract class AiImageService {
  /// The app-relative path of the cached image for [uzbekWord], or null when it
  /// has not been generated yet. UI renders a placeholder while this is null.
  Future<String?> cachedPath(String uzbekWord);

  /// Ensure an image will be generated for [uzbekWord]. Idempotent: a no-op
  /// when the image is already cached. Otherwise enqueues an [aiImageQueueType]
  /// work item; the offline queue drains it on reconnect (NFR-2.1.3). Safe to
  /// call
  /// offline — enqueue never blocks on the network.
  Future<void> enqueueGeneration(String uzbekWord);

  /// Generate the image now (the queue-handler body). No-op if cached. Throws
  /// on any network / I/O / auth failure so the worker records the attempt and
  /// retries on the next reconnect.
  Future<void> generateNow(String uzbekWord);
}
