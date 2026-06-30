// Anki note-type (model) definitions (M4, FR-1.3.3 / FR-1.3.4). A model names
// its fields and the front/back card templates that render them. Two are
// pinned for Rivendell:
//
//   Type 1 — English ↔ Uzbek: a plain translation card (T4.2).
//   Type 2 — Image → Uzbek: an AI concept image on the front, the Uzbek word
//            on the back (T4.4, FR-1.3.4).
//
// Templates use Anki's `{{Field}}` substitution. The back side carries
// `{{FrontSide}}` + a divider so the question stays visible on the answer.

import 'package:flutter/foundation.dart';

@immutable
class AnkiModelSpec {
  const AnkiModelSpec({
    required this.name,
    required this.fields,
    required this.frontTemplate,
    required this.backTemplate,
    this.css = '',
  });

  /// Stable, human-readable model name. Used as the lookup key when the
  /// adapter resolves a model id (create-or-find).
  final String name;

  /// Ordered field names. Note field values must be supplied in this order.
  final List<String> fields;

  /// Front template (Anki qfmt) for the single card.
  final String frontTemplate;

  /// Back template (Anki afmt) for the single card.
  final String backTemplate;

  /// Optional shared CSS. Empty keeps Anki's defaults.
  final String css;
}

/// Type 1 — translation card. Front shows the English word, back reveals the
/// Uzbek translation beneath a divider.
const ankiType1Model = AnkiModelSpec(
  name: 'Rivendell: English↔Uzbek',
  fields: ['English', 'Uzbek'],
  frontTemplate: '{{English}}',
  backTemplate: '{{FrontSide}}\n<hr id=answer>\n\n{{Uzbek}}',
);

/// Type 2 — concept-image card. Front shows the AI image, back reveals the
/// Uzbek word. The Image field holds a stored-filename Anki media reference
/// (populated by T4.4 once an image is cached).
const ankiType2Model = AnkiModelSpec(
  name: 'Rivendell: Image→Uzbek',
  fields: ['Image', 'Uzbek'],
  frontTemplate: '<img src="{{Image}}">',
  backTemplate: '{{FrontSide}}\n<hr id=answer>\n\n{{Uzbek}}',
);
