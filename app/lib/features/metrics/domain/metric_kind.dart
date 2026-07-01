// The engagement metrics Rivendell tracks (M6, FR-1.5.1). Only the kinds with
// no authoritative source table are written to the metrics_events ledger; the
// two derivable metrics (journaling output, completed queue items) are read
// straight from word_logs / review_events in T6.2 to stay single-source.

/// The metrics stored as ledger rows in the metrics_events table.
enum MetricKind {
  /// Accumulated listening time, in milliseconds. Ingested by the playback
  /// position accumulator (T6.1b follow-up: player wiring).
  lessonDuration('lesson_duration'),

  /// Flashcards sent to AnkiDroid in a successful export. Ingested by the
  /// Anki export button on each run.
  flashcardsReviewed('flashcards_reviewed');

  const MetricKind(this.columnValue);

  /// The string persisted in the `kind` column. Stable across renames.
  final String columnValue;

  static MetricKind fromColumn(String value) {
    return MetricKind.values.firstWhere(
      (k) => k.columnValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'unknown MetricKind'),
    );
  }
}
