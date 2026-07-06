// App-relative storage path for an image word log (M3, FR-1.3.1). Pure: no I/O,
// no DateTime — the caller supplies a unique [stem] (e.g. a millisecond
// timestamp from the application layer), so this stays unit-testable. Images
// live under wordlog/<recordingId>/ so a recording's photos cluster and a
// future per-recording cleanup is a directory delete.

import 'package:rivendell/features/wordlog/domain/supported_image_format.dart';

/// Builds `wordlog/<recordingId>/<stem>.<ext>` from a validated [extension].
/// [extension] may be passed with or without a leading dot; unsupported
/// extensions throw — the caller must pre-validate with [isSupportedImageExt].
String buildImageLogPath({
  required int recordingId,
  required String stem,
  required String extension,
}) {
  if (!isSupportedImageExt(extension)) {
    throw ArgumentError.value(extension, 'extension', 'unsupported image type');
  }
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  return 'wordlog/$recordingId/$stem.${ext.toLowerCase()}';
}
