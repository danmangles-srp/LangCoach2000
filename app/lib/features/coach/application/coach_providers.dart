// Riverpod wiring for the Coach Bank feature (T5.5, FR-1.4.3). The repository
// wraps the Drift store; the list screen reads [coachNotesProvider]. Mutations
// go through [coachNoteCommandsProvider] (T15.5) then invalidate the list so it
// refetches atomically. The vocab picker reads [allTextWordLogsProvider]; the
// recordings picker reuses the shared [recordingsProvider].

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/coach/application/coach_note_commands.dart';
import 'package:rivendell/features/coach/data/coach_note_repository.dart';
import 'package:rivendell/features/coach/domain/coach_note.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';

/// Singleton [CoachNoteRepository] over the local store.
final coachNoteRepositoryProvider = FutureProvider<CoachNoteRepository>(
  (ref) async =>
      CoachNoteRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Mutation orchestrator over the repository (T15.5). Presentation writes
/// through this — never the repository directly — so the write surface is one
/// seam for future cross-cutting concerns.
final coachNoteCommandsProvider = FutureProvider<CoachNoteCommands>(
  (ref) async =>
      CoachNoteCommands(await ref.watch(coachNoteRepositoryProvider.future)),
);

/// Every coach note with its agenda, newest-touched first. Drives the Coach
/// Bank list. Invalidate after a create/update/delete so the list refetches.
final coachNotesProvider = FutureProvider<List<CoachNoteWithLinks>>((
  ref,
) async {
  final repo = await ref.watch(coachNoteRepositoryProvider.future);
  return repo.all();
});

/// Every text vocab log, newest first. Drives the Coach Bank vocab attach
/// picker. Invalidate after a recording's text log changes so the picker
/// refetches.
final allTextWordLogsProvider = FutureProvider<List<WordLog>>((ref) async {
  final repo = await ref.watch(wordLogRepositoryProvider.future);
  return repo.allTextLogs();
});
