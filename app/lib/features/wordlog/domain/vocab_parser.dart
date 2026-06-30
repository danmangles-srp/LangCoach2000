// Vocab text-log parser (M3, FR-1.3.2). Pure function: a raw text body → a
// list of English↔Uzbek pairs. No I/O, no device — exhaustively unit-tested.
//
// Rule (FR-1.3.2: "lines containing `:` or `-`"):
//   - Split the body into lines.
//   - For each line, trim and skip blanks.
//   - Find the first delimiter. `:` wins over `-` when both appear; otherwise
//     whichever comes first. Markdown list bullets ("- ") are stripped before
//     delimiter search so "- cat: mushuk" parses as cat / mushuk, not "- cat".
//   - Split into exactly two halves on that delimiter. Trim both. A pair with
//     an empty half is dropped (the line had no real word on one side).
//
// Direction is fixed: left = English, right = Uzbek (GPA convention). Latin vs
// Cyrillic Uzbek is left untouched here — both pass through as-is (open
// decision #5, deferred; the parser is script-agnostic).

import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';

/// Parse [body] into [VocabPair]s, preserving source order. Lines that don't
/// contain a delimiter, or that yield an empty half, are skipped.
List<VocabPair> parseVocabPairs(String body) {
  final out = <VocabPair>[];
  for (final rawLine in body.split('\n')) {
    final line = _stripBullet(rawLine.trim());
    if (line.isEmpty) continue;
    final cut = _firstDelimiterIndex(line);
    if (cut == null) continue;
    final left = line.substring(0, cut).trim();
    final right = line.substring(cut + 1).trim();
    if (left.isEmpty || right.isEmpty) continue;
    out.add(VocabPair(english: left, uzbek: right));
  }
  return out;
}

/// Strip a leading markdown list bullet ("- ", "* ", or "• ") so bulleted
/// vocab lists parse the same as bare ones. Only the bullet at the very start.
String _stripBullet(String line) {
  if (line.startsWith('• ')) return line.substring(2);
  if (line.startsWith('- ') || line.startsWith('* ')) {
    return line.substring(2);
  }
  return line;
}

/// Index of the delimiter that splits this line. `:` wins when present
/// (dashes appear inside hyphenated English words like "mother-in-law", so a
/// dash is only used as the splitter when no colon exists). Returns null when
/// neither delimiter is present.
int? _firstDelimiterIndex(String line) {
  final colon = line.indexOf(':');
  if (colon >= 0) return colon;
  final dash = line.indexOf('-');
  if (dash >= 0) return dash;
  return null;
}
