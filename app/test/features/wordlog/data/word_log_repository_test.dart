// WordLogRepository — T3.1 (FR-1.3.1). In-memory Drift; no device.
// Covers the single-text-log replace invariant, image append, ordering,
// allForRecording, delete, and the FK cascade when a recording is removed.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';

void main() {
  late AppDatabase db;
  late RecordingRepository recordings;
  late WordLogRepository wordLogs;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recordings = RecordingRepository(db);
    wordLogs = WordLogRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seed({String path = '/svr/lec.m4a'}) async {
    await recordings.upsertScanned([
      ScannedFile(
        path: path,
        name: 'lec.m4a',
        createdAt: DateTime(2026, 3, 15),
        sizeBytes: 1,
        format: AudioFormat.m4a,
      ),
    ]);
    final row = await recordings.findByPath(path);
    if (row == null) fail('seed recording not found at $path');
    return row.id;
  }

  group('text log', () {
    test('setTextLog + textLogFor round-trips the body', () async {
      final id = await seed();
      await wordLogs.setTextLog(id, body: 'cat: mushuk\ndog: it');
      final log = await wordLogs.textLogFor(id);
      expect(log, isNotNull);
      expect(log!.kind, 'text');
      expect(log.body, 'cat: mushuk\ndog: it');
    });

    test(
      're-attaching replaces the prior text log (one per recording)',
      () async {
        final id = await seed();
        await wordLogs.setTextLog(id, body: 'old');
        await wordLogs.setTextLog(id, body: 'new');
        final log = await wordLogs.textLogFor(id);
        expect(log!.body, 'new');
        // Exactly one text row.
        expect(await wordLogs.allForRecording(id), hasLength(1));
      },
    );

    test('textLogFor returns null when nothing attached', () async {
      final id = await seed();
      expect(await wordLogs.textLogFor(id), isNull);
    });
  });

  group('images', () {
    test('addImage + imagesFor round-trips the path', () async {
      final id = await seed();
      final row = await wordLogs.addImage(id, path: 'images/note1.jpg');
      expect(row.kind, 'image');
      expect(row.body, 'images/note1.jpg');
      final imgs = await wordLogs.imagesFor(id);
      expect(imgs, hasLength(1));
      expect(imgs.first.body, 'images/note1.jpg');
    });

    test('multiple images stack (append-only)', () async {
      final id = await seed();
      await wordLogs.addImage(id, path: 'images/a.jpg');
      await wordLogs.addImage(id, path: 'images/b.jpg');
      expect(await wordLogs.imagesFor(id), hasLength(2));
    });

    test('a text log and images coexist on one recording', () async {
      final id = await seed();
      await wordLogs.setTextLog(id, body: 'hello: salom');
      await wordLogs.addImage(id, path: 'images/note.jpg');
      final all = await wordLogs.allForRecording(id);
      expect(all, hasLength(2)); // 1 text + 1 image
    });
  });

  group('delete', () {
    test('removes a single row', () async {
      final id = await seed();
      final row = await wordLogs.addImage(id, path: 'images/note.jpg');
      await wordLogs.delete(row.id);
      expect(await wordLogs.allForRecording(id), isEmpty);
    });

    test('delete is a no-op on an unknown id', () async {
      // Should not throw.
      await wordLogs.delete(9999);
    });
  });

  group('textLogTimestamps (T6.2 metric source)', () {
    test(
      'returns createdAts of text logs in [from, until), oldest first',
      () async {
        final id = await seed();
        await wordLogs.setTextLog(id, body: 'a: a');
        final id2 = await seed(path: '/svr/two.m4a');
        await wordLogs.setTextLog(id2, body: 'b: b');

        final all = await wordLogs.textLogTimestamps(
          DateTime(2020),
          DateTime(2030),
        );
        expect(all, hasLength(2));
        final sorted = [...all]..sort();
        expect(all, orderedEquals(sorted));
      },
    );

    test('half-open: an empty future window returns nothing', () async {
      expect(
        await wordLogs.textLogTimestamps(DateTime(2030), DateTime(2030, 1, 2)),
        isEmpty,
      );
    });

    test('ignores image logs', () async {
      final id = await seed();
      await wordLogs.setTextLog(id, body: 't: t');
      await wordLogs.addImage(id, path: 'images/note.jpg');
      expect(
        await wordLogs.textLogTimestamps(DateTime(2020), DateTime(2030)),
        hasLength(1),
      );
    });
  });

  group('FK cascade', () {
    test('deleting a recording drops its word log', () async {
      final id = await seed();
      await wordLogs.setTextLog(id, body: 'gone: ketdi');
      await wordLogs.addImage(id, path: 'images/x.jpg');
      expect(await wordLogs.allForRecording(id), hasLength(2));

      // recordings table delete cascades via ON DELETE CASCADE.
      await (db.delete(db.recordings)..where((t) => t.id.equals(id))).go();
      expect(await wordLogs.allForRecording(id), isEmpty);
    });
  });
}
