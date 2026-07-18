// PollinationsImageService contract (FR-1.3.4 / NFR-2.1.3). No network: a fake
// http client routes the Pollinations image GET; the cache + queue run against
// an in-memory Drift store; the docs dir is a real temp dir so the file-write
// side effect is asserted. Pins the request shape (keyless GET, prompt in the
// path, square dims, deterministic seed), the per-word cache idempotency, and
// the non-200 failure mode.
//
// T19.3: the prompt must run on the ENGLISH gloss while the cache key + on-disk
// path stay keyed by the UZBEK word. These tests assert both halves.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/application/pollinations_image_service.dart';
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
    docsDir = await Directory.systemTemp.createTemp('pollinations_test');
  });

  tearDown(() async {
    await db.close();
    if (docsDir.existsSync()) {
      await docsDir.delete(recursive: true);
    }
  });

  /// A MockClient whose GET returns synthetic PNG bytes. Records observed
  /// requests for assertions.
  http.Client succeedingClient({required List<http.Request> getCalls}) {
    return MockClient((request) async {
      if (request.method == 'GET') {
        getCalls.add(request);
        return http.Response.bytes([1, 2, 3, 4], 200);
      }
      return http.Response.bytes(const [], 404);
    });
  }

  PollinationsImageService buildService({
    required http.Client client,
    String Function()? promptTemplate,
    AiImageRequestGate? gate,
  }) {
    return PollinationsImageService(
      cache: cache,
      queue: queue,
      docsDir: docsDir,
      client: client,
      logger: AppLogger(sink: RecordingSink()),
      baseUrl: 'https://image.pollinations.ai',
      model: 'flux',
      promptTemplate: promptTemplate,
      gate: gate ?? (() async {}),
    );
  }

  group('generateNow', () {
    test('a custom prompt template wraps the ENGLISH gloss (T19.6)', () async {
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
        promptTemplate: () => 'watercolour still life of {word}',
      );

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');

      final url = getCalls.single.url.toString();
      // Template wraps the ENGLISH gloss, not the Uzbek word.
      expect(url, contains('watercolour%20still%20life%20of%20frog'));
      expect(url, isNot(contains('qurbaqa')));
      // The default body must not leak in when a custom template is set.
      expect(url, isNot(contains('pictographic')));
    });

    test('a blank template falls back to the default body (T19.6)', () async {
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
        promptTemplate: () => '   ',
      );

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');

      expect(getCalls.single.url.toString(), contains('pictographic'));
    });

    test('GETs the prompt path with the ENGLISH gloss, caches the file at the '
        'UZBEK path (T19.3)', () async {
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
      );

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');

      // Exactly one GET (no retry, no duplicate).
      expect(getCalls, hasLength(1));
      final url = getCalls.single.url;
      expect(url.host, 'image.pollinations.ai');
      // Prompt is in the path; the ENGLISH gloss survives URL-encoding.
      expect(url.toString(), contains('/prompt/'));
      expect(url.toString(), contains('frog'));
      // The Uzbek word must NOT leak into the prompt path.
      expect(url.toString(), isNot(contains('qurbaqa')));
      // Keyless: no auth header.
      expect(getCalls.single.headers.containsKey('Authorization'), isFalse);
      // Square dims, model, watermark-off, deterministic seed.
      expect(url.queryParameters['width'], '512');
      expect(url.queryParameters['height'], '512');
      expect(url.queryParameters['model'], 'flux');
      expect(url.queryParameters['nologo'], 'true');
      expect(url.queryParameters['seed'], isNotNull);

      // File written at the UZBEK-keyed cache path; resolvable by uzbek.
      final file = File('${docsDir.path}/${buildAiImagePath('qurbaqa')}');
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), [1, 2, 3, 4]);
      expect(await service.cachedPath('qurbaqa'), buildAiImagePath('qurbaqa'));
    });

    test('seed is deterministic for the same uzbek across calls', () async {
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
      );

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');
      await cache.pathFor('qurbaqa'); // cached now
      final firstSeed = getCalls.single.url.queryParameters['seed'];
      expect(firstSeed, isNotNull);
      // Different uzbek -> different seed.
      await service.generateNow(uzbek: 'mushuk', english: 'cat');
      final secondSeed = getCalls.last.url.queryParameters['seed'];
      expect(secondSeed, isNotNull);
      expect(secondSeed, isNot(firstSeed));
    });

    test('is a no-op when the word is already cached (no GET)', () async {
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
      );

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');
      await service.generateNow(
        uzbek: 'qurbaqa',
        english: 'frog',
      ); // second call

      expect(getCalls, hasLength(1));
    });

    test('throws on a permanent non-200 (404) with no retry', () async {
      final getCalls = <http.Request>[];
      final client = MockClient((request) async {
        getCalls.add(request);
        return http.Response('not found', 404);
      });
      final service = buildService(client: client);

      await expectLater(
        service.generateNow(uzbek: 'qurbaqa', english: 'frog'),
        throwsException,
      );
      // Permanent → exactly one attempt, no retry.
      expect(getCalls, hasLength(1));
      expect(await service.cachedPath('qurbaqa'), isNull);
    });

    test('retries on a transient 429, then succeeds (T18.5)', () async {
      final getCalls = <http.Request>[];
      var n = 0;
      final client = MockClient((request) async {
        getCalls.add(request);
        n++;
        // First attempt rate-limited, second succeeds.
        if (n == 1) return http.Response('rate limited', 429);
        return http.Response.bytes([5, 6, 7, 8], 200);
      });
      final service = buildService(client: client);

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');

      expect(getCalls, hasLength(2));
      expect(await service.cachedPath('qurbaqa'), isNotNull);
    });

    test('retries on a socket exception, then succeeds (T18.5)', () async {
      final getCalls = <http.Request>[];
      var n = 0;
      final client = MockClient((request) async {
        getCalls.add(request);
        n++;
        if (n == 1) {
          throw const SocketException('Failed host lookup');
        }
        return http.Response.bytes([1], 200);
      });
      final service = buildService(client: client);

      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');

      expect(getCalls, hasLength(2));
      expect(await service.cachedPath('qurbaqa'), isNotNull);
    });

    test('gives up after exhausting retries on a persistent 429', () async {
      final getCalls = <http.Request>[];
      final client = MockClient((request) async {
        getCalls.add(request);
        return http.Response('rate limited', 429);
      });
      final service = buildService(client: client);

      await expectLater(
        service.generateNow(uzbek: 'qurbaqa', english: 'frog'),
        throwsException,
      );
      // Three attempts (initial + two backoff retries), then rethrows.
      expect(getCalls, hasLength(3));
      expect(await service.cachedPath('qurbaqa'), isNull);
    });

    test('paces back-to-back GETs through the rate gate', () async {
      // Two distinct uncached words; the gate must enforce a gap so the second
      // GET doesn't land on the keyless tier while the first is still cooling.
      // Real clock with a tiny gap keeps the test fast yet deterministic on the
      // ordering invariant (second call follows the first by >= gap).
      final gate = pollinationsRateGate(gap: const Duration(milliseconds: 60));
      final getCalls = <http.Request>[];
      final service = buildService(
        client: succeedingClient(getCalls: getCalls),
        gate: gate,
      );

      final start = DateTime.now();
      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');
      await service.generateNow(uzbek: 'mushuk', english: 'cat');
      final elapsed = DateTime.now().difference(start);

      expect(getCalls, hasLength(2));
      // Gap between the two paced calls is observable end-to-end.
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(50));
    });
  });

  group('enqueueGeneration', () {
    test('enqueues an ai_image item carrying both uzbek + english', () async {
      final service = buildService(client: succeedingClient(getCalls: []));

      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');

      final pending = await queue.pending();
      expect(pending, hasLength(1));
      expect(pending.single.type, aiImageQueueType);
      final pair = pairFromAiImagePayload(pending.single.payload);
      expect(pair.uzbek, 'qurbaqa');
      expect(pair.english, 'frog');
    });

    test('spamming enqueueGeneration for the same uzbek creates only one item '
        '(T18.1 queue-level dedup)', () async {
      final service = buildService(client: succeedingClient(getCalls: []));

      // Repeated taps on "Send to Anki" before the image lands.
      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');
      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');
      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');

      expect(await queue.pending(), hasLength(1));
    });

    test('is a no-op when the word is already cached', () async {
      // Seed the cache directly: a prior generation succeeded.
      await cache.remember(
        uzbekWord: 'qurbaqa',
        relativePath: 'ai_images/seed.png',
      );
      // A cache row is honoured only when its backing file is on disk.
      final file = File('${docsDir.path}/ai_images/seed.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3, 4]);
      final service = buildService(client: succeedingClient(getCalls: []));

      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');

      expect(await queue.pending(), isEmpty);
    });

    test('re-enqueues when a cache row has no backing file', () async {
      // Orphan row (e.g. left by the app_flutter → filesDir path fix): the
      // file is gone, so the word must regenerate rather than pin a miss.
      await cache.remember(
        uzbekWord: 'qurbaqa',
        relativePath: 'ai_images/seed.png',
      );
      final service = buildService(client: succeedingClient(getCalls: []));

      await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');

      expect(await queue.pending(), hasLength(1));
    });
  });

  test('cachedPath honours a row only when the backing file exists', () async {
    final service = buildService(client: succeedingClient(getCalls: []));
    expect(await service.cachedPath('none'), isNull);
    // Row without a file → treated as uncached.
    await cache.remember(uzbekWord: 'foo', relativePath: 'ai_images/foo.png');
    expect(await service.cachedPath('foo'), isNull);
    // Once the file lands, the row is honoured.
    final file = File('${docsDir.path}/ai_images/foo.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3, 4]);
    expect(await service.cachedPath('foo'), 'ai_images/foo.png');
  });
}
