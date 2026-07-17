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
    required this.createdAt,
    this.lastError,
  });
  final int id;
  final String type;
  final String payload;
  final int attempts;
  final DateTime createdAt;
  final String? lastError;
}

class QueueRepository {
  QueueRepository(this._db);
  final AppDatabase _db;

  /// Append a work item. Idempotent among pending rows: a `(type, payload)`
  /// already pending (done = 0) is a no-op (T18.1 — enforced by the partial
  /// unique index `offline_queue_pending_uniq`). Returns the inserted rowid;
  /// on a duplicate the insert is skipped, so do NOT read the return value as
  /// a dedup signal (it reflects `last_insert_rowid()`, not whether this call
  /// inserted). Use [pending] to observe state.
  Future<int> enqueue({required String type, required String payload}) {
    return _db
        .into(_db.offlineQueueItems)
        .insert(
          OfflineQueueItemsCompanion.insert(type: type, payload: payload),
          mode: InsertMode.insertOrIgnore,
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
    return rows.map(_toItem).toList();
  }

  /// Pending items of a single [type], in enqueue order. Backs the per-feature
  /// queue-review UI (e.g. AI image attempts awaiting drain).
  Future<List<QueueItem>> pendingByType(String type) async {
    final rows =
        await (_db.select(_db.offlineQueueItems)
              ..where((t) => t.done.equals(false) & t.type.equals(type))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toItem).toList();
  }

  /// Reactive signal over the pending set: emits whenever a pending row is
  /// inserted, completed (done=1), failed (attempts bumped), or deleted. The
  /// worker drains on this (T19.2) so an enqueue during an already-online
  /// foreground session fires a drain without a network edge; the queue-review
  /// snapshot re-fetches on this so the UI is live without manual refresh.
  /// Emits void — observers re-query via [pending] / [pendingByType].
  Stream<void> pendingChanges() {
    final query = _db.select(_db.offlineQueueItems)
      ..where((t) => t.done.equals(false));
    return query.watch().map((rows) {});
  }

  QueueItem _toItem(OfflineQueueItem r) => QueueItem(
    id: r.id,
    type: r.type,
    payload: r.payload,
    attempts: r.attempts,
    createdAt: r.createdAt,
    lastError: r.lastError,
  );

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

  /// Reset the attempt counter + error for a pending item (a manual "retry"
  /// affordance zeroes the failure history before the next drain).
  Future<void> resetAttempts(int id) {
    return (_db.update(
      _db.offlineQueueItems,
    )..where((t) => t.id.equals(id))).write(
      const OfflineQueueItemsCompanion(
        attempts: Value(0),
        lastError: Value(null),
      ),
    );
  }

  /// Hard-delete an item. Used by the queue-review "cancel" affordance to drop
  /// a pending item the user no longer wants retried (markDone would leave the
  /// row in the completed history).
  Future<void> delete(int id) {
    return (_db.delete(
      _db.offlineQueueItems,
    )..where((t) => t.id.equals(id))).go();
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
