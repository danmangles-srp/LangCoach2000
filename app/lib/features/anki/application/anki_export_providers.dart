// Provider for the Anki export service (M4, T4.2 / T4.4). Wires the gateway +
// AI image service + logger into [AnkiExportService]; the export UI (T4.5)
// reads it here.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/anki/application/anki_export_service.dart';
import 'package:rivendell/features/anki/application/anki_providers.dart';

final ankiExportServiceProvider = FutureProvider<AnkiExportService>((
  ref,
) async {
  final aiImageService = await ref.watch(aiImageServiceProvider.future);
  return AnkiExportService(
    gateway: ref.watch(ankiGatewayProvider),
    aiImageService: aiImageService,
    logger: ref.watch(appLoggerProvider),
  );
});
