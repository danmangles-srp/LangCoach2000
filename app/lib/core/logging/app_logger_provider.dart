// Riverpod wiring for AppLogger.
//
// The default uses [DebugPrintSink] (no-op outside debug builds). Tests
// override this provider with a [RecordingSink]-backed logger.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger.dart';

final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger(sink: const DebugPrintSink());
});
