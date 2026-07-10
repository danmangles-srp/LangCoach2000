// Prompt template for AI concept images (T4.3, FR-1.3.4). The locked style is
// "language-neutral pictographic": the image must depict the CONCEPT of the
// Uzbek word with no script, letters, or captions, so the same card works for a
// learner who can't yet read the word and doesn't prime them with text. Pure.

/// Build the image prompt for a single Uzbek word.
///
/// The word is passed verbatim (it may be Cyrillic or Latin with diacritics).
/// The surrounding instructions forbid any rendered text so the model returns a
/// pure pictograph; without that guard, image models habitually smear Latin
/// lettering into the picture and prime the answer.
String buildPictographPrompt(String uzbekWord) {
  final word = uzbekWord.trim();
  return 'A simple, clean, minimalist pictographic illustration depicting the '
      'concept of the word "$word". Single centered subject, plain neutral '
      'background, flat modern style, no people faces, no text, no letters, '
      'no captions, no words, no writing of any kind, no logos.';
}
