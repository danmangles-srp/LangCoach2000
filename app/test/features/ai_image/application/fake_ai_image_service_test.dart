// FakeAiImageService contract (T4.3 → T19.3). The fake is the test double for
// the drain pipeline and for offline UI scaffolding; this pins its in-memory
// semantics so later tests that rely on it stay honest — including that the
// english it was asked to prompt is recorded (T19.3).

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/application/fake_ai_image_service.dart';

void main() {
  late FakeAiImageService service;

  setUp(() => service = FakeAiImageService());

  test('cachedPath is null until generateNow runs', () async {
    expect(await service.cachedPath('qurbaqa'), isNull);
  });

  test(
    'generateNow records a synthetic path keyed by uzbek + the pair',
    () async {
      await service.generateNow(uzbek: 'qurbaqa', english: 'frog');
      expect(await service.cachedPath('qurbaqa'), 'ai_images/fake_qurbaqa.png');
      expect(service.generated.single.uzbek, 'qurbaqa');
      expect(service.generated.single.english, 'frog');
    },
  );

  test('enqueueGeneration records the pair but does not generate', () async {
    await service.enqueueGeneration(uzbek: 'qurbaqa', english: 'frog');
    expect(service.enqueued.single.uzbek, 'qurbaqa');
    expect(service.enqueued.single.english, 'frog');
    expect(service.generated, isEmpty);
    expect(await service.cachedPath('qurbaqa'), isNull);
  });

  test('generateNow is idempotent on the uzbek key across calls', () async {
    await service.generateNow(uzbek: 'qurbaqa', english: 'frog');
    // A second drain with a different english still no-ops once cached.
    await service.generateNow(uzbek: 'qurbaqa', english: 'toad');
    expect(service.generated, hasLength(1));
    expect(await service.cachedPath('qurbaqa'), 'ai_images/fake_qurbaqa.png');
  });
}
