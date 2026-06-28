// coverage:ignore-file
//
// Drift schema for Rivendell's local-only, SQLCipher-encrypted store.
//
// Tables land with their milestones (recordings @ M1, review_events @ M2,
// word_logs @ M3, tasks/coach_notes @ M5, metrics_events @ M6). T0.2 ships a
// trivial `key_values` table to prove the seam end-to-end (open → migrate →
// round-trip) before any feature depends on it.
//
// Excluded from line-coverage: pure schema (column defs + a PK getter). The
// table is exercised end-to-end by [app_database_test.dart] round-trips.

import 'package:drift/drift.dart';

/// Proof-of-seam table (T0.2). Reused later as a generic KV store for small
/// app state (e.g. selected Samsung folder URI, last-rescan timestamp).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
