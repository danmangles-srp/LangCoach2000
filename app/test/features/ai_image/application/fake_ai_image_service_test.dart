// FakeAiImageService contract (T4.3). The fake is the test double for the drain
// pipeline and for offline UI scaffolding; this pins its in-memory semantics so
// later tests that rely on it stay honest.

import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/ai_image/application/fake_ai_image_service.dart';

void main() {
  late FakeAiImageService service;

  setUp(() => service = FakeAiImageService());

  test('cachedPath is null until generateNow runs', () async {
    expect(await service.cachedPath('salom'), isNull);
  });

  test('generateNow records a synthetic path and the call', () async {
    await service.generateNow('salom');
    expect(await service.cachedPath('salom'), 'ai_images/fake_salom.png');
    expect(service.generated, ['salom']);
  });

  test('enqueueGeneration records the call but does not generate', () async {
    await service.enqueueGeneration('salom');
    expect(service.enqueued, ['salom']);
    expect(service.generated, isEmpty);
    expect(await service.cachedPath('salom'), isNull);
  });
}
