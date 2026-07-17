// reviewProgressWatcherProvider — FR-1.2.3 append-retry (T15.4).
// A failing append must not silently lose the review: the watcher rearms the
// latch and retries on the next >=80% snapshot up to a cap, then ticks a
// failure signal the UI surfaces. Drives the real Riverpod wiring over a
// memory Drift store + a controllable audio notifier; no device.

import 'package:audio_service/audio_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';

PlaybackSnapshot _at80({required int recordingId, int positionMs = 80_000}) {
  return PlaybackSnapshot(
    recordingId: recordingId,
    processingState: AudioProcessingState.ready,
    isPlaying: true,
    isCompleted: false,
    position: Duration(milliseconds: positionMs),
    duration: const Duration(milliseconds: 100_000),
    bufferedPosition: Duration.zero,
    speed: 1,
  );
}

class _ControllableAudio extends AudioPlayerController {
  @override
  PlaybackSnapshot build() => const PlaybackSnapshot.idle();

  /// Push [snap] as the controller's current state so the watcher's listen
  /// fires. A method (not a setter) because `avoid_setters_without_getters`
  /// and `use_setters_to_change_properties` conflict for a test-only knob —
  /// the assignment IS the point.
  // ignore: use_setters_to_change_properties
  void emit(PlaybackSnapshot snap) {
    state = snap;
  }
}

/// Repo whose [recordReview] always fails — drives the retry path.
class _ThrowingRepo extends ReviewEventRepository {
  _ThrowingRepo(super.db);

  int recordCalls = 0;

  @override
  Future<void> recordReview(
    int recordingId, {
    required DateTime completedAt,
  }) async {
    recordCalls++;
    throw StateError('append boom');
  }
}

/// Repo whose [recordReview] always succeeds — no Drift transaction, so the
/// success path is deterministic without depending on real query timing.
class _SuccessRepo extends ReviewEventRepository {
  _SuccessRepo(super.db);

  int recordCalls = 0;

  @override
  Future<void> recordReview(
    int recordingId, {
    required DateTime completedAt,
  }) async {
    recordCalls++;
  }
}

/// Flush the microtask chain deep enough for the async listener to settle
/// between emits: repo-future read + recordReview await + catch/rearm/tick.
Future<void> _pump() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.microtask(() {});
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  ProviderContainer buildContainer(ReviewEventRepository repo) {
    final c = ProviderContainer(
      overrides: [
        reviewEventRepositoryProvider.overrideWith((ref) async => repo),
        audioPlayerControllerProvider.overrideWith(_ControllableAudio.new),
      ],
    );
    // Build the watcher so its listen attaches.
    return c..read(reviewProgressWatcherProvider);
  }

  _ControllableAudio controllerOf(ProviderContainer c) =>
      c.read(audioPlayerControllerProvider.notifier) as _ControllableAudio;

  group('append retry (T15.4)', () {
    test(
      'retries a failing append up to the cap, then ticks + stops retrying',
      () async {
        final repo = _ThrowingRepo(db);
        final c = buildContainer(repo);
        addTearDown(c.dispose);
        final audio = controllerOf(c);
        await _pump();

        // Four distinct >=80% snapshots for the same recording. The first three
        // each fire (rearm keeps the latch live while still >=80%); after the
        // cap the latch is left consumed, so the fourth never calls
        // recordReview.
        audio.emit(_at80(recordingId: 7));
        await _pump();
        audio.emit(_at80(recordingId: 7, positionMs: 85_000));
        await _pump();
        audio.emit(_at80(recordingId: 7, positionMs: 90_000));
        await _pump();
        audio.emit(_at80(recordingId: 7, positionMs: 95_000));
        await _pump();

        expect(repo.recordCalls, 3);
        expect(c.read(reviewSaveFailureTickProvider), 1);
      },
    );

    test('a non-throwing append never ticks the failure signal', () async {
      // Success repo: recordReview resolves cleanly. No rearm, no tick, and
      // the latch stays consumed so a second >=80% snapshot doesn't call it
      // again.
      final repo = _SuccessRepo(db);
      final c = buildContainer(repo);
      addTearDown(c.dispose);
      final audio = controllerOf(c);
      await _pump();

      audio.emit(_at80(recordingId: 7));
      await _pump();
      audio.emit(_at80(recordingId: 7, positionMs: 85_000));
      await _pump();

      expect(repo.recordCalls, 1);
      expect(c.read(reviewSaveFailureTickProvider), 0);
    });

    test('a new recording after a terminal failure fires again', () async {
      // After the cap gives up on recording 7, the latch is consumed for 7.
      // A different recording crosses 80% — that's a fresh latch and a fresh
      // retry budget.
      final repo = _ThrowingRepo(db);
      final c = buildContainer(repo);
      addTearDown(c.dispose);
      final audio = controllerOf(c);
      await _pump();

      // Burn recording 7's retry budget.
      audio.emit(_at80(recordingId: 7));
      await _pump();
      audio.emit(_at80(recordingId: 7, positionMs: 85_000));
      await _pump();
      audio.emit(_at80(recordingId: 7, positionMs: 90_000));
      await _pump();
      expect(repo.recordCalls, 3);
      expect(c.read(reviewSaveFailureTickProvider), 1);

      // Recording 8 crosses — fresh budget, three more attempts, one more tick.
      audio.emit(_at80(recordingId: 8));
      await _pump();
      audio.emit(_at80(recordingId: 8, positionMs: 85_000));
      await _pump();
      audio.emit(_at80(recordingId: 8, positionMs: 90_000));
      await _pump();
      expect(repo.recordCalls, 6);
      expect(c.read(reviewSaveFailureTickProvider), 2);
    });
  });
}
