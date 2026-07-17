// End-to-end offline-queue contract for AI images (T4.3, NFR-2.1.3). The AC:
// a word enqueued while offline is generated when connectivity returns, and
// the per-word cache means a second drain of the same word is a no-op. Drives
// the real QueueWorker against a real in-memory queue, with a
// FakeAiImageService standing in for the network and a FakeNetworkService
// driving the online edge — the same seam the production Pollinations handler
// rides.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/connectivity/network_service.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/core/queue/queue_worker.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/fake_ai_image_service.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';

void main() {
  late AppDatabase db;
  late QueueRepository queue;
  late FakeNetworkService network;
  late FakeAiImageService ai;
  late QueueWorker worker;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = QueueRepository(db);
    network = FakeNetworkService(online: false);
    ai = FakeAiImageService();
    // Register the ai_image handler exactly as production boot does, decoding
    // the payload then delegating to the service.
    worker =
        QueueWorker(
          repository: queue,
          network: network,
          logger: AppLogger(sink: RecordingSink()),
        )..registerHandler(aiImageQueueType, (payload) async {
          final pair = pairFromAiImagePayload(payload);
          await ai.generateNow(uzbek: pair.uzbek, english: pair.english);
        });
  });

  tearDown(() async {
    await worker.stop();
    await db.close();
    network.dispose();
  });

  test('an item enqueued offline drains and generates on reconnect', () async {
    // Enqueue while offline.
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbek: 'salom', english: 'hello'),
    );
    expect(await queue.pendingCount(), 1);
    expect(await ai.cachedPath('salom'), isNull);

    worker.start();
    // Coming online fires the drain.
    network.emit(online: true);

    // The drain is fire-and-forget; pump the microtask queue so it completes.
    await Future<void>.delayed(Duration.zero);

    expect(ai.generated.single.uzbek, 'salom');
    expect(ai.generated.single.english, 'hello');
    expect(await ai.cachedPath('salom'), isNotNull);
    // The item was marked done once the handler succeeded.
    expect(await queue.pendingCount(), 0);
  });

  test('a duplicate item for an already-cached word is a no-op', () async {
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbek: 'salom', english: 'hello'),
    );
    await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload(uzbek: 'salom', english: 'hello'),
    );

    worker.start();
    network.emit(online: true);
    await Future<void>.delayed(Duration.zero);

    // Only one generation call across two items.
    expect(ai.generated.single.uzbek, 'salom');
    expect(await queue.pendingCount(), 0);
  });

  test(
    'a failed generation leaves the item pending for the next reconnect',
    () async {
      // A flaky fake: fails the first call, succeeds after.
      final flaky = _FlakyAi(failFirstNFails: 1);
      worker.registerHandler(aiImageQueueType, (payload) async {
        final pair = pairFromAiImagePayload(payload);
        await flaky.generateNow(uzbek: pair.uzbek, english: pair.english);
      });

      await queue.enqueue(
        type: aiImageQueueType,
        payload: aiImagePayload(uzbek: 'xayr', english: 'bye'),
      );

      worker.start();
      network.emit(online: true);
      await Future<void>.delayed(Duration.zero);

      // First drain failed: item still pending, attempt bumped.
      expect(await queue.pendingCount(), 1);
      final pending = await queue.pending();
      expect(pending.single.attempts, 1);

      // Next reconnect retries and succeeds.
      network.emit(online: true);
      await Future<void>.delayed(Duration.zero);

      expect(await queue.pendingCount(), 0);
    },
  );
}

class _FlakyAi implements AiImageService {
  _FlakyAi({required this.failFirstNFails});
  int failFirstNFails;
  final FakeAiImageService _inner = FakeAiImageService();

  @override
  Future<String?> cachedPath(String uzbekWord) => _inner.cachedPath(uzbekWord);

  @override
  Future<void> enqueueGeneration({
    required String uzbek,
    required String english,
  }) => _inner.enqueueGeneration(uzbek: uzbek, english: english);

  @override
  Future<void> generateNow({
    required String uzbek,
    required String english,
  }) async {
    if (failFirstNFails > 0) {
      failFirstNFails--;
      throw Exception('transient failure');
    }
    await _inner.generateNow(uzbek: uzbek, english: english);
  }
}
