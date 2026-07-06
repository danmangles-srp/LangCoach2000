// Riverpod wiring for the metrics feature (T6.1, FR-1.5.1). The repository
// wraps the Drift store; producers (Anki export, the playback accumulator) read
// it to record increments. The dashboard (T6.3) reads derived series off it.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/gpa/data/review_event_repository.dart';
import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/data/metrics_repository.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';

/// Singleton [MetricsRepository] over the local store.
final metricsRepositoryProvider = FutureProvider<MetricsRepository>(
  (ref) async => MetricsRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Singleton [MetricsAggregationService] over the local store.
final metricsAggregationServiceProvider =
    FutureProvider<MetricsAggregationService>(
      (ref) async => MetricsAggregationService(
        MetricsRepository(await ref.watch(appDatabaseProvider.future)),
        WordLogRepository(await ref.watch(appDatabaseProvider.future)),
        ReviewEventRepository(await ref.watch(appDatabaseProvider.future)),
      ),
    );

/// Rolling window widths per granularity for the dashboard (T6.3): enough
/// buckets to show a trend without crowding a phone screen.
int _bucketsPerGranularity(MetricsGranularity g) => switch (g) {
  MetricsGranularity.daily => 14,
  MetricsGranularity.weekly => 8,
  MetricsGranularity.monthly => 6,
};

/// The half-open window from today-midnight-minus-N-buckets through tomorrow
/// midnight, covering the last N buckets of the given granularity ending today.
/// `until` is tomorrow's midnight so today is the final full bucket.
MetricsWindow dashboardWindow(MetricsGranularity g, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final buckets = _bucketsPerGranularity(g);
  final span = switch (g) {
    MetricsGranularity.daily => MetricsWindow(
      from: DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day - (buckets - 1),
      ),
      until: DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day + 1,
      ),
    ),
    MetricsGranularity.weekly => MetricsWindow(
      from: DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day - 7 * (buckets - 1),
      ),
      until: DateTime(
        todayMidnight.year,
        todayMidnight.month,
        todayMidnight.day + 1,
      ),
    ),
    MetricsGranularity.monthly => MetricsWindow(
      from: DateTime(todayMidnight.year, todayMidnight.month - (buckets - 1)),
      until: DateTime(todayMidnight.year, todayMidnight.month + 1),
    ),
  };
  return span;
}

/// Dashboard granularity selection (T6.3). Default daily.
class StatsGranularityNotifier extends Notifier<MetricsGranularity> {
  @override
  MetricsGranularity build() => MetricsGranularity.daily;

  MetricsGranularity get selection => state;
  set selection(MetricsGranularity g) => state = g;
}

final statsGranularityProvider =
    NotifierProvider<StatsGranularityNotifier, MetricsGranularity>(
      StatsGranularityNotifier.new,
    );

/// The current dashboard snapshot, derived from the selected granularity.
/// Watches [metricsAggregationServiceProvider] + [statsGranularityProvider]
/// and re-runs whenever either changes.
final statsSnapshotProvider = FutureProvider<DashboardSnapshot>((ref) async {
  final service = await ref.watch(metricsAggregationServiceProvider.future);
  final granularity = ref.watch(statsGranularityProvider);
  return service.snapshot(
    window: dashboardWindow(granularity),
    granularity: granularity,
  );
});
