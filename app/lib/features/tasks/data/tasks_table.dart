// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Tasks engine (M5, FR-1.4.1). One row per user-created exercise / to-do:
// "Memorize 'Yor-Yor'", "Review chapter 3", etc. `dueDate` is nullable — a
// task need not carry a deadline. `completed` is the completion flag;
// `completedAt` records when it was checked off (analytics / undo, M6) and is
// cleared again on un-complete. Tasks are free-standing — no recording link,
// unlike word logs — so the user can track goals that exist outside any one
// recording.

import 'package:drift/drift.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Short human title (FR-1.4.1). Required.
  TextColumn get title => text()();

  /// Longer free-form notes. Optional.
  TextColumn get description => text().nullable()();

  /// When the task is due, or null for an undated task. Day granularity.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// The completion flag (FR-1.4.1). False while pending.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// When the user checked the task off. Null while pending; cleared on undo.
  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
