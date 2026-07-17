// Repository over [Tasks] (T5.1, FR-1.4.1). Pure logic over the Drift store —
// no platform deps, fully unit-tested. Create / update / complete / un-complete
// / delete, plus an ordered read that drives the tasks screen and the due-date
// set notifications (T5.3) key off. Completion state is the one mutating op
// the checkbox performs; everything else is an edit of the descriptive fields.

import 'package:drift/drift.dart';

import 'package:rivendell/core/database/app_database.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  /// Create a task. Only [title] is required (FR-1.4.1); [description] and
  /// [dueDate] are optional. Returns the inserted row.
  Future<Task> create({
    required String title,
    String? description,
    DateTime? dueDate,
  }) {
    return _db
        .into(_db.tasks)
        .insertReturning(
          TasksCompanion.insert(
            title: title,
            description: Value(description),
            dueDate: Value(dueDate),
          ),
        );
  }

  Future<Task?> getById(int id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Edit the descriptive fields. Completion state is owned by
  /// [setCompleted] so an edit never accidentally flips the flag. Returns the
  /// updated row.
  Future<Task> update(
    int id, {
    required String title,
    String? description,
    DateTime? dueDate,
  }) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .writeReturning(
          TasksCompanion(
            title: Value(title),
            description: Value(description),
            dueDate: Value(dueDate),
          ),
        )
        .then((rows) => rows.single);
  }

  /// Set the completion flag, stamping [Task.completedAt] on complete and
  /// clearing it on undo. Returns the updated row.
  Future<Task> setCompleted(int id, {required bool completed}) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .writeReturning(
          TasksCompanion(
            completed: Value(completed),
            completedAt: Value(completed ? DateTime.now() : null),
          ),
        )
        .then((rows) => rows.single);
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();

  /// Every task, ordered for the tasks screen: incomplete before complete,
  /// dated before undated, earliest due first, then by creation. Undated
  /// tasks never float above a real deadline.
  Future<List<Task>> all() {
    final t = _db.tasks;
    return (_db.select(t)..orderBy([
          (c) => OrderingTerm.asc(c.completed),
          (c) => OrderingTerm.asc(c.dueDate.isNull()),
          (c) => OrderingTerm.asc(c.dueDate),
          (c) => OrderingTerm.asc(c.createdAt),
        ]))
        .get();
  }

  /// Incomplete tasks due on or before [day] (date-only compare). Drives the
  /// "due today / overdue" surface for notifications (T5.3) and screen badges.
  Future<List<Task>> dueOnOrBefore(DateTime day) {
    final t = _db.tasks;
    return (_db.select(t)
          ..where(
            (c) =>
                c.completed.equals(false) &
                c.dueDate.isSmallerOrEqualValue(day),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.dueDate)]))
        .get();
  }
}
