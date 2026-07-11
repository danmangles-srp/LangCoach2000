// Live (network) verification of the Pollinations image pipeline. These hit
// the real `image.pollinations.ai` endpoint, so they are skipped by default
// and only run when RUN_LIVE=1 — keeping the offline gate deterministic while
// giving us a one-command way to confirm the URL/host/params the service builds
// actually round-trip to image bytes on the real API.
//
// Run from app/:
//   RUN_LIVE=1 flutter test \
//     test/features/ai_image/application/pollinations_image_service_live_test.dart
//
// (Windows PowerShell:  $env:RUN_LIVE=1; flutter test <path>)

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/pollinations_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_path.dart';
import 'package:rivendell/features/ai_image/platform/pollinations_config.dart';

final bool _live = Platform.environment['RUN_LIVE'] == '1';
const _skipReason = 'set RUN_LIVE=1 to hit the real pollinations endpoint';

/// True iff [bytes] start with a PNG or JPEG magic-number header.
bool _looksLikeImage(List<int> bytes) {
  if (bytes.length < 4) return false;
  final png =
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47;
  final jpeg = bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff;
  return png || jpeg;
}

void main() {
  test(
    'raw GET to the pollinations prompt URL returns image bytes',
    () async {
      final url = Uri.parse(
        '$pollinationsBaseUrl/prompt/${Uri.encodeComponent('a simple minimalist illustration of a cat')}'
        '?width=512&height=512&nologo=true&model=$pollinationsModel&seed=42',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 60));

      expect(response.statusCode, 200, reason: response.body);
      expect(response.bodyBytes, isNotEmpty);
      expect(
        _looksLikeImage(response.bodyBytes),
        isTrue,
        reason:
            'first bytes: '
            '${response.bodyBytes.take(8).toList()}',
      );
    },
    skip: _live ? false : _skipReason,
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'PollinationsImageService.generateNow writes a real image + caches it',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final cache = AiImageCacheRepository(db);
      final queue = QueueRepository(db);
      final docsDir = await Directory.systemTemp.createTemp(
        'pollinations_live',
      );
      addTearDown(() async {
        await db.close();
        if (docsDir.existsSync()) await docsDir.delete(recursive: true);
      });

      final service = PollinationsImageService(
        cache: cache,
        queue: queue,
        docsDir: docsDir,
        client: http.Client(),
        logger: AppLogger(sink: RecordingSink()),
        baseUrl: pollinationsBaseUrl,
        model: pollinationsModel,
      );

      await service
          .generateNow(uzbek: 'mushuk', english: 'cat')
          .timeout(const Duration(seconds: 60));

      final file = File('${docsDir.path}/${buildAiImagePath('mushuk')}');
      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(1024));
      expect(
        _looksLikeImage(bytes),
        isTrue,
        reason: 'first bytes: ${bytes.take(8).toList()}',
      );
      expect(await service.cachedPath('cat'), buildAiImagePath('cat'));
    },
    skip: _live ? false : _skipReason,
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
