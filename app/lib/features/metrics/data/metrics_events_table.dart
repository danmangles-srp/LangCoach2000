// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Engagement metrics ledger (M6, FR-1.5.1). Append-only: each row is a single
// increment (e.g. +N ms of lesson duration, +N flashcards reviewed). The kind
// column discriminates the metric; T6.2 rolls these up into daily/weekly/
// monthly series. Two of the four FR-1.5.1 metrics are NOT stored here
// because they are derived directly from their source tables (so they can't
// drift out of sync): journaling_output ← word_logs kind='text', and
// completed_queue_items ← review_events. The stored kinds live in
// metric_kind.dart.

import 'package:drift/drift.dart';

class MetricsEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Which metric this increment belongs to (a metric_kind.dart name).
  TextColumn get kind => text()();

  /// The delta recorded by this event (ms for lesson duration, count
  /// otherwise). Always non-negative; the recorder sums across a window.
  IntColumn get value => integer()();

  /// When the increment happened. Drives the daily/weekly/monthly buckets.
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
}
