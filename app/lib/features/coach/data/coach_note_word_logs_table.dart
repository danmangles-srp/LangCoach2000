// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Join table: a Coach Bank note ↔ a vocab log it references as a talking
// point (FR-1.4.3). Vocab lives as raw text in [WordLogs] (one text log per
// recording), so the linkable unit is the whole log, not an individual pair.
// Both sides cascade; composite key keeps a log linked to a note at most once.

import 'package:drift/drift.dart';

import 'package:rivendell/features/coach/data/coach_notes_table.dart';
import 'package:rivendell/features/wordlog/data/word_logs_table.dart';

class CoachNoteWordLogs extends Table {
  IntColumn get noteId =>
      integer().references(CoachNotes, #id, onDelete: KeyAction.cascade)();
  IntColumn get wordLogId =>
      integer().references(WordLogs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {noteId, wordLogId};
}
