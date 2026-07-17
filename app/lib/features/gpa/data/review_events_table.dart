// coverage:ignore-file — declarative Drift schema; no unit-testable logic.
// Review-event log (M2, FR-1.2.3). One row per 80%-play and per manual
// correction. `milestoneIndex` is nullable: a play that crossed 80% but
// satisfied no GPA milestone (an early review before D+1, or a bonus re-review
// after every due milestone is already reached) is logged with null so
// FR-1.2.4's review count reflects real engagement rather than collapsing into
// "milestones reached". "Reviewed for milestone N" is DERIVED from the
// existence of a row carrying that index — there is no separate flag to keep
// in sync (FR-1.2.3).

import 'package:drift/drift.dart';

import 'package:rivendell/features/audio/data/recordings_table.dart';

class ReviewEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The recording this review counts toward. Cascade-deleted with the
  /// recording so a (future) recording delete cleans its history.
  IntColumn get recordingId =>
      integer().references(Recordings, #id, onDelete: KeyAction.cascade)();

  /// The GPA milestone (0..7) this event satisfied, or null for a play that
  /// earned no milestone. Nullable by design — see file header.
  IntColumn get milestoneIndex => integer().nullable()();

  /// When the 80%-threshold was crossed (auto) or the correction was made
  /// (manual). Day-granularity drives milestone assignment (see gpa_review).
  DateTimeColumn get completedAt => dateTime()();
}
