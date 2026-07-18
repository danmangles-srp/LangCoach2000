// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// XP ledger (M11, AC 1). Append-only: each row is a single XP award from one
// of the five sources in xp_level.dart's XpSource enum (a review completion,
// a word-log attach, an Anki export, a task done, or a logged reading/movie
// activity). The total / level / progress bar are all DERIVED from the sum of
// `points` — never a hand-edited counter (decision #9), the same shape as
// review_events and metrics_events.
//
// `recordingId` / `taskId` trace an award back to its origin row when one
// exists; both are nullable because a reading/movie log carries neither. The
// FK uses ON DELETE SET NULL (not CASCADE): deleting a recording or task must
// NOT retroactively erase earned XP from the ledger — the event stands, only
// the trace softens.

import 'package:drift/drift.dart';

import 'package:rivendell/features/audio/data/recordings_table.dart';
import 'package:rivendell/features/tasks/data/tasks_table.dart';

class XpEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Which action earned this XP (an xp_level.dart XpSource columnValue).
  TextColumn get source => text()();

  /// The points awarded. Always non-negative; the award site computes it
  /// (e.g. Anki = 2 × cards exported).
  IntColumn get points => integer()();

  /// The recording this award traces to (review/wordlog/anki), or null.
  /// SET NULL on recording delete — the XP event survives.
  IntColumn get recordingId => integer().nullable().references(
    Recordings,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The task this award traces to, or null. SET NULL on task delete.
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When the award happened. Drives nothing today; kept for future analytics.
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}
