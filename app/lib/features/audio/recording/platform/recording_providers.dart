// Provider wiring for the in-app recorder (FR-1.1.3, T2.7). The mic + folder
// writer are platform impls under platform/ (coverage-excluded); the clock +
// temp dir are overridable seams so RecorderController's state machine is
// unit-tested with fakes + a pinned time and temp path.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:rivendell/features/audio/recording/application/audio_recorder_service.dart';
import 'package:rivendell/features/audio/recording/application/recording_writer_service.dart';
import 'package:rivendell/features/audio/recording/platform/record_audio_recorder_service.dart';
import 'package:rivendell/features/audio/recording/platform/saf_recording_writer_service.dart';

/// Mic recorder singleton. `record` is cross-platform, so one impl serves
/// every host (Android gets AudioRecord/MediaCodec under the hood).
final audioRecorderServiceProvider = Provider<AudioRecorderService>(
  (_) => RecordAudioRecorderService(),
);

/// SAF folder writer singleton. Android-only; degrades to a write error
/// elsewhere (the controller surfaces it).
final recordingWriterServiceProvider = Provider<RecordingWriterService>(
  (_) => SafRecordingWriterService(),
);

/// Injected clock so the recorder filename is deterministic in tests. Defaults
/// to wall-clock now; the filename is stamped from this.
final recorderClockProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);

/// A writable temp directory for the in-progress recording. The OS-private
/// cache keeps a half-finished capture out of the gallery + media store until
/// the writer lifts it into the designated folder.
final recorderTempDirProvider = FutureProvider<String>(
  (_) async => (await getTemporaryDirectory()).path,
);
