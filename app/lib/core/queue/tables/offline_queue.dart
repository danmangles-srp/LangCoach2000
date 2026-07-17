// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Drift schema for the persistent offline queue (NFR-2.1.3).
//
// Network-dependent work (AI image generation FR-1.3.4, email reports
// FR-1.5.3) is enqueued here when offline and drained by QueueProcessor when
// connectivity returns. The queue is the single source of truth for pending
// work — it survives process death because it lives in the Drift store.

import 'package:drift/drift.dart';

/// Persisted offline work item.
///
/// `type` names the handler registered with QueueWorker
/// (e.g. `ai_image`, `email`). `payload` is a feature-defined JSON blob the
/// handler knows how to interpret.
class OfflineQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    // (type, payload) dedup is enforced as a PARTIAL unique index, created in
    // the v10 migration (see AppDatabase.migration), not here — Drift's table-
    // level uniqueKeys can't express "only among pending rows". The partial
    // index `offline_queue_pending_uniq ON (type, payload) WHERE done = 0`
    // means a replay of the same item while one is pending is a no-op; once
    // that row is markDone (done = 1) it leaves the pending set, so a later
    // replay can enqueue a fresh pending row.
  ];
}
