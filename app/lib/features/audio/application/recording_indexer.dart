// Orchestrates a library scan: read the chosen folder, list its audio files via
// the indexer seam, upsert into the store. Pure logic over injected seams so
// the contract (no-folder short-circuit, scan -> upsert count) is unit-tested
// with a fake indexer + in-memory store. The platform MethodChannel scan and
// the off-isolate parse live in platform/ + domain/.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/application/audio_indexer_service.dart';
import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/platform/audio_indexer_providers.dart';

class RecordingIndexer {
  RecordingIndexer({
    required FolderRepository folderRepository,
    required RecordingRepository recordingRepository,
    required this._indexer,
    required this._logger,
  }) : _folder = folderRepository,
       _recordings = recordingRepository;

  final FolderRepository _folder;
  final RecordingRepository _recordings;
  final AudioIndexerService _indexer;
  final AppLogger _logger;

  /// Scan the chosen folder and upsert the result. Returns the number of files
  /// written (inserts + updates). A no-op (0) when no folder is set — startup
  /// and refresh both call this, and the pre-onboarding state must be safe.
  Future<int> scanAndStore() async {
    final folder = await _folder.currentFolder();
    if (folder == null) {
      _logger.w(LogTag.audio, 'scan requested but no folder is set');
      return 0;
    }
    final scanned = await _indexer.scan(folder);
    final written = await _recordings.upsertScanned(scanned);
    _logger.i(LogTag.audio, 'indexed $written file(s) from folder');
    return written;
  }
}

final recordingIndexerProvider = FutureProvider<RecordingIndexer>((ref) async {
  return RecordingIndexer(
    folderRepository: await ref.watch(folderRepositoryProvider.future),
    recordingRepository: await ref.watch(recordingRepositoryProvider.future),
    indexer: ref.watch(audioIndexerServiceProvider),
    logger: ref.watch(appLoggerProvider),
  );
});
