// Riverpod wiring for the metrics feature (T6.1, FR-1.5.1). The repository
// wraps the Drift store; producers (Anki export, the playback accumulator) read
// it to record increments. The dashboard (T6.3) reads derived series off it.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/metrics/data/metrics_repository.dart';

/// Singleton [MetricsRepository] over the local store.
final metricsRepositoryProvider = FutureProvider<MetricsRepository>(
  (ref) async => MetricsRepository(await ref.watch(appDatabaseProvider.future)),
);
