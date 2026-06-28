// Riverpod wiring for the folder-selection feature (T1.1). Lives under
// application/ (pure DI composition); the native picker impl that overrides
// [folderSelectionServiceProvider] lands in platform/ at B2.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';

/// True once a folder has been chosen. Drives the first-run redirect.
final hasFolderProvider = FutureProvider<bool>((ref) async {
  final repo = await ref.watch(folderRepositoryProvider.future);
  return repo.hasFolder();
});

/// The [FolderRepository] singleton. Read by the indexer (T1.2) and the
/// onboarding flow to get/set the chosen folder.
final folderRepositoryProvider = FutureProvider<FolderRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return FolderRepository(KvRepository(db));
});
