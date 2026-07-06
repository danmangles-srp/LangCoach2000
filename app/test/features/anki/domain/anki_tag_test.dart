// Pure tests for Anki deck/tag naming (M4, T4.2). Anki stores tags
// space-delimited, so a recording name containing whitespace must collapse to
// a single underscore before it can tag a note.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/anki/domain/anki_tag.dart';

void main() {
  group('ankiDeckName', () {
    test('is the localized product name', () {
      expect(ankiDeckName, 'Rivendell');
    });
  });

  group('ankiTagForRecording', () {
    test('collapses a single space to one underscore', () {
      expect(ankiTagForRecording('My Lecture.m4a'), 'My_Lecture.m4a');
    });

    test('collapses runs of whitespace to a single underscore', () {
      expect(ankiTagForRecording('My  Lecture   3.m4a'), 'My_Lecture_3.m4a');
    });

    test('collapses tabs and mixed whitespace', () {
      expect(ankiTagForRecording('a\t b\n c'), 'a_b_c');
    });

    test('leaves a name with no whitespace untouched (extension kept)', () {
      expect(ankiTagForRecording('Lecture.m4a'), 'Lecture.m4a');
    });

    test('returns empty for an empty name', () {
      expect(ankiTagForRecording(''), '');
    });
  });
}
