// Deck + tag naming for Anki export (M4, FR-1.3.3). One localized deck holds
// every Rivendell card; the source recording tags each note so a learner can
// filter "what came from this lecture" inside Anki. Anki tags are
// space-delimited in storage, so a tag may not itself contain a space — the
// recording name is sanitized (spaces → underscores) before use.

/// The single deck Rivendell exports into.
const String ankiDeckName = 'Rivendell';

/// Turn a recording's file name into a safe Anki tag.
///
/// "My Lecture 3.m4a" → "My_Lecture_3.m4a". Whitespace runs collapse to a
/// single underscore; the rest of the name (extension included) is kept so
/// the tag matches what the user sees in the library.
String ankiTagForRecording(String recordingName) {
  return recordingName.replaceAll(RegExp(r'\s+'), '_');
}
