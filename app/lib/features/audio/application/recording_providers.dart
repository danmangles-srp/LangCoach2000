// Riverpod wiring for the recordings feature (T1.4). The repository wraps the
// Drift store; the list screen reads [recordingsProvider]. FutureProvider (not
// Stream) matches the hasFolder gate pattern — the list refreshes when the
// indexer (T1.3) invalidates this provider after a rescan.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';

/// Singleton [RecordingRepository] over the local store.
final recordingRepositoryProvider = FutureProvider<RecordingRepository>(
  (ref) async =>
      RecordingRepository(await ref.watch(appDatabaseProvider.future)),
);

/// All indexed recordings, newest first. Drives the recordings list (T1.4).
/// Invalidate after a rescan (T1.3) so the list refetches.
final recordingsProvider = FutureProvider<List<Recording>>((ref) async {
  final repo = await ref.watch(recordingRepositoryProvider.future);
  return repo.all();
});

/// A single recording by row id. Drives the detail screen (T1.6). `family`
/// caches each id independently; returns `null` for a stale id so the screen
/// can render a "not found" state instead of throwing.
final recordingByIdProvider = FutureProvider.family<Recording?, int>((
  ref,
  id,
) async {
  final repo = await ref.watch(recordingRepositoryProvider.future);
  return repo.findById(id);
});
