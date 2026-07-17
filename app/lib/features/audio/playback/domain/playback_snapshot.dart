// Domain snapshot of the audio player's transport state, surfaced to the UI
// via the Riverpod controller (T1.5). Mirrors the bits of audio_service's
// [PlaybackState] the app actually consumes — normalized into a single value
// the widget tree can read without re-subscribing to two streams.
//
// Plain immutable (no freezed): the codebase hand-rolls small value types, and
// dragging codegen in for one class isn't worth the generated-file churn.

import 'package:audio_service/audio_service.dart';
import 'package:meta/meta.dart';

@immutable
class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.recordingId,
    required this.processingState,
    required this.isPlaying,
    required this.isCompleted,
    required this.position,
    required this.duration,
    required this.bufferedPosition,
    required this.speed,
  });

  const PlaybackSnapshot.idle()
    : recordingId = null,
      processingState = AudioProcessingState.idle,
      isPlaying = false,
      isCompleted = false,
      position = Duration.zero,
      duration = Duration.zero,
      bufferedPosition = Duration.zero,
      speed = 1.0;

  /// The id of the recording currently loaded, or `null` when nothing is
  /// cued. Tracked by the controller from the media-item stream (the OS-facing
  /// id is the file URI; this is the row id the rest of the app keys on).
  final int? recordingId;

  /// Low-level transport phase from audio_service (idle/loading/buffering/
  /// ready/completed/error). Surfaced as-is rather than re-enum'd so the UI
  /// can branch on the framework's own states — including `error`, which is
  /// how the engine signals a failed source-load.
  final AudioProcessingState processingState;

  /// `true` while audio is playing, or will as soon as buffering completes
  /// (audio_service's `playing` semantics — drives the play/pause button).
  final bool isPlaying;

  /// `true` once the current item has finished (drives the replay affordance).
  final bool isCompleted;

  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double speed;

  /// Loading or buffering — the spinner state.
  bool get isLoading =>
      processingState == AudioProcessingState.loading ||
      processingState == AudioProcessingState.buffering;

  /// `true` when the engine hit a non-recoverable error this item.
  bool get isError => processingState == AudioProcessingState.error;

  /// Normalized playback progress in `[0, 1]` for the seek slider. Also the
  /// basis for the "crossed 80% -> append review event" rule (FR-1.2.3, T2.2);
  /// guard against a zero duration (unknown-length source) returning NaN.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    final clamped = position.inMilliseconds.clamp(0, total);
    return clamped / total;
  }

  PlaybackSnapshot copyWith({
    int? recordingId,
    AudioProcessingState? processingState,
    bool? isPlaying,
    bool? isCompleted,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? speed,
  }) {
    return PlaybackSnapshot(
      recordingId: recordingId ?? this.recordingId,
      processingState: processingState ?? this.processingState,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      speed: speed ?? this.speed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackSnapshot &&
          other.recordingId == recordingId &&
          other.processingState == processingState &&
          other.isPlaying == isPlaying &&
          other.isCompleted == isCompleted &&
          other.position == position &&
          other.duration == duration &&
          other.bufferedPosition == bufferedPosition &&
          other.speed == speed;

  @override
  int get hashCode => Object.hash(
    recordingId,
    processingState,
    isPlaying,
    isCompleted,
    position,
    duration,
    bufferedPosition,
    speed,
  );
}
