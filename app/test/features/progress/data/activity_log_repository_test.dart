// ActivityLogRepository — M11 T11.4 (AC 2). In-memory Drift; no device. Covers
// the single mutation site: the insert + the +15 XP hook in the same tx, the
// optional duration, the newest-first list, and delete.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/progress/data/activity_log_repository.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/activity_kind.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';

void main() {
  late AppDatabase db;
  late XpRepository xp;
  late ActivityLogRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    xp = XpRepository(db);
    repo = ActivityLogRepository(db, xp: xp);
  });
  tearDown(() => db.close());

  test('add inserts the row and awards +15 (reading)', () async {
    await repo.add(
      kind: ActivityKind.reading,
      title: 'Chapter 3',
      at: DateTime(2026, 7, 15, 10),
    );
    final logs = await repo.all();
    expect(logs, hasLength(1));
    expect(logs.single.kind, 'reading');
    expect(logs.single.title, 'Chapter 3');
    expect(logs.single.durationMinutes, isNull);
    expect(await xp.total(), 15);
  });

  test('a movie entry awards +15 under the movie source', () async {
    await repo.add(
      kind: ActivityKind.movie,
      title: 'Sevara',
      at: DateTime(2026, 7, 15, 10),
    );
    final row = await (db.select(db.xpEvents)..limit(1)).getSingle();
    expect(row.source, XpSource.movie.columnValue);
    expect(row.points, 15);
  });

  test('durationMinutes is stored when given', () async {
    await repo.add(
      kind: ActivityKind.reading,
      title: 'Read',
      durationMinutes: 20,
      at: DateTime(2026, 7, 15, 10),
    );
    expect((await repo.all()).single.durationMinutes, 20);
  });

  test('all() returns newest first', () async {
    await repo.add(
      kind: ActivityKind.reading,
      title: 'older',
      at: DateTime(2026, 6, 15),
    );
    await repo.add(
      kind: ActivityKind.movie,
      title: 'newer',
      at: DateTime(2026, 7, 15),
    );
    final logs = await repo.all();
    expect(logs.map((l) => l.title), ['newer', 'older']);
  });

  test('delete removes the row', () async {
    await repo.add(
      kind: ActivityKind.reading,
      title: 'gone',
      at: DateTime(2026, 7, 15),
    );
    final id = (await repo.all()).single.id;
    await repo.delete(id);
    expect(await repo.all(), isEmpty);
  });

  test('the award traces to no recording/task (null FKs)', () async {
    await repo.add(
      kind: ActivityKind.reading,
      title: 'x',
      at: DateTime(2026, 7, 15),
    );
    final row = await (db.select(db.xpEvents)..limit(1)).getSingle();
    expect(row.recordingId, isNull);
    expect(row.taskId, isNull);
  });

  test('with no xp sink: insert works, no award', () async {
    final noXpRepo = ActivityLogRepository(db);
    await noXpRepo.add(
      kind: ActivityKind.reading,
      title: 'x',
      at: DateTime(2026, 7, 15),
    );
    expect(await noXpRepo.all(), hasLength(1));
    expect(await xp.total(), 0);
  });
}
