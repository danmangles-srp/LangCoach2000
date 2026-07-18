// SafImageWriterService channel contract — T3.3 (FR-1.3.1). Presentation/
// platform is coverage-excluded; this pins the channel name + arg shape +
// error mapping so a Kotlin-side change that breaks the contract fails here.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/wordlog/platform/saf_image_writer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('rivendell/wordlog'),
          null,
        ),
  );

  void mockHandler(Future<Object?>? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('rivendell/wordlog'),
          handler,
        );
  }

  test('invokes copyImage with the source URI + dest path', () async {
    Map<String, dynamic>? args;
    mockHandler((call) async {
      if (call.method == 'copyImage') {
        args = Map<String, dynamic>.from(call.arguments as Map);
      }
      return null;
    });

    await SafImageWriterService().copyIntoAppData(
      sourceUri: 'content://picker/note.jpg',
      destRelativePath: 'wordlog/7/s.jpg',
    );

    expect(args, {
      'sourceUri': 'content://picker/note.jpg',
      'destRelativePath': 'wordlog/7/s.jpg',
    });
  });

  test('a PlatformException degrades to a FileSystemException', () async {
    mockHandler((_) async {
      throw PlatformException(code: 'IO', message: 'read failed');
    });

    await expectLater(
      SafImageWriterService().copyIntoAppData(
        sourceUri: 'content://x',
        destRelativePath: 'wordlog/7/s.jpg',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });

  // T15.9: the rethrow must keep the original platform stack so an image-copy
  // failure points into the channel machinery, not this adapter's rethrow line.
  test('preserves the platform stack across the rethrow (T15.9)', () async {
    mockHandler((_) async {
      throw PlatformException(code: 'IO', message: 'read failed');
    });

    late StackTrace caught;
    try {
      await SafImageWriterService().copyIntoAppData(
        sourceUri: 'content://x',
        destRelativePath: 'wordlog/7/s.jpg',
      );
      fail('did not throw');
    } on FileSystemException catch (_, st) {
      caught = st;
    }

    // Pre-fix the rethrow's leading frame was this adapter's throw line;
    // post-fix the PlatformException's own stack survives.
    final leading = caught.toString().split('\n').first;
    expect(leading, isNot(contains('saf_image_writer_service.dart')));
  });

  test(
    'a missing handler (non-Android) throws a FileSystemException',
    () async {
      // No mock set up → MissingPluginException.
      await expectLater(
        SafImageWriterService().copyIntoAppData(
          sourceUri: 'content://x',
          destRelativePath: 'wordlog/7/s.jpg',
        ),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}
