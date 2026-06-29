// Riverpod wiring for the review-event feature (T2.2, FR-1.2.3).
//
// [reviewEventRepositoryProvider] wraps the Drift store. The watcher is an
// always-on listener (kept alive by the app shell) that turns an 80%-
// crossing in the playback controller into a `recordReview` append via the
// [ReviewProgressGate] latch. The auto path lives here; the manual correction
// surface (markReviewed / deleteEvent) is driven from the UI in T2.6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/gpa/domain/review_progress_gate.dart';

/// Singleton [ReviewEventRepository] over the local store.
final reviewEventRepositoryProvider = FutureProvider<ReviewEventRepository>(
  (ref) async =>
      ReviewEventRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Monotonic bump that invalidates anything derived from the review-event log.
/// The 80% watcher bumps it after a successful auto-append; the manual
/// correction surface (T2.6) bumps after mark / un-review. Consumers watch this
/// alongside the repository so the today-queue + per-recording status refresh
/// without polling or a full Drift stream rebuild.
class ReviewGeneration extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final reviewGenerationProvider = NotifierProvider<ReviewGeneration, int>(
  ReviewGeneration.new,
);

/// Always-on listener that appends a review event when playback crosses 80%
/// (FR-1.2.3). The latch ([ReviewProgressGate]) guarantees one append per
/// upward crossing per recording. Watched once by the app shell so it survives
/// for the app's lifetime and keeps observing background playback.
final reviewProgressWatcherProvider = Provider<void>((ref) {
  final gate = ReviewProgressGate();
  ref.listen(audioPlayerControllerProvider, (_, snap) async {
    if (!gate.evaluate(snap)) return;
    final recordingId = snap.recordingId;
    if (recordingId == null) return;
    try {
      final repo = await ref.read(reviewEventRepositoryProvider.future);
      await repo.recordReview(recordingId, completedAt: DateTime.now());
      // A real append changes the queue; bump so live consumers refresh.
      ref.read(reviewGenerationProvider.notifier).bump();
    } on Object catch (e, st) {
      // A failed append must never break playback — log and swallow.
      ref.read(appLoggerProvider).e(LogTag.db, 'review append failed: $e\n$st');
    }
  });
});

/// Today's review queue (FR-1.2.5): recordings due today or 1-day-stale, most-
/// overdue first. `asOf` is now. Watched by the home/queue screen (T2.5).
/// Rebuilds when the review log changes ([reviewGenerationProvider]).
final todayQueueProvider = FutureProvider<List<QueueItem>>((ref) async {
  ref.watch(reviewGenerationProvider);
  final repo = await ref.watch(reviewEventRepositoryProvider.future);
  return repo.todayQueue(asOf: DateTime.now());
});
