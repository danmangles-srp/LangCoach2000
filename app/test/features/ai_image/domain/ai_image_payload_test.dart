// ai_image queue payload (de)serialization (T4.3 → T19.3). Pure. The enqueuer
// and the drain handler agree on the (uzbek, english) shape; a malformed
// payload must throw so the worker records the item failed rather than silently
// dropping it. Legacy `{"word": X}` rows (pre-T19.3) still drain.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';

void main() {
  group('round trip', () {
    test('uzbek + english survive encode -> decode', () {
      final p = pairFromAiImagePayload(
        aiImagePayload(uzbek: 'qurbaqa', english: 'frog'),
      );
      expect(p.uzbek, 'qurbaqa');
      expect(p.english, 'frog');
    });

    test('Cyrillic + diacritics survive', () {
      final p = pairFromAiImagePayload(
        aiImagePayload(uzbek: 'oʻgʻil bolaga rahmat', english: 'boy thanks'),
      );
      expect(p.uzbek, 'oʻgʻil bolaga rahmat');
      expect(p.english, 'boy thanks');
    });

    test('a value with a double-quote survives', () {
      final p = pairFromAiImagePayload(
        aiImagePayload(uzbek: 'so\'z"qo\'sh', english: 'a"b'),
      );
      expect(p.uzbek, 'so\'z"qo\'sh');
      expect(p.english, 'a"b');
    });
  });

  group('shape', () {
    test('payload is a JSON object with uzbek + english fields', () {
      final p = aiImagePayload(uzbek: 'qurbaqa', english: 'frog');
      expect(p, contains('"uzbek"'));
      expect(p, contains('"english"'));
      expect(p, contains('"qurbaqa"'));
      expect(p, contains('"frog"'));
    });
  });

  group('legacy tolerance (pre-T19.3 {"word": X})', () {
    test('reads a single-word payload as uzbek=english=word', () {
      final p = pairFromAiImagePayload('{"word":"salom"}');
      expect(p.uzbek, 'salom');
      expect(p.english, 'salom');
    });
  });

  group('pairFromAiImagePayload rejects malformed payloads', () {
    test('not a JSON object', () {
      expect(() => pairFromAiImagePayload('[1,2]'), throwsFormatException);
    });

    test('missing both uzbek and word', () {
      expect(
        () => pairFromAiImagePayload('{"english":"x"}'),
        throwsFormatException,
      );
    });

    test('missing both english and word', () {
      expect(
        () => pairFromAiImagePayload('{"uzbek":"x"}'),
        throwsFormatException,
      );
    });

    test('empty uzbek', () {
      expect(
        () => pairFromAiImagePayload('{"uzbek":"","english":"x"}'),
        throwsFormatException,
      );
    });

    test('non-string uzbek', () {
      expect(
        () => pairFromAiImagePayload('{"uzbek":5,"english":"x"}'),
        throwsFormatException,
      );
    });
  });
}
