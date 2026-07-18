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

  // T15.9: the rethrown FileSystemException must carry the ORIGINAL platform
  // stack, not a fresh stack captured at the adapter's rethrow line —
  // otherwise a SAVE failure logs only the adapter, never the channel frame.
  test(
    'copyToFolder preserves the platform stack across the rethrow (T15.9)',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            throw PlatformException(code: 'COPY_FAILED', message: 'no'),
      );
      late StackTrace caught;
      try {
        await SafRecordingWriterService().copyToFolder(
          treeUri: 'content://tree',
          sourcePath: '/tmp/x.m4a',
          displayName: 'x.m4a',
        );
        fail('did not throw');
      } on FileSystemException catch (_, st) {
        caught = st;
      }
      // Pre-fix the rethrow's leading frame was this adapter's throw line;
      // post-fix the PlatformException's own stack survives, so the adapter is
      // no longer the leading frame.
      final leading = caught.toString().split('\n').first;
      expect(leading, isNot(contains('saf_recording_writer_service.dart')));
    },
  );

  test('publishToMediaStore returns void on success', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'publishToMediaStore');
      return null;
    });
    await SafRecordingWriterService().publishToMediaStore(
      sourceUri: 'content://x',
      displayName: 'x.m4a',
    );
  });

  test('publishToMediaStore preserves the platform stack across the rethrow '
      '(T15.9)', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'IO', message: 'x'),
    );
    late StackTrace caught;
    try {
      await SafRecordingWriterService().publishToMediaStore(
        sourceUri: 'content://x',
        displayName: 'x.m4a',
      );
      fail('did not throw');
    } on FileSystemException catch (_, st) {
      caught = st;
    }
    final leading = caught.toString().split('\n').first;
    expect(leading, isNot(contains('saf_recording_writer_service.dart')));
  });

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
