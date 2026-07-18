// ImageLogService — orchestrates the attach pipeline (FR-1.3.1, T3.3): given a
// picked image's content URI, copy its bytes into app-private storage, then
// record the app-relative path as an image word log on the recording. Pure
// orchestration over injected seams (writer + repo + clock), so the whole
// flow is provable without a device. On a copy failure nothing is inserted —
// no orphan row pointing at a file that was never written.

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';
import 'package:rivendell/features/wordlog/application/image_log_writer_service.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';
import 'package:rivendell/features/wordlog/domain/image_log_path.dart';

class ImageLogService {
  ImageLogService({
    required this.repository,
    required this.writer,
    required this.logger,
    required this.clock,
    this.xp,
  });

  final WordLogRepository repository;
  final ImageLogWriterService writer;
  final AppLogger logger;
  final DateTime Function() clock;

  /// Optional XP sink (M11 T11.2). When wired, a successful attach awards +5.
  final XpRepository? xp;

  /// Attach [sourceUri] (a photo-picker content URI) to [recordingId] as a
  /// JPG/PNG word log. The extension must be a supported image type; the path
  /// builder validates it. Returns the stored app-relative path. Throws if the
  /// copy fails — the caller surfaces the error and no database row is made.
  Future<String> attach({
    required int recordingId,
    required String sourceUri,
    required String extension,
  }) async {
    final stem = clock().millisecondsSinceEpoch.toString();
    final dest = buildImageLogPath(
      recordingId: recordingId,
      stem: stem,
      extension: extension,
    );
    try {
      await writer.copyIntoAppData(
        sourceUri: sourceUri,
        destRelativePath: dest,
      );
    } on Object catch (e) {
      logger.e(LogTag.wordlog, 'image copy failed for $recordingId: $e');
      rethrow;
    }
    await repository.addImage(recordingId, path: dest);
    // M11 T11.2: a successful image attach awards +5 (a word-log attach). Not
    // in addImage's tx — an image with no award is a trivial inconsistency,
    // and wrapping would mean handing this service the db handle.
    await xp?.record(
      source: XpSource.wordlog,
      points: 5,
      recordingId: recordingId,
    );
    logger.i(LogTag.wordlog, 'attached image → $dest');
    return dest;
  }
}
