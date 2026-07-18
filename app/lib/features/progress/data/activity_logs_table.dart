// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Manual activity log (M11 T11.4, AC 2 — the 5th XP source). A row per a
// reading or movie the learner logged by hand (not derived from a recording).
// Each insert is the single site that awards the reading/movie +15 XP hook.
//
// `durationMinutes` is nullable: a "read 20 min" entry has one, a "watched a
// film" entry may not. No FKs — an activity log stands alone (it traces to no
// recording or task), so its XP award rows carry null recordingId/taskId.

import 'package:drift/drift.dart';

class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'reading' | 'movie' — an activity_kind.dart ActivityKind columnValue.
  TextColumn get kind => text()();

  /// Free-text label the learner typed (book/film title, chapter, etc.).
  TextColumn get title => text()();

  /// Optional duration in minutes. Null when not recorded.
  IntColumn get durationMinutes => integer().nullable()();

  /// When the activity happened (user-chosen; defaults to now).
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}
