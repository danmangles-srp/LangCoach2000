// Type 1 Anki export (M4, FR-1.3.3, T4.2). Maps parsed English↔Uzbek pairs to
// AnkiDroid Type 1 notes in the Rivendell deck, tagged by the source
// recording. Idempotent: a word already present (matched on the model's first
// field, English) is skipped, so re-saving a text log never duplicates cards.
// AnkiDroid's addNote does not dedupe on its own — the [hasNoteWithFirstField]
// guard below is what makes re-export safe.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/anki/application/anki_gateway.dart';
import 'package:rivendell/features/anki/domain/anki_model_spec.dart';
import 'package:rivendell/features/anki/domain/anki_tag.dart';
import 'package:rivendell/features/wordlog/domain/vocab_pair.dart';

class AnkiExportResult {
  const AnkiExportResult({
    required this.added,
    required this.skipped,
    required this.failed,
  });

  /// Notes newly created this run.
  final int added;

  /// Pairs skipped because a note with that English first field already exists.
  final int skipped;

  /// Pairs whose insert returned no id (AnkiDroid failure), NOT dupes.
  final int failed;

  int get total => added + skipped + failed;

  @override
  String toString() => 'added=$added skipped=$skipped failed=$failed';
}

class AnkiExportService {
  AnkiExportService({required this.gateway, required this.logger});

  final AnkiGateway gateway;
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
}
