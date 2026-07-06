// Pictograph prompt builder (T4.3). Pure. The locked style forbids rendered
// text so the image never primes the answer with letters.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';

void main() {
  group('buildPictographPrompt', () {
    test('embeds the trimmed word', () {
      final p = buildPictographPrompt('  salom  ');
      expect(p, contains('"salom"'));
    });

    test('forbids text, letters, captions, words', () {
      final p = buildPictographPrompt('rahmat');
      expect(p, contains('no text'));
      expect(p, contains('no letters'));
      expect(p, contains('no captions'));
      expect(p, contains('no words'));
    });

    test('keeps Cyrillic / diacritic words verbatim', () {
      final p = buildPictographPrompt('oʻgʻil');
      expect(p, contains('"oʻgʻil"'));
    });
  });
}
