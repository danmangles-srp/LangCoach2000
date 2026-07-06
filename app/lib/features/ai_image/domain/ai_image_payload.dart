// Payload (de)serialization for `ai_image` queue items (T4.3). Pure. The
// enqueuer (an [AiImageService] impl) and the drain handler agree on this shape
// — a single `word` field — without either reaching into the other.

import 'dart:convert';

/// `{"word": "<uzbekWord>"}` — the payload for an `ai_image` queue item.
String aiImagePayload(String uzbekWord) => jsonEncode({'word': uzbekWord});

/// Read the `word` back out of an `ai_image` payload. Throws [FormatException]
/// when malformed — the worker records the item failed and retries / dead-letters.
String wordFromAiImagePayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('ai_image payload is not a JSON object: $payload');
  }
  final word = decoded['word'];
  if (word is! String || word.isEmpty) {
    throw FormatException(
      'ai_image payload missing non-empty "word": $payload',
    );
  }
  return word;
}
