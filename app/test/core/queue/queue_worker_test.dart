// QueueWorker — enqueue → reconnect → drain (T0.3 gate, NFR-2.1.3).

import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/core/queue/queue_worker.dart';

void main() {
  late AppDatabase db;
  late QueueRepository queue;
  late FakeNetworkService network;
  late QueueWorker worker;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = QueueRepository(db);
    network = FakeNetworkService();
    worker = QueueWorker(
      repository: queue,
      network: network,
      logger: AppLogger(sink: RecordingSink()),
      baseBackoff: const Duration(milliseconds: 5),
      maxBackoff: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await worker.stop();
    network.dispose();
    await db.close();
  });

  test(
    'onDrained emits after a drain completes (T18.3 live snapshot)',
    () async {
      worker.registerHandler('echo', (payload) async {});
      await queue.enqueue(type: 'echo', payload: 'a');

      // Collect drain signals. Each completed drain fires exactly one.
      final signals = <int>[];
      final sub = worker.onDrained.listen((_) => signals.add(1));

      await worker.drain();
      await Future<void>.delayed(Duration.zero);

      expect(signals, [1]);
      await sub.cancel();
    },
  );

  test('drains pending items on reconnect', () async {
    final handled = <String>[];
    worker.registerHandler('echo', (payload) async {
      handled.add(payload);
    });
    // Enqueue while offline, then go online.
    network.emit(online: false);
    worker.start();
    await queue.enqueue(type: 'echo', payload: 'a');
    await queue.enqueue(type: 'echo', payload: 'b');

    // Reconnect: the online edge fires a drain.
    network.emit(online: true);
    // Give the async drain a beat to complete.
    await Future<void>.delayed(Duration.zero);
    await worker.drain();

    expect(handled, ['a', 'b']);
    expect(await queue.pending(), isEmpty);
  });

  test(
    'a handler that throws leaves the item pending and records the failure',
    () async {
      worker.registerHandler('boom', (payload) async {
        throw StateError('fail');
      });
      final id = await queue.enqueue(type: 'boom', payload: 'x');
      await worker.drain();

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.id, id);
      expect(pending.single.attempts, 1);
      expect(pending.single.lastError, contains('Bad state: fail'));
    },
  );

  test('items with no registered handler are skipped, not failed', () async {
    final id = await queue.enqueue(type: 'unhandled', payload: 'x');
    await worker.drain();

    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.id, id);
    expect(pending.single.attempts, 0); // not marked failed
  });

  test('offline edge does not trigger a drain', () async {
    final handled = <String>[];
    // Go offline before start so the initial seed is offline.
    network.emit(online: false);
    worker
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
    worker.registerHandler('echo', (payload) async {
      calls++;
      if (calls == 1) await gate.future;
    });
    await queue.enqueue(type: 'echo', payload: 'a');

    final first = worker.drain();
    final second = worker.drain(); // concurrent — must not double-process
    gate.complete();
    await Future.wait([first, second]);

    expect(calls, 1);
  });

  // Regression for the on-device Pollinations failures: a handler that throws a
  // transient socket/DNS error on the first attempt must be retried in-app
  // while online — without needing a new connectivity edge (which may never
  // fire during a foreground session). This is the case the old "fail once,
  // wait for the next edge" model did not cover.
  test(
    'retries a transiently-failing handler while online until it succeeds',
    () async {
      var calls = 0;
      worker.registerHandler('flaky', (payload) async {
        calls++;
        if (calls < 3) {
          // Same shape the device logs showed: a DNS lookup miss.
          throw const SocketException(
            'Failed host lookup: image.pollinations.ai',
          );
        }
      });
      await queue.enqueue(type: 'flaky', payload: 'x');
      network.emit(online: true);
      worker.start();

      // Seed drain fails (attempts 1), then two backoff retries at ~5-20ms.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(calls, 3);
      expect(await queue.pending(), isEmpty);
      final drained = await queue.pendingByType('flaky');
      expect(drained, isEmpty); // markDone after the 3rd call cleared it.
    },
  );

  test(
    'does not retry while offline — defers to the next online edge',
    () async {
      var calls = 0;
      worker.registerHandler('echo', (payload) async {
        calls++;
      });
      await queue.enqueue(type: 'echo', payload: 'a');
      network.emit(online: false);
      worker.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(calls, 0); // never drained offline
      expect(await queue.pendingCount(), 1);

      // Real connectivity returns: drains immediately, backoff reset.
      network.emit(online: true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(calls, 1);
      expect(await queue.pending(), isEmpty);
    },
  );
}
