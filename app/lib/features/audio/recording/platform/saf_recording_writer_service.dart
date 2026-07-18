// SAF folder writer (FR-1.1.3, T2.7). Calls the Kotlin `rivendell/record`
// channel to create a child document under the chosen tree URI and stream the
// temp recording into it. Lives under platform/ (coverage-excluded); the
// channel contract is pinned by the host-channel test, the byte copy is
// device-verified. Throws a [FileSystemException] on failure so the controller
// can surface an error.

import 'dart:io';

import 'package:flutter/services.dart';

import 'package:rivendell/features/audio/recording/application/recording_writer_service.dart';

class SafRecordingWriterService implements RecordingWriterService {
  static const MethodChannel _channel = MethodChannel('rivendell/record');

  /// Kotlin `copyToFolder` error codes.
  static const _noGrantCode = 'NO_PERSISTED_GRANT';

  @override
  Future<String> copyToFolder({
    required String treeUri,
    required String sourcePath,
    required String displayName,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'copyToFolder',
        <String, Object?>{
          'treeUri': treeUri,
          'sourcePath': sourcePath,
          'displayName': displayName,
        },
      );
      if (result == null) {
        throw const FileSystemException('copy returned no uri');
      }
      return result;
    } on PlatformException catch (e, st) {
      // NO_PERSISTED_GRANT = the SAF tree grant lapsed; route to re-pick
      // (T19.7). Anything else is a genuine IO/provider failure. Both paths
      // preserve the original stack (T15.9).
      if (e.code == _noGrantCode) {
        Error.throwWithStackTrace(FolderGrantLostException(e.message), st);
      }
      Error.throwWithStackTrace(
        FileSystemException('copy failed: ${e.code} ${e.message ?? ''}'),
        st,
      );
    }
  }

  @override
  Future<void> publishToMediaStore({
    required String sourceUri,
    required String displayName,
  }) async {
    try {
      await _channel.invokeMethod<void>(
        'publishToMediaStore',
        <String, Object?>{'sourceUri': sourceUri, 'displayName': displayName},
      );
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        FileSystemException(
          'mediastore publish failed: ${e.code} ${e.message ?? ''}',
        ),
        st,
      );
    }
  }
}
