// Supported audio container formats (FR-1.1.1: `.m4a`, `.mp3`, `.wav`).
//
// Stored as the enum name in the `recordings.format` text column (encoded at
// the repository seam via `f.format.name`, decoded via `formatOf`). Plain text
// is used instead of a Drift TypeConverter — `EnumNameConverter` misgenerates
// in drift 2.34. Parsed from a filename/extension at index time.

/// Audio container formats Rivendell indexes and plays.
enum AudioFormat {
  m4a,
  mp3,
  wav;

  /// Parse the format from a filename or bare extension. Returns `null` for
  /// anything Rivendell doesn't index (e.g. `.aac`, `.flac`) so the indexer
  /// can skip it.
  static AudioFormat? fromFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    return switch (name.substring(dot + 1).toLowerCase()) {
      'm4a' => AudioFormat.m4a,
      'mp3' => AudioFormat.mp3,
      'wav' => AudioFormat.wav,
      _ => null,
    };
  }
}
