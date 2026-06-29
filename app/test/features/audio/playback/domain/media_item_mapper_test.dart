// Pure mapper test (T1.5). Pins the OS-facing media identity: the file URI is
// the stable id, the stored name is the title, the album is the app label, and
// a known duration (filled lazily on first play) round-trips through the media
// item while an unknown one stays null.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/playback/domain/media_item_mapper.dart';

Recording recording({int? durationMs}) => Recording(
  id: 42,
  filePath: 'content://folder/lecture.m4a',
  name: 'lecture.m4a',
  createdAt: DateTime(2026),
  sizeBytes: 1024,
  format: 'm4a',
  durationMs: durationMs,
  indexedAt: DateTime(2026),
);

void main() {
  test('keys the media id on the file URI + titles it with the name', () {
    final item = mediaItemFromRecording(recording());
    expect(item.id, 'content://folder/lecture.m4a');
    expect(item.title, 'lecture.m4a');
  });

  test('groups under the app album label', () {
    final item = mediaItemFromRecording(recording());
    expect(item.album, kPlaybackAlbum);
    expect(item.album, 'Rivendell');
  });

  test('round-trips a known duration', () {
    final item = mediaItemFromRecording(recording(durationMs: 60000));
    expect(item.duration, const Duration(seconds: 60));
  });

  test('leaves the duration null when the recording has none yet', () {
    final item = mediaItemFromRecording(recording());
    expect(item.duration, isNull);
  });
}
