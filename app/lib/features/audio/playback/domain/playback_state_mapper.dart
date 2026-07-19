// Pure bridge from audio_service's [PlaybackState] into the domain
// [PlaybackSnapshot] (T1.5). Isolates the controller/tests from the framework
// type so the stream-combine + duration-stamping lives in one tested spot.
//
// `duration` is passed in (resolved from the current [MediaItem]) rather than
// read off [PlaybackState] — the OS-side state carries the live transport but
// not the source's known length, which comes from the media-item metadata.

import 'package:audio_service/audio_service.dart';

import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';

PlaybackSnapshot mapPlaybackState(
  PlaybackState state, {
  required int? recordingId,
  required Duration duration,
}) {
  final completed = state.processingState == AudioProcessingState.completed;
  return PlaybackSnapshot(
    recordingId: recordingId,
    processingState: state.processingState,
    // A completed item is never "playing" from the app's view, even if the
    // engine reports `playing=true` on the completed edge — the transport
    // button + togglePlayPause branch on isPlaying first, so without this a
    // completed recording would show pause + pause-on-tap instead of
    // replay-from-top.
    isPlaying: state.playing && !completed,
    isCompleted: completed,
    position: state.updatePosition,
    duration: duration,
    bufferedPosition: state.bufferedPosition,
    speed: state.speed,
  );
}
