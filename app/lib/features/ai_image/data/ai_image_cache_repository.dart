// Repository over [AiImageCacheItems] (T4.3, FR-1.3.4). Pure logic over the
// Drift store — no platform deps, fully unit-tested via AppDatabase.forTesting.
//
// The cache is the "is this word generated yet?" oracle. A row exists iff the
// image bytes are on disk; the queue handler inserts a row only after a
// successful Fal.ai round-trip + file write, so a present row is always usable.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';

/// One successfully generated image (the read model for the queue-review UI).
class AiImageCacheEntry {
  const AiImageCacheEntry({
    required this.uzbekWord,
    required this.relativePath,
    required this.createdAt,
  });
  final String uzbekWord;
  final String relativePath;
  final DateTime createdAt;
}

class AiImageCacheRepository {
  AiImageCacheRepository(this._db);

  final AppDatabase _db;

  /// The cached image's app-relative path for [uzbekWord], or null when the
  /// word has not yet been generated (placeholder territory).
  Future<String?> pathFor(String uzbekWord) async {
    final row = await (_db.select(
      _db.aiImageCacheItems,
    )..where((t) => t.uzbekWord.equals(uzbekWord))).getSingleOrNull();
    return row?.relativePath;
  }

  /// True iff a generated image exists for [uzbekWord].
  Future<bool> has(String uzbekWord) async =>
      (await pathFor(uzbekWord)) != null;

  /// Recently generated words, newest first. Backs the queue-review "completed"
  /// list — the authoritative success log (one row per word, written only after
  /// a Fal.ai round-trip + file write succeeds).
  Future<List<AiImageCacheEntry>> recent({int limit = 20}) async {
    final rows =
        await (_db.select(_db.aiImageCacheItems)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();
    return rows
        .map(
          (r) => AiImageCacheEntry(
            uzbekWord: r.uzbekWord,
            relativePath: r.relativePath,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  /// Record a successful generation. INSERT OR REPLACE on the `uzbekWord`
  /// unique key so a re-generation (e.g. after a manual "regenerate image"
  /// action) overwrites the old path rather than colliding. The table has a
  /// unique key (not a primary key), so this uses InsertMode.insertOrReplace
  /// rather than insertOnConflictUpdate, which would need a conflict target.
  Future<void> remember({
    required String uzbekWord,
    required String relativePath,
  }) {
    return _db
        .into(_db.aiImageCacheItems)
        .insert(
          AiImageCacheItemsCompanion.insert(
            uzbekWord: uzbekWord,
            relativePath: relativePath,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
