// StatsScreen widget test (T6.3). Overrides [statsSnapshotProvider] with fixed
// snapshots to verify the four metric cards render, the granularity toggle
// updates provider state, and the empty state shows when all series are zero.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/metrics/application/metrics_aggregation_service.dart';
import 'package:rivendell/features/metrics/application/metrics_providers.dart';
import 'package:rivendell/features/metrics/domain/metrics_aggregator.dart';
import 'package:rivendell/features/metrics/domain/metrics_window.dart';
import 'package:rivendell/features/metrics/presentation/stats_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

DashboardSnapshot _snapshot({
  int lessonMs = 0,
  int journal = 0,
  int queue = 0,
  int flash = 0,
}) {
  // Single bucket so the per-bucket value equals the series total — keeps the
  // headline-number assertions readable.
  MetricSeries seriesFor(int v) => MetricSeries([
    MetricSeriesPoint(bucketStart: DateTime(2026, 7), value: v),
  ]);
  return DashboardSnapshot(
    window: MetricsWindow(from: DateTime(2026, 7), until: DateTime(2026, 7, 4)),
    granularity: MetricsGranularity.daily,
    lessonDuration: seriesFor(lessonMs),
    journalingOutput: seriesFor(journal),
    completedQueueItems: seriesFor(queue),
    flashcardsReviewed: seriesFor(flash),
  );
}

Widget _harness(ProviderContainer container, {required Widget child}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppStrings.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('renders all four metric cards + totals', (tester) async {
    // Tall viewport so the lazy ListView builds all four cards.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        statsSnapshotProvider.overrideWith(
          (ref) async =>
              _snapshot(lessonMs: 4_500_000, journal: 3, queue: 2, flash: 10),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, child: const StatsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Lesson time'), findsOneWidget);
    expect(find.text('1h 15m'), findsOneWidget);
    expect(find.text('Vocab logs'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Reviews done'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('shows empty state when all series are zero', (tester) async {
    final container = ProviderContainer(
      overrides: [
        statsSnapshotProvider.overrideWith((ref) async => _snapshot()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, child: const StatsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No data yet'), findsOneWidget);
    expect(find.text('Lesson time'), findsNothing);
  });

  testWidgets('tapping Weekly updates the granularity provider', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        statsSnapshotProvider.overrideWith(
          (ref) async => _snapshot(lessonMs: 60_000),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, child: const StatsScreen()));
    await tester.pumpAndSettle();

    expect(container.read(statsGranularityProvider), MetricsGranularity.daily);

    await tester.tap(find.text('Weekly'));
    await tester.pump();

    expect(container.read(statsGranularityProvider), MetricsGranularity.weekly);
  });
}
