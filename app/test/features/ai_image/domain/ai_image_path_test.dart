// AI image cache path (T4.3). Pure. The filename is a sha1 of the word so any
// Uzbek script maps to a stable ASCII filename without stripping diacritics,
// and the same word always maps to the same path (per-word cache).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';

void main() {
  group('buildAiImagePath', () {
    test('lives under ai_images/ as a .png', () {
      final p = buildAiImagePath('salom');
      expect(p, startsWith('ai_images/'));
      expect(p, endsWith('.png'));
    });

    test('is stable for the same word', () {
      expect(buildAiImagePath('salom'), buildAiImagePath('salom'));
    });

    test('differs for different words', () {
      expect(buildAiImagePath('salom'), isNot(buildAiImagePath('xayr')));
    });

    test('differs for Cyrillic vs Latin spelling of the same idea', () {
      // Stripping non-ASCII would risk colliding these; sha1 keeps them apart.
      expect(buildAiImagePath('salom'), isNot(buildAiImagePath('Салом')));
    });

    test('contains only ASCII (filesystem-safe) chars after the dir', () {
      final p = buildAiImagePath('oʻgʻil bola');
      final name = p.substring('ai_images/'.length, p.length - '.png'.length);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(name), isTrue);
    });
  });
}
