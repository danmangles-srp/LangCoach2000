// Riverpod wiring for the audio indexer. Under platform/ so the coverage gate
// excludes it (MethodChannel + foundation isolate glue, device-verified).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/platform/saf_audio_indexer_service.dart';

final audioIndexerServiceProvider = Provider<SafAudioIndexerService>((ref) {
  return SafAudioIndexerService(ref.watch(appLoggerProvider));
});
