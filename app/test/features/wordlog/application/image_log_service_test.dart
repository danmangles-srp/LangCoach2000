// ImageLogService — T3.3 (FR-1.3.1). Orchestration over fakes: the happy
// path copies then inserts the built path; a copy failure inserts nothing.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/progress/data/xp_repository.dart';
import 'package:rivendell/features/wordlog/application/image_log_service.dart';
import 'package:rivendell/features/wordlog/application/image_log_writer_service.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';

class _RecordingWriter implements ImageLogWriterService {
  String? lastSource;
  String? lastDest;
  Exception? throwOnCopy;
  int copies = 0;

  @override
  Future<void> copyIntoAppData({
    required String sourceUri,
    required String destRelativePath,
  }) async {
    copies++; // count the attempt regardless of outcome
    final err = throwOnCopy;
    if (err != null) throw err;
    lastSource = sourceUri;
    lastDest = destRelativePath;
  }
}

void main() {
  late AppDatabase db;
  late WordLogRepository repo;
  late RecordingRepository recordings;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WordLogRepository(db);
    recordings = RecordingRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seedRecording() async {
    await recordings.upsertScanned([
      ScannedFile(
        path: '/svr/lec.m4a',
        name: 'lec.m4a',
        createdAt: DateTime(2026, 3, 15),
        sizeBytes: 1,
        format: AudioFormat.m4a,
      ),
    ]);
    final row = await recordings.findByPath('/svr/lec.m4a');
    return row!.id;
  }

  test('attach copies the bytes then inserts the built path', () async {
    final id = await seedRecording();
    final writer = _RecordingWriter();
    final service = ImageLogService(
      repository: repo,
      writer: writer,
      logger: AppLogger(sink: RecordingSink()),
      clock: () => DateTime(2026, 6, 30, 12, 5, 7),
    );

    final dest = await service.attach(
      recordingId: id,
      sourceUri: 'content://picker/note1.jpg',
      extension: 'jpg',
    );

    expect(writer.lastSource, 'content://picker/note1.jpg');
    expect(writer.lastDest, startsWith('wordlog/$id/'));
    expect(writer.lastDest, endsWith('.jpg'));
    expect(dest, writer.lastDest);
    expect(writer.copies, 1);

    final imgs = await repo.imagesFor(id);
    expect(imgs, hasLength(1));
    expect(imgs.first.body, dest);
  });

  test('attach inserts nothing when the copy fails', () async {
    final id = await seedRecording();
    final writer = _RecordingWriter()..throwOnCopy = Exception('disk full');
    final service = ImageLogService(
      repository: repo,
      writer: writer,
      logger: AppLogger(sink: RecordingSink()),
      clock: () => DateTime(2026, 6, 30, 12, 5, 7),
    );

    await expectLater(
      service.attach(
        recordingId: id,
        sourceUri: 'content://picker/note1.jpg',
        extension: 'png',
      ),
      throwsA(isA<Exception>()),
    );
    expect(writer.copies, 1);
    expect(await repo.imagesFor(id), isEmpty); // no orphan row
  });

  group('XP awards (M11 T11.2)', () {
    test('attach awards +5 on a successful copy', () async {
      final id = await seedRecording();
      final writer = _RecordingWriter();
      final xp = XpRepository(db);
      final service = ImageLogService(
        repository: repo,
        writer: writer,
        logger: AppLogger(sink: RecordingSink()),
        clock: () => DateTime(2026, 6, 30, 12, 5, 7),
        xp: xp,
      );

      await service.attach(
        recordingId: id,
        sourceUri: 'content://picker/note1.jpg',
        extension: 'jpg',
      );

      expect(await xp.total(), 5);
      final row = await (db.select(db.xpEvents)..limit(1)).getSingle();
      expect(row.source, 'wordlog');
      expect(row.recordingId, id);
    });

    test('a failed copy awards nothing', () async {
      final id = await seedRecording();
      final writer = _RecordingWriter()..throwOnCopy = Exception('disk full');
      final xp = XpRepository(db);
      final service = ImageLogService(
        repository: repo,
        writer: writer,
        logger: AppLogger(sink: RecordingSink()),
        clock: () => DateTime(2026, 6, 30, 12, 5, 7),
        xp: xp,
      );

      await expectLater(
        service.attach(
          recordingId: id,
          sourceUri: 'content://picker/note1.jpg',
          extension: 'png',
        ),
        throwsA(isA<Exception>()),
      );
      expect(await xp.total(), 0);
    });
  });
}
