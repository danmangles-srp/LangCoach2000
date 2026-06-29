// Widget test for the post-pick auto-scan (T1.3). Picking a folder indexes it
// immediately and routes home with the recordings populated — no manual refresh
// needed. The folder-picker and indexer seams are faked; no platform channels.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/audio_indexer_service.dart';
import 'package:rivendell/features/audio/application/folder_selection_service.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/audio/platform/folder_selection_providers.dart';

class _FakeFolderSelection implements FolderSelectionService {
  @override
  Future<String?> pickFolder() async => 'content://folder';
}

class _FakeIndexer implements AudioIndexerService {
  @override
  Future<List<ScannedFile>> scan(String folderUri) async => [
    ScannedFile(
      path: 'content://folder/lecture.m4a',
      name: 'lecture.m4a',
      createdAt: DateTime.utc(2024),
      sizeBytes: 1024,
      format: AudioFormat.m4a,
    ),
  ];
}

void main() {
  testWidgets('picking a folder indexes it and routes home with recordings', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final indexer = RecordingIndexer(
      folderRepository: FolderRepository(KvRepository(db)),
      recordingRepository: RecordingRepository(db),
      indexer: _FakeIndexer(),
      logger: AppLogger(sink: RecordingSink()),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          folderSelectionServiceProvider.overrideWith(
            (ref) => _FakeFolderSelection(),
          ),
          recordingIndexerProvider.overrideWith((ref) => indexer),
        ],
        child: const RivendellApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Point Rivendell at your recordings'), findsOneWidget);

    await tester.tap(find.text('Choose folder'));
    await tester.pumpAndSettle();
    // Home opens on the Today tab (T2.5); the library is the second tab.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    // Routed home; the auto-scan populated the library.
    expect(find.text('lecture.m4a'), findsOneWidget);
  });
}
