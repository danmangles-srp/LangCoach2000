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
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';
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
    this.xp,
  });

  final AnkiGateway gateway;
  final AiImageService aiImageService;
  final AppLogger logger;

  /// Optional XP sink (M11 T11.2). When wired, a run awards +2 per newly
  /// created note (only `added`, not skipped/failed/pending). Null in tests
  /// that don't care.
  final XpRepository? xp;

  /// Award +2 × [added] (canonical, per card created). No-op when [added] is
  /// 0 (a pure-skip or all-failed run earns nothing) or when the sink is null.
  Future<void> _awardXp(int added) => added <= 0
      ? Future.value()
      : xp?.record(source: XpSource.anki, points: 2 * added) ?? Future.value();

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
    await _awardXp(added);
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
        await aiImageService.enqueueGeneration(
          uzbek: pair.uzbek,
          english: pair.english,
        );
        logger.i(
          LogTag.anki,
          'type2 "${pair.uzbek}": image not cached → enqueued, deferred',
        );
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
        logger.w(
          LogTag.anki,
          'type2 "${pair.uzbek}": addMedia returned null '
          '(relativePath=$cached) — AnkiDroid refused the import',
        );
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
        logger.w(
          LogTag.anki,
          'type2 "${pair.uzbek}": addNote returned null — insert failed',
        );
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
    await _awardXp(added);
    return AnkiExportResult(
      added: added,
      skipped: skipped,
      failed: failed,
      pending: pending,
    );
  }

  /// Best-effort single-word Type 2 export. Closes the gap where a word had no
  /// cached image when the user tapped Export (deferred as pending) but its
  /// image has since finished generating: the queue handler calls this once
  /// the image lands so the card attaches without a manual re-export.
  /// Idempotent via the first-field guard.
  ///
  /// Only the Uzbek word is known at this boundary (the post-generation hook
  /// fires with the cache key). T19.3 split the prompt onto the English gloss,
  /// so an UNCACHED word here cannot be re-enqueued (no english to prompt from)
  /// — but the hook only fires after a successful generation, so uncached is a
  /// no-op race rather than a re-queue. Returns an empty result in that case.
  Future<AnkiExportResult> exportType2Word(String uzbekWord) async {
    if (await aiImageService.cachedPath(uzbekWord) == null) {
      return const AnkiExportResult(added: 0, skipped: 0, failed: 0);
    }
    return exportType2(
      pairs: [VocabPair(english: '', uzbek: uzbekWord)],
    );
  }

  /// Filename stem of an app-relative image path (`a/b.png` → `b`).
  static String _stem(String relativePath) {
    final name = relativePath.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(0, dot) : name;
  }
}
