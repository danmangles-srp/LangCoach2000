// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Drift schema for indexed recordings (M1, FR-1.1.1/FR-1.1.2).
//
// One row per audio file in the user-designated Samsung Voice Recorder
// directory. `filePath` is the stable identity (absolute path or SAF URI) and
// is unique, so re-indexing upserts instead of duplicating. `durationMs` is
// nullable: the indexer reads filesystem metadata only (cheap, scales to
// 1000 files < 2s per NFR-2.2.1); duration is filled lazily on first play
// (FR-1.2.3's 80%-played rule needs it, but decoding every file at index time
// would blow the budget).

import 'package:drift/drift.dart';

class Recordings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sizeBytes => integer()();
  TextColumn get format => text()();
  IntColumn get durationMs => integer().nullable()();
  DateTimeColumn get indexedAt => dateTime().withDefault(currentDateAndTime)();

  /// `filePath` is the upsert key: the same file re-indexed updates in place.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {filePath},
  ];
}
