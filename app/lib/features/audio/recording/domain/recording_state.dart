// Immutable UI state for the in-app recorder (FR-1.1.3, T2.7). Hand-rolled to
// match the project's model convention (no freezed in lib yet); the controller
// owns transitions, the sheet renders off phase + elapsed.

import 'package:flutter/foundation.dart';

enum RecordPhase { idle, requesting, recording, saving, error }

@immutable
class RecordingState {
  const RecordingState({
    this.phase = RecordPhase.idle,
    this.elapsed = Duration.zero,
    this.error,
  });

  final RecordPhase phase;
  final Duration elapsed;
  final String? error;

  bool get isIdle => phase == RecordPhase.idle;
  bool get isRecording => phase == RecordPhase.recording;
  bool get isBusy =>
      phase == RecordPhase.requesting || phase == RecordPhase.saving;
  bool get isError => phase == RecordPhase.error;

  RecordingState copyWith({
    RecordPhase? phase,
    Duration? elapsed,
    Object? error = _sentinel,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingState &&
          phase == other.phase &&
          elapsed == other.elapsed &&
          error == other.error;

  @override
  int get hashCode => Object.hash(phase, elapsed, error);
}

const Object _sentinel = Object();
