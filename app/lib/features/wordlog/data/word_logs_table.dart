// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Drift schema for the GPA word log (M3, FR-1.3.1). One row per attached
// vocab artifact: a single text log and/or many notebook photos, linked to a
// recording. `kind` discriminates the two: 'text' (raw vocab list in `body`)
// or 'image' (an app-relative path to a copied JPG/PNG in `body`).
//
// "One text log per recording" (FR-1.3.1) is enforced by the repository's
// upsert, not the schema: re-attaching a text log replaces the prior row so
// there is never more than one. Images are append-only and unordered.

import 'package:drift/drift.dart';

import 'package:rivendell/features/audio/data/recordings_table.dart';

class WordLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The recording this artifact belongs to. Cascade-deleted with the
  /// recording so no orphaned text/images survive a recording delete.
  IntColumn get recordingId =>
      integer().references(Recordings, #id, onDelete: KeyAction.cascade)();

  TextColumn get kind => text()(); // 'text' | 'image'
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
