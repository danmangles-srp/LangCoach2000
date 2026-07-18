// Repository over [ActivityLogs] (M11 T11.4, AC 2). The single mutation site
// for manual reading/movie entries: an [add] inserts the row AND fires the
// +15 XP hook in the SAME transaction (ambient Drift join via the shared db),
// so a failed award rolls the log back — no orphan activity with no XP. XP is
// informational; nothing is gated on it (plan M11).

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/activity_kind.dart';

class ActivityLogRepository {
  ActivityLogRepository(this._db, {this.xp});

  final AppDatabase _db;

  /// Optional XP sink (M11 T11.2). When wired, [add] awards +15 in the same
  /// transaction as the insert. Null in tests that don't care.
  final XpRepository? xp;

  /// Insert a logged activity and award +15 (canonical). [durationMinutes] is
  /// optional; [at] defaults to now. The award joins the insert's transaction.
  Future<void> add({
    required ActivityKind kind,
    required String title,
    int? durationMinutes,
    DateTime? at,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.activityLogs)
          .insert(
            ActivityLogsCompanion.insert(
              kind: kind.columnValue,
              title: title,
              durationMinutes: durationMinutes == null
                  ? const Value.absent()
                  : Value(durationMinutes),
              at: at == null ? const Value.absent() : Value(at),
            ),
          );
      await xp?.record(source: kind.xpSource, points: 15, at: at);
    });
  }

  /// All logs, newest first (the dashboard list reads this, T11.5).
  Future<List<ActivityLog>> all() {
    return (_db.select(
      _db.activityLogs,
    )..orderBy([(t) => OrderingTerm.desc(t.at)])).get();
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.activityLogs)..where((t) => t.id.equals(id))).go();
  }
}
