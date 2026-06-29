// Widget tests for the recordings list screen (T1.4). Covers the four
// AsyncValue states: empty (folder set, no files), data (seeded files),
// error (repository throws → retry CTA), and retry re-fetch. Reuses the
// smoke-test DB-override pattern: in-memory store, set the folder so the
// redirect routes home. Overrides are inlined as list literals so the
// element type (riverpod's unexported Override) is inferred, never named.
//
// Home is the review-queue shell (T2.5); the library lives on the second
// nav tab, so these tests switch to it before asserting on its content.

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
