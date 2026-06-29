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
    } on Object catch (e, st) {
      // A failed append must never break playback — log and swallow.
      ref.read(appLoggerProvider).e(LogTag.db, 'review append failed: $e\n$st');
    }
  });
});
