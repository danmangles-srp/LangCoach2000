// Repository over [OfflineQueueItems]. Pure logic over the Drift store — no
// platform deps, fully unit-tested.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';

/// A pending (or done) offline work item.
class QueueItem {
  QueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.attempts,
    this.lastError,
  });
  final int id;
  final String type;
  final String payload;
  final int attempts;
  final String? lastError;
}

class QueueRepository {
  QueueRepository(this._db);
  final AppDatabase _db;

  /// Append a work item. Returns its id.
  Future<int> enqueue({required String type, required String payload}) {
    return _db
        .into(_db.offlineQueueItems)
        .insert(
          OfflineQueueItemsCompanion.insert(type: type, payload: payload),
        );
  }

  /// All items not yet completed, in enqueue order. Ordered by the
  /// autoincrement `id` (not `createdAt`) so two enqueues in the same clock
  /// tick still return in insertion order.
  Future<List<QueueItem>> pending() async {
    final rows =
        await (_db.select(_db.offlineQueueItems)
              ..where((t) => t.done.equals(false))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows
        .map(
          (r) => QueueItem(
            id: r.id,
            type: r.type,
            payload: r.payload,
            attempts: r.attempts,
            lastError: r.lastError,
          ),
        )
        .toList();
  }

  /// Count of pending items (for UI badges / status).
  Future<int> pendingCount() async {
    final count = _db.offlineQueueItems.id.count();
    final expr = _db.selectOnly(_db.offlineQueueItems)
      ..addColumns([count])
      ..where(_db.offlineQueueItems.done.equals(false));
    final row = await expr.getSingle();
    return row.read(count) ?? 0;
  }

  /// Mark an item completed.
  Future<void> markDone(int id) {
    return (_db.update(_db.offlineQueueItems)..where((t) => t.id.equals(id)))
        .write(const OfflineQueueItemsCompanion(done: Value(true)));
  }

  /// Record a failed attempt with the error, bumping the attempt counter.
  /// Raw SQL so the increment is atomic (companion writes can't express
  /// `attempts = attempts + 1`).
  Future<void> markFailed(int id, {required String error}) {
    return _db.customStatement(
      'UPDATE offline_queue_items '
      'SET attempts = attempts + 1, last_error = ? '
      'WHERE id = ?',
      [error, id],
    );
  }

  /// Remove completed items older than [before]. Keeps recent history for the
  /// "last sent" indicator without unbounded growth.
  Future<int> pruneDone({required DateTime before}) {
    return (_db.delete(_db.offlineQueueItems)..where(
          (t) => t.done.equals(true) & t.createdAt.isSmallerThanValue(before),
        ))
        .go();
  }
}
