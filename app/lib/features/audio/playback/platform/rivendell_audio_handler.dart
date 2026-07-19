// The background media-session handler (T1.5, FR-1.1.4). audio_service owns
// the OS contract — lock-screen controls, the media notification, audio-focus
// handling (pause / duck on incoming call per Android norms). just_audio is
// the engine: decode, seek, position.
//
// The handler bridges the engine's event stream into the session by reissuing
// a PlaybackState on every playback event — that single broadcast is what both
// the notification and the in-app controller consume.

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/playback/domain/media_item_mapper.dart';

class RivendellAudioHandler extends BaseAudioHandler with SeekHandler {
  RivendellAudioHandler({required this._logger}) {
    // just_audio's default Android audio attributes request the media / music
    // focus layer, which is what makes Android duck for transient losses (a
    // phone call) and pause on a permanent one — so no explicit attributes are
    // set here.
    _player.playbackEventStream.listen(
      _broadcast,
      onError: (Object e, StackTrace st) {
        _logger.e(LogTag.audio, 'playback error: $e\n$st');
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            controls: [MediaControl.play, MediaControl.stop],
          ),
        );
      },
    );
    // The media item is seeded from the stored durationMs (often null — the
    // indexer reads filesystem metadata only), while just_audio resolves the
    // real length after setAudioSource. Surface it back onto the media item so
    // the in-app seek bar (T1.6) + the OS media UI can show progress; without
    // this the bar would stay empty for the typical recording.
    _player.durationStream.listen(_onDurationResolved);
    // Periodic position tick -> re-broadcast. just_audio's playbackEventStream
    // fires only on discrete state changes (play / pause / seek / complete), so
    // without this the in-app seek bar (T1.6) would freeze during continuous
    // playback and the 80%-review watcher (T2.2, FR-1.2.3) would never see
    // progress cross the threshold. positionStream is the Timer-driven source
    // (~5-8Hz for typical clip lengths); _broadcast re-reads _player.position
    // each tick, so no payload is needed.
    _player.positionStream.listen((_) => _broadcast());
  }

  final AudioPlayer _player = AudioPlayer();
  final AppLogger _logger;

  int? _currentRecordingId;

  /// Row id of the cued recording; surfaced to the controller via the service.
  int? get currentRecordingId => _currentRecordingId;

  /// Cue a recording without starting playback. Sets the media item first so
  /// the notification updates immediately, then attaches the source. A failed
  /// load surfaces as [AudioProcessingState.error] via the stream's error path.
  Future<void> loadRecording(Recording recording) async {
    _currentRecordingId = recording.id;
    mediaItem.add(mediaItemFromRecording(recording));
    _logger.i(LogTag.audio, 'cued ${recording.name}');
    // setAudioSource returns the source's resolved duration; patch it onto the
    // media item immediately rather than waiting on durationStream. On
    // auto-advance the engine swaps sources straight out of a `completed`
    // state and the async durationStream can race or drop, leaving the new
    // recording stuck at 0:00. `_player.duration` is authoritative here.
    final resolved = await _player.setAudioSource(
      AudioSource.uri(Uri.parse(recording.filePath)),
    );
    final seeded = mediaItem.value;
    if (resolved != null && seeded != null && seeded.duration != resolved) {
      mediaItem.add(seeded.copyWith(duration: resolved));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentRecordingId = null;
    await super.stop();
  }

  /// Patch the resolved duration onto the current media item, once. Re-emits
  /// the item so the controller (and thus the seek bar) pick up the length the
  /// engine discovered. No-op if there's no item or it already carries one.
  void _onDurationResolved(Duration? duration) {
    if (duration == null) return;
    final current = mediaItem.value;
    if (current == null || current.duration != null) return;
    mediaItem.add(current.copyWith(duration: duration));
  }

  /// Re-broadcast the engine's current transport as a session PlaybackState.
  // The per-state control set + compact indices are what the system media UI
  // renders; `playing` flips the primary affordance between play and pause.
  // The event arg is ignored — the engine's current state is read fresh off
  // [_player] each call — so callers from both the event stream and the
  // position tick can pass nothing.
  void _broadcast([PlaybackEvent? _]) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
