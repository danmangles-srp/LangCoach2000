// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Join table: a Coach Bank note ↔ a recording it references as a talking
// point (FR-1.4.3). Both sides cascade — deleting the note or the recording
// clears the link, never orphans it. Composite key keeps a recording linked
// to a note at most once.

import 'package:drift/drift.dart';

import 'package:rivendell/features/audio/data/recordings_table.dart';
import 'package:rivendell/features/coach/data/coach_notes_table.dart';

class CoachNoteRecordings extends Table {
  IntColumn get noteId =>
      integer().references(CoachNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get recordingId =>
      integer().references(Recordings, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {noteId, recordingId};
}
