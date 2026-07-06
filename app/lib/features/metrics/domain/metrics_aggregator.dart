// Pure-Dart metric aggregation (T6.2, FR-1.5.1). Bucket raw events into
// per-granularity series. Two flavors: count metrics (one row = one event, e.g.
// a completed queue item or a journaling entry) and sum metrics (an event
// carries a delta, e.g. lesson-duration ms). Both drop events that fall
// outside the supplied bucket list so a dashboard's x-axis never leaks a
// stray point from before/after the visible range.
//
// Side-effect free + takes only data in → fully unit-tested without a device.

import 'package:rivendell/features/metrics/domain/metrics_window.dart';

/// One point in a metric series: the bucket start + the aggregated value.
class MetricSeriesPoint {
  const MetricSeriesPoint({required this.bucketStart, required this.value});

  final DateTime bucketStart;
  final int value;

  @override
  String toString() => 'MetricSeriesPoint($bucketStart, $value)';
}

/// A bucketed metric series over [points]. [total] is the sum across the whole
/// range — convenient for headline numbers ("this week: 4h 12m").
class MetricSeries {
  const MetricSeries(this.points);

  final List<MetricSeriesPoint> points;

  int get total => points.fold(0, (sum, p) => sum + p.value);

  @override
  String toString() => 'MetricSeries(total=$total, points=$points)';
}

/// A timestamped delta for sum metrics (e.g. lesson-duration ms increments).
typedef MetricEvent = ({DateTime at, int value});

/// Bucket a collection of events into a per-bucket value series. [at] extracts
/// the timestamp used to assign each event to a bucket; [value] extracts its
/// numeric contribution (1 for count metrics, the delta for sum metrics).
/// Events whose bucket is not in [buckets] are dropped.
///
/// Guards against a duplicate [buckets] entry, which would otherwise silently
/// attribute every event for that key to the last duplicate index and leave
/// the earlier index stuck at zero.
List<int> _bucketize<T>(
  List<DateTime> buckets,
  Iterable<T> events,
  DateTime Function(T) at,
  int Function(T) value, {
  required MetricsGranularity granularity,
  int weekStartWeekday = DateTime.saturday,
}) {
  assert(
    buckets.length == {...buckets}.length,
    'duplicate bucket starts in $buckets',
  );
  final out = List<int>.filled(buckets.length, 0);
  final index = {for (var i = 0; i < buckets.length; i++) buckets[i]: i};
  for (final e in events) {
    final key = bucketStart(
      granularity,
      at(e),
      weekStartWeekday: weekStartWeekday,
    );
    final i = index[key];
    if (i != null) out[i] += value(e);
  }
  return out;
}

/// Count the events whose bucket (per [granularity]) matches each bucket in
/// [buckets]. Events outside any listed bucket are dropped.
List<int> bucketizeCounts(
  List<DateTime> buckets,
  List<DateTime> events,
  MetricsGranularity granularity, {
  int weekStartWeekday = DateTime.saturday,
}) => _bucketize(
  buckets,
  events,
  (d) => d,
  (_) => 1,
  granularity: granularity,
  weekStartWeekday: weekStartWeekday,
);

/// Sum the values of [events] whose bucket (per [granularity]) matches each
/// bucket in [buckets]. Events outside any listed bucket are dropped.
List<int> bucketizeSums(
  List<DateTime> buckets,
  List<MetricEvent> events,
  MetricsGranularity granularity, {
  int weekStartWeekday = DateTime.saturday,
}) => _bucketize(
  buckets,
  events,
  (e) => e.at,
  (e) => e.value,
  granularity: granularity,
  weekStartWeekday: weekStartWeekday,
);

/// Build a count [MetricSeries] aligned to [buckets].
MetricSeries aggregateCounts(
  List<DateTime> buckets,
  List<DateTime> events,
  MetricsGranularity granularity, {
  int weekStartWeekday = DateTime.saturday,
}) {
  final values = bucketizeCounts(
    buckets,
    events,
    granularity,
    weekStartWeekday: weekStartWeekday,
  );
  return MetricSeries([
    for (var i = 0; i < buckets.length; i++)
      MetricSeriesPoint(bucketStart: buckets[i], value: values[i]),
  ]);
}

/// Build a sum [MetricSeries] aligned to [buckets].
MetricSeries aggregateSums(
  List<DateTime> buckets,
  List<MetricEvent> events,
  MetricsGranularity granularity, {
  int weekStartWeekday = DateTime.saturday,
}) {
  final values = bucketizeSums(
    buckets,
    events,
    granularity,
    weekStartWeekday: weekStartWeekday,
  );
  return MetricSeries([
    for (var i = 0; i < buckets.length; i++)
      MetricSeriesPoint(bucketStart: buckets[i], value: values[i]),
  ]);
}
