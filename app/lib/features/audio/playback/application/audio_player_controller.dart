// Riverpod controller that turns the platform playback service into a single
// domain [PlaybackSnapshot] the UI can read (T1.5, FR-1.1.4). Combines the
// service's two streams (transport + media item) into one value, tracking the
// current recording's id + duration so the snapshot is self-describing.
//
// Depends on the abstract [AudioPlaybackService] — faked in tests, real engine
// on Android — so the stream-combine logic is provable without a device.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/audio/playback/domain/playback_state_mapper.dart';
import 'package:rivendell/features/audio/playback/platform/audio_playback_providers.dart';

class AudioPlayerController extends Notifier<PlaybackSnapshot> {
  AudioPlaybackService? _service;
  StreamSubscription<PlaybackState>? _transportSub;
  StreamSubscription<MediaItem?>? _mediaItemSub;

  PlaybackState? _lastTransport;
  int? _recordingId;
  Duration _duration = Duration.zero;

  @override
  PlaybackSnapshot build() {
    // Service resolves async (engine init on Android). Subscribe when it lands
    // and tear down on dispose so a hot-restart / provider invalidation doesn't
    // leak a dangling listener into the singleton handler.
    ref.listen<AsyncValue<AudioPlaybackService>>(
      audioPlaybackServiceProvider,
      (_, next) => next.whenData(_attach),
    );
    // In case it was already resolved before this build ran:
    ref.read(audioPlaybackServiceProvider).whenData(_attach);
    ref.onDispose(() {
      _transportSub?.cancel();
      _mediaItemSub?.cancel();
    });
    return const PlaybackSnapshot.idle();
  }

  void _attach(AudioPlaybackService service) {
    if (_service == service) return;
    // Drop the previous subscriptions before re-subscribing — if the service
    // swapped (provider rebuild), holding the old subs would double-emit into
    // the new state and leak the prior listeners.
    _transportSub?.cancel();
    _mediaItemSub?.cancel();
    _service = service;
    _transportSub = service.playbackState.listen(_onTransport);
    _mediaItemSub = service.mediaItem.listen(_onMediaItem);
    // Seed the id from a service that may already have a recording cued.
    _recordingId = service.currentRecordingId;
  }

  void _onTransport(PlaybackState state) {
    _lastTransport = state;
    _emit();
  }

  void _onMediaItem(MediaItem? item) {
    // The id the OS sees is the file URI; the app-domain id is what the
    // service tracks alongside it, so read it back here rather than parsing
    // the URI.
    _recordingId = _service?.currentRecordingId;
    _duration = item?.duration ?? Duration.zero;
    _emit();
  }

  void _emit() {
    final transport = _lastTransport;
    if (transport == null) {
      // Only metadata has arrived so far (loadRecording before any transport
      // update) — surface a cued-but-idle snapshot so the UI can render the
      // title + duration immediately.
      state = PlaybackSnapshot(
        recordingId: _recordingId,
        processingState: AudioProcessingState.idle,
        isPlaying: false,
        isCompleted: false,
        position: Duration.zero,
        duration: _duration,
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      return;
    }
    state = mapPlaybackState(
      transport,
      recordingId: _recordingId,
      duration: _duration,
    );
  }

  /// Cue [recording] and begin playback. Preloading the source on open (rather
  /// than on play-tap) is what keeps touch-to-sound under the latency budget
  /// (NFR-2.2.2) — the detail screen calls this on appear.
  Future<void> loadAndPlay(Recording recording) async {
    final service = _service ?? await _awaitService();
    if (service == null) return;
    // Seed the duration floor from the recording row BEFORE loadRecording so
    // the snapshot carries a real duration on the first frame after an
    // auto-advance (the engine emits MediaItem.duration asynchronously, which
    // left a 0:00 + indeterminate bar in the gap). Deferred via microtask:
    // loadAndPlay can run inside a widget build (the detail screen's data
    // branch), and a synchronous state set trips Riverpod's build-phase guard.
    // Stream-originated emits (below) don't, so only this seed needs deferring.
    _recordingId = recording.id;
    _duration = Duration(milliseconds: recording.durationMs ?? 0);
    scheduleMicrotask(_emit);
    await service.loadRecording(recording);
    await service.play();
  }

  /// Flip play/pause for the cued recording.
  Future<void> togglePlayPause() async {
    final service = _service ?? await _awaitService();
    if (service == null) return;
    if (state.isPlaying) {
      await service.pause();
    } else if (state.isCompleted) {
      // Replay from the top after finishing — matches user expectation.
      await service.seek(Duration.zero);
      await service.play();
    } else {
      await service.play();
    }
  }

  Future<void> seek(Duration position) async {
    final service = _service ?? await _awaitService();
    await service?.seek(position);
  }

  Future<void> stop() async {
    final service = _service ?? await _awaitService();
    await service?.stop();
  }

  Future<AudioPlaybackService?> _awaitService() async {
    if (_service != null) return _service;
    final async = await ref.read(audioPlaybackServiceProvider.future);
    _attach(async);
    return async;
  }
}

final audioPlayerControllerProvider =
    NotifierProvider<AudioPlayerController, PlaybackSnapshot>(
      AudioPlayerController.new,
    );
