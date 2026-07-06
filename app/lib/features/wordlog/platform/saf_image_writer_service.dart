// coverage:ignore-file — thin MethodChannel wrapper; verified by the channel
// contract test, not logic coverage. Streams a picked image's content URI
// into app-private storage at a relative path (FR-1.3.1, T3.3). The Kotlin
// side (MainActivity WORDLOG_CHANNEL) does the actual File I/O off the main
// thread.

import 'dart:io';

import 'package:flutter/services.dart';

import 'package:rivendell/features/wordlog/application/image_log_writer_service.dart';

class SafImageWriterService implements ImageLogWriterService {
  SafImageWriterService();

  static const MethodChannel _channel = MethodChannel('rivendell/wordlog');

  @override
  Future<void> copyIntoAppData({
    required String sourceUri,
    required String destRelativePath,
  }) async {
    try {
      await _channel.invokeMethod<void>('copyImage', <String, dynamic>{
        'sourceUri': sourceUri,
        'destRelativePath': destRelativePath,
      });
    } on PlatformException catch (e) {
      throw FileSystemException(
        'image copy failed: ${e.code} ${e.message ?? ''}',
      );
    } on MissingPluginException {
      throw const FileSystemException(
        'wordlog channel not available on this platform',
      );
    }
  }
}
