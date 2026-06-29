// Dart-side contract test for the SAF folder picker (T1.1 B2). The Kotlin
// host (ACTION_OPEN_DOCUMENT_TREE + takePersistableUriPermission) is verified
// on-device; this pins the MethodChannel contract from Dart: success returns
// the tree URI, a platform error degrades to null + a warning, and a missing
// handler (non-Android) does the same without throwing.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/platform/saf_folder_selection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rivendell/folder');
  final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

  late AppLogger logger;
  late RecordingSink sink;

  setUp(() {
    sink = RecordingSink();
    logger = AppLogger(sink: sink);
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the tree URI when the native side succeeds', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickFolder');
      return 'content://com.android.externalstorage.documents/tree/primary%3AVoice%20Recorder';
    });
    final uri = await SafFolderSelectionService(logger).pickFolder();
    expect(uri, startsWith('content://'));
    expect(sink.lines, isEmpty); // success path is silent
  });

  test('returns null and warns when the native side throws', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'PERMISSION_FAILED', message: 'denied');
    });
    final uri = await SafFolderSelectionService(logger).pickFolder();
    expect(uri, isNull);
    expect(sink.lines, isNotEmpty);
    expect(sink.lines.first, contains('PERMISSION_FAILED'));
  });

  test('returns null and warns when the channel is not registered', () async {
    // No handler → invokeMethod throws MissingPluginException.
    final uri = await SafFolderSelectionService(logger).pickFolder();
    expect(uri, isNull);
    expect(sink.lines.single, contains('not registered'));
  });
}
