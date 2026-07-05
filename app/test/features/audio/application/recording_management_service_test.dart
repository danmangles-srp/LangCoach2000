// Unit tests for in-app rename + delete orchestration (T10.4 / T10.5). The
// service is pure sequencing over injected seams — an in-memory store, a fake
// [RecordingFileService], a fake folder repo, and a temp dir stand in for the
// device so the whole flow is provable without a Samsung folder or SAF.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/recording_management_service.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/audio/recording/application/recording_file_service.dart';

/// Captures every SAF call so a test can assert ordering + arguments without
/// touching the platform. `renameResult` drives the rename return value;
/// `renameThrows`/`deleteThrows` force a failure path.
class _FakeFileService implements RecordingFileService {
  _FakeFileService({
    this.renameResult = 'content://tree/renamed',
    this.renameThrows = false,
    this.deleteThrows = false,
  });

  final String renameResult;
  final bool renameThrows;
  final bool deleteThrows;

  final List<({String docUri, String displayName})> renames = [];
  final List<String> deletes = [];

  @override
  Future<String> rename({
    required String docUri,
    required String displayName,
  }) async {
    renames.add((docUri: docUri, displayName: displayName));
    if (renameThrows) throw StateError('rename boom');
    return renameResult;
  }

  @override
  Future<bool> delete({required String docUri}) async {
    deletes.add(docUri);
    if (deleteThrows) throw StateError('delete boom');
    return true;
  }
}

/// A [RecordingRepository] whose `updateNameAndPath` throws — for the
/// post-SAF-rename DB-failure path. Everything else reads through to the real
/// in-memory store so the recording can be seeded normally.
class _ThrowingUpdateRepo extends RecordingRepository {
  _ThrowingUpdateRepo(super.db);

  @override
  Future<void> updateNameAndPath(
    int id, {
    required String name,
    required String filePath,
  }) {
    throw StateError('db update boom');
  }
}

/// FolderRepository is concrete + tiny; reusing the real one over an in-memory
/// kv keeps the "no folder → no-op" path honest.
Future<FolderRepository> _folderRepo(AppDatabase db, {String? folder}) async {
  final repo = FolderRepository(KvRepository(db));
  if (folder != null) {
    await repo.setFolder(folder);
  }
  return repo;
}

