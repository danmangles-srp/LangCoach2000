// Dart-side contract test for the SAF audio indexer (T1.2). The Kotlin cursor
// walk is device-verified; this pins the MethodChannel contract from Dart:
// success hands the raw list to the off-isolate parser (and returns typed
// ScannedFiles), a platform error degrades to [], and a missing handler
// (non-Android) does the same without throwing.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/audio/platform/saf_audio_indexer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rivendell/scan');
  final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

  late AppLogger logger;

  setUp(() {
    logger = AppLogger(sink: RecordingSink());
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('parses the raw list into supported ScannedFiles', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'listAudioFiles');
      expect(call.arguments, {'treeUri': 'content://folder'});
      return [
        {'path': 'a', 'name': 'a.m4a', 'size': 10, 'lastModified': 1},
        {'path': 'b', 'name': 'b.flac', 'size': 20, 'lastModified': 2},
      ];
    });
    final files = await SafAudioIndexerService(logger).scan('content://folder');
    expect(files, hasLength(1)); // flac filtered by the mapper
    expect(files.single.name, 'a.m4a');
    expect(files.single.format, AudioFormat.m4a);
  });

  test('returns an empty list on PlatformException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'SCAN_FAILED', message: 'denied');
    });
    final files = await SafAudioIndexerService(logger).scan('content://folder');
    expect(files, isEmpty);
  });

  test('returns an empty list when the channel is not registered', () async {
    final files = await SafAudioIndexerService(logger).scan('content://folder');
    expect(files, isEmpty);
  });
}
