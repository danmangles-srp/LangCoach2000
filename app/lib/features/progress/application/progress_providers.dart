// Riverpod wiring for the progress feature (M11). The XP repository (T11.2) is
// shared by every awarding site; the streak service (T11.3) derives the streak
// + freeze balance for the dashboard (T11.5). Both are singletons over the
// local store.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';
import 'package:rivendell/features/progress/application/streak_service.dart';
import 'package:rivendell/features/progress/data/activity_log_repository.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';

/// Singleton [XpRepository] over the local store. Shared by every awarding
/// site so an award called inside another repo's transaction joins it (Drift
/// ambient tx via the shared AppDatabase).
final xpRepositoryProvider = FutureProvider<XpRepository>(
  (ref) async => XpRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Singleton [KvRepository] for progress state (the freeze bank). Scoped per
/// the codebase convention — each feature owns its KV provider.
final progressKvRepositoryProvider = FutureProvider<KvRepository>(
  (ref) async => KvRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Singleton [StreakService]. [DateTime.now] is injected so the asOf boundary
/// is deterministic in tests.
final streakServiceProvider = FutureProvider<StreakService>(
  (ref) async => StreakService(
    kv: await ref.watch(progressKvRepositoryProvider.future),
    reviews: await ref.watch(reviewEventRepositoryProvider.future),
    now: DateTime.now,
  ),
);

/// Singleton [ActivityLogRepository] (T11.4). Wired with the XP sink so an
/// [ActivityLogRepository.add] award joins the insert's transaction.
final activityLogRepositoryProvider = FutureProvider<ActivityLogRepository>(
  (ref) async => ActivityLogRepository(
    await ref.watch(appDatabaseProvider.future),
    xp: await ref.watch(xpRepositoryProvider.future),
  ),
);

/// The logged activities, newest first (the dashboard list reads this, T11.5).
/// Re-read on invalidate (after an add/delete via logActivity).
final activityLogsProvider = FutureProvider<List<ActivityLog>>(
  (ref) async => (await ref.watch(activityLogRepositoryProvider.future)).all(),
);
