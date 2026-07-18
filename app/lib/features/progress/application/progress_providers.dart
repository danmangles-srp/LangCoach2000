// Riverpod wiring for the progress feature (M11 T11.2). The repository wraps
// the Drift store; every awarding site (review, word-log, Anki, task) reads
// this singleton to post XP. The dashboard snapshot lands in T11.5.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';

/// Singleton [XpRepository] over the local store. Shared by every awarding
/// site so an award called inside another repo's transaction joins it (Drift
/// ambient tx via the shared AppDatabase).
final xpRepositoryProvider = FutureProvider<XpRepository>(
  (ref) async => XpRepository(await ref.watch(appDatabaseProvider.future)),
);
