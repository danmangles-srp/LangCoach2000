// Pure logic for recognising the Samsung Voice Recorder folder and guiding
// the first-run folder pick (FR-1.1.1). No platform deps — the matcher is the
// unit-testable heart of the "guess + confirm / allow-any warn-once" UX.

/// The folder Samsung Voice Recorder writes to by default. Seeds the
/// first-run prompt's hint and the non-SVR warn-once nudge. The user may pick
/// elsewhere; this never blocks a pick.
const voiceRecorderFolderName = 'Voice Recorder';

/// True if [folderUriOrPath] looks like the Samsung Voice Recorder directory.
///
/// Accepts either shape the platform layer may hand us:
///   - a filesystem path: `/storage/emulated/0/Voice Recorder`
///   - an Android SAF content tree URI:
///     `content://com.android.externalstorage.documents/tree/primary%3AVoice%20Recorder`
///
/// Conservative on purpose: matches the folder as a full segment (after
/// URL-decoding and splitting on `/` and `:`), so `VoiceRecorderNotes` or
/// `My Voice Recorder Backup` don't false-positive. Empty/blank → false.
/// (Backslash handling is omitted — Android paths and SAF URIs use `/`.)
bool looksLikeVoiceRecorderFolder(String folderUriOrPath) {
  if (folderUriOrPath.trim().isEmpty) return false;
  final decoded = Uri.decodeFull(folderUriOrPath).toLowerCase();
  final target = voiceRecorderFolderName.toLowerCase();
  // SAF tree URIs for the primary volume encode the folder after `primary:`,
  // so `:` is also a segment boundary. Splitting on it lets `primary:Voice
  // Recorder` match without false-positiving on a colon elsewhere.
  final segments = decoded.replaceAll(':', '/').split('/');
  return segments.contains(target);
}
