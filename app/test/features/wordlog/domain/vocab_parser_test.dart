// VocabParser — T3.2 (FR-1.3.2). Pure-function cases: the two delimiters,
// mixed input, bullet stripping, malformed-line skipping, order preservation,
// and the empty-body edge. Entry scheme is `uzbek: english` (uzbek left).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';
import 'package:rivendell/features/wordlog/domain/vocab_parser.dart';

void main() {
  group('parseVocabPairs', () {
    test('colon delimiter splits uzbek / english', () {
      final pairs = parseVocabPairs('mushuk: cat');
      expect(pairs, [const VocabPair(english: 'cat', uzbek: 'mushuk')]);
    });

    test('dash delimiter splits uzbek / english', () {
      final pairs = parseVocabPairs('it - dog');
      expect(pairs, [const VocabPair(english: 'dog', uzbek: 'it')]);
    });

    test('parses a multiline list preserving order', () {
      const body = 'mushuk: cat\nit: dog\nkitob: book';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
        const VocabPair(english: 'book', uzbek: 'kitob'),
      ]);
    });

    test('mixes colon and dash delimiters in one body', () {
      const body = 'mushuk: cat\nit - dog';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('strips leading markdown bullets (-, *, •)', () {
      const body = '- mushuk: cat\n* it: dog\n• kitob: book';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
        const VocabPair(english: 'book', uzbek: 'kitob'),
      ]);
    });

    test('hyphenated english term parses on the colon, not the hyphen', () {
      // English is the right half now; "mother-in-law" stays whole because the
      // colon is the splitter, not the hyphen.
      final pairs = parseVocabPairs('qaynona: mother-in-law');
      expect(pairs, [
        const VocabPair(english: 'mother-in-law', uzbek: 'qaynona'),
      ]);
    });

    test('skips blank lines and lines without a delimiter', () {
      const body = 'mushuk: cat\n\na line with no delim\nit: dog';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'cat', uzbek: 'mushuk'),
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('drops a line whose uzbek (left) half is empty', () {
      const body = ': cat\nit: dog';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('drops a line whose english (right) half is empty', () {
      const body = 'mushuk:\nit: dog';
      expect(parseVocabPairs(body), [
        const VocabPair(english: 'dog', uzbek: 'it'),
      ]);
    });

    test('trims whitespace around both halves', () {
      final pairs = parseVocabPairs('   mushuk    :    cat   ');
      expect(pairs, [const VocabPair(english: 'cat', uzbek: 'mushuk')]);
    });

    test('passes Cyrillic uzbek through untouched', () {
      final pairs = parseVocabPairs('мушук: cat');
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
