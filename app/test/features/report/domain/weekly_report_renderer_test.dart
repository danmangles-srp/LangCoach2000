// WeeklyReportRenderer test (T6.4, FR-1.5.3). Pure Dart — feed a fixed weekly
// DashboardSnapshot, assert the generated HTML contains the date range, the
// four metric totals (duration formatted), and the brand styling. Empty and
// populated cases both covered.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/report/domain/weekly_report_renderer.dart';

// 8 Saturdays: 2026-05-23 .. 2026-07-11. Window spans [2026-05-23, 2026-07-18).
final _buckets = [
  for (var i = 0; i < 8; i++) DateTime(2026, 5, 23).add(Duration(days: 7 * i)),
];

MetricSeries _series(List<int> values) {
  final max = values.length > _buckets.length ? _buckets.length : values.length;
  final points = <MetricSeriesPoint>[];
  for (var i = 0; i < _buckets.length; i++) {
    points.add(
      MetricSeriesPoint(
        bucketStart: _buckets[i],
        value: i < max ? values[i] : 0,
      ),
    );
  }
  return MetricSeries(points);
}

DashboardSnapshot _snapshot({
  List<int> lessonMsPerWeek = const [],
  List<int> journalPerWeek = const [],
  List<int> queuePerWeek = const [],
  List<int> flashPerWeek = const [],
}) {
  return DashboardSnapshot(
    window: MetricsWindow(
      from: DateTime(2026, 5, 23),
      until: DateTime(2026, 7, 18),
    ),
    granularity: MetricsGranularity.weekly,
    lessonDuration: _series(lessonMsPerWeek),
    journalingOutput: _series(journalPerWeek),
    completedQueueItems: _series(queuePerWeek),
    flashcardsReviewed: _series(flashPerWeek),
  );
}

void main() {
  const renderer = WeeklyReportRenderer();

  test('produces a complete HTML document', () {
    final html = renderer.render(_snapshot(lessonMsPerWeek: [60000]));
    expect(html, startsWith('<!DOCTYPE html>'));
    expect(html, contains('</html>'));
    expect(html, contains('<html'));
    expect(html, contains('<head>'));
    expect(html, contains('<body'));
  });

  test('includes the weekly date range in the header', () {
    final html = renderer.render(_snapshot());
    // Window spans 2026-05-23 .. 2026-07-18.
    expect(html, contains('2026'));
    expect(html, contains('May'));
    expect(html, contains('Jul'));
  });

  test('renders all four metric totals with labels', () {
    final html = renderer.render(
      _snapshot(
        lessonMsPerWeek: [4_500_000], // 1h 15m in week 0
        journalPerWeek: [3, 0, 5],
        queuePerWeek: [2],
        flashPerWeek: [10],
      ),
    );
    expect(html, contains('Lesson time'));
    expect(html, contains('1h 15m'));
    expect(html, contains('Vocab logs'));
    expect(html, contains('Reviews done'));
    expect(html, contains('Flashcards'));
  });

  test('formats duration across hours, minutes, and zero', () {
    String renderDuration(int ms) =>
        renderer.render(_snapshot(lessonMsPerWeek: [ms]));

    expect(renderDuration(0), contains('0m'));
    expect(renderDuration(60_000), contains('1m'));
    expect(renderDuration(3_600_000), contains('1h'));
    expect(renderDuration(5_400_000), contains('1h 30m')); // 90 min
  });

  test('renders gracefully when every metric is zero', () {
    final html = renderer.render(_snapshot());
    expect(html, contains('Lesson time'));
    expect(html, contains('0m'));
    // No NaN or unevaluated placeholders.
    expect(html, isNot(contains('NaN')));
    expect(html, isNot(contains('null')));
  });

  test('embeds the brand accent color for email-client fidelity', () {
    final html = renderer.render(_snapshot());
    expect(html, contains('#2E7D6B'));
  });

  test('each metric section lists its weekly buckets as rows', () {
    final html = renderer.render(
      _snapshot(journalPerWeek: [1, 2, 3, 4, 5, 6, 7, 8]),
    );
    final vocabSection = html.substring(html.indexOf('Vocab logs'));
    expect('week-row'.allMatches(vocabSection).length, greaterThanOrEqualTo(8));
  });
}
