// Repository over [XpEvents] (M11 T11.2, AC 2). The single insert path for XP
// awards: every awarding site (review completion, word-log attach, Anki export,
// task done, reading/movie log) funnels through [record]. [total] rolls up the
// ledger for the dashboard (T11.5). Pure logic over the Drift store.
//
// Same-transaction awards: when [record] is called inside another repo's
// `_db.transaction` (e.g. ReviewEventRepository.recordReview), the insert
// joins that ambient transaction because this repo shares the same
// [AppDatabase]. A throw after the award rolls the XP row back with the
// triggering write — no orphan award for a failed append.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';

class XpRepository {
  XpRepository(this._db);

  final AppDatabase _db;

  /// Append an XP award of [points] for [source], stamped at [at] (default
  /// now). [recordingId]/[taskId] trace the award to its origin when one
  /// exists (nullable — a reading/movie log carries neither). [points] should
  /// be non-negative; the award sites compute it.
  Future<void> record({
    required XpSource source,
    required int points,
    int? recordingId,
    int? taskId,
    DateTime? at,
  }) {
    return _db
        .into(_db.xpEvents)
        .insert(
          XpEventsCompanion.insert(
            source: source.columnValue,
            points: points,
            recordingId: Value(recordingId),
            taskId: Value(taskId),
            at: Value(at ?? DateTime.now()),
          ),
        );
  }

  /// Sum of every awarded point — the XP total (T11.5 reads this for the level
  /// + progress bar). Null-safe: an empty ledger sums to 0.
  Future<int> total() async {
    final expr = _db.xpEvents.points.sum();
    final row = await (_db.selectOnly(
      _db.xpEvents,
    )..addColumns([expr])).getSingleOrNull();
    return row?.read(expr) ?? 0;
  }
}
