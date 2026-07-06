// Anki export (M4, FR-1.3.3 / FR-1.3.4). Maps parsed vocab to AnkiDroid notes in
// the Rivendell deck.
//
//   exportType1 (T4.2) — English↔Uzbek translation cards, tagged by recording.
//   exportType2 (T4.4) — image→Uzbek concept cards, one per Uzbek word, tagged
//                        `rivendell:type2`. The image is the per-word cached AI
//                        render; words without a cached image are enqueued for
//                        generation and deferred to a later export.
//
// Idempotency: AnkiDroid's addNote performs NO duplicate checking — it always
// inserts. The [AnkiGateway.hasNoteWithFirstField] guard (keys on the model's
// first field — English for Type 1, Uzbek for Type 2) makes re-export safe.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';
import 'package:rivendell/features/anki/domain/anki_tag.dart';
import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';

class AnkiExportResult {
  const AnkiExportResult({
    required this.added,
    required this.skipped,
    required this.failed,
    this.pending = 0,
  });

  /// Notes newly created this run.
  final int added;

  /// Pairs skipped because a note with that first field already exists.
  final int skipped;

  /// Pairs whose insert (Type 1/2 note, or Type 2 media import) returned no
  /// result — an AnkiDroid failure, NOT a dupe. Retryable on the next export.
  final int failed;

  /// Type 2 only: words whose image was not cached yet (enqueued this run, no
  /// card created). Always 0 for Type 1.
  final int pending;

  int get total => added + skipped + failed + pending;

  @override
  String toString() =>
      'added=$added skipped=$skipped failed=$failed pending=$pending';
}

class AnkiExportService {
  AnkiExportService({
    required this.gateway,
    required this.aiImageService,
    required this.logger,
  });

  final AnkiGateway gateway;
  final AiImageService aiImageService;
  final AppLogger logger;

  /// Export [pairs] as Type 1 (English↔Uzbek) notes tagged [tag] (a recording
  /// name; see [ankiTagForRecording]) into the Rivendell deck. Idempotent.
  Future<AnkiExportResult> exportType1({
    required String tag,
    required List<VocabPair> pairs,
  }) async {
    final deckId = await gateway.ensureDeck(ankiDeckName);
    final modelId = await gateway.ensureModel(ankiType1Model);
    final safeTag = ankiTagForRecording(tag);

    var added = 0;
    var skipped = 0;
    var failed = 0;
    for (final pair in pairs) {
      if (await gateway.hasNoteWithFirstField(
        modelId: modelId,
        firstField: pair.english,
      )) {
        skipped++;
        continue;
      }
      final id = await gateway.addNote(
        deckId: deckId,
        modelId: modelId,
        fields: [pair.english, pair.uzbek],
        tags: {safeTag},
      );
      if (id == null) {
        failed++;
      } else {
        added++;
      }
    }

    logger.i(
      LogTag.anki,
      'type1 export tag=$safeTag added=$added skipped=$skipped failed=$failed',
    );
    return AnkiExportResult(added: added, skipped: skipped, failed: failed);
  }

  /// Export [pairs] as Type 2 (image→Uzbek) notes — one card per Uzbek word,
  /// tagged `rivendell:type2`. For each pair:
  ///   - if the image is not cached yet, enqueue generation and defer the card
  ///     (it attaches on a later export once the image is ready);
  ///   - if a card for the word already exists, skip (idempotent);
  ///   - otherwise import the cached image into AnkiDroid's media collection
  ///     and add the note whose Image field is the returned `<img>` tag. A null
  ///     media import is a retryable failure (the image stays cached).
  Future<AnkiExportResult> exportType2({required List<VocabPair> pairs}) async {
    final deckId = await gateway.ensureDeck(ankiDeckName);
    final modelId = await gateway.ensureModel(ankiType2Model);

    var added = 0;
    var skipped = 0;
    var failed = 0;
    var pending = 0;
    for (final pair in pairs) {
      final cached = await aiImageService.cachedPath(pair.uzbek);
      if (cached == null) {
        await aiImageService.enqueueGeneration(pair.uzbek);
        pending++;
        continue;
      }
      if (await gateway.hasNoteWithFirstField(
        modelId: modelId,
        firstField: pair.uzbek,
      )) {
        skipped++;
        continue;
      }
      final imageField = await gateway.addMedia(
        relativePath: cached,
        preferredName: 'rivendell_${_stem(cached)}',
      );
      if (imageField == null) {
        failed++;
        continue;
      }
      final id = await gateway.addNote(
        deckId: deckId,
        modelId: modelId,
        fields: [pair.uzbek, imageField],
        tags: const {ankiType2Tag},
      );
      if (id == null) {
        failed++;
      } else {
        added++;
      }
    }

    logger.i(
      LogTag.anki,
      'type2 export added=$added skipped=$skipped failed=$failed '
      'pending=$pending',
    );
    return AnkiExportResult(
      added: added,
      skipped: skipped,
      failed: failed,
      pending: pending,
    );
  }

  /// Filename stem of an app-relative image path (`a/b.png` → `b`).
  static String _stem(String relativePath) {
    final name = relativePath.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(0, dot) : name;
  }
}
