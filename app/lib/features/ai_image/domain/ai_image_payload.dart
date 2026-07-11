// Payload (de)serialization for `ai_image` queue items (T4.3 → T19.3). Pure.
// The enqueuer (an [AiImageService] impl) and the drain handler agree on this
// shape without either reaching into the other.
//
// T19.3 split the single `word` field into a (uzbek, english) pair: the image
// prompt runs on the ENGLISH gloss (Pollinations maps an English concept far
// more reliably than Uzbek), while the cache + Anki card stay keyed by the
// UZBEK word — the card is IMAGE:UZBEK, so the learner recalls the Uzbek.

import 'dart:convert';

/// The word pair an `ai_image` queue item carries. `uzbek` keys the cache and
/// the Anki Type-2 first field; `english` drives the image prompt.
typedef AiImageWord = ({String uzbek, String english});

/// `{"uzbek": "...", "english": "..."}` — the payload for an `ai_image` queue
/// item. Both fields are required: the drain handler prompts from `english` and
/// writes the cache row keyed by `uzbek`.
String aiImagePayload({required String uzbek, required String english}) =>
    jsonEncode({'uzbek': uzbek, 'english': english});

/// Read the pair back out of an `ai_image` payload. Tolerates the legacy
/// pre-T19.3 `{"word": X}` shape — a pending row written before the upgrade —
/// by reading both fields as X: the item still drains (the image may be murky
/// when X is Uzbek, but no dead-letter). Throws [FormatException] on any other
/// shape — the worker records the item failed rather than silently dropping it.
AiImageWord pairFromAiImagePayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('ai_image payload is not a JSON object: $payload');
  }
  final uzbek = decoded['uzbek'] ?? decoded['word'];
  final english = decoded['english'] ?? decoded['word'];
  if (uzbek is! String || uzbek.isEmpty) {
    throw FormatException(
      'ai_image payload missing non-empty "uzbek"/"word": $payload',
    );
  }
  if (english is! String || english.isEmpty) {
    throw FormatException(
      'ai_image payload missing non-empty "english"/"word": $payload',
    );
  }
  return (uzbek: uzbek, english: english);
}
