// RecorderController — orchestration over injected seams (T2.7, FR-1.1.3).
// Pins the idle → requesting → recording → saving → idle state machine and
// the no-folder / permission / write-failure error paths, with fakes for the
// mic, the SAF writer, the indexer, and a pinned clock + temp dir.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/core/logging/app_logger_provider.dart';
import 'package:rivendell/features/audio/application/folder_providers.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/recording/application/audio_recorder_service.dart';
import 'package:rivendell/features/audio/recording/application/recorder_controller.dart';
import 'package:rivendell/features/audio/recording/application/recording_writer_service.dart';
import 'package:rivendell/features/audio/recording/domain/recording_state.dart';
import 'package:rivendell/features/audio/recording/platform/recording_providers.dart';

class _FakeRecorder implements AudioRecorderService {
  _FakeRecorder({this.permission = true, this.startOk = true});
  bool permission;
  bool startOk;
  String? startPath;
  int stopCalls = 0;
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<bool> start({required String path}) async {
    startPath = path;
    return startOk;
  }

  @override
  // Mirrors `record`: stop returns the path the capture was started with.
  Future<String?> stop() async {
    stopCalls++;
    return startPath;
  }

  @override
  Future<bool> isRecording() async => startPath != null;
  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeWriter implements RecordingWriterService {
  String? lastTreeUri;
  String? lastSource;
  String? lastName;
  Exception? throwOnCopy;
  @override
  Future<String> copyToFolder({
    required String treeUri,
    required String sourcePath,
    required String displayName,
  }) async {
    final err = throwOnCopy;
    if (err != null) throw err;
    lastTreeUri = treeUri;
    lastSource = sourcePath;
    lastName = displayName;
    return 'content://folder/$displayName';
  }
}

class _FakeIndexer implements RecordingIndexer {
  int scanCalls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #scanAndStore) {
      scanCalls++;
      return Future<int>.value(1);
    }
    return super.noSuchMethod(invocation);
  }
}

const _treeUri = 'content://folder';
final _clock = DateTime(2026, 6, 29, 14, 30, 5);
// Matches buildRecordingFileName(_clock) — asserted in the happy-path test.
const _expectedName = 'rivendell-2026-0629-143005.m4a';

