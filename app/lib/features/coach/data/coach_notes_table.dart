// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Drift schema for the Coach Bank (M5, FR-1.4.3). One row per reusable script
// / talking-point note for a live coaching session. [body] holds the script
// text; links to recordings and vocab logs (the "agenda") live in the two
// join tables so a note can map existing material without duplicating it.
//
// [updatedAt] is defaulted on insert but rewritten by the repository on every
// edit so the agenda view can order by last-touched.

import 'package:drift/drift.dart';

class CoachNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
