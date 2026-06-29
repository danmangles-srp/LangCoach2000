// Pure mapper test (T1.5). Pins the bridge from audio_service's PlaybackState
// into the domain snapshot, including duration passthrough (resolved from the
// media item, not the transport) and the completed-phase derivation.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/playback/domain/playback_state_mapper.dart';

PlaybackState transport({
  AudioProcessingState phase = AudioProcessingState.ready,
  bool playing = true,
  Duration position = Duration.zero,
  Duration buffered = Duration.zero,
}) {
  return PlaybackState(
    processingState: phase,
    playing: playing,
  ).copyWith(updatePosition: position, bufferedPosition: buffered);
}

void main() {
  test('maps a ready + playing transport to a playing snapshot', () {
    final snapshot = mapPlaybackState(
      transport(),
      recordingId: 5,
      duration: const Duration(seconds: 100),
    );
    expect(snapshot.recordingId, 5);
    expect(snapshot.isPlaying, isTrue);
    expect(snapshot.isCompleted, isFalse);
    expect(snapshot.duration, const Duration(seconds: 100));
  });

  test('derives isCompleted from the completed phase, not playing', () {
    final snapshot = mapPlaybackState(
      transport(phase: AudioProcessingState.completed, playing: false),
      recordingId: 5,
      duration: const Duration(seconds: 100),
    );
    expect(snapshot.isCompleted, isTrue);
    expect(snapshot.isPlaying, isFalse);
  });

  test('carries position + buffered through verbatim', () {
    final snapshot = mapPlaybackState(
      transport(
        position: const Duration(seconds: 42),
        buffered: const Duration(seconds: 60),
      ),
      recordingId: 1,
      duration: const Duration(seconds: 100),
    );
    expect(snapshot.position, const Duration(seconds: 42));
    expect(snapshot.bufferedPosition, const Duration(seconds: 60));
    expect(snapshot.progress, closeTo(0.42, 0.001));
  });
}
