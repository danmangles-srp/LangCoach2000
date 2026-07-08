// FalAiImageService contract (T4.3, FR-1.3.4 / NFR-2.1.3). No network: a fake
// http client routes the Fal.ai POST and the image GET; the cache + queue run
// against an in-memory Drift store; the docs dir is a real temp dir so the
// file-write side effect is asserted. Pins the request shape (URL, auth, body),
// the per-word cache idempotency, and the no-key / non-200 / malformed-body
// failure modes.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/fal_ai_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';

void main() {
  late AppDatabase db;
  late AiImageCacheRepository cache;
  late QueueRepository queue;
  late Directory docsDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cache = AiImageCacheRepository(db);
    queue = QueueRepository(db);
    docsDir = await Directory.systemTemp.createTemp('fal_ai_test');
  });

  tearDown(() async {
    await db.close();
    if (docsDir.existsSync()) {
      await docsDir.delete(recursive: true);
    }
  });

  /// A MockClient whose POST returns the Fal.ai image URL and whose GET returns
  /// synthetic PNG bytes. Records observed requests for assertions.
  http.Client succeedingClient({
    required List<http.Request> postCalls,
    String imageUrl = 'https://cdn.fal.ai/abc.png',
  }) {
    return MockClient((request) async {
      if (request.method == 'POST') {
        postCalls.add(request);
        return http.Response(
          '{"images":[{"url":"$imageUrl","content_type":"image/png"}]}',
          200,
        );
      }
      // GET the image URL.
      return http.Response.bytes([1, 2, 3, 4], 200);
    });
  }

  FalAiImageService buildService({
    required http.Client client,
    String apiKey = 'test-key',
  }) {
    return FalAiImageService(
      cache: cache,
      queue: queue,
      docsDir: docsDir,
      readApiKey: () async => apiKey,
      client: client,
      logger: AppLogger(sink: RecordingSink()),
      baseUrl: 'https://fal.run',
      modelId: 'fal-ai/flux/schnell',
    );
  }

  group('generateNow', () {
    test(
      'POSTs to fal host + model with Key auth, downloads, writes, caches',
      () async {
        final postCalls = <http.Request>[];
        final service = buildService(
          client: succeedingClient(postCalls: postCalls),
        );

        await service.generateNow('salom');

        // Exactly one POST (no retry, no duplicate).
        expect(postCalls, hasLength(1));
        final req = postCalls.single;
        expect(req.url.toString(), 'https://fal.run/fal-ai/flux/schnell');
        expect(req.headers['Authorization'], 'Key test-key');
        expect(req.headers['Content-Type'], 'application/json');
        expect(req.body, contains('"prompt"'));
        expect(req.body, contains('salom'));
        expect(req.body, contains('square_hd'));

        // File written at the canonical cache path; cache path now resolvable.
        final file = File('${docsDir.path}/${buildAiImagePath('salom')}');
        expect(file.existsSync(), isTrue);
        expect(await file.readAsBytes(), [1, 2, 3, 4]);
        expect(await service.cachedPath('salom'), buildAiImagePath('salom'));
      },
    );

    test('is a no-op when the word is already cached (no POST)', () async {
      final postCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(postCalls: postCalls),
      );

      await service.generateNow('salom');
      await service.generateNow('salom'); // second call

      expect(postCalls, hasLength(1));
    });

    test('throws StateError when the api key is empty', () async {
      final service = buildService(
        client: succeedingClient(postCalls: []),
        apiKey: '',
      );
      await expectLater(service.generateNow('salom'), throwsStateError);
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('{"detail":"rate limited"}', 429);
        }
        return http.Response.bytes(const [], 200);
      });
      final service = buildService(client: client);

      await expectLater(service.generateNow('salom'), throwsException);
      // Nothing cached on failure.
      expect(await service.cachedPath('salom'), isNull);
    });

    test('throws on a malformed response body', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('{"unexpected": true}', 200);
        }
        return http.Response.bytes(const [], 200);
      });
      final service = buildService(client: client);

      await expectLater(service.generateNow('salom'), throwsFormatException);
    });
  });

  group('enqueueGeneration', () {
    test('enqueues an ai_image item when the word is not cached', () async {
      final service = buildService(client: succeedingClient(postCalls: []));

      await service.enqueueGeneration('salom');

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.type, aiImageQueueType);
      expect(wordFromAiImagePayload(pending.single.payload), 'salom');
    });

    test('is a no-op when the word is already cached', () async {
      // Seed the cache directly: a prior generation succeeded.
      await cache.remember(
        uzbekWord: 'salom',
        relativePath: 'ai_images/seed.png',
      );
      final service = buildService(client: succeedingClient(postCalls: []));

      await service.enqueueGeneration('salom');

      expect(await queue.pending(), isEmpty);
    });
  });

  test('cachedPath delegates to the cache', () async {
    final service = buildService(client: succeedingClient(postCalls: []));
    expect(await service.cachedPath('none'), isNull);
    await cache.remember(uzbekWord: 'foo', relativePath: 'ai_images/foo.png');
    expect(await service.cachedPath('foo'), 'ai_images/foo.png');
  });
}
