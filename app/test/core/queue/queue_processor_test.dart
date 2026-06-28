// QueueProcessor — enqueue → reconnect → drain (T0.3 gate, NFR-2.1.3).

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/network_service.dart';
import 'package:rivendell/core/queue/queue_processor.dart';
import 'package:rivendell/core/queue/queue_repository.dart';

void main() {
  late AppDatabase db;
  late QueueRepository queue;
  late FakeNetworkService network;
  late QueueProcessor processor;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = QueueRepository(db);
    network = FakeNetworkService();
    processor = QueueProcessor(
      repository: queue,
      network: network,
      logger: AppLogger(sink: RecordingSink()),
    );
  });

  tearDown(() async {
    await processor.stop();
    network.dispose();
    await db.close();
  });

  test('drains pending items on reconnect', () async {
    final handled = <String>[];
    processor.registerHandler('echo', (payload) async {
      handled.add(payload);
    });
    // Enqueue while offline, then go online.
    network.emit(online: false);
    processor.start();
    await queue.enqueue(type: 'echo', payload: 'a');
    await queue.enqueue(type: 'echo', payload: 'b');

    // Reconnect: the online edge fires a drain.
    network.emit(online: true);
    // Give the async drain a beat to complete.
    await Future<void>.delayed(Duration.zero);
    await processor.drain();

    expect(handled, ['a', 'b']);
    expect(await queue.pending(), isEmpty);
  });

  test(
    'a handler that throws leaves the item pending and records the failure',
    () async {
      processor.registerHandler('boom', (payload) async {
        throw StateError('fail');
      });
      final id = await queue.enqueue(type: 'boom', payload: 'x');
      await processor.drain();

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.id, id);
      expect(pending.single.attempts, 1);
      expect(pending.single.lastError, contains('Bad state: fail'));
    },
  );

  test('items with no registered handler are skipped, not failed', () async {
    final id = await queue.enqueue(type: 'unhandled', payload: 'x');
    await processor.drain();

    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.id, id);
    expect(pending.single.attempts, 0); // not marked failed
  });

  test('offline edge does not trigger a drain', () async {
    final handled = <String>[];
    // Go offline before start so the initial seed is offline.
    network.emit(online: false);
    processor
      ..registerHandler('echo', (payload) async {
        handled.add(payload);
      })
      ..start();
    await queue.enqueue(type: 'echo', payload: 'a');

    network.emit(online: false);
    await Future<void>.delayed(Duration.zero);

    expect(handled, isEmpty);
    expect(await queue.pendingCount(), 1);
  });

  test('re-entry guard prevents overlapping drains', () async {
    var calls = 0;
    final gate = Completer<void>();
    processor.registerHandler('echo', (payload) async {
      calls++;
      if (calls == 1) await gate.future;
    });
    await queue.enqueue(type: 'echo', payload: 'a');

    final first = processor.drain();
    final second = processor.drain(); // concurrent — must not double-process
    gate.complete();
    await Future.wait([first, second]);

    expect(calls, 1);
  });
}
