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

  /// Whether the AnkiDroid READ_WRITE permission still needs a runtime grant
  /// (T16.1). True → the UI shows a one-time explainer, then calls
  /// [requestPermission]. Read live from the API, never cached — repeated
  /// exports must not re-prompt once granted.
  Future<bool> shouldRequestPermission();

  /// Drive AnkiDroid's native runtime-permission grant screen (T16.2).
  /// Returns true if the grant succeeded. On AnkiDroid 2.24+ the user must
  /// also have the global "Enable AnkiDroid API" toggle ON, else this returns
  /// false and the UI surfaces current-copy guidance.
  Future<bool> requestPermission();

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

  /// Add an image to AnkiDroid's media collection and return the formatted
  /// field string to drop into a note (`<img src="...">`), or null on failure.
  ///
  /// [relativePath] is app-relative under the documents dir (where the AI image
  /// cache writes, e.g. `ai_images/<sha1>.png`); the platform side resolves it
  /// against `filesDir` and exposes it to AnkiDroid via a FileProvider content
  /// URI with a read grant. [preferredName] is the base filename (no
  /// extension) AnkiDroid stores the media under. Returns null when AnkiDroid
  /// can't import the media — callers treat that as a retryable failure (the
  /// image is still cached, so a later export re-tries the attach).
  Future<String?> addMedia({
    required String relativePath,
    required String preferredName,
  });
}
