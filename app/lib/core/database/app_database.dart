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
import 'package:rivendell/features/gpa/data/review_events_table.dart';
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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
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
    },
    beforeOpen: (details) async {
      // Enforce FK constraints on every open (off by default in SQLite).
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}
