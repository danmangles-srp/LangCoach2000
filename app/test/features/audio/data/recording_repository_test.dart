// RecordingRepository + AudioFormat — M1 data layer (T1.2).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';

void main() {
  late AppDatabase db;
  late RecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingRepository(db);
  });

  tearDown(() => db.close());

  group('AudioFormat.fromFileName', () {
    test('parses supported extensions case-insensitively', () {
      expect(AudioFormat.fromFileName('lecture.M4A'), AudioFormat.m4a);
      expect(AudioFormat.fromFileName('song.Mp3'), AudioFormat.mp3);
      expect(AudioFormat.fromFileName('clip.WAV'), AudioFormat.wav);
    });

    test('returns null for unsupported or extensionless names', () {
      expect(AudioFormat.fromFileName('notes.aac'), isNull);
      expect(AudioFormat.fromFileName('notes'), isNull);
      expect(AudioFormat.fromFileName('notes.'), isNull);
    });
  });

  group('upsertScanned', () {
    test('inserts new files and assigns ids', () async {
      final touched = await repo.upsertScanned([
        ScannedFile(
          path: '/svr/a.m4a',
          name: 'a.m4a',
          createdAt: DateTime(2026, 6),
          sizeBytes: 100,
          format: AudioFormat.m4a,
        ),
      ]);
      expect(touched, 1);
      final all = await repo.all();
      expect(all, hasLength(1));
      expect(all.single.id, greaterThan(0));
      expect(all.single.durationMs, isNull); // filled lazily at play
    });

    test('upserts by filePath: no duplicate, mutable stat refreshed', () async {
      final t1 = DateTime(2026, 6);
      await repo.upsertScanned([
        ScannedFile(
          path: '/svr/a.m4a',
          name: 'a.m4a',
          createdAt: t1,
          sizeBytes: 100,
          format: AudioFormat.m4a,
        ),
      ]);
      // Duration filled by playback between scans.
      final first = await repo.findByPath('/svr/a.m4a');
      if (first == null) {
        fail('expected recording at /svr/a.m4a after upsert');
      }
      await repo.setDuration(first.id, durationMs: 42_000);

      // Re-scan: file grew, name metadata changed.
      await repo.upsertScanned([
        ScannedFile(
          path: '/svr/a.m4a',
          name: 'Renamed Lecture.m4a',
          createdAt: t1,
          sizeBytes: 250,
          format: AudioFormat.m4a,
        ),
      ]);

      final all = await repo.all();
      expect(all, hasLength(1)); // no duplicate
      expect(all.single.name, 'Renamed Lecture.m4a');
      expect(all.single.sizeBytes, 250);
      expect(all.single.durationMs, 42_000); // preserved across upsert
      expect(all.single.id, first.id); // id stable
    });

    test('a 1000-file batch commits without per-row churn', () async {
      final files = [
        for (var i = 0; i < 1000; i++)
          ScannedFile(
            path: '/svr/file-$i.mp3',
            name: 'file-$i.mp3',
            createdAt: DateTime(2026).add(Duration(minutes: i)),
            sizeBytes: i,
            format: AudioFormat.mp3,
          ),
      ];
      final touched = await repo.upsertScanned(files);
      expect(touched, 1000);
      expect(await repo.all(), hasLength(1000));
    });
  });

  group('all', () {
    test('orders newest file first', () async {
      await repo.upsertScanned([
        ScannedFile(
          path: '/old.wav',
          name: 'old.wav',
          createdAt: DateTime(2026),
          sizeBytes: 1,
          format: AudioFormat.wav,
        ),
        ScannedFile(
          path: '/new.wav',
          name: 'new.wav',
          createdAt: DateTime(2026, 6),
          sizeBytes: 1,
          format: AudioFormat.wav,
        ),
      ]);
      final all = await repo.all();
      expect(all.map((r) => r.filePath), ['/new.wav', '/old.wav']);
    });

    test('ties on createdAt break by newest id for a stable order', () async {
      final sameSecond = DateTime(2026, 6, 15, 10);
      await repo.upsertScanned([
        ScannedFile(
          path: '/a.m4a',
          name: 'a.m4a',
          createdAt: sameSecond,
          sizeBytes: 1,
          format: AudioFormat.m4a,
        ),
        ScannedFile(
          path: '/b.m4a',
          name: 'b.m4a',
          createdAt: sameSecond,
          sizeBytes: 1,
          format: AudioFormat.m4a,
        ),
      ]);
      final all = await repo.all();
      // Same createdAt → higher id (inserted last) leads, deterministically.
      expect(all.map((r) => r.filePath), ['/b.m4a', '/a.m4a']);
    });
  });

  group('schema', () {
    test('is at version 9 with the recordings table', () async {
      expect(db.schemaVersion, 9);
      final tables = await db
          .customSelect(
            'SELECT name FROM sqlite_master '
            "WHERE type='table' AND name='recordings'",
          )
          .get();
      expect(tables, hasLength(1));
    });

    test('filePath is unique: a duplicate path insert is rejected', () async {
      await repo.upsertScanned([
        ScannedFile(
          path: '/dup.m4a',
          name: 'dup.m4a',
          createdAt: DateTime(2026),
          sizeBytes: 1,
          format: AudioFormat.m4a,
        ),
      ]);
      // A raw second insert (not via upsert) must collide on the unique key.
      expect(
        () => db
            .into(db.recordings)
            .insert(
              RecordingsCompanion.insert(
                filePath: '/dup.m4a',
                name: 'dup.m4a',
                createdAt: DateTime(2026),
                sizeBytes: 1,
                format: AudioFormat.m4a.name,
              ),
            ),
        throwsA(
          predicate(
            (Object e) => e.toString().toUpperCase().contains('UNIQUE'),
          ),
        ),
      );
    });
  });

  group('formatOf', () {
    Recording row({String format = 'm4a'}) => Recording(
      id: 1,
      filePath: '/x',
      name: 'x',
      createdAt: DateTime(2026),
      sizeBytes: 1,
      format: format,
      indexedAt: DateTime(2026),
    );

    test('decodes a stored format to its enum', () {
      expect(formatOf(row(format: AudioFormat.wav.name)), AudioFormat.wav);
    });

    test('returns null for an unknown format instead of throwing', () {
      expect(formatOf(row(format: 'bogus')), isNull);
    });
  });
}
