// Pure presentation helpers for recordings. No platform or widget deps — the
// duration/size formatting is unit-tested directly. Keeping these out of the
// widget tree means the list screen stays a thin AsyncValue→widget mapping.

/// Format a duration in milliseconds as `m:ss` (or `h:mm:ss` past an hour).
///
/// Returns `null` when the duration isn't known yet — the indexer reads
/// filesystem metadata only, so `durationMs` is filled lazily at first play.
/// Callers map `null` to the localized "—" placeholder.
String? formatDurationMs(int? millis) {
  if (millis == null || millis < 0) return null;
  final totalSeconds = millis ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}

/// Human-readable file size from bytes (e.g. "1.2 MB"). Uses binary units
/// (1024) to match Android file managers.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB'];
  var size = bytes / 1024;
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unit]}';
}
