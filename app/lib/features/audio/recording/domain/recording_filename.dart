// Pure filename helpers for in-app recordings (FR-1.1.3, T2.7, T10.3). The
// recorder saves into the user-designated Samsung folder; a stable, sortable
// name keeps the new file discoverable in both Rivendell and the user's file
// manager. T10.3 lets the user edit the name while recording — these helpers
// expose the default base name (no extension) and sanitize free-text input.
//
// `recordedAt` is taken in (not DateTime.now()) so the format is deterministic
// and unit-testable. Local time, matching how the indexer stores `createdAt`
// (cursor epoch ms → DateTime.fromMillisecondsSinceEpoch, local).

const String _kRecordingExt = '.m4a';
const int _kRecordingNameMax = 80;

String _two(int n) => n.toString().padLeft(2, '0');
String _four(int n) => n.toString().padLeft(4, '0');

/// Default base name (no extension) for an in-app recording: sortable + unique
/// to the second when left untouched. The sheet seeds the editable name field
/// with this so a blank field still produces a useful filename.
String defaultRecordingBaseName({required DateTime recordedAt}) {
  final y = _four(recordedAt.year);
  final mo = _two(recordedAt.month);
  final d = _two(recordedAt.day);
  final h = _two(recordedAt.hour);
  final mi = _two(recordedAt.minute);
  final s = _two(recordedAt.second);
  return 'rivendell-$y-$mo$d-$h$mi$s';
}

/// `rivendell-YYYY-MMdd-HHmmss.m4a` — zero-padded, chronological on sort.
String buildRecordingFileName({required DateTime recordedAt}) =>
    '${defaultRecordingBaseName(recordedAt: recordedAt)}$_kRecordingExt';

/// Sanitize a user-entered base name into a safe filename for the Samsung
/// folder. Strips path separators and filesystem-illegal characters (the SAF
/// document contract rejects `/`, NUL, `:`, `*`, `?`, `"`, `<`, `>`, `|`,
/// backslash, and C0 control chars), collapses runs of replacement dashes,
/// trims leading/trailing dashes, and caps length. Returns `null` if nothing
/// usable remains — callers fall back to the timestamped default. Does NOT add
/// the extension; the caller appends it so the format stays centralized.
String? sanitizeRecordingBaseName(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'[\x00-\x1f/\\:*?"<>|]'), '-')
      .replaceAll(RegExp('-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '')
      .trim();
  if (cleaned.isEmpty) return null;
  return cleaned.length > _kRecordingNameMax
      ? cleaned.substring(0, _kRecordingNameMax)
      : cleaned;
}

/// Build the final save filename from a user-entered base name, falling back to
/// the timestamped default when [baseName] is null/blank/unsafe. Appends the
/// canonical extension.
String saveRecordingFileName({
  required String? baseName,
  required DateTime recordedAt,
}) {
  final sanitized = sanitizeRecordingBaseName(baseName ?? '');
  final base = sanitized ?? defaultRecordingBaseName(recordedAt: recordedAt);
  return '$base$_kRecordingExt';
}
