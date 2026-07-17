// SafImageLogPickerService channel contract — T3.4 (FR-1.3.1). Pins the
// pickImage channel name, the {uri, ext} result shape, and null-on-cancel.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/wordlog/platform/saf_image_log_picker_service.dart';

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

  test('returns a PickedImage from the channel map', () async {
    mockHandler((call) async {
      if (call.method == 'pickImage') {
        return <String, String>{'uri': 'content://media/42', 'ext': 'jpg'};
      }
      return null;
    });

    final picked = await SafImageLogPickerService().pickImage();
    expect(picked, isNotNull);
    expect(picked!.uri, 'content://media/42');
    expect(picked.extension, 'jpg');
  });

  test('null result (user cancelled) yields null', () async {
    mockHandler((call) async => null);
    expect(await SafImageLogPickerService().pickImage(), isNull);
  });
}
