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
    } on PlatformException catch (e) {
      throw FileSystemException('copy failed: ${e.code} ${e.message ?? ''}');
    }
  }
}
