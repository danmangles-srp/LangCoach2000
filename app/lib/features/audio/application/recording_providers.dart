// Riverpod wiring for the recordings feature (T1.4). The repository wraps the
// Drift store; the list screen reads [recordingsProvider]. FutureProvider (not
// Stream) matches the hasFolder gate pattern — the list refreshes when the
// indexer (T1.3) invalidates this provider after a rescan.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/application/recording_management_service.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/recording/application/recording_file_service.dart';
import 'package:rivendell/features/audio/recording/platform/saf_recording_file_service.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';

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

/// The SAF-backed rename/delete service (T10.4 / T10.5). Singleton — wraps a
/// static method channel.
final recordingFileServiceProvider = Provider<RecordingFileService>(
  (ref) => SafRecordingFileService(),
);

/// Orchestrates in-app rename + delete (T10.4 / T10.5). Awaits its
/// dependencies (repo, folder repo, app docs dir) so the detail screen can
/// call it directly.
final recordingManagementProvider = FutureProvider<RecordingManagementService>((
  ref,
) async {
  final recordings = await ref.watch(recordingRepositoryProvider.future);
  final folderRepository = await ref.watch(folderRepositoryProvider.future);
  final appDocsDir = await ref.watch(appDocsDirProvider.future);
  return RecordingManagementService(
    recordings: recordings,
    folderRepository: folderRepository,
    fileService: ref.watch(recordingFileServiceProvider),
    appDocsDir: appDocsDir,
    logger: ref.watch(appLoggerProvider),
  );
});
