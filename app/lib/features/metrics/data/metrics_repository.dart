// Repository over [MetricsEvents] (T6.1, FR-1.5.1). Append-only ledger: callers
// record increments; [sum] rolls them up over a half-open time window. Pure
// logic over the Drift store — no platform deps, fully unit-tested. The two
// derived metrics (journaling output, completed queue items) are NOT written
// here; T6.2 reads them from word_logs / review_events directly.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/metrics/domain/metric_kind.dart';

class MetricsRepository {
  MetricsRepository(this._db);

  final AppDatabase _db;

  /// Append an increment of [value] for [kind], stamped at [at] (default now).
  /// [value] should be non-negative; the recorder does not guard against that
  /// because the only legitimate producers (player position, Anki export count)
  /// are already non-negative by construction.
  Future<void> record(MetricKind kind, int value, {DateTime? at}) {
    return _db
        .into(_db.metricsEvents)
        .insert(
          MetricsEventsCompanion.insert(
            kind: kind.columnValue,
            value: value,
            recordedAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  /// Sum every increment of [kind] whose recordedAt falls in [from, until)
  /// (half-open: an event exactly at [until] is excluded, matching "today's
  /// total" queries that start the next bucket at midnight).
  Future<int> sum(MetricKind kind, DateTime from, DateTime until) async {
    final expr = _db.metricsEvents.value.sum();
    final row =
        await (_db.selectOnly(_db.metricsEvents)
              ..addColumns([expr])
              ..where(
                _db.metricsEvents.kind.equals(kind.columnValue) &
                    _db.metricsEvents.recordedAt.isBiggerOrEqualValue(from) &
                    _db.metricsEvents.recordedAt.isSmallerThanValue(until),
              ))
            .getSingleOrNull();
    return row?.read(expr) ?? 0;
  }

  /// Every recorded increment of [kind] in [from, until), oldest first. Drives
  /// T6.2 bucketing when a simple sum isn't enough (e.g. daily series).
  Future<List<MetricsEvent>> eventsFor(
    MetricKind kind,
    DateTime from,
    DateTime until,
  ) {
    return (_db.select(_db.metricsEvents)
          ..where(
            (t) =>
                t.kind.equals(kind.columnValue) &
                t.recordedAt.isBiggerOrEqualValue(from) &
                t.recordedAt.isSmallerThanValue(until),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
  }
}
