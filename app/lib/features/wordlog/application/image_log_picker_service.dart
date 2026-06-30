// Abstract seam over the native photo picker (FR-1.3.1, T3.4). The platform
// impl opens the Android image picker and returns the chosen item's content
// URI + its extension (resolved from MIME on the Kotlin side, since a content
// URI carries no file suffix); returns null on cancel.

import 'package:flutter/foundation.dart';

@immutable
class PickedImage {
  const PickedImage({required this.uri, required this.extension});

  /// The content:// URI of the chosen image.
  final String uri;

  /// Lowercased extension with no dot (jpg / jpeg / png), resolved from MIME.
  final String extension;
}

abstract class ImageLogPickerService {
  /// Open the photo picker. Returns the chosen image + extension, or null if
  /// the user cancelled.
  Future<PickedImage?> pickImage();
}
