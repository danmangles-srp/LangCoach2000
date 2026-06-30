// Abstract seam over AnkiDroid (M4, FR-1.3.3, T4.1). The platform impl talks
// to AnkiDroid via its API; tests swap in a fake. Keeping the seam local —
// names, not ids — lets the caller stay in the domain while the adapter
// resolves ids and hides AnkiDroid's content-provider details.
//
// Idempotency: AnkiDroid's addNote performs NO duplicate checking — it always
// inserts. Callers must guard re-saves by checking [hasNoteWithFirstField]
// first (Anki keys uniqueness on the model's first field). This is the
// re-save-safety the spec asks for (FR-1.3.3).

import 'package:rivendell/features/anki/domain/anki_model_spec.dart';

abstract class AnkiGateway {
  /// Whether AnkiDroid is installed and its API is reachable. False triggers
  /// the "install AnkiDroid" affordance in the UI.
  Future<bool> isInstalled();

  /// Create the deck [name] if absent, else return its id. Stable across calls.
  Future<int> ensureDeck(String name);

  /// Create the note type [spec] if absent, else return its id. Stable across
  /// calls; looked up by [AnkiModelSpec.name].
  Future<int> ensureModel(AnkiModelSpec spec);

  /// Whether a note whose first field equals [firstField] already exists for
  /// [modelId]. The idempotency guard the export service checks before adding.
  Future<bool> hasNoteWithFirstField({
    required int modelId,
    required String firstField,
  });

  /// Add a note to [deckId] using [modelId]. [fields] must match the model's
  /// field order; [tags] label the note (e.g. the recording filename). Always
  /// inserts — callers must dedupe via [hasNoteWithFirstField].
  ///
  /// Returns the new note id, or null if the insert failed (not on dupe).
  Future<int?> addNote({
    required int deckId,
    required int modelId,
    required List<String> fields,
    required Set<String> tags,
  });
}
