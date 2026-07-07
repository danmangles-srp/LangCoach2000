// CoachNoteCommands — the mutation orchestrator for the Coach Bank (T15.5,
// FR-1.4.3). Mirrors the M0 pattern ([TaskCommands]): presentation goes through
// this, never the repository directly, so the write surface is one place future
// cross-cutting concerns (analytics, validation, search reindex) can hook.
// Today it delegates to [CoachNoteRepository] — the value is the seam, kept
// consistent with the rest of the feature layers.
//
// The repository stays a pure data layer; invalidation of the read providers
// stays at the Riverpod call site (the screen), matching [TaskCommands].

import 'package:rivendell/features/coach/data/coach_note_repository.dart';
import 'package:rivendell/features/coach/domain/coach_note.dart';

class CoachNoteCommands {
  CoachNoteCommands(this._repo);

  final CoachNoteRepository _repo;

  Future<CoachNoteWithLinks> create({
    required String title,
    String? body,
    List<int> recordingIds = const [],
    List<int> wordLogIds = const [],
  }) => _repo.create(
    title: title,
    body: body,
    recordingIds: recordingIds,
    wordLogIds: wordLogIds,
  );

  Future<CoachNoteWithLinks> update(
    int id, {
    required String title,
    required List<int> recordingIds,
    required List<int> wordLogIds,
    String? body,
  }) => _repo.update(
    id,
    title: title,
    body: body,
    recordingIds: recordingIds,
    wordLogIds: wordLogIds,
  );

  Future<void> delete(int id) => _repo.delete(id);
}
