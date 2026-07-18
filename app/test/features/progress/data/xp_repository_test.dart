// XpRepository — M11 T11.2 (AC 2). In-memory Drift; no device. Covers the
// single insert path every awarding site funnels through, the running total
// the dashboard reads (T11.5), the source/trace fidelity, and — critically —
// that an award called inside another repo's transaction rolls back with it
// (no orphan XP for a failed review append).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';

void main() {
  late AppDatabase db;
  late XpRepository xp;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    xp = XpRepository(db);
  });

  tearDown(() => db.close());

  test('total is 0 on an empty ledger', () async {
    expect(await xp.total(), 0);
  });

  test('record appends a row and total reflects it', () async {
    await xp.record(source: XpSource.review, points: 10);
    expect(await xp.total(), 10);
  });

  test('record accumulates across every source', () async {
    await xp.record(source: XpSource.review, points: 10);
    await xp.record(source: XpSource.wordlog, points: 5);
    await xp.record(source: XpSource.anki, points: 4);
    await xp.record(source: XpSource.task, points: 8);
    await xp.record(source: XpSource.reading, points: 15);
    expect(await xp.total(), 42);
  });

  test('record stores source + points, traces null when none given', () async {
    await xp.record(source: XpSource.review, points: 10);
    final row = await (db.select(db.xpEvents)..limit(1)).getSingle();
    expect(row.source, XpSource.review.columnValue);
    expect(row.points, 10);
    expect(row.recordingId, isNull);
    expect(row.taskId, isNull);
  });

  test('record traces the award to a seeded recording + task', () async {
    // FK is ON: tracing ids must reference real rows or the insert rejects.
    final recId = await db
        .into(db.recordings)
        .insert(
          RecordingsCompanion.insert(
            filePath: '/svr/lec.m4a',
            name: 'lec.m4a',
            createdAt: DateTime(2026, 3, 15),
            sizeBytes: 1024,
            format: 'm4a',
          ),
        );
    final taskId = await db
        .into(db.tasks)
        .insert(TasksCompanion.insert(title: 'Memorize Yor-Yor'));
    await xp.record(
      source: XpSource.review,
      points: 10,
      recordingId: recId,
      taskId: taskId,
    );
    final row = await (db.select(db.xpEvents)..limit(1)).getSingle();
    expect(row.recordingId, recId);
    expect(row.taskId, taskId);
  });

  test(
    'record joins an ambient transaction: a downstream throw rolls it back',
    () async {
      // The review hook awards XP inside ReviewEventRepository's transaction.
      // If anything after the award throws, the XP row must roll back with the
      // review event — no orphan award for a failed append.
      await expectLater(
        db.transaction(() async {
          await xp.record(source: XpSource.review, points: 10);
          throw StateError('simulated downstream failure');
        }),
        throwsA(isA<StateError>()),
      );
      expect(await xp.total(), 0);
    },
  );
}
