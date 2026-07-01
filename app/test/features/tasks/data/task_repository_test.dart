// TaskRepository — T5.1 (FR-1.4.1). In-memory Drift; no device. Covers create
// defaults, edit (no flag flip), complete/un-complete stamping, delete, the
// ordered read (incomplete first, dated-before-undated, earliest due first),
// and the dueOnOrBefore filter used by notifications.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create seeds defaults: pending, no completion stamp', () async {
    final t = await tasks.create(title: 'Memorize Yor-Yor');
    expect(t.title, 'Memorize Yor-Yor');
    expect(t.description, isNull);
    expect(t.dueDate, isNull);
    expect(t.completed, isFalse);
    expect(t.completedAt, isNull);
  });

  test('create keeps an optional description + due date', () async {
    final due = DateTime(2026, 7, 5);
    final t = await tasks.create(
      title: 'Review ch.3',
      description: 'pages 12-40',
      dueDate: due,
    );
    expect(t.description, 'pages 12-40');
    expect(t.dueDate, due);
  });

  test(
    'update edits the descriptive fields without flipping the flag',
    () async {
      final t = await tasks.create(title: 'Old');
      final edited = await tasks.update(
        t.id,
        title: 'New',
        description: 'desc',
        dueDate: DateTime(2026, 7, 5),
      );
      expect(edited.title, 'New');
      expect(edited.description, 'desc');
      expect(edited.completed, isFalse); // edit didn't complete it
    },
  );

  test('setCompleted stamps completedAt on, clears it on undo', () async {
    final t = await tasks.create(title: 'X');
    final done = await tasks.setCompleted(t.id, completed: true);
    expect(done.completed, isTrue);
    expect(done.completedAt, isNotNull);

    final undone = await tasks.setCompleted(t.id, completed: false);
    expect(undone.completed, isFalse);
    expect(undone.completedAt, isNull);
  });

  test('delete removes the row', () async {
    final t = await tasks.create(title: 'X');
    await tasks.delete(t.id);
    expect(await tasks.getById(t.id), isNull);
  });

  test(
    'all() orders: incomplete first, dated before undated, earliest due first',
    () async {
      await tasks.create(title: 'undated A'); // pending, no due
      await tasks.create(title: 'due jul5', dueDate: DateTime(2026, 7, 5));
      await tasks.create(title: 'due jul2', dueDate: DateTime(2026, 7, 2));
      final done = await tasks.create(title: 'done undated');
      await tasks.setCompleted(done.id, completed: true);

      final rows = await tasks.all();
      expect(rows.map((t) => t.title).toList(), [
        'due jul2',
        'due jul5',
        'undated A',
        'done undated',
      ]);
    },
  );

  test(
    'dueOnOrBefore returns only incomplete tasks on/before the cutoff',
    () async {
      await tasks.create(title: 'due jul2', dueDate: DateTime(2026, 7, 2));
      await tasks.create(title: 'due jul5', dueDate: DateTime(2026, 7, 5));
      await tasks.create(title: 'undated'); // excluded — no due date
      final done = await tasks.create(
        title: 'done due jul2',
        dueDate: DateTime(2026, 7, 2),
      );
      await tasks.setCompleted(done.id, completed: true); // excluded — complete

      final rows = await tasks.dueOnOrBefore(DateTime(2026, 7, 2));
      expect(rows.map((t) => t.title).toList(), ['due jul2']);
    },
  );
}
