// Riverpod wiring for the folder-selection feature (T1.1). Lives under
// application/ (pure DI composition); the native picker impl that overrides
// [folderSelectionServiceProvider] lands in platform/ at B2.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';

/// True once the DB is open and a folder has been chosen. Drives the first-run
/// redirect: while this resolves, the router shows the app shell; once false,
/// it routes to onboarding.
final hasFolderProvider = FutureProvider<bool>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final repo = FolderRepository(KvRepository(db));
  return repo.hasFolder();
});

/// The persisted folder identity, or null. Read by the indexer (T1.2) to know
/// where to scan.
final folderRepositoryProvider = FutureProvider<FolderRepository>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  return FolderRepository(KvRepository(db));
});
