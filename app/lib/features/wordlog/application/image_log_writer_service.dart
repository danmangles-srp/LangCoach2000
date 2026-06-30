// Abstract seam over the platform copy of a picked image into app data
// (FR-1.3.1). The platform impl streams the source content URI's bytes into
// `File(filesDir, destRelativePath)` via a Kotlin channel; the seam keeps the
// orchestrator (and its tests) device-free.

abstract class ImageLogWriterService {
  /// Copy the image at [sourceUri] (a content:// URI handed back by the photo
  /// picker) into app-private storage at [destRelativePath]. Throws on any I/O
  /// or permission failure — the caller surfaces it and does not insert a row.
  Future<void> copyIntoAppData({
    required String sourceUri,
    required String destRelativePath,
  });
}
