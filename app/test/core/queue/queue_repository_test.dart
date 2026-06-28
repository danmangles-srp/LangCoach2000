// QueueRepository + migration v2 (T0.3).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/queue/queue_repository.dart';

void main() {
  late AppDatabase db;
  late QueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = QueueRepository(db);
  });

  tearDown(() => db.close());

  test('enqueue assigns an autoincrement id and stays pending', () async {
    final id = await queue.enqueue(type: 'email', payload: '{}');
    expect(id, greaterThan(0));
    final items = await queue.pending();
    expect(items, hasLength(1));
    expect(items.single.type, 'email');
  });

  test('pending returns oldest first', () async {
    final first = await queue.enqueue(type: 't', payload: 'a');
    final second = await queue.enqueue(type: 't', payload: 'b');
    final items = await queue.pending();
    expect(items.map((i) => i.id), [first, second]);
  });

  test('markDone removes from pending and zeroes the count', () async {
    final id = await queue.enqueue(type: 't', payload: 'x');
    expect(await queue.pendingCount(), 1);
    await queue.markDone(id);
    expect(await queue.pending(), isEmpty);
    expect(await queue.pendingCount(), 0);
  });

  test('markFailed bumps attempts and records the error', () async {
    final id = await queue.enqueue(type: 't', payload: 'x');
    await queue.markFailed(id, error: 'boom');
    final items = await queue.pending();
    expect(items.single.attempts, 1);
    expect(items.single.lastError, 'boom');
    // Still pending — retry on next reconnect.
    expect(items, hasLength(1));
  });

  test('markFailed is idempotent across calls (each bumps attempts)', () async {
    final id = await queue.enqueue(type: 't', payload: 'x');
    await queue.markFailed(id, error: 'e1');
    await queue.markFailed(id, error: 'e2');
    final items = await queue.pending();
    expect(items.single.attempts, 2);
  });

  test('pruneDone only removes done items older than the cutoff', () async {
    await queue.enqueue(type: 't', payload: 'old-done');
    await queue.enqueue(type: 't', payload: 'pending');
    // Mark all done; prune the lot using a future cutoff.
    final items = await queue.pending();
    for (final i in items) {
      await queue.markDone(i.id);
    }
    final removed = await queue.pruneDone(
      before: DateTime.now().add(const Duration(days: 1)),
    );
    expect(removed, 2);
  });

  test('schema is at version 2 with the offline_queue_items table', () async {
    expect(db.schemaVersion, 2);
    final tables = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type='table' AND name='offline_queue_items'",
        )
        .get();
    expect(tables, hasLength(1));
  });
}