void main() {
  late AppDatabase db;
  late RecordingRepository recordings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordings = RecordingRepository(db);
  });
  tearDown(() => db.close());

  Future<int> seedRecording({
    String path = 'content://tree/a',
    String name = 'a.m4a',
    AudioFormat format = AudioFormat.m4a,
  }) async {
    await recordings.upsertScanned([
      ScannedFile(
        path: path,
        name: name,
        createdAt: DateTime(2026),
        sizeBytes: 1,
        format: format,
      ),
    ]);
    final rec = await recordings.findByPath(path);
    if (rec == null) fail('seed recording missing');
    return rec.id;
  }

  group('renameRecording', () {
    test(
      'sanitizes, SAF-renames, then updates DB name + path together',
      () async {
        final id = await seedRecording();
        final fs = _FakeFileService(renameResult: 'content://tree/lesson-1');
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: RecordingSink()),
        );

        final newName = await svc.renameRecording(id, ' Lesson 1 ');
        // One SAF rename, with the trimmed base + original container ext.
        expect(fs.renames, hasLength(1));
        expect(fs.renames.single.displayName, 'Lesson 1.m4a');
        expect(fs.renames.single.docUri, 'content://tree/a');
        // DB row carries the new name + the authoritative SAF URI.
        expect(newName, 'Lesson 1.m4a');
        final rec = await recordings.findById(id);
        expect(rec?.name, 'Lesson 1.m4a');
        expect(rec?.filePath, 'content://tree/lesson-1');
      },
    );

    test(
      'falls back to a timestamped base when the input sanitizes to empty',
      () async {
        final id = await seedRecording(name: 'old.m4a');
        final fs = _FakeFileService();
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: RecordingSink()),
        );

        final newName = await svc.renameRecording(id, '   / : *   ');
        // Sanitized to empty → default base (rivendell-YYYY-MMdd-HHmmss.m4a).
        expect(newName, isNotNull);
        expect(newName!.endsWith('.m4a'), isTrue);
        expect(fs.renames.single.displayName, newName);
      },
    );

    test(
      'returns null and skips SAF + DB when the recording is gone',
      () async {
        final fs = _FakeFileService();
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: RecordingSink()),
        );

        final result = await svc.renameRecording(9999, 'whatever');
        expect(result, isNull);
        expect(fs.renames, isEmpty);
      },
    );

    test(
      'returns null when no folder is set (no SAF path to rename through)',
      () async {
        final id = await seedRecording();
        final fs = _FakeFileService();
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db), // no folder
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: RecordingSink()),
        );

        final result = await svc.renameRecording(id, 'Lesson 1');
        expect(result, isNull);
        expect(fs.renames, isEmpty);
        // DB untouched.
        final rec = await recordings.findById(id);
        expect(rec?.name, 'a.m4a');
      },
    );

    test('throws on SAF failure without mutating the DB row', () async {
      final id = await seedRecording();
      final fs = _FakeFileService(renameThrows: true);
      final svc = RecordingManagementService(
        recordings: recordings,
        folderRepository: await _folderRepo(db, folder: 'content://tree'),
        fileService: fs,
        appDocsDir: '/tmp/docs',
        logger: AppLogger(sink: RecordingSink()),
      );

      await expectLater(
        svc.renameRecording(id, 'Lesson 1'),
        throwsA(isA<StateError>()),
      );
      // Row is unchanged — the SAF call failed before the DB write.
      final rec = await recordings.findById(id);
      expect(rec?.name, 'a.m4a');
      expect(rec?.filePath, 'content://tree/a');
    });

    test(
      'rolls the file rename back when the DB update fails post-rename',
      () async {
        final id = await seedRecording();
        // Fake repo whose updateNameAndPath throws — simulates a DB failure
        // landing after the SAF rename succeeded.
        final throwingRepo = _ThrowingUpdateRepo(db);
        final fs = _FakeFileService(renameResult: 'content://tree/lesson-1');
        final sink = RecordingSink();
        final svc = RecordingManagementService(
          recordings: throwingRepo,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: sink),
        );

        await expectLater(
          svc.renameRecording(id, 'Lesson 1'),
          throwsA(isA<StateError>()),
        );
        // Forward rename landed, then the rollback renamed it back to the
        // original name — two SAF calls, the second undoing the first.
        expect(fs.renames, hasLength(2));
        expect(fs.renames[0].displayName, 'Lesson 1.m4a');
        expect(fs.renames[1].displayName, 'a.m4a');
        expect(fs.renames[1].docUri, 'content://tree/lesson-1');
        // The failure was logged at error level so it survives a release build.
        expect(sink.lines.any((l) => l.contains('rolling back')), isTrue);
      },
    );
  });

  group('deleteRecording', () {
    test(
      'deletes image dir, SAF-deletes the audio, then drops the DB row',
      () async {
        final id = await seedRecording();
        // Simulate an image-log dir under app-private storage.
        final tempDir = await Directory.systemTemp.createTemp(
          'rivendell_test_',
        );
        final imageDir = Directory('${tempDir.path}/wordlog/$id');
        await imageDir.create(recursive: true);
        await File(
          '${imageDir.path}/img1.jpg',
        ).writeAsString('not really a jpg');

        final fs = _FakeFileService();
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: tempDir.path,
          logger: AppLogger(sink: RecordingSink()),
        );

        final removed = await svc.deleteRecording(id);
        expect(removed, isTrue);
        expect(fs.deletes, ['content://tree/a']);
        expect(imageDir.existsSync(), isFalse); // image dir wiped
        expect(await recordings.findById(id), isNull); // row gone
        await tempDir.delete(recursive: true);
      },
    );

    test('still deletes the DB row when the image dir is absent', () async {
      final id = await seedRecording();
      final fs = _FakeFileService();
      final svc = RecordingManagementService(
        recordings: recordings,
        folderRepository: await _folderRepo(db, folder: 'content://tree'),
        fileService: fs,
        appDocsDir: '/tmp/no-such-docs',
        logger: AppLogger(sink: RecordingSink()),
      );

      expect(await svc.deleteRecording(id), isTrue);
      expect(await recordings.findById(id), isNull);
    });

    test(
      'still deletes the DB row when SAF delete throws (best-effort)',
      () async {
        final id = await seedRecording();
        final fs = _FakeFileService(deleteThrows: true);
        final svc = RecordingManagementService(
          recordings: recordings,
          folderRepository: await _folderRepo(db, folder: 'content://tree'),
          fileService: fs,
          appDocsDir: '/tmp/docs',
          logger: AppLogger(sink: RecordingSink()),
        );

        expect(await svc.deleteRecording(id), isTrue);
        expect(fs.deletes, ['content://tree/a']); // tried
        expect(await recordings.findById(id), isNull); // row still dropped
      },
    );

    test('returns false when the recording is already gone', () async {
      final fs = _FakeFileService();
      final svc = RecordingManagementService(
        recordings: recordings,
        folderRepository: await _folderRepo(db, folder: 'content://tree'),
        fileService: fs,
        appDocsDir: '/tmp/docs',
        logger: AppLogger(sink: RecordingSink()),
      );

      expect(await svc.deleteRecording(9999), isFalse);
      expect(fs.deletes, isEmpty);
    });
  });
}
