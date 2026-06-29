// Adapter that exposes the background [RivendellAudioHandler] through the
// abstract [AudioPlaybackService] seam (T1.5). Thin by design — the handler
// already provides the streams + transport methods; this just ports the row-id
// tracking + recording-cue surface onto the contract the controller depends on.

import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/application/audio_playback_service.dart';
import 'package:rivendell/features/audio/playback/platform/rivendell_audio_handler.dart';

class RivendellAudioPlaybackService implements AudioPlaybackService {
  RivendellAudioPlaybackService({required RivendellAudioHandler audioHandler})
    : _handler = audioHandler;

  final RivendellAudioHandler _handler;

  @override
  Stream<PlaybackState> get playbackState => _handler.playbackState;

  @override
  Stream<MediaItem?> get mediaItem => _handler.mediaItem;

  @override
  int? get currentRecordingId => _handler.currentRecordingId;

  @override
  Future<void> loadRecording(Recording recording) =>
      _handler.loadRecording(recording);

  @override
  Future<void> play() => _handler.play();

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> stop() => _handler.stop();

  @override
  Future<void> dispose() => _handler.stop();
}
