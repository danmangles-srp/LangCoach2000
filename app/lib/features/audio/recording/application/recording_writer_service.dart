// Folder-writer port (FR-1.1.3, T2.7). Lifts a recorded temp file into the
// user-designated Samsung folder via the SAF write grant, returning the new
// document's URI (the same shape the indexer scans). Abstract so the
// controller is unit-tested with a fake; the Kotlin channel impl is in
// platform/. Throws on failure — the controller surfaces an error state.

/// The persistable SAF write grant for the chosen folder is no longer held
/// (app reinstall, data clear, OS prune, or never persisted). Distinct from a
/// generic IO failure so the controller can route the user to re-pick the
/// folder rather than retrying a write that will keep failing (T19.7).
class FolderGrantLostException implements Exception {
  const FolderGrantLostException([this.message]);
  final String? message;

  @override
  String toString() => message == null
      ? 'FolderGrantLostException'
      : 'FolderGrantLostException: $message';
}

abstract class RecordingWriterService {
  /// Copy [sourcePath] into [treeUri] as [displayName], returning the new
  /// document URI string. Overwrites are NOT collapsed — callers ensure a
  /// unique name (the filename builder is timestamped to the second).
  Future<String> copyToFolder({
    required String treeUri,
    required String sourcePath,
    required String displayName,
  });

  /// Publish the just-saved recording ([sourceUri] = the doc URI returned by
  /// [copyToFolder]) into MediaStore so Samsung Voice Recorder's "All
  /// recordings" tab surfaces it (T14.5). Throws on failure — the caller logs
  /// and continues, since the SAF copy has already succeeded and MediaStore
  /// visibility is purely additive.
  Future<void> publishToMediaStore({
    required String sourceUri,
    required String displayName,
  });
}
