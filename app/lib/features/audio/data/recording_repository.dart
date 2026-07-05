// Repository over [Recordings]. Pure logic over the Drift store — no
// platform deps — so the upsert/reconcile contract is unit-tested via the
// in-memory executor. The platform scan (dir walk + stat) produces
// [ScannedFile]s and hands them here; this layer owns identity + ordering.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';

/// A filesystem entry the indexer discovered: enough to upsert a recording
/// row without touching the platform. Produced by the platform scan layer.
class ScannedFile {
  const ScannedFile({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.format,
  });

  final String path;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
  final AudioFormat format;
}

class RecordingRepository {
  RecordingRepository(this._db);

  final AppDatabase _db;

  /// All recordings, newest file first (matches the library list order).
  /// `id` is a secondary key so same-`createdAt` rows stay in a stable order —
  /// batch recordings share a timestamp (Android `stat()` is second-grained).
  Future<List<Recording>> all() {
    return (_db.select(_db.recordings)..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.desc(t.id),
        ]))
        .get();
  }

  /// Look up a recording by its row id. The detail screen (T1.6) keys off this
  /// so a deep link or process-death restore resolves without the list. Returns
  /// `null` for a stale/deleted id — callers degrade to a "not found" state.
  Future<Recording?> findById(int id) {
    return (_db.select(
      _db.recordings,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Look up a recording by its stable file path (SAF URI / absolute path).
  Future<Recording?> findByPath(String filePath) {
    return (_db.select(
      _db.recordings,
    )..where((t) => t.filePath.equals(filePath))).getSingleOrNull();
  }

  /// Upsert a batch of scanned files. New paths insert; known paths update
  /// their mutable stat (name/createdAt/sizeBytes/format) while preserving
  /// `durationMs` and `id`. Returns the number of input files written (inserts
  /// + updates), NOT distinct rows — a re-scan of an unchanged directory
  /// returns the input size, so callers needing "new since last scan" must
  /// diff against prior state themselves.
  ///
  /// Batched into one transaction so a 1000-file scan commits once
  /// (NFR-2.2.1 — indexing must not thrash the store).
  Future<int> upsertScanned(List<ScannedFile> files) async {
    if (files.isEmpty) return 0;
    await _db.batch((batch) {
      for (final f in files) {
        batch.insert(
          _db.recordings,
          RecordingsCompanion.insert(
            filePath: f.path,
            name: f.name,
            createdAt: f.createdAt,
            sizeBytes: f.sizeBytes,
            format: f.format.name,
          ),
          onConflict: DoUpdate(
            (_) => RecordingsCompanion(
              name: Value(f.name),
              createdAt: Value(f.createdAt),
              sizeBytes: Value(f.sizeBytes),
              format: Value(f.format.name),
            ),
            target: [_db.recordings.filePath],
          ),
        );
      }
    });
    return files.length;
  }

  /// Record a recording's duration once known (filled lazily at first play).
  Future<void> setDuration(int id, {required int durationMs}) {
    return (_db.update(_db.recordings)..where((t) => t.id.equals(id))).write(
      RecordingsCompanion(durationMs: Value(durationMs)),
    );
  }

  /// Update a recording's display name and file path atomically (T10.4). The
  /// SAF file rename returns a new document URI (the URI stem can change on
  /// rename), so both columns move together to keep the next rescan keyed on
  /// the new path instead of re-adding the row.
  Future<void> updateNameAndPath(
    int id, {
    required String name,
    required String filePath,
  }) {
    return (_db.update(_db.recordings)..where((t) => t.id.equals(id))).write(
      RecordingsCompanion(name: Value(name), filePath: Value(filePath)),
    );
  }

  /// Delete a recording row by id (T10.5). Schema FKs cascade — this single
  /// delete also drops the recording's `review_events`, `word_logs`, and
  /// coach-bank join rows (`coach_note_recordings`, and
  /// `coach_note_word_logs` via the word-log cascade). Image *files* under
  /// app-private storage are cleaned up by the management service before this
  /// runs; the audio file in the Samsung folder is deleted by it too.
  Future<int> deleteById(int id) {
    return (_db.delete(_db.recordings)..where((t) => t.id.equals(id))).go();
  }
}

/// Decode a stored recording's `format` text back to the typed enum.
///
/// Returns `null` for a value outside [AudioFormat]. The column is free text,
/// so a manual edit, stale build, or future migration could write something
/// unknown — degrading to `null` keeps a single bad row from crashing the list
/// UI instead of `AudioFormat.values.byName` throwing `ArgumentError`.
AudioFormat? formatOf(Recording recording) {
  for (final f in AudioFormat.values) {
    if (f.name == recording.format) return f;
  }
  return null;
}
