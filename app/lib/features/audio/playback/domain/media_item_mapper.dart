// Map a stored [Recording] row into the audio_service [MediaItem] that the
// background session + lock-screen notification render (T1.5). Pure, so the
// id/title/duration contract is unit-tested without a device.
//
// The OS-side media id is the recording's file URI (the stable identity the
// indexer keys on); the row id is what the app domain uses and is tracked
// separately by the controller from this same mapping.

import 'package:audio_service/audio_service.dart';

import 'package:rivendell/core/database/app_database.dart';

/// App label shown as the media item's album (the notification grouping).
const String kPlaybackAlbum = 'Rivendell';

MediaItem mediaItemFromRecording(Recording recording) {
  final durationMs = recording.durationMs;
  return MediaItem(
    id: recording.filePath,
    title: recording.name,
    album: kPlaybackAlbum,
    duration: durationMs == null ? null : Duration(milliseconds: durationMs),
  );
}
