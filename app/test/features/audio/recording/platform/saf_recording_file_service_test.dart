// Dart-side contract test for SAF rename + delete (T10.4 / T10.5). The Kotlin
// byte ops are device-verified; this pins the MethodChannel contract —
// `renameDocument` returns the new URI, `deleteDocument` returns whether a row
// was removed, and both rethrow a FileSystemException that carries the
// ORIGINAL platform stack (T15.9), not a fresh stack at the rethrow line.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/recording/platform/saf_recording_file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rivendell/record');
  final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('rename', () {
    test('returns the new URI the channel hands back', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'renameDocument');
        expect(call.arguments, {
          'docUri': 'content://doc',
          'displayName': 'renamed.m4a',
        });
        return 'content://doc/renamed.m4a';
      });
      final uri = await SafRecordingFileService().rename(
        docUri: 'content://doc',
        displayName: 'renamed.m4a',
      );
      expect(uri, 'content://doc/renamed.m4a');
    });

    test('a null result throws a FileSystemException', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      expect(
        () => SafRecordingFileService().rename(
          docUri: 'content://doc',
          displayName: 'renamed.m4a',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('preserves the platform stack across the rethrow (T15.9)', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            throw PlatformException(code: 'RENAME_FAILED', message: 'no'),
      );
      late StackTrace caught;
      try {
        await SafRecordingFileService().rename(
          docUri: 'content://doc',
          displayName: 'renamed.m4a',
        );
        fail('did not throw');
      } on FileSystemException catch (_, st) {
        caught = st;
      }
      // Pre-fix, the rethrow captured a fresh stack whose leading frame was
      // this adapter's throw line. Post-fix the PlatformException's own stack
      // (reconstructed by the channel codec) survives, so the adapter is no
      // longer the leading frame — a failure log points into the platform
      // machinery, not the rethrow.
      final leading = caught.toString().split('\n').first;
      expect(leading, isNot(contains('saf_recording_file_service.dart')));
    });
  });

  group('delete', () {
    test('returns true when the channel removed a row', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'deleteDocument');
        expect(call.arguments, {'docUri': 'content://doc'});
        return true;
      });
      expect(
        await SafRecordingFileService().delete(docUri: 'content://doc'),
        isTrue,
      );
    });

    test('returns false on a null result', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);
      expect(
        await SafRecordingFileService().delete(docUri: 'content://doc'),
        isFalse,
      );
    });

    test('preserves the platform stack across the rethrow (T15.9)', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async =>
            throw PlatformException(code: 'DELETE_FAILED', message: 'no'),
      );
      late StackTrace caught;
      try {
        await SafRecordingFileService().delete(docUri: 'content://doc');
        fail('did not throw');
      } on FileSystemException catch (_, st) {
        caught = st;
      }
      // See rename: the adapter must not overwrite the platform stack with its
      // own rethrow line.
      final leading = caught.toString().split('\n').first;
      expect(leading, isNot(contains('saf_recording_file_service.dart')));
    });
  });
}
