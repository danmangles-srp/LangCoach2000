// voice_recorder_paths matcher — T1.1 "guess + confirm / warn-once" logic.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/domain/voice_recorder_paths.dart';

void main() {
  group('looksLikeVoiceRecorderFolder', () {
    test('matches a filesystem path', () {
      expect(
        looksLikeVoiceRecorderFolder('/storage/emulated/0/Voice Recorder'),
        isTrue,
      );
    });

    test('matches an Android SAF content tree URI', () {
      expect(
        looksLikeVoiceRecorderFolder(
          'content://com.android.externalstorage.documents/tree/primary%3AVoice%20Recorder',
        ),
        isTrue,
      );
    });

    test('matches case-insensitively and tolerates a trailing slash', () {
      expect(looksLikeVoiceRecorderFolder('/sdcard/voice recorder/'), isTrue);
      expect(looksLikeVoiceRecorderFolder('Voice Recorder'), isTrue);
    });

    test('rejects lookalikes that only contain the name', () {
      expect(
        looksLikeVoiceRecorderFolder('/sdcard/VoiceRecorderNotes'),
        isFalse,
      );
      expect(
        looksLikeVoiceRecorderFolder('/sdcard/My Voice Recorder Backup'),
        isFalse,
      );
      expect(
        looksLikeVoiceRecorderFolder('/sdcard/Voice Recorder Stuff'),
        isFalse,
      );
    });

    test('rejects empty or blank input', () {
      expect(looksLikeVoiceRecorderFolder(''), isFalse);
      expect(looksLikeVoiceRecorderFolder('   '), isFalse);
    });
  });
}
