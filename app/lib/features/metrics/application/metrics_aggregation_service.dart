// MetricsAggregationService (T6.2, FR-1.5.1). The impure facade that pulls raw
// engagement rows from the four metric sources and buckets them into per-
// granularity series via the pure aggregator. The dashboard (T6.3) and the
// weekly report renderer (T6.4) both consume this — one aggregation pipeline,
// two presentation layers.
//
// The four FR-1.5.1 metrics:
//   1. Lesson Duration        — sum of metrics ledger kind=lessonDuration (ms)
//   2. Journaling Output      — count of word_logs kind='text'
//   3. Completed Queue items  — count of review_events
//   4. Flashcards reviewed    — sum of metrics ledger kind=flashcardsReviewed
//
// Every source query is half-open [from, until) so adjacent buckets partition
// time without double-counting, matching the pure aggregator's contract.

import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/metrics/data/metrics_repository.dart';
import 'package:rivendell/features/metrics/domain/metric_kind.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';

/// One engagement-metric snapshot over [window] at [granularity]. Every series
/// is aligned to the same bucket list so a dashboard can stack/compare them on
/// a shared x-axis.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.window,
    required this.granularity,
    required this.lessonDuration,
    required this.journalingOutput,
    required this.completedQueueItems,
    required this.flashcardsReviewed,
  });

  final MetricsWindow window;
  final MetricsGranularity granularity;

  /// Total lesson-listening time per bucket, in milliseconds.
  final MetricSeries lessonDuration;

  /// Number of text vocab-log entries per bucket.
  final MetricSeries journalingOutput;

  /// Number of completed GPA queue items (review events) per bucket.
  final MetricSeries completedQueueItems;

  /// Number of Anki cards reviewed per bucket.
  final MetricSeries flashcardsReviewed;
}

class MetricsAggregationService {
  MetricsAggregationService(this._metrics, this._wordLogs, this._reviewEvents);

  final MetricsRepository _metrics;
  final WordLogRepository _wordLogs;
  final ReviewEventRepository _reviewEvents;

  /// Build a [DashboardSnapshot] over [window] at [granularity]. All four
  /// series share the same bucket list derived from [window]. Pin
  /// [weekStartWeekday] to match the report cadence (default Saturday).
  Future<DashboardSnapshot> snapshot({
    required MetricsWindow window,
    required MetricsGranularity granularity,
    int weekStartWeekday = DateTime.saturday,
  }) async {
    final buckets = bucketsInRange(
      granularity,
      window.from,
      window.until,
      weekStartWeekday: weekStartWeekday,
    );

    // Kick all four range queries off before awaiting any of them — they're
    // independent, so snapshot latency is the max query time, not the sum.
    final lessonEventsFuture = _metrics.eventsFor(
      MetricKind.lessonDuration,
      window.from,
      window.until,
    );
    final flashEventsFuture = _metrics.eventsFor(
      MetricKind.flashcardsReviewed,
      window.from,
      window.until,
    );
    final journalTimestampsFuture = _wordLogs.textLogTimestamps(
      window.from,
      window.until,
    );
    final reviewTimestampsFuture = _reviewEvents.eventTimestamps(
      window.from,
      window.until,
    );
    final lessonEvents = await lessonEventsFuture;
    final flashEvents = await flashEventsFuture;
    final journalTimestamps = await journalTimestampsFuture;
    final reviewTimestamps = await reviewTimestampsFuture;

    return DashboardSnapshot(
      window: window,
      granularity: granularity,
      lessonDuration: aggregateSums(
        buckets,
        [for (final e in lessonEvents) (at: e.recordedAt, value: e.value)],
        granularity,
        weekStartWeekday: weekStartWeekday,
      ),
      flashcardsReviewed: aggregateSums(
        buckets,
        [for (final e in flashEvents) (at: e.recordedAt, value: e.value)],
        granularity,
        weekStartWeekday: weekStartWeekday,
      ),
      journalingOutput: aggregateCounts(
        buckets,
        journalTimestamps,
        granularity,
        weekStartWeekday: weekStartWeekday,
      ),
      completedQueueItems: aggregateCounts(
        buckets,
        reviewTimestamps,
        granularity,
        weekStartWeekday: weekStartWeekday,
      ),
    );
  }
}
