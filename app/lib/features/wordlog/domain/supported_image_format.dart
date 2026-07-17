// Supported notebook-photo formats (M3, FR-1.3.1: JPG/PNG). Centralized so the
// path builder and the picker stay in sync on what's accepted.

/// Lowercased extensions (no dot) the word log accepts for images.
const supportedImageExtensions = <String>{'jpg', 'jpeg', 'png'};

/// True when [value] is a supported image extension, with or without a dot,
/// case-insensitive. Anything else is rejected before we copy bytes.
bool isSupportedImageExt(String value) {
  final clean = value.toLowerCase();
  final noDot = clean.startsWith('.') ? clean.substring(1) : clean;
  return supportedImageExtensions.contains(noDot);
}
