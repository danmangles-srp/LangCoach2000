// Unit tests for the scan orchestration (T1.2). RecordingIndexer is pure logic
// over injected seams — a fake AudioIndexerService + in-memory store prove the
// no-folder short-circuit and the scan -> upsert count without any platform.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/audio_indexer_service.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';

class _FakeIndexer implements AudioIndexerService {
  _FakeIndexer(this.files, {this.scanThrows = false});
  List<ScannedFile> files;
  bool scanThrows;
  String? lastFolder;

  @override
  Future<List<ScannedFile>> scan(String folderUri) async {
    lastFolder = folderUri;
    if (scanThrows) throw StateError('scan failed');
    return files;
  }
}

RecordingIndexer _indexer({
  required AppDatabase db,
  required String? folder,
  required List<ScannedFile> files,
  bool scanThrows = false,
}) {
  final kv = KvRepository(db);
  final folderRepo = FolderRepository(kv);
  final recRepo = RecordingRepository(db);
  return RecordingIndexer(
    folderRepository: folderRepo,
    recordingRepository: recRepo,
    indexer: _FakeIndexer(files, scanThrows: scanThrows),
    logger: AppLogger(sink: RecordingSink()),
  );
}

Future<void> _setFolder(AppDatabase db, String folder) async {
  await FolderRepository(KvRepository(db)).setFolder(folder);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('scanAndStore is a no-op (0) when no folder is set', () async {
    final indexer = _indexer(
      db: db,
      folder: null,
      files: [
        ScannedFile(
          path: 'a',
          name: 'a.m4a',
          createdAt: DateTime.utc(2024),
          sizeBytes: 10,
          format: AudioFormat.m4a,
        ),
      ],
    );
    expect(await indexer.scanAndStore(), 0);
    expect(await RecordingRepository(db).all(), isEmpty);
  });

  test('scanAndStore scans the chosen folder and upserts the files', () async {
    await _setFolder(db, 'content://folder');
    final files = [
      ScannedFile(
        path: 'content://folder/file1',
        name: 'file1.m4a',
        createdAt: DateTime.utc(2024, 1, 2),
        sizeBytes: 100,
        format: AudioFormat.m4a,
      ),
      ScannedFile(
        path: 'content://folder/file2',
        name: 'file2.wav',
        createdAt: DateTime.utc(2024),
        sizeBytes: 200,
        format: AudioFormat.wav,
      ),
    ];
    final indexer = _indexer(db: db, folder: 'content://folder', files: files);

    expect(await indexer.scanAndStore(), 2);

    final all = await RecordingRepository(db).all();
    expect(all.map((r) => r.name), ['file1.m4a', 'file2.wav']); // newest first
  });

  test('propagates the chosen folder URI to the indexer seam', () async {
    await _setFolder(db, 'content://picked');
    final fake = _FakeIndexer(const []);
    final indexer = RecordingIndexer(
      folderRepository: FolderRepository(KvRepository(db)),
      recordingRepository: RecordingRepository(db),
      indexer: fake,
      logger: AppLogger(sink: RecordingSink()),
    );
    await indexer.scanAndStore();
    expect(fake.lastFolder, 'content://picked');
  });
}
