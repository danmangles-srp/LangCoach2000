// Abstract playback seam (T1.5). The Riverpod controller depends on this, not
// on [BaseAudioHandler] / just_audio, so the stream-combine + transport logic
// is testable with a fake and the engine swaps cleanly between the Android
// background handler and a non-Android placeholder (NFR-2.3 — desktop/test
// hosts have no audio_service native side).
//
// Mirrors the codebase's other platform seams (AudioIndexerService,
// FolderSelectionService): interface in application/, real impl in platform/.

import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:rivendell/core/database/app_database.dart';

abstract class AudioPlaybackService {
  /// Live transport stream from the media session (playing/position/phase).
  Stream<PlaybackState> get playbackState;

  /// Live media-item stream (carries the current [Recording]'s title +
  /// duration). `null` when nothing is cued.
  Stream<MediaItem?> get mediaItem;

  /// Row id of the recording currently cued, or `null`. The OS-side id is the
  /// file URI; this is the app-domain id the controller stamps into snapshots.
  int? get currentRecordingId;

  /// Cue a recording's source without starting playback. Sets the media item
  /// so the session UI updates immediately; `play()` follows to begin.
  Future<void> loadRecording(Recording recording);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> stop();

  Future<void> dispose();
}
