// Folder-writer port (FR-1.1.3, T2.7). Lifts a recorded temp file into the
// user-designated Samsung folder via the SAF write grant, returning the new
// document's URI (the same shape the indexer scans). Abstract so the
// controller is unit-tested with a fake; the Kotlin channel impl is in
// platform/. Throws on failure — the controller surfaces an error state.

abstract class RecordingWriterService {
  /// Copy [sourcePath] into [treeUri] as [displayName], returning the new
  /// document URI string. Overwrites are NOT collapsed — callers ensure a
  /// unique name (the filename builder is timestamped to the second).
  Future<String> copyToFolder({
    required String treeUri,
    required String sourcePath,
    required String displayName,
  });
}
