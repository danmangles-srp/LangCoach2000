// recording_filename pure-helper tests (T2.7, T10.3). Deterministic — no
// device, no DateTime.now.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/recording/domain/recording_filename.dart';

final DateTime _recordedAt = DateTime(2026, 7, 5, 13, 4, 9);

void main() {
  group('buildRecordingFileName', () {
    test('produces a zero-padded, chronological, .m4a-terminated name', () {
      expect(
        buildRecordingFileName(recordedAt: _recordedAt),
        'rivendell-2026-0705-130409.m4a',
      );
    });
  });

  group('defaultRecordingBaseName', () {
    test('matches the filename minus the extension', () {
      expect(
        defaultRecordingBaseName(recordedAt: _recordedAt),
        'rivendell-2026-0705-130409',
      );
    });
  });

  group('sanitizeRecordingBaseName', () {
    test('returns null for blank / whitespace-only input', () {
      expect(sanitizeRecordingBaseName(''), isNull);
      expect(sanitizeRecordingBaseName('   '), isNull);
    });

    test('returns null when only illegal characters remain', () {
      expect(sanitizeRecordingBaseName('///'), isNull);
      expect(sanitizeRecordingBaseName(':*?'), isNull);
    });

    test('strips filesystem-illegal characters to dashes', () {
      expect(sanitizeRecordingBaseName('Lecture: Yor-Yor'), 'Lecture- Yor-Yor');
      expect(sanitizeRecordingBaseName(r'a/b\c'), 'a-b-c');
    });

    test('collapses runs of dashes and trims edges', () {
      expect(sanitizeRecordingBaseName('a---b'), 'a-b');
      expect(sanitizeRecordingBaseName('--a--b--'), 'a-b');
    });

    test('preserves unicode (Uzbek Latin/Cyrillic) letters', () {
      expect(sanitizeRecordingBaseName('Yor-Yor ñ'), 'Yor-Yor ñ');
      expect(sanitizeRecordingBaseName('Шамол'), 'Шамол');
    });

    test('caps length at 80 characters', () {
      final long = 'a' * 120;
      final out = sanitizeRecordingBaseName(long);
      expect(out, isNotNull);
      expect(out!.length, 80);
    });
  });

  group('saveRecordingFileName', () {
    test('uses the sanitized user name + extension when valid', () {
      expect(
        saveRecordingFileName(baseName: 'Lecture 1', recordedAt: _recordedAt),
        'Lecture 1.m4a',
      );
    });

    test('falls back to the timestamped default when blank', () {
      expect(
        saveRecordingFileName(baseName: '', recordedAt: _recordedAt),
        'rivendell-2026-0705-130409.m4a',
      );
      expect(
        saveRecordingFileName(baseName: null, recordedAt: _recordedAt),
        'rivendell-2026-0705-130409.m4a',
      );
    });

    test('falls back to the default when the name is only illegal chars', () {
      expect(
        saveRecordingFileName(baseName: '///', recordedAt: _recordedAt),
        'rivendell-2026-0705-130409.m4a',
      );
    });

    test('sanitizes unsafe characters before appending the extension', () {
      expect(
        saveRecordingFileName(baseName: 'a/b:c', recordedAt: _recordedAt),
        'a-b-c.m4a',
      );
    });
  });
}
