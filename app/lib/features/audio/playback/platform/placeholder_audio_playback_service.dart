// No-op [AudioPlaybackService] for non-Android hosts (T1.5). audio_service's
// native side is Android/iOS-only, so on a desktop or test host the provider
// hands the controller this stub instead of crashing. Real playback is
// Android-first (NFR-2.3) — desktop is a dev convenience, not a target.
//
// Every command is a no-op and the streams never emit, so a UI bound to the
// controller renders a permanent idle state off-device, which is the honest
// signal that there's nothing to play.

import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';

class PlaceholderAudioPlaybackService implements AudioPlaybackService {
  PlaceholderAudioPlaybackService({required this._logger});

  final AppLogger _logger;
  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<MediaItem?> _itemController =
      StreamController<MediaItem?>.broadcast();

  @override
  Stream<PlaybackState> get playbackState => _stateController.stream;

  @override
  Stream<MediaItem?> get mediaItem => _itemController.stream;

  @override
  int? get currentRecordingId => null;

  @override
  Future<void> loadRecording(Recording recording) async {
    _logger.w(
      LogTag.audio,
      'load ignored — playback is Android-only on this host',
    );
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _stateController.close();
    await _itemController.close();
  }
}
