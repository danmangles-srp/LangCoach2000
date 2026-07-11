// Pictograph prompt builder (T4.3 → T19.3). Pure. The locked style forbids
// rendered text so the image never primes the answer with letters. T19.3: the
// prompt runs on the ENGLISH gloss; the Uzbek word never reaches Pollinations.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

void main() {
  group('buildPictographPrompt', () {
    test('embeds the trimmed english gloss', () {
      final p = buildPictographPrompt('  frog  ');
      expect(p, contains('"frog"'));
    });

    test('forbids text, letters, captions, words', () {
      final p = buildPictographPrompt('frog');
      expect(p, contains('no text'));
      expect(p, contains('no letters'));
      expect(p, contains('no captions'));
      expect(p, contains('no words'));
    });

    test('keeps multi-word english glosses verbatim', () {
      final p = buildPictographPrompt('small frog');
      expect(p, contains('"small frog"'));
    });
  });
}
