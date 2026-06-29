// Unit tests for the SAF scan entry -> ScannedFile mapper (T1.2). Pure domain
// logic — no platform, no isolate — so every edge (extension filter, missing
// fields, defaults, non-map junk) is pinned deterministically.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/audio/domain/scanned_file_mapper.dart';

void main() {
  group('scannedFileFromEntry', () {
    test('parses a supported m4a entry into a ScannedFile', () {
      final f = scannedFileFromEntry(const {
        'path': 'content://tree/abc',
        'name': 'lecture.m4a',
        'size': 4096,
        'lastModified': 1_700_000_000_000,
      });
      expect(f, isNotNull);
      expect(f!.path, 'content://tree/abc');
      expect(f.name, 'lecture.m4a');
      expect(f.sizeBytes, 4096);
      expect(f.format, AudioFormat.m4a);
      expect(
        f.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000, isUtc: true),
      );
    });

    test('parses mp3 and wav case-insensitively', () {
      expect(
        scannedFileFromEntry(const {'path': 'p', 'name': 'x.MP3'})?.format,
        AudioFormat.mp3,
      );
      expect(
        scannedFileFromEntry(const {'path': 'p', 'name': 'y.WaV'})?.format,
        AudioFormat.wav,
      );
    });

    test('skips unsupported containers (flac/aac/extensionless)', () {
      expect(
        scannedFileFromEntry(const {'path': 'p', 'name': 'song.flac'}),
        isNull,
      );
      expect(
        scannedFileFromEntry(const {'path': 'p', 'name': 'noext'}),
        isNull,
      );
    });

    test('skips entries missing name or path', () {
      expect(scannedFileFromEntry(const {'name': 'a.m4a'}), isNull);
      expect(scannedFileFromEntry(const {'path': 'p'}), isNull);
    });

    test('defaults size/lastModified to 0 when absent', () {
      final f = scannedFileFromEntry(const {'path': 'p', 'name': 'a.m4a'});
      expect(f, isNotNull);
      expect(f!.sizeBytes, 0);
      expect(f.createdAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
    });
  });

  group('parseScannedEntries', () {
    test('keeps supported files and drops junk in one pass', () {
      final out = parseScannedEntries([
        {'path': 'a', 'name': 'a.m4a', 'size': 10, 'lastModified': 1},
        {'path': 'b', 'name': 'b.flac'}, // unsupported
        'not a map', // junk
        null, // junk
        {'name': 'c.m4a'}, // missing path
        {'path': 'd', 'name': 'd.wav', 'size': 20, 'lastModified': 2},
      ]);
      expect(out.map((f) => f.name), ['a.m4a', 'd.wav']);
      expect(out, isA<List<ScannedFile>>());
    });

    test('returns an empty (non-null) list for no input', () {
      expect(parseScannedEntries(const []), isEmpty);
    });
  });
}
