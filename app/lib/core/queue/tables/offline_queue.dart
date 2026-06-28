// Drift schema for the persistent offline queue (NFR-2.1.3).
//
// Network-dependent work (AI image generation FR-1.3.4, email reports
// FR-1.5.3) is enqueued here when offline and drained by QueueProcessor when
// connectivity returns. The queue is the single source of truth for pending
// work — it survives process death because it lives in the Drift store.

import 'package:drift/drift.dart';

/// Persisted offline work item.
///
/// `type` names the handler registered with QueueProcessor
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
    // No dup constraint by design: replaying the same action (e.g. regenerating
    // an image) appends a new item — the handler decides idempotency.
  ];
}
