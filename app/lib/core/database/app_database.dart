// The single source of truth for Rivendell (NFR-2.1.2).
//
// SQLCipher-encrypted by default (NFR-2.4.2): the key is derived per-install
// and held in platform keystore. The platform-bound open path lives in
// [database_connection.dart]; this file holds the schema, the migration
// strategy, and the in-memory testing constructor — all pure Dart, unit-tested
// via [AppDatabase.forTesting].

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/tables/key_values.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests — no encryption, no file, no platform calls.
  factory AppDatabase.forTesting(QueryExecutor executor) =>
      AppDatabase(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Enforce FK constraints on every open (off by default in SQLite).
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );
}
