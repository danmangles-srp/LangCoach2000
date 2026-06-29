// Widget test for the recordings screen refresh action (T1.2). Proves the
// wiring: tap refresh -> RecordingIndexer.scanAndStore -> snackbar with the
// count -> recordingsProvider invalidates and the list repopulates. The
// indexer seam is faked so no platform channel is involved.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/logging/app_logger.dart';
import 'package:rivendell/features/audio/application/audio_indexer_service.dart';
import 'package:rivendell/features/audio/application/recording_indexer.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';

class _FakeIndexer implements AudioIndexerService {
  _FakeIndexer(this.files);
  final List<ScannedFile> files;
  @override
  Future<List<ScannedFile>> scan(String folderUri) async => files;
}

final AppLogger _silentLogger = AppLogger(sink: RecordingSink());

void main() {
  testWidgets('refresh scans the folder and shows the indexed recording', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('content://folder');

    final fakeIndexer = _FakeIndexer([
      ScannedFile(
        path: 'content://folder/lecture.m4a',
        name: 'lecture.m4a',
        createdAt: DateTime.utc(2024, 1, 2),
        sizeBytes: 1024,
        format: AudioFormat.m4a,
      ),
    ]);
    final indexer = RecordingIndexer(
      folderRepository: FolderRepository(KvRepository(db)),
      recordingRepository: RecordingRepository(db),
      indexer: fakeIndexer,
      logger: _silentLogger,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async {
            ref.onDispose(db.close);
            return db;
          }),
          recordingIndexerProvider.overrideWith((ref) => indexer),
        ],
        child: const RivendellApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('No recordings yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh library'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Indexed 1'), findsOneWidget);
    expect(find.text('lecture.m4a'), findsOneWidget);
  });
}
