// Pure mapping from a raw SAF scan entry to a [ScannedFile]. Kept in domain/
// (no platform deps) so the extension/size/timestamp contract is unit-tested
// without a device, and so it can run inside a background isolate via
// [parseScannedEntries] (NFR-2.2.1 — a 1000-file parse must not block the UI).
//
// Entries arrive as untyped Maps: the MethodChannel codec (and the isolate
// message port) deserialize platform maps as Map<Object?, Object?>, so we key
// loosely and validate each value's runtime type rather than trusting generics.

import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';

/// Convert one raw channel entry into a [ScannedFile], or `null` if the name
/// isn't a supported audio container (the Kotlin side pre-filters, but this is
/// the trust boundary — a future SVR format or a stray file still lands here).
ScannedFile? scannedFileFromEntry(Map<dynamic, dynamic> entry) {
  final name = entry['name'];
  final path = entry['path'];
  if (name is! String || path is! String) return null;
  final format = AudioFormat.fromFileName(name);
  if (format == null) return null;
  final size = (entry['size'] as num?)?.toInt() ?? 0;
  final lastModified = (entry['lastModified'] as num?)?.toInt() ?? 0;
  return ScannedFile(
    path: path,
    name: name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(lastModified, isUtc: true),
    sizeBytes: size,
    format: format,
  );
}

/// Isolate-friendly parse of a whole raw scan list. Top-level so it can be
/// handed to `compute()`; drops anything [scannedFileFromEntry] rejects.
List<ScannedFile> parseScannedEntries(List<dynamic> raw) {
  return raw
      .whereType<Map<dynamic, dynamic>>()
      .map(scannedFileFromEntry)
      .whereType<ScannedFile>()
      .toList(growable: false);
}
