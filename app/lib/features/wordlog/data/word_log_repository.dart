// Repository over [WordLogs] (T3.1, FR-1.3.1). One text log and/or many image
// logs per recording. The text log is single-valued at the repository layer:
// re-attaching replaces the prior row (delete-then-insert in a transaction)
// so there is never more than one. Images are append-only.
//
// The recording link cascades on delete (see the FK in the table), so a
// recording vanishing also drops its word log — no orphaned text/images.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';

class WordLogRepository {
  WordLogRepository(this._db);

  final AppDatabase _db;

  /// Attach or replace the single text vocab log for [recordingId]. Runs in a
  /// transaction so the replace is atomic — a concurrent call can't leave two
  /// text rows.
  Future<void> setTextLog(int recordingId, {required String body}) {
    return _db.transaction(() async {
      await (_db.delete(_db.wordLogs)..where(
            (t) => t.recordingId.equals(recordingId) & t.kind.equals('text'),
          ))
          .go();
      await _db
          .into(_db.wordLogs)
          .insert(
            WordLogsCompanion.insert(
              recordingId: recordingId,
              kind: 'text',
              body: body,
            ),
          );
    });
  }

  /// The text log for [recordingId], or null if none attached.
  Future<WordLog?> textLogFor(int recordingId) {
    return (_db.select(_db.wordLogs)
          ..where(
            (t) => t.recordingId.equals(recordingId) & t.kind.equals('text'),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  /// Every text vocab log, newest first. Drives the Coach Bank attach picker
  /// (FR-1.4.3) — distinct from [allForRecording], which is per-recording.
  Future<List<WordLog>> allTextLogs() {
    return (_db.select(_db.wordLogs)
          ..where((t) => t.kind.equals('text'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// createdAts of every text log in [from, until), oldest first (T6.2 metric
  /// source for "Journaling Output"). Half-open: a log stamped exactly at
  /// [until] belongs to the next bucket. Image logs are excluded.
  Future<List<DateTime>> textLogTimestamps(DateTime from, DateTime until) {
    final rows =
        (_db.selectOnly(_db.wordLogs)
              ..addColumns([_db.wordLogs.createdAt])
              ..where(
                _db.wordLogs.kind.equals('text') &
                    _db.wordLogs.createdAt.isBiggerOrEqualValue(from) &
                    _db.wordLogs.createdAt.isSmallerThanValue(until),
              )
              ..orderBy([OrderingTerm.asc(_db.wordLogs.createdAt)]))
            .get();
    return rows.then((r) {
      return [
        for (final e in r)
          if (e.read(_db.wordLogs.createdAt) case final DateTime v) v,
      ];
    });
  }

  /// Attach a notebook photo. [path] is app-relative (the image was copied
  /// into app data by T3.3). Returns the new row. Append-only.
  Future<WordLog> addImage(int recordingId, {required String path}) {
    return _db
        .into(_db.wordLogs)
        .insertReturning(
          WordLogsCompanion.insert(
            recordingId: recordingId,
            kind: 'image',
            body: path,
          ),
        );
  }

  /// All image logs for [recordingId], newest first (createdAt then id).
  Future<List<WordLog>> imagesFor(int recordingId) {
    return (_db.select(_db.wordLogs)
          ..where(
            (t) => t.recordingId.equals(recordingId) & t.kind.equals('image'),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
  }

  /// Every word-log row for [recordingId] (text + images). Drives the player
  /// viewer panel (T3.4).
  Future<List<WordLog>> allForRecording(int recordingId) {
    return (_db.select(_db.wordLogs)
          ..where((t) => t.recordingId.equals(recordingId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Remove a single word-log row by id (delete-correction affordance).
  Future<void> delete(int id) {
    return (_db.delete(_db.wordLogs)..where((t) => t.id.equals(id))).go();
  }
}
