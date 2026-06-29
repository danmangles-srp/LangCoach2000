// Pure unit tests for the domain snapshot value (T1.5). The derived getters
// (progress / isLoading / isError) are the contract the UI + the upcoming
// "crossed 80%" review-event rule (T2.2) lean on, so they're pinned here.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';

void main() {
  group('PlaybackSnapshot.progress', () {
    test('zero when duration is unknown', () {
      const snapshot = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.ready,
        isPlaying: true,
        isCompleted: false,
        position: Duration(seconds: 5),
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(snapshot.progress, 0);
    });

    test('halfway at the midpoint', () {
      const snapshot = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.ready,
        isPlaying: true,
        isCompleted: false,
        position: Duration(seconds: 30),
        duration: Duration(minutes: 1),
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(snapshot.progress, 0.5);
    });

    test('clamps past-end positions to 1', () {
      const snapshot = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.completed,
        isPlaying: false,
        isCompleted: true,
        position: Duration(minutes: 2),
        duration: Duration(minutes: 1),
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(snapshot.progress, 1);
    });

    test('crosses 0.8 past the GPA completion threshold', () {
      const snapshot = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.ready,
        isPlaying: true,
        isCompleted: false,
        position: Duration(seconds: 81),
        duration: Duration(seconds: 100),
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(snapshot.progress, greaterThan(0.8));
    });
  });

  group('PlaybackSnapshot derived flags', () {
    test('isLoading is true only for loading + buffering', () {
      PlaybackSnapshot build(AudioProcessingState state) => PlaybackSnapshot(
        recordingId: null,
        processingState: state,
        isPlaying: false,
        isCompleted: false,
        position: Duration.zero,
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(build(AudioProcessingState.loading).isLoading, isTrue);
      expect(build(AudioProcessingState.buffering).isLoading, isTrue);
      expect(build(AudioProcessingState.ready).isLoading, isFalse);
    });

    test('isError tracks the error phase', () {
      const idle = PlaybackSnapshot.idle();
      expect(idle.isError, isFalse);
      const errored = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.error,
        isPlaying: false,
        isCompleted: false,
        position: Duration.zero,
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      expect(errored.isError, isTrue);
    });
  });

  test('idle factory seeds a safe default', () {
    const idle = PlaybackSnapshot.idle();
    expect(idle.recordingId, isNull);
    expect(idle.processingState, AudioProcessingState.idle);
    expect(idle.isPlaying, isFalse);
    expect(idle.progress, 0);
  });

  test('copyWith preserves unmentioned fields', () {
    const base = PlaybackSnapshot(
      recordingId: 7,
      processingState: AudioProcessingState.ready,
      isPlaying: false,
      isCompleted: false,
      position: Duration(seconds: 10),
      duration: Duration(seconds: 100),
      bufferedPosition: Duration(seconds: 20),
      speed: 1.5,
    );
    final updated = base.copyWith(position: const Duration(seconds: 50));
    expect(updated.recordingId, 7);
    expect(updated.duration, const Duration(seconds: 100));
    expect(updated.speed, 1.5);
    expect(updated.position, const Duration(seconds: 50));
  });

  test('equality is value-based', () {
    final a = const PlaybackSnapshot.idle().copyWith(recordingId: 1);
    final b = const PlaybackSnapshot.idle().copyWith(recordingId: 1);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
