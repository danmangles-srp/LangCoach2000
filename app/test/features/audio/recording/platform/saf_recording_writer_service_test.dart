// Dart-side contract test for the SAF folder writer (T2.7). The Kotlin byte
// copy is device-verified; this pins the MethodChannel contract: success
// returns the new document URI, a platform error degrades to a
// FileSystemException, a lapsed grant surfaces a typed
// FolderGrantLostException (T19.7), and the arg shape matches the Kotlin
// handler.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/recording/application/recording_writer_service.dart';
import 'package:rivendell/features/audio/recording/platform/saf_recording_writer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rivendell/record');
  final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the document URI the channel hands back', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'copyToFolder');
      expect(call.arguments, {
        'treeUri': 'content://tree',
        'sourcePath': '/tmp/x.m4a',
        'displayName': 'rivendell-x.m4a',
      });
      return 'content://tree/document/rivendell-x.m4a';
    });
    final uri = await SafRecordingWriterService().copyToFolder(
      treeUri: 'content://tree',
      sourcePath: '/tmp/x.m4a',
      displayName: 'rivendell-x.m4a',
    );
    expect(uri, 'content://tree/document/rivendell-x.m4a');
  });

  test('a null result throws a FileSystemException', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(
      () => SafRecordingWriterService().copyToFolder(
        treeUri: 'content://tree',
        sourcePath: '/tmp/x.m4a',
        displayName: 'x.m4a',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('a PlatformException degrades to a FileSystemException', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async =>
          throw PlatformException(code: 'COPY_FAILED', message: 'no'),
    );
    expect(
      () => SafRecordingWriterService().copyToFolder(
        treeUri: 'content://tree',
        sourcePath: '/tmp/x.m4a',
        displayName: 'x.m4a',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  // T19.7: the NO_PERSISTED_GRANT code (lapsed SAF tree grant) maps to the
  // typed exception so the controller can route to re-pick.
  test(
    'a NO_PERSISTED_GRANT PlatformException throws FolderGrantLostException',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(
          code: 'NO_PERSISTED_GRANT',
          message: 'gone',
        ),
      );
      expect(
        () => SafRecordingWriterService().copyToFolder(
          treeUri: 'content://tree',
          sourcePath: '/tmp/x.m4a',
          displayName: 'x.m4a',
        ),
        throwsA(isA<FolderGrantLostException>()),
      );
    },
  );

  test('a missing handler (non-Android) throws', () async {
    expect(
      () => SafRecordingWriterService().copyToFolder(
        treeUri: 'content://tree',
        sourcePath: '/tmp/x.m4a',
        displayName: 'x.m4a',
      ),
      throwsA(isA<MissingPluginException>()),
    );
  });
}
