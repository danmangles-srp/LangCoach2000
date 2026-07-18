// SAF rename + delete for indexed recordings (T10.4 / T10.5). Calls the Kotlin
// `rivendell/record` channel — `renameDocument` returns the new URI (SAF may
// change the URI stem); `deleteDocument` returns whether a row was removed.
// Lives under platform/ (coverage-excluded); the channel contract is pinned by
// the host-channel test, the file ops are device-verified.

import 'dart:io';

import 'package:flutter/services.dart';

import 'package:rivendell/features/audio/recording/application/recording_file_service.dart';

class SafRecordingFileService implements RecordingFileService {
  static const MethodChannel _channel = MethodChannel('rivendell/record');

  @override
  Future<String> rename({
    required String docUri,
    required String displayName,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'renameDocument',
        <String, Object?>{'docUri': docUri, 'displayName': displayName},
      );
      if (result == null) {
        throw const FileSystemException('rename returned no uri');
      }
      return result;
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        FileSystemException('rename failed: ${e.code} ${e.message ?? ''}'),
        st,
      );
    }
  }

  @override
  Future<bool> delete({required String docUri}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'deleteDocument',
        <String, Object?>{'docUri': docUri},
      );
      return result ?? false;
    } on PlatformException catch (e, st) {
      Error.throwWithStackTrace(
        FileSystemException('delete failed: ${e.code} ${e.message ?? ''}'),
        st,
      );
    }
  }
}
