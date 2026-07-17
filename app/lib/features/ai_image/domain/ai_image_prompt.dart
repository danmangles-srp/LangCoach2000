// Prompt template for AI concept images (T4.3, FR-1.3.4; T19.3 english gloss,
// T19.6 user-tunable). The locked style is "language-neutral pictographic": the
// image must depict the CONCEPT of the word with no script, letters, or
// captions, so the same card works for a learner who can't yet read the word
// and doesn't prime them with text. Pure.
//
// T19.3: the prompt runs on the ENGLISH gloss, not the Uzbek word. Image models
// map an English concept to a clean pictograph reliably; the Uzbek string
// (Cyrillic or Latin-with-diacritics) frequently smeared into rendered text and
// primed the answer. The Uzbek word still fronts the Anki card (IMAGE:UZBEK).
//
// T19.6: the surrounding template is user-tunable from Settings. The {word}
// placeholder is substituted with the english gloss at drain time.

/// The default image-prompt template (T19.6). User-editable from Settings; the
/// engine substitutes `{word}` for the concept word at drain time. The no-text
/// / no-letters guard is load-bearing — without it, image models smear Latin
/// lettering into the picture and prime the answer.
const String defaultAiImagePrompt =
    'A simple, clean, minimalist pictographic illustration depicting the '
    'concept of the word "{word}". Single centered subject, plain neutral '
    'background, flat modern style, no people faces, no text, no letters, '
    'no captions, no words, no writing of any kind, no logos.';

/// Substitute [word] into [template]'s `{word}` placeholder (T19.6). A blank
/// template falls back to [defaultAiImagePrompt] so a user who clears the
/// field never sends an empty prompt. The caller feeds the ENGLISH gloss
/// (T19.3).
String buildAiImagePrompt(String word, String template) {
  final body = template.trim().isEmpty ? defaultAiImagePrompt : template;
  return body.replaceAll('{word}', word.trim());
}
