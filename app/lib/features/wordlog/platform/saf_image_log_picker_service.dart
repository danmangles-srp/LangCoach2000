// coverage:ignore-file — thin MethodChannel wrapper; verified by the channel
// contract test. Opens the Android image picker via the rivendell/wordlog
// channel and returns the chosen content URI + extension (or null on cancel).

import 'package:flutter/services.dart';

import 'package:rivendell/features/wordlog/application/image_log_picker_service.dart';

class SafImageLogPickerService implements ImageLogPickerService {
  SafImageLogPickerService();

  static const MethodChannel _channel = MethodChannel('rivendell/wordlog');

  @override
  Future<PickedImage?> pickImage() async {
    try {
      final raw = await _channel.invokeMethod<Object>('pickImage');
      if (raw is Map) {
        return PickedImage(
          uri: raw['uri']! as String,
          extension: raw['ext']! as String,
        );
      }
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
