// Controller test (T1.5). Proves the stream-combine + transport logic without
// a device: a fake [AudioPlaybackService] drives synthetic media-item +
// transport events, and the controller's snapshot must reflect load, play,
// pause, and completed-replay. The fake mirrors the real handler by emitting
// the media item on load and a transport state on play/pause.

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/media_item_mapper.dart';
import 'package:rivendell/features/audio/playback/platform/audio_playback_providers.dart';

Recording _recording({int? durationMs}) => Recording(
  id: 42,
  filePath: 'content://folder/lecture.m4a',
  name: 'lecture.m4a',
  createdAt: DateTime(2026),
  sizeBytes: 1024,
  format: 'm4a',
  durationMs: durationMs,
  indexedAt: DateTime(2026),
);

// Build a transport state without tripping redundant-arg lints: copyWith's
// nullable params default to null, so passing a zero duration there is never
// flagged (unlike the ctor, whose defaults are zero).
PlaybackState _transport({
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

class _FakePlaybackService implements AudioPlaybackService {
  final StreamController<PlaybackState> _state =
      StreamController<PlaybackState>.broadcast();
  final StreamController<MediaItem?> _item =
      StreamController<MediaItem?>.broadcast();

  int? _currentId;
  final List<String> calls = <String>[];

  @override
  Stream<PlaybackState> get playbackState => _state.stream;

  @override
  Stream<MediaItem?> get mediaItem => _item.stream;

  @override
  int? get currentRecordingId => _currentId;

  // Mirrors the real handler: cue sets the row id + emits the media item so the
  // controller picks up the duration.
  @override
  Future<void> loadRecording(Recording recording) async {
    _currentId = recording.id;
    calls.add('load');
    _item.add(mediaItemFromRecording(recording));
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _state.add(_transport());
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _state.add(_transport(playing: false));
  }

  @override
  Future<void> seek(Duration position) async {
    calls.add('seek:${position.inSeconds}');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> dispose() async {
    await _state.close();
    await _item.close();
  }
}

Future<void> _flush(ProviderContainer container) async {
  // Drain the microtask queue a few times so streamed events reach listeners.
  for (var i = 0; i < 4; i++) {
    await container.pump();
  }
}

ProviderContainer _containerWith(_FakePlaybackService fake) {
  return ProviderContainer(
    overrides: [
      // Cast pins the closure's return to AudioPlaybackService (the provider
      // type) so overrideWith infers the right FutureProviderOverride instead
      // of one keyed on the concrete fake.
      audioPlaybackServiceProvider.overrideWith(
        (ref) async => fake as AudioPlaybackService,
      ),
    ],
  );
}

void main() {
  test(
    'loadAndPlay cues + plays, surfacing the recording id + duration',
    () async {
      final fake = _FakePlaybackService();
      final container = _containerWith(fake);
      addTearDown(container.dispose);

      final sub = container.listen(
        audioPlayerControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );

      expect(sub.read().recordingId, isNull);

      await container
          .read(audioPlayerControllerProvider.notifier)
          .loadAndPlay(_recording(durationMs: 100000));
      await _flush(container);

      final snapshot = sub.read();
      expect(snapshot.recordingId, 42);
      expect(snapshot.isPlaying, isTrue);
      expect(snapshot.duration, const Duration(seconds: 100));
      expect(fake.calls, containsAll(const ['load', 'play']));
    },
  );

  test('togglePlayPause flips play to pause and back', () async {
    final fake = _FakePlaybackService();
    final container = _containerWith(fake);
    addTearDown(container.dispose);
    container.listen(audioPlayerControllerProvider, (_, __) {});

    await container
        .read(audioPlayerControllerProvider.notifier)
        .loadAndPlay(_recording(durationMs: 100000));
    await _flush(container);
    expect(fake.calls, contains('play'));

    await container
        .read(audioPlayerControllerProvider.notifier)
        .togglePlayPause();
    await _flush(container);
    expect(fake.calls, contains('pause'));

    await container
        .read(audioPlayerControllerProvider.notifier)
        .togglePlayPause();
    await _flush(container);
    // play called again (resume) — second 'play'.
    expect(
      'play'.allMatches(fake.calls.join(',')).length,
      greaterThanOrEqualTo(2),
    );
  });

  test('togglePlayPause from completed replays from the top', () async {
    final fake = _FakePlaybackService();
    final container = _containerWith(fake);
    addTearDown(container.dispose);
    container.listen(audioPlayerControllerProvider, (_, __) {});

    await container
        .read(audioPlayerControllerProvider.notifier)
        .loadAndPlay(_recording(durationMs: 100000));
    await _flush(container);

    // Simulate the engine finishing the item.
    fake._state.add(
      _transport(phase: AudioProcessingState.completed, playing: false),
    );
    await _flush(container);
    expect(container.read(audioPlayerControllerProvider).isCompleted, isTrue);

    await container
        .read(audioPlayerControllerProvider.notifier)
        .togglePlayPause();
    await _flush(container);

    expect(fake.calls, contains('seek:0'));
    expect(fake.calls.last, 'play');
  });

  test('seek forwards the position to the service', () async {
    final fake = _FakePlaybackService();
    final container = _containerWith(fake);
    addTearDown(container.dispose);
    container.listen(audioPlayerControllerProvider, (_, __) {});

    await container
        .read(audioPlayerControllerProvider.notifier)
        .loadAndPlay(_recording(durationMs: 100000));
    await _flush(container);

    await container
        .read(audioPlayerControllerProvider.notifier)
        .seek(const Duration(seconds: 30));
    await _flush(container);

    expect(fake.calls, contains('seek:30'));
  });

  test(
    'metadata before any transport yields a cued-but-idle snapshot',
    () async {
      final fake = _FakePlaybackService();
      final container = _containerWith(fake);
      addTearDown(container.dispose);
      final sub = container.listen(audioPlayerControllerProvider, (_, __) {});

      // Let the service resolve + the controller attach its stream listeners
      // before emitting — broadcast streams don't buffer, so an item pushed
      // before the subscription lands is lost.
      await _flush(container);

      // Cue a recording directly on the service: this emits the media item
      // (setting the row id) without any transport state yet — the real window
      // between loadRecording and the first playback event.
      await fake.loadRecording(_recording(durationMs: 50000));
      await _flush(container);

      final snapshot = sub.read();
      expect(snapshot.recordingId, 42);
      expect(snapshot.duration, const Duration(seconds: 50));
      expect(snapshot.isPlaying, isFalse);
      expect(snapshot.processingState, AudioProcessingState.idle);
    },
  );
}
