// Platform seam over renaming / deleting an indexed recording's audio file in
// the Samsung Voice Recorder folder (T10.4 rename, T10.5 delete). The file
// lives under the user-granted SAF tree, so both ops go through the Android
// DocumentsContract — direct `File` APIs would miss the SAF-mediated writes.
//
// Abstract so the orchestrator ([RecordingManagementService]) is provable
// without a device; the SAF impl lives in platform/. Throws [FileSystemException]
// on failure so the caller can surface a clear error.

abstract class RecordingFileService {
  /// Rename the document at [docUri] to [displayName], returning the new
  /// document URI. SAF rename can change the URI stem even when the name
  /// matches (e.g. a collision suffix), so the returned URI is authoritative —
  /// callers must persist it as the recording's new `filePath`.
  Future<String> rename({required String docUri, required String displayName});

  /// Delete the document at [docUri]. Returns true on success, false if the
  /// file is already gone (idempotent — a re-scan may have removed it).
  /// Throws on permission or I/O failure.
  Future<bool> delete({required String docUri});
}
