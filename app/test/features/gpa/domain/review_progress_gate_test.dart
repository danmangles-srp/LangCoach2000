// ReviewProgressGate — the 80%-cross latch (T2.2, FR-1.2.3). Pure; no device.

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';
import 'package:rivendell/features/gpa/domain/review_progress_gate.dart';

PlaybackSnapshot _snap({
  int? recordingId,
  int positionMs = 0,
  int durationMs = 100_000,
}) {
  return PlaybackSnapshot(
    recordingId: recordingId,
    processingState: AudioProcessingState.ready,
    isPlaying: true,
    isCompleted: false,
    position: Duration(milliseconds: positionMs),
    duration: Duration(milliseconds: durationMs),
    bufferedPosition: Duration.zero,
    speed: 1,
  );
}

void main() {
  test('below 80% does not fire', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 10_000)), isFalse);
  });

  test('fires exactly once on the first >=80% snapshot', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 80_000)), isTrue);
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 85_000)), isFalse);
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 90_000)), isFalse);
  });

  test('dropping below 80% re-arms; the next crossing fires again', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 80_000)), isTrue);
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 50_000)), isFalse);
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 81_000)), isTrue);
  });

  test('a new recording re-arms the latch', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 80_000)), isTrue);
    // Recording 2 cued mid-way at 85%: id change resets, then it fires.
    expect(gate.evaluate(_snap(recordingId: 2, positionMs: 85_000)), isTrue);
  });

  test('idle snapshot (no recording) does not fire', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(const PlaybackSnapshot.idle()), isFalse);
  });

  test('unknown duration does not fire even at full position', () {
    final gate = ReviewProgressGate();
    expect(
      gate.evaluate(_snap(recordingId: 1, positionMs: 99, durationMs: 0)),
      isFalse,
    );
  });

  test('exactly 0.8 fires (boundary is inclusive)', () {
    final gate = ReviewProgressGate();
    expect(gate.evaluate(_snap(recordingId: 1, positionMs: 80_000)), isTrue);
  });
}
