// VocabParser — T3.2 (FR-1.3.2). Pure-function cases: the two delimiters,
// mixed input, bullet stripping, malformed-line skipping, order preservation,
// and the empty-body edge.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';
import 'package:rivendell/features/wordlog/domain/vocab_parser.dart';

void main() {
  group('parseVocabPairs', () {
    test('colon delimiter splits english / uzbek', () {
      final pairs = parseVocabPairs('cat: mushuk');
      expect(pairs, [const VocabPair(english: 'cat', uzbek: 'mushuk')]);
    });

    test('dash delimiter splits english / uzbek', () {
      final pairs = parseVocabPairs('dog - it');
      expect(pairs, [const VocabPair(english: 'dog', uzbek: 'it')]);
    });

    test('parses a multiline list preserving order', () {
      const body = 'cat: mushuk\ndog: it\nbook: kitob';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
        const VocabPair(english: 'book', uzbek: 'kitob'),
      ]);
    });

    test('mixes colon and dash delimiters in one body', () {
      const body = 'cat: mushuk\ndog - it';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('strips leading markdown bullets (-, *, •)', () {
      const body = '- cat: mushuk\n* dog: it\n• book: kitob';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
        const VocabPair(english: 'book', uzbek: 'kitob'),
      ]);
    });

    test('hyphenated english term parses on the colon, not the hyphen', () {
      // "mother-in-law" stays whole; the colon is the splitter.
      final pairs = parseVocabPairs('mother-in-law: qaynona');
      expect(pairs, [
        const VocabPair(english: 'mother-in-law', uzbek: 'qaynona'),
      ]);
    });

    test('skips blank lines and lines without a delimiter', () {
      const body = 'cat: mushuk\n\na line with no delim\ndog: it';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('drops a line whose uzbek half is empty', () {
      const body = 'cat:\ndog: it';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('drops a line whose english half is empty', () {
      const body = ': mushuk\ndog: it';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('trims whitespace around both halves', () {
      final pairs = parseVocabPairs('   cat    :    mushuk   ');
      expect(pairs, [const VocabPair(english: 'cat', uzbek: 'mushuk')]);
    });

    test('passes Cyrillic uzbek through untouched', () {
      final pairs = parseVocabPairs('cat: мушук');
      expect(pairs, [const VocabPair(english: 'cat', uzbek: 'мушук')]);
    });

    test('empty body yields no pairs', () {
      expect(parseVocabPairs(''), isEmpty);
    });

    test('whitespace-only body yields no pairs', () {
      expect(parseVocabPairs('   \n  \n'), isEmpty);
    });
  });

  group('VocabPair value semantics', () {
    test('equality is by content', () {
      expect(
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
      );
      expect(
        const VocabPair(english: 'cat', uzbek: 'mushuk').hashCode,
        const VocabPair(english: 'cat', uzbek: 'mushuk').hashCode,
      );
    });
  });
}
