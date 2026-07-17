// Orchestrates the in-app record → save → rescan pipeline (FR-1.1.3, T2.7).
// Pure logic over injected seams (mic recorder, folder writer, indexer) so the
// state machine is provable without a device. The UI (record sheet) reads the
// resulting [RecordingState]; the platform impls live under platform/.
//
// Flow: idle → requesting (permission + folder check) → recording → saving
// (copy into folder + rescan) → idle. Any failure parks in [RecordPhase.error]
// with a message; the sheet shows it and the user dismisses back to idle.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/recording/application/audio_recorder_service.dart';
import 'package:rivendell/features/audio/recording/application/recording_writer_service.dart';
import 'package:rivendell/features/audio/recording/domain/recording_filename.dart';
import 'package:rivendell/features/audio/recording/domain/recording_state.dart';
import 'package:rivendell/features/audio/recording/platform/recording_providers.dart';
import 'package:rivendell/features/gpa/application/review_providers.dart';

class RecorderController extends Notifier<RecordingState> {
  Timer? _tick;
  String? _pendingPath;
  // Base name (no extension) stamped when capture started. The user can edit
  // this via the sheet's name field; stop() sanitizes it into the final
  // filename (T10.3).
  String? _pendingBaseName;
  Stopwatch? _stopwatch;
  bool _recordingActive = false;
  // Captured at start() so onDispose can release the mic without touching Ref
  // (Riverpod forbids ref.read inside life-cycles). Null when not recording.
  AudioRecorderService? _startedMic;

  /// Filename of the most recent successful save; the sheet pops with this so
  /// the host screen can show a confirmation snackbar.
  String? lastSavedName;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _tick?.cancel();
      _stopwatch?.stop();
      // If the sheet was dismissed mid-record, the provider (autoDispose) is
      // torn down but the native mic is still capturing — release it so the
      // mic light/notification doesn't stay on. Uses the captured handle, not
      // Ref (invalid during life-cycles). Fire-and-forget; the engine owns it.
      final mic = _startedMic;
      if (_recordingActive && mic != null) {
        _recordingActive = false;
        _startedMic = null;
        mic.stop();
      }
    });
    return const RecordingState();
  }

  AudioRecorderService get _recorder => ref.read(audioRecorderServiceProvider);
  RecordingWriterService get _writer =>
      ref.read(recordingWriterServiceProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  DateTime _now() => ref.read(recorderClockProvider)();

  /// Start a new recording if idle; a no-op otherwise (the sheet's only action
  /// while recording is stop).
  Future<void> start() async {
    if (state.phase != RecordPhase.idle && !state.isError) return;
    state = const RecordingState(phase: RecordPhase.requesting);

    final folder = await _folder();
    if (folder == null) {
      _fail('no-folder');
      return;
    }
    final granted = await _recorder.hasPermission();
    if (!granted) {
      _logger.w(LogTag.record, 'mic permission denied');
      _fail('permission');
      return;
    }

    final now = _now();
    final baseName = defaultRecordingBaseName(recordedAt: now);
    final tempName = buildRecordingFileName(recordedAt: now);
    final dir = await ref.read(recorderTempDirProvider.future);
    _pendingBaseName = baseName;
    final path = '$dir/$tempName';
    final ok = await _recorder.start(path: path);
    if (!ok) {
      _logger.e(LogTag.record, 'recorder.start returned false');
      _fail('start');
      return;
    }
    _pendingPath = path;
    _recordingActive = true;
    _startedMic = _recorder;
    _stopwatch = Stopwatch()..start();
    final sw = _stopwatch;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isRecording && sw != null) {
        state = state.copyWith(elapsed: sw.elapsed);
      }
    });
    state = RecordingState(phase: RecordPhase.recording, defaultName: baseName);
    _logger.i(LogTag.record, 'recording started → $tempName');
  }

  /// Stop, save into the designated folder, and rescan. Transitions to idle on
  /// success (clearing [lastSavedName] first, then setting it).
  ///
  /// [name] is the user-edited base name (no extension) from the sheet's name
  /// field (T10.3). It is sanitized; if null/blank/unsafe the stamped default
  /// is used so a save never fails on a bad name.
  Future<void> stop({String? name}) async {
    if (!state.isRecording) return;
    _tick?.cancel();
    _tick = null;
    _stopwatch?.stop();
    _recordingActive = false;
    _startedMic = null;
    state = state.copyWith(phase: RecordPhase.saving);

    final tempPath = await _recorder.stop();
    final recordedPath = tempPath ?? _pendingPath;
    final saveName = saveRecordingFileName(baseName: name, recordedAt: _now());
    final stampedBase = _pendingBaseName;
    _pendingPath = null;
    _pendingBaseName = null;
    if (recordedPath == null || stampedBase == null) {
      _logger.e(LogTag.record, 'recorder.stop returned no path');
      _fail('stop');
      return;
    }

    final folder = await _folder();
    if (folder == null) {
      _logger.e(LogTag.record, 'folder vanished between start and stop');
      _fail('no-folder');
      return;
    }

    String docUri;
    try {
      docUri = await _writer.copyToFolder(
        treeUri: folder,
        sourcePath: recordedPath,
        displayName: saveName,
      );
    } on Object catch (e) {
      _logger.e(LogTag.record, 'copy to folder failed: $e');
      _fail('write');
      return;
    }

    // T14.5: also publish to MediaStore so Samsung Voice Recorder's "All
    // recordings" tab surfaces the capture. Best-effort — the SAF copy already
    // succeeded, so a failure here is logged and the save flow continues.
    try {
      await _writer.publishToMediaStore(
        sourceUri: docUri,
        displayName: saveName,
      );
    } on Object catch (e) {
      _logger.w(LogTag.record, 'mediastore publish failed: $e');
    }

    final indexer = await ref.read(recordingIndexerProvider.future);
    try {
      await indexer.scanAndStore();
    } on Object catch (e) {
      _logger.w(LogTag.record, 'rescan after save failed: $e');
      // Non-fatal: the file is saved; the next manual/auto rescan picks it up.
    }

    ref.invalidate(recordingsProvider);
    ref.read(reviewGenerationProvider.notifier).bump();
    lastSavedName = saveName;
    _logger.i(LogTag.record, 'saved $lastSavedName');
    state = const RecordingState(); // idle
  }

  /// Convenience for a single toggle button.
  Future<void> toggle() => state.isRecording ? stop() : start();

  /// Clear an error back to idle.
  void dismissError() {
    if (state.isError) state = const RecordingState();
  }

  Future<String?> _folder() async {
    final repo = await ref.read(folderRepositoryProvider.future);
    return repo.currentFolder();
  }

  void _fail(String code) {
    _tick?.cancel();
    _tick = null;
    _stopwatch?.stop();
    // A failed start/stop may have left the mic running; ensure it's released
    // so the dispose guard isn't the only backstop.
    final mic = _startedMic;
    if (_recordingActive && mic != null) {
      _recordingActive = false;
      _startedMic = null;
      mic.stop();
    }
    state = RecordingState(phase: RecordPhase.error, error: code);
  }
}

final recorderControllerProvider =
    NotifierProvider<RecorderController, RecordingState>(
      RecorderController.new,
    );
