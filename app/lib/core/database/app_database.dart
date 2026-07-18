// The single source of truth for Rivendell (NFR-2.1.2).
//
// SQLCipher-encrypted by default (NFR-2.4.2): the key is derived per-install
// and held in platform keystore. The platform-bound open path lives in
// `platform/database_connection.dart`; this file holds the schema, the
// migration strategy, and the in-memory testing constructor — all pure Dart,
// unit-tested via `forTesting`.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/tables/key_values.dart';
import 'package:rivendell/core/queue/tables/offline_queue.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_table.dart';
import 'package:rivendell/features/audio/data/recordings_table.dart';
import 'package:rivendell/features/coach/data/coach_note_recordings_table.dart';
import 'package:rivendell/features/coach/data/coach_note_word_logs_table.dart';
import 'package:rivendell/features/coach/data/coach_notes_table.dart';
import 'package:rivendell/features/gpa/data/review_events_table.dart';
import 'package:rivendell/features/metrics/data/metrics_events_table.dart';
import 'package:rivendell/features/progress/data/xp_events_table.dart';
import 'package:rivendell/features/tasks/data/tasks_table.dart';
import 'package:rivendell/features/wordlog/data/word_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    KeyValues,
    OfflineQueueItems,
    Recordings,
    ReviewEvents,
    WordLogs,
    AiImageCacheItems,
    Tasks,
    CoachNotes,
    CoachNoteRecordings,
    CoachNoteWordLogs,
    MetricsEvents,
    XpEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Internal — accepts any executor. Production MUST open through
  /// `openAppDatabase` (SQLCipher key applied); tests through `forTesting`.
  /// Constructing AppDatabase directly with a plaintext NativeDatabase
  /// bypasses encryption and violates NFR-2.4.2 — do not.
  AppDatabase(super.e);

  /// In-memory database for tests — no encryption, no file, no platform calls.
  factory AppDatabase.forTesting(QueryExecutor executor) =>
      AppDatabase(executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // T18.1: dedup-by-(type,payload) among pending rows. Created here for
      // fresh installs AND in the v10 onUpgrade for existing DBs.
      await _createPendingUniqueIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(offlineQueueItems);
      }
      if (from < 3) {
        await m.createTable(recordings);
      }
      if (from < 4) {
        await m.createTable(reviewEvents);
      }
      if (from < 5) {
        await m.createTable(wordLogs);
      }
      if (from < 6) {
        await m.createTable(aiImageCacheItems);
      }
      if (from < 7) {
        await m.createTable(tasks);
      }
      if (from < 8) {
        // Coach Bank (FR-1.4.3): notes + the two join tables that map them to
        // recordings and vocab logs. Order matters — the join tables reference
        // coach_notes, so it must exist first.
        await m.createTable(coachNotes);
        await m.createTable(coachNoteRecordings);
        await m.createTable(coachNoteWordLogs);
      }
      if (from < 9) {
        // Engagement metrics ledger (FR-1.5.1). Append-only increments; the
        // two derivable metrics (journaling output, completed queue items)
        // stay in their source tables and are not duplicated here.
        await m.createTable(metricsEvents);
      }
      if (from < 10) {
        // T18.1: collapse duplicate pending rows first (keep the lowest id per
        // (type, payload)), then add the partial unique index that stops spam-
        // enqueueing the same item while one is already pending.
        await customStatement(
          'DELETE FROM offline_queue_items WHERE done = 0 AND id NOT IN '
          '(SELECT MIN(id) FROM offline_queue_items '
          'WHERE done = 0 GROUP BY type, payload)',
        );
        await _createPendingUniqueIndex();
      }
      if (from < 11) {
        // M11 T11.1: append-only XP ledger. Level/total are derived from the
        // sum of `points`; FK traces to recordings/tasks SET NULL on delete so
        // earned XP survives a source-row deletion.
        await m.createTable(xpEvents);
      }
    },
    beforeOpen: (details) async {
      // Enforce FK constraints on every open (off by default in SQLite).
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  /// Partial unique index that dedups pending queue rows by (type, payload).
  /// A `done` row leaves the pending set, so a later replay can re-enqueue.
  Future<void> _createPendingUniqueIndex() => customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS offline_queue_pending_uniq '
    'ON offline_queue_items (type, payload) WHERE done = 0',
  );
}
