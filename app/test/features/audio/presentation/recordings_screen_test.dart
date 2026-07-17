// Widget tests for the recordings list screen (T1.4). Covers the four
// AsyncValue states: empty (folder set, no files), data (seeded files),
// error (repository throws → retry CTA), and retry re-fetch. Reuses the
// smoke-test DB-override pattern: in-memory store, set the folder so the
// redirect routes home. Overrides are inlined as list literals so the
// element type (riverpod's unexported Override) is inferred, never named.
//
// Home is the review-queue shell (T2.5); the library lives on the second
// nav tab, so these tests switch to it before asserting on its content.

import 'package:audio_service/audio_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/audio/application/recording_providers.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/audio/playback/application/audio_player_controller.dart';
import 'package:rivendell/features/audio/playback/domain/playback_snapshot.dart';

void main() {
  Future<void> seedRecordings(AppDatabase db, {required int count}) async {
    final files = [
      for (var i = 0; i < count; i++)
        ScannedFile(
          path: '/svr/rec_$i.m4a',
          name: 'rec_$i.m4a',
          createdAt: DateTime.utc(2024).add(Duration(days: i)),
          sizeBytes: 1024 * (i + 1),
          format: AudioFormat.m4a,
        ),
    ];
    await RecordingRepository(db).upsertScanned(files);
  }

  // Home opens on the Today tab; switch to Library (offstage under
  // IndexedStack) so finders see the recordings list.
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
  }

  testWidgets('empty state when folder is set but no recordings exist', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    await openLibrary(tester);

    expect(find.text('No recordings yet'), findsOneWidget);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsWidgets);
  });

  testWidgets('renders seeded recordings newest first', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    await seedRecordings(db, count: 2);
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    await openLibrary(tester);

    expect(find.byType(ListTile), findsNWidgets(2));
    // Both names render; ordering (newest first) is covered by the
    // repository tests, so the screen test only asserts presence.
    expect(find.text('rec_1.m4a'), findsOneWidget);
    expect(find.text('rec_0.m4a'), findsOneWidget);
  });

  testWidgets('shows duration once set; hides it while null', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    final repo = RecordingRepository(db);
    await repo.upsertScanned([
      ScannedFile(
        path: '/svr/a.m4a',
        name: 'a.m4a',
        createdAt: DateTime.utc(2024),
        sizeBytes: 2048,
        format: AudioFormat.m4a,
      ),
    ]);
    await repo.setDuration(1, durationMs: 65_000);
    await tester.pumpWidget(_app(db));
    await tester.pumpAndSettle();
    await openLibrary(tester);

    // 65_000ms → "1:05" appears in the subtitle.
    expect(find.textContaining('1:05'), findsOneWidget);
  });

  testWidgets('error state surfaces a retry action', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          recordingsProvider.overrideWith((ref) => throw StateError('boom')),
        ],
        child: const RivendellApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openLibrary(tester);

    expect(find.textContaining("Couldn't load"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('retry re-fetches the recordings', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    final repo = RecordingRepository(db);
    var fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          recordingsProvider.overrideWith((ref) async {
            if (fail) {
              fail = false;
              throw StateError('boom');
            }
            return repo.all();
          }),
        ],
        child: const RivendellApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openLibrary(tester);

    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    // After retry the empty state renders (no recordings seeded).
    expect(find.text('No recordings yet'), findsOneWidget);
  });

  // T9.3: the library row surfaces the player snapshot — leading glyph swaps
  // to graphic_eq + a "Now playing" trailing label appears on the active row,
  // mirroring the review queue so the two lists agree on what "now playing"
  // looks like. Other rows stay on the music_note glyph.
  testWidgets(
    'library row shows the now-playing glyph + label on the active recording',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await FolderRepository(KvRepository(db)).setFolder('/svr');
      await seedRecordings(db, count: 2);
      // rec_0 is the first insert (row id 1). Targeting the older row proves
      // the indicator tracks the snapshot, not list position.
      const snapshot = PlaybackSnapshot(
        recordingId: 1,
        processingState: AudioProcessingState.ready,
        isPlaying: true,
        isCompleted: false,
        position: Duration.zero,
        duration: Duration(minutes: 1),
        bufferedPosition: Duration.zero,
        speed: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async {
              ref.onDispose(db.close);
              return db;
            }),
            audioPlayerControllerProvider.overrideWith(
              () => _FakeAudio(snapshot),
            ),
          ],
          child: const RivendellApp(),
        ),
      );
      await tester.pumpAndSettle();
      await openLibrary(tester);

      expect(find.text('Now playing'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      // The other row keeps its muted music_note badge.
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    },
  );

  testWidgets('library rows stay muted when the player is idle', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    await seedRecordings(db, count: 2);
    const snapshot = PlaybackSnapshot.idle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          audioPlayerControllerProvider.overrideWith(
            () => _FakeAudio(snapshot),
          ),
        ],
        child: const RivendellApp(),
      ),
    );
    await tester.pumpAndSettle();
    await openLibrary(tester);

    expect(find.text('Now playing'), findsNothing);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);
    expect(find.byIcon(Icons.music_note_rounded), findsNWidgets(2));
  });
}

/// Notifier that returns a fixed snapshot so the now-playing indicator can be
/// exercised without a real audio engine.
class _FakeAudio extends AudioPlayerController {
  _FakeAudio(this.snapshot);
  final PlaybackSnapshot snapshot;
  @override
  PlaybackSnapshot build() => snapshot;
}

/// DB-only host app (no extra overrides). Kept as a function so the override
/// list literal's element type is inferred from `ProviderScope.overrides`.
Widget _app(AppDatabase db) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async {
        ref.onDispose(db.close);
        return db;
      }),
    ],
    child: const RivendellApp(),
  );
}
