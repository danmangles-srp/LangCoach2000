// ai_image queue payload (de)serialization (T4.3). Pure. The enqueuer and the
// drain handler agree on the `word` field shape; a malformed payload must throw
// so the worker records the item failed rather than silently dropping it.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';

void main() {
  group('round trip', () {
    test('word survives encode -> decode', () {
      const word = 'salom';
      expect(wordFromAiImagePayload(aiImagePayload(word)), word);
    });

    test('Cyrillic + diacritics survive', () {
      const word = 'oʻgʻil bolaga rahmat';
      expect(wordFromAiImagePayload(aiImagePayload(word)), word);
    });

    test('a word with a double-quote survives', () {
      const word = 'so\'z"qo\'sh';
      expect(wordFromAiImagePayload(aiImagePayload(word)), word);
    });
  });

  group('shape', () {
    test('payload is a JSON object with a word field', () {
      final p = aiImagePayload('hello');
      expect(p, contains('"word"'));
      expect(p, contains('"hello"'));
    });
  });

  group('wordFromAiImagePayload rejects malformed payloads', () {
    test('not a JSON object', () {
      expect(() => wordFromAiImagePayload('[1,2]'), throwsFormatException);
    });

    test('missing word field', () {
      expect(() => wordFromAiImagePayload('{"x":1}'), throwsFormatException);
    });

    test('empty word', () {
      expect(
        () => wordFromAiImagePayload('{"word":""}'),
        throwsFormatException,
      );
    });

    test('non-string word', () {
      expect(() => wordFromAiImagePayload('{"word":5}'), throwsFormatException);
    });
  });
}
