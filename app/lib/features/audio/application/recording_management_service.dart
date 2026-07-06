// RecordingManagementService — orchestrates in-app rename + delete of an
// indexed recording (T10.4, T10.5). Pure sequencing over injected seams
// (recording repo, folder repo, SAF file service, app-data dir, logger), so
// the whole flow is provable without a device.
//
// Rename: sanitize the user base name → new filename with the recording's
// existing extension → SAF-rename the audio file → update the DB row's name +
// filePath together (the SAF URI stem can change on rename, so both move
// atomically to keep the next rescan keyed on the new path).
//
// Delete: best-effort delete the recording's image-log directory under
// app-private storage (a directory, per image_log_path clustering), best-effort
// SAF-delete the audio file, then a single DB row delete whose FK cascade drops
// review_events, word_logs, and coach-bank join rows. The DB delete is the
// source of truth — file-op failures are logged but don't block it.

import 'dart:io';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/recording/application/recording_file_service.dart';
import 'package:rivendell/features/audio/recording/domain/recording_filename.dart';

class RecordingManagementService {
  RecordingManagementService({
    required this.recordings,
    required this.folderRepository,
    required this.fileService,
    required this.appDocsDir,
    required this.logger,
  });

  final RecordingRepository recordings;
  final FolderRepository folderRepository;
  final RecordingFileService fileService;
  final String appDocsDir;
  final AppLogger logger;

  /// Rename recording [id] to [baseName] (a free-text base, no extension).
  /// Returns the new display name on success, or null if the recording or its
  /// folder is gone. Throws on SAF rename failure so the caller surfaces it
  /// without mutating the DB. If the SAF rename lands but the DB update fails,
  /// the file rename is rolled back so the on-disk name keeps matching the
  /// unchanged DB row — without that, the next rescan would re-add the renamed
  /// file as a new row and strand the old row's review history on a ghost.
  Future<String?> renameRecording(int id, String baseName) async {
    final rec = await recordings.findById(id);
    if (rec == null) return null;
    final sanitized = sanitizeRecordingBaseName(baseName);
    final base =
        sanitized ?? defaultRecordingBaseName(recordedAt: rec.createdAt);
    // Preserve the original container extension so a renamed .m4a stays .m4a.
    final newName = '$base.${rec.format}';
    final treeUri = await folderRepository.currentFolder();
    if (treeUri == null) return null;
    final newUri = await fileService.rename(
      docUri: rec.filePath,
      displayName: newName,
    );
    try {
      await recordings.updateNameAndPath(id, name: newName, filePath: newUri);
    } on Object catch (e) {
      logger.e(
        LogTag.core,
        'db update failed post-rename for $id, rolling back file: $e',
      );
      try {
        await fileService.rename(docUri: newUri, displayName: rec.name);
      } on Object catch (e2) {
        logger.e(LogTag.core, 'rename rollback failed for $id: $e2');
      }
      rethrow;
    }
    logger.i(LogTag.core, 'renamed recording $id → $newName');
    return newName;
  }

  /// Delete recording [id] — audio file, image-log directory, and the DB row
  /// (cascade drops its review events, word logs, and coach links). Returns
  /// true if a row was removed. File-op failures are logged but never block
  /// the DB delete.
  Future<bool> deleteRecording(int id) async {
    final rec = await recordings.findById(id);
    if (rec == null) return false;

    // Image-log files cluster under wordlog/<recordingId>/ (app-private — no
    // SAF needed). Best-effort: a missing dir is fine; an IO error is logged.
    final imageDir = Directory('$appDocsDir/wordlog/$id');
    try {
      if (imageDir.existsSync()) {
        imageDir.deleteSync(recursive: true);
      }
    } on Object catch (e) {
      logger.w(LogTag.wordlog, 'image dir cleanup failed for $id: $e');
    }

    // SAF-delete the audio file. Best-effort: if it's already gone the DB row
    // still drops; a permission blip is logged but doesn't strand the row.
    try {
      await fileService.delete(docUri: rec.filePath);
    } on Object catch (e) {
      logger.w(LogTag.record, 'audio file delete failed for $id: $e');
    }

    final removed = await recordings.deleteById(id);
    logger.i(LogTag.core, 'deleted recording $id (rows=$removed)');
    return removed > 0;
  }
}
