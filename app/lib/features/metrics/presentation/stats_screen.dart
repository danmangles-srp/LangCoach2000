// Stats dashboard (T6.3, FR-1.5.2, NFR-2.4.1). 4th bottom-nav tab. Renders the
// four FR-1.5.1 engagement metrics as native bar charts over a rolling window
// (daily/weekly/monthly). Premium Material 3 styling, empty state when no data.
//
// Reads [statsSnapshotProvider] (granularity-keyed). Toggle lives in the
// AppBar as a SegmentedButton. Each metric is a [BarChart] in a Card with a
// headline total above it.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/application/metrics_providers.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/l10n/app_strings.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final granularity = ref.watch(statsGranularityProvider);
    final async = ref.watch(statsSnapshotProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.statsTitle),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<MetricsGranularity>(
              segments: [
                ButtonSegment(
                  value: MetricsGranularity.daily,
                  label: Text(strings.statsGranularityDaily),
                ),
                ButtonSegment(
                  value: MetricsGranularity.weekly,
                  label: Text(strings.statsGranularityWeekly),
                ),
                ButtonSegment(
                  value: MetricsGranularity.monthly,
                  label: Text(strings.statsGranularityMonthly),
                ),
              ],
              selected: {granularity},
              onSelectionChanged: (s) =>
                  ref.read(statsGranularityProvider.notifier).selection =
                      s.first,
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(statsSnapshotProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (snapshot) {
          if (_allZero(snapshot)) {
            return _StatusView(
              icon: Icons.insights_rounded,
              message: strings.statsEmptyTitle,
              body: strings.statsEmptyBody,
            );
          }
          return Scrollbar(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _MetricChartCard(
                  title: strings.statsMetricLessonDuration,
                  totalLabel: _formatDuration(snapshot.lessonDuration.total),
                  series: snapshot.lessonDuration,
                  granularity: snapshot.granularity,
                ),
                _MetricChartCard(
                  title: strings.statsMetricJournalingOutput,
                  totalLabel: '${snapshot.journalingOutput.total}',
                  series: snapshot.journalingOutput,
                  granularity: snapshot.granularity,
                ),
                _MetricChartCard(
                  title: strings.statsMetricCompletedQueueItems,
                  totalLabel: '${snapshot.completedQueueItems.total}',
                  series: snapshot.completedQueueItems,
                  granularity: snapshot.granularity,
                ),
                _MetricChartCard(
                  title: strings.statsMetricFlashcardsReviewed,
                  totalLabel: '${snapshot.flashcardsReviewed.total}',
                  series: snapshot.flashcardsReviewed,
                  granularity: snapshot.granularity,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _allZero(DashboardSnapshot s) =>
      s.lessonDuration.total == 0 &&
      s.journalingOutput.total == 0 &&
      s.completedQueueItems.total == 0 &&
      s.flashcardsReviewed.total == 0;

  static String _formatDuration(int ms) {
    if (ms <= 0) return '0m';
    final mins = ms ~/ 60000;
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _MetricChartCard extends StatelessWidget {
  const _MetricChartCard({
    required this.title,
    required this.totalLabel,
    required this.series,
    required this.granularity,
  });

  final String title;
  final String totalLabel;
  final MetricSeries series;
  final MetricsGranularity granularity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final maxY = _maxY();
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  totalLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 128,
              child: Semantics(
                label: '$title chart, total $totalLabel',
                excludeSemantics: true,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _labelInterval.toDouble(),
                          getTitlesWidget: (value, _) =>
                              _bottomTitle(value, context),
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      for (var i = 0; i < series.points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: series.points[i].value.toDouble(),
                              color: color,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxY() {
    final max = series.points.fold<int>(0, (m, p) => p.value > m ? p.value : m);
    if (max == 0) return 1;
    // Headroom so the tallest bar doesn't kiss the top edge.
    return max * 1.2;
  }

  int get _labelInterval => switch (granularity) {
    MetricsGranularity.daily => 3, // label every ~3rd day across 14
    MetricsGranularity.weekly => 1, // every week
    MetricsGranularity.monthly => 1, // every month
  };

  Widget _bottomTitle(double value, BuildContext context) {
    final i = value.toInt();
    if (i < 0 || i >= series.points.length) return const SizedBox.shrink();
    final date = series.points[i].bucketStart;
    final fmt = switch (granularity) {
      MetricsGranularity.daily => DateFormat('d/M'),
      MetricsGranularity.weekly => DateFormat('d/M'),
      MetricsGranularity.monthly => DateFormat('MMM'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        fmt.format(date),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
    this.body,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = this.body;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
