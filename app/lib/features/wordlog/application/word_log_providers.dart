// Riverpod wiring for the word-log feature (T3.1+). The repository wraps the
// Drift store; the image-log service orchestrates the attach pipeline. Both
// read off the singleton database.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/wordlog/application/image_log_picker_service.dart';
import 'package:rivendell/features/wordlog/application/image_log_service.dart';
import 'package:rivendell/features/wordlog/application/image_log_writer_service.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';
import 'package:rivendell/features/wordlog/platform/saf_image_log_picker_service.dart';
import 'package:rivendell/features/wordlog/platform/saf_image_writer_service.dart';

/// Singleton [WordLogRepository] over the local store.
final wordLogRepositoryProvider = FutureProvider<WordLogRepository>(
  (ref) async => WordLogRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Injectable wall clock so the stem (millisecond timestamp) is deterministic
/// in tests. Defaults to the real clock.
final imageLogClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

final imageLogWriterServiceProvider = Provider<ImageLogWriterService>(
  (_) => SafImageWriterService(),
);

final imageLogPickerServiceProvider = Provider<ImageLogPickerService>(
  (_) => SafImageLogPickerService(),
);

/// App documents directory (where images are copied). Resolved once and
/// cached; the panel joins it with each image's app-relative path.
final appDocsDirProvider = FutureProvider<String>(
  (ref) async => (await getApplicationDocumentsDirectory()).path,
);

/// Singleton [ImageLogService] wiring the writer, repo, and logger together.
final imageLogServiceProvider = FutureProvider<ImageLogService>((ref) async {
  final repository = await ref.watch(wordLogRepositoryProvider.future);
  return ImageLogService(
    repository: repository,
    writer: ref.watch(imageLogWriterServiceProvider),
    logger: ref.watch(appLoggerProvider),
    clock: ref.watch(imageLogClockProvider),
  );
});

/// All word-log rows for a recording (text + images). Drives the player viewer
/// panel (T3.4). Invalidate after an attach so the panel refetches.
final wordLogsForRecordingProvider = FutureProvider.family<List<WordLog>, int>((
  ref,
  recordingId,
) async {
  final repo = await ref.watch(wordLogRepositoryProvider.future);
  return repo.allForRecording(recordingId);
});
