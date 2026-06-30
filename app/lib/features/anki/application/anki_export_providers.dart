// Provider for the Anki export service (M4, T4.2). Wires the gateway + logger
// into [AnkiExportService]; the export UI (T4.5) reads it here.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/anki/application/anki_export_service.dart';
import 'package:rivendell/features/anki/application/anki_providers.dart';

final ankiExportServiceProvider = Provider<AnkiExportService>(
  (ref) => AnkiExportService(
    gateway: ref.watch(ankiGatewayProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);
