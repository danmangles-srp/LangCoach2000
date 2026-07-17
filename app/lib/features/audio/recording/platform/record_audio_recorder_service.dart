// `record`-backed mic recorder (FR-1.1.3, T2.7). Lives under platform/ so the
// coverage gate excludes it — the channel/codec plumbing is device-verified.
// Encodes AAC/M4A to match the format the indexer recognizes (.m4a) and that
// just_audio + audio_service decode natively for immediate playback.

import 'package:record/record.dart';

import 'package:rivendell/features/audio/recording/application/audio_recorder_service.dart';

class RecordAudioRecorderService implements AudioRecorderService {
  RecordAudioRecorderService();

  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<bool> start({required String path}) async {
    try {
      // `record`'s start returns void; fold its failure into the bool the
      // controller's seam expects so a native codec error parks in error state
      // instead of throwing through the state machine.
      await _recorder.start(
        // numChannels 1 = mono voice memo (matches Samsung Voice Recorder's
        // default); the rest are RecordConfig defaults (AAC-LC, 128 kbps,
        // 44.1 kHz).
        const RecordConfig(numChannels: 1),
        path: path,
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<bool> isRecording() => _recorder.isRecording();

  @override
  Future<void> dispose() => _recorder.dispose();
}
