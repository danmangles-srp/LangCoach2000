// Latch that decides when an 80%-crossing earns a review-event append
// (FR-1.2.3, T2.2). Pure over [PlaybackSnapshot] so the fire / re-arm logic is
// unit-tested without the store or a device — the [ReviewProgressWatcher] owns
// the instance and performs the DB write.
//
// Fires exactly once per upward crossing per recording: stays armed after the
// first ≥80% snapshot until progress drops back below 80% (a seek-back or
// replay-from-start re-arms for a fresh review) OR the cued recording changes
// (loading a new recording mid-way starts a fresh latch).

import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';

class ReviewProgressGate {
  ReviewProgressGate({this.threshold = 0.8});

  final double threshold;
  int? _lastRecordingId;
  bool _crossed = false;

  /// `true` exactly once per upward 80%-crossing for the current recording;
  /// `false` otherwise. Ignores snapshots with no recording or unknown
  /// duration (progress would be 0 — no milestone to earn).
  bool evaluate(PlaybackSnapshot snapshot) {
    final id = snapshot.recordingId;
    if (id != _lastRecordingId) {
      _lastRecordingId = id;
      _crossed = false;
    }
    if (id == null) return false;
    if (snapshot.duration.inMilliseconds <= 0) return false;
    if (snapshot.progress >= threshold) {
      if (_crossed) return false;
      _crossed = true;
      return true;
    }
    _crossed = false;
    return false;
  }

  /// Force the latch back to its armed state for the current recording, so the
  /// next >=80% snapshot fires again without a recording change or a drop
  /// below the threshold (T15.4). The watcher calls this to retry an append
  /// that failed — playback is still past 80%, so there's no natural re-cross.
  void rearm() => _crossed = false;
}
