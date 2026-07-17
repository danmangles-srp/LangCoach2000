// Pictograph prompt builder (T4.3 → T19.3, T19.6). Pure. The locked style
// forbids rendered text so the image never primes the answer with letters.
// T19.3: the prompt runs on the ENGLISH gloss; the Uzbek word never reaches
// Pollinations. T19.6: the surrounding template is user-tunable.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

void main() {
  group('buildAiImagePrompt', () {
    test('substitutes the trimmed word into a custom template', () {
      final p = buildAiImagePrompt('  frog  ', 'photo of {word}');
      expect(p, 'photo of frog');
    });

    test('a blank template falls back to the default pictograph body', () {
      final p = buildAiImagePrompt('frog', '   ');
      expect(p, contains('"frog"'));
      expect(p, contains('no text'));
      expect(p, contains('no letters'));
      expect(p, contains('no captions'));
      expect(p, contains('no words'));
    });

    test('keeps a multi-word english gloss verbatim', () {
      final p = buildAiImagePrompt('small frog', defaultAiImagePrompt);
      expect(p, contains('"small frog"'));
    });

    test('the default template carries the placeholder + no-script guard', () {
      expect(defaultAiImagePrompt, contains('{word}'));
      expect(defaultAiImagePrompt, contains('no letters'));
    });

    test('a template without a placeholder is returned verbatim', () {
      final p = buildAiImagePrompt('frog', 'a still-life painting');
      expect(p, 'a still-life painting');
    });
  });
}