ProviderContainer _container({
  required _FakeRecorder recorder,
  required _FakeWriter writer,
  required _FakeIndexer indexer,
  required AppDatabase db,
  bool withFolder = true,
}) {
  final folderRepo = FolderRepository(KvRepository(db));
  final container = ProviderContainer(
    overrides: [
      audioRecorderServiceProvider.overrideWith((ref) => recorder),
      recordingWriterServiceProvider.overrideWith((ref) => writer),
      recordingIndexerProvider.overrideWith((ref) async => indexer),
      folderRepositoryProvider.overrideWith((ref) async => folderRepo),
      recordingsProvider.overrideWith((ref) async => const <Recording>[]),
      recorderClockProvider.overrideWith(
        (ref) =>
            () => _clock,
      ),
      recorderTempDirProvider.overrideWith((ref) async => '/tmp'),
      appLoggerProvider.overrideWith((ref) => AppLogger(sink: RecordingSink())),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _setFolder(AppDatabase db) async {
  await FolderRepository(KvRepository(db)).setFolder(_treeUri);
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('start without a folder → error(no-folder)', () async {
    final container = _container(
      recorder: _FakeRecorder(),
      writer: _FakeWriter(),
      indexer: _FakeIndexer(),
      db: db,
      withFolder: false,
    );
    await container.read(recorderControllerProvider.notifier).start();
    final state = container.read(recorderControllerProvider);
    expect(state.phase, RecordPhase.error);
    expect(state.error, 'no-folder');
  });

  test('start with permission denied → error(permission)', () async {
    await _setFolder(db);
    final container = _container(
      recorder: _FakeRecorder(permission: false),
      writer: _FakeWriter(),
      indexer: _FakeIndexer(),
      db: db,
    );
    await container.read(recorderControllerProvider.notifier).start();
    final state = container.read(recorderControllerProvider);
    expect(state.phase, RecordPhase.error);
    expect(state.error, 'permission');
  });

  test(
    'start happy → records to /tmp/<timestamped name>, phase recording',
    () async {
      await _setFolder(db);
      final recorder = _FakeRecorder();
      final container = _container(
        recorder: recorder,
        writer: _FakeWriter(),
        indexer: _FakeIndexer(),
        db: db,
      );
      await container.read(recorderControllerProvider.notifier).start();
      expect(recorder.startPath, '/tmp/$_expectedName');
      expect(
        container.read(recorderControllerProvider).phase,
        RecordPhase.recording,
      );
    },
  );

  test('start failing at the mic → error(start), never records', () async {
    await _setFolder(db);
    final recorder = _FakeRecorder(startOk: false);
    final container = _container(
      recorder: recorder,
      writer: _FakeWriter(),
      indexer: _FakeIndexer(),
      db: db,
    );
    await container.read(recorderControllerProvider.notifier).start();
    final state = container.read(recorderControllerProvider);
    expect(state.phase, RecordPhase.error);
    expect(state.error, 'start');
  });

  test(
    'stop happy → copies to folder, rescans, lastSavedName set, idle',
    () async {
      await _setFolder(db);
      final recorder = _FakeRecorder();
      final writer = _FakeWriter();
      final indexer = _FakeIndexer();
      final container = _container(
        recorder: recorder,
        writer: writer,
        indexer: indexer,
        db: db,
      );
      final controller = container.read(recorderControllerProvider.notifier);
      await controller.start();
      await controller.stop();

      expect(writer.lastTreeUri, _treeUri);
      expect(writer.lastSource, '/tmp/$_expectedName');
      expect(writer.lastName, _expectedName);
      expect(indexer.scanCalls, 1);
      expect(controller.lastSavedName, _expectedName);
      expect(
        container.read(recorderControllerProvider).phase,
        RecordPhase.idle,
      );
    },
  );

  test('stop when the writer throws → error(write), no rescan', () async {
    await _setFolder(db);
    final writer = _FakeWriter()..throwOnCopy = Exception('disk full');
    final indexer = _FakeIndexer();
    final container = _container(
      recorder: _FakeRecorder(),
      writer: writer,
      indexer: indexer,
      db: db,
    );
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start();
    await controller.stop();

    expect(container.read(recorderControllerProvider).phase, RecordPhase.error);
    expect(container.read(recorderControllerProvider).error, 'write');
    expect(indexer.scanCalls, 0); // bailed before rescan
    expect(controller.lastSavedName, isNull);
  });

  test('toggle stops when recording', () async {
    await _setFolder(db);
    final indexer = _FakeIndexer();
    final container = _container(
      recorder: _FakeRecorder(),
      writer: _FakeWriter(),
      indexer: indexer,
      db: db,
    );
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start();
    await controller.toggle(); // recording → stop
    expect(indexer.scanCalls, 1);
    expect(controller.lastSavedName, _expectedName);
  });

  test('dismissError clears an error back to idle', () async {
    final container = _container(
      recorder: _FakeRecorder(),
      writer: _FakeWriter(),
      indexer: _FakeIndexer(),
      db: db,
      withFolder: false,
    );
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start(); // no folder → error
    expect(container.read(recorderControllerProvider).isError, isTrue);
    controller.dismissError();
    expect(container.read(recorderControllerProvider).isIdle, isTrue);
  });

  test(
    'disposing mid-record releases the mic (no background capture)',
    () async {
      await _setFolder(db);
      final recorder = _FakeRecorder();
      final container = _container(
        recorder: recorder,
        writer: _FakeWriter(),
        indexer: _FakeIndexer(),
        db: db,
      );
      await container.read(recorderControllerProvider.notifier).start();
      expect(recorder.stopCalls, 0); // still recording
      // Emulates the user swiping the sheet away while recording. dispose() is
      // synchronous, but onDispose fires the async stop(); pump the microtask
      // queue so the fake's stopCalls is visible.
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(recorder.stopCalls, 1); // mic released on teardown
    },
  );
}
