// Microphone recorder port (FR-1.1.3, T2.7). Abstract so [RecorderController]
// depends on a pure seam and is unit-tested with a fake; the `record`-backed
// impl lives in platform/ (coverage-excluded). Records to a temp file path the
// controller chooses; the writer (below) lifts that file into the folder.

abstract class AudioRecorderService {
  /// True iff mic permission is granted. Implementations request it if absent.
  Future<bool> hasPermission();

  /// Begin recording to [path]. Returns true on success.
  Future<bool> start({required String path});

  /// Stop and finalize. Returns the path of the recorded file.
  Future<String?> stop();

  /// Whether a recording is in progress.
  Future<bool> isRecording();

  /// Release native resources (called on controller dispose).
  Future<void> dispose();
}
