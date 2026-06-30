// Vocab pair model (M3, FR-1.3.2). One English-definition ↔ Uzbek-word pair
// extracted from a text word log. The parser (see [parseVocabPairs]) produces
// these; Anki card generation (M4) consumes them. Immutable value type.

import 'package:flutter/foundation.dart';

@immutable
class VocabPair {
  const VocabPair({required this.english, required this.uzbek});

  /// Left-hand side of the delimiter. Assumed to be the English definition
  /// (the GPA convention is `english: uzbek`). Both halves are trimmed; an
  /// empty half means the line was malformed and is dropped by the parser.
  final String english;

  /// Right-hand side — the Uzbek word/phrase.
  final String uzbek;

  @override
  bool operator ==(Object other) =>
      other is VocabPair && other.english == english && other.uzbek == uzbek;

  @override
  int get hashCode => Object.hash(english, uzbek);

  @override
  String toString() => 'VocabPair(english: $english, uzbek: $uzbek)';
}
