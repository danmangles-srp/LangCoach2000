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

  test(
    'includes the offline_queue_items table at the current schema version',
    () async {
      expect(db.schemaVersion, greaterThanOrEqualTo(2));
      final tables = await db
          .customSelect(
            'SELECT name FROM sqlite_master '
            "WHERE type='table' AND name='offline_queue_items'",
          )
          .get();
      expect(tables, hasLength(1));
    },
  );

  test('pending carries the createdAt timestamp', () async {
    await queue.enqueue(type: 't', payload: 'x');
    final items = await queue.pending();
    expect(items.single.createdAt, isNotNull);
  });

  test('pendingByType filters by type and skips done items', () async {
    await queue.enqueue(type: 'ai_image', payload: 'a');
    await queue.enqueue(type: 'email', payload: 'b');
    final done = await queue.enqueue(type: 'ai_image', payload: 'c');
    await queue.markDone(done);

    final items = await queue.pendingByType('ai_image');
    expect(items, hasLength(1));
    expect(items.single.payload, 'a');
  });

  test('resetAttempts zeroes attempts + clears lastError', () async {
    final id = await queue.enqueue(type: 't', payload: 'x');
    await queue.markFailed(id, error: 'boom');
    await queue.markFailed(id, error: 'again');
    expect((await queue.pending()).single.attempts, 2);

    await queue.resetAttempts(id);
    final item = (await queue.pending()).single;
    expect(item.attempts, 0);
    expect(item.lastError, isNull);
  });

  test('delete hard-removes a row (not just marks done)', () async {
    final id = await queue.enqueue(type: 't', payload: 'x');
    await queue.delete(id);
    expect(await queue.pending(), isEmpty);
    // Confirms the row is gone entirely (cancel), not flipped to done.
    final remaining = await db.select(db.offlineQueueItems).get();
    expect(remaining, isEmpty);
  });

  group('T18.1 idempotent enqueue', () {
    test(
      'spamming the same (type, payload) keeps only one pending row',
      () async {
        final first = await queue.enqueue(
          type: 'ai_image',
          payload: '{"word":"x"}',
        );
        await queue.enqueue(type: 'ai_image', payload: '{"word":"x"}');
        await queue.enqueue(type: 'ai_image', payload: '{"word":"x"}');

        // The replayed enqueues are ignored (no-op), not appended — only the
        // original row remains.
        expect(await queue.pending(), hasLength(1));
        expect((await queue.pending()).single.id, first);
      },
    );

    test('distinct payloads each get their own pending row', () async {
      await queue.enqueue(type: 'ai_image', payload: '{"word":"a"}');
      await queue.enqueue(type: 'ai_image', payload: '{"word":"b"}');
      await queue.enqueue(type: 'email', payload: '{"word":"a"}'); // diff type
      expect(await queue.pending(), hasLength(3));
    });

    test(
      'a done row frees the slot so the same payload can re-enqueue',
      () async {
        final id = await queue.enqueue(type: 't', payload: 'x');
        await queue.markDone(id);
        // Slot freed (done row excluded from the partial index) → fresh insert.
        final reId = await queue.enqueue(type: 't', payload: 'x');
        expect(reId, greaterThan(0));
        final pending = await queue.pending();
        expect(pending, hasLength(1));
        expect(pending.single.id, isNot(id));
      },
    );

    test(
      'the partial unique index exists at the current schema version',
      () async {
        final rows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='index' "
              "AND name='offline_queue_pending_uniq'",
            )
            .get();
        expect(rows, hasLength(1));
      },
    );
  });
}
