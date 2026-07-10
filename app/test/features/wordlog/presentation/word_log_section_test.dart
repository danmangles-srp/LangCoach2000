// WordLogSection render — T3.4 (FR-1.3.1). Presentation is coverage-excluded;
// this guards the toggle + state mapping (empty text → attach affordance,
// attached text → parsed pairs, images → thumbnails) over an injected repo.
//
// The repo is overridden with a real WordLogRepository over an in-memory db so
// the provider's read/parse/invalidate loop is exercised end-to-end.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/platform/ai_image_providers.dart';
import 'package:rivendell/features/audio/data/recording_repository.dart';
import 'package:rivendell/features/audio/domain/audio_format.dart';
import 'package:rivendell/features/wordlog/application/word_log_providers.dart';
import 'package:rivendell/features/wordlog/data/word_log_repository.dart';
import 'package:rivendell/features/wordlog/presentation/word_log_section.dart';
import 'package:rivendell/l10n/app_strings.dart';

Future<int> _seedRecording(AppDatabase db) async {
  final recordings = RecordingRepository(db);
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
  if (row == null) fail('seed recording not found');
  return row.id;
}

Widget _host(ProviderContainer container, {required int recordingId}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: WordLogSection(
            recordingId: recordingId,
            recordingName: 'lecture.m4a',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('with no log: shows the text empty state + add affordance', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await _seedRecording(db);
    final container = ProviderContainer(
      overrides: [
        wordLogRepositoryProvider.overrideWith(
          (ref) async => WordLogRepository(db),
        ),
        appDocsDirProvider.overrideWith((ref) async => '/tmp'),
        // T18.4: the text body now mounts an _AiImageQueueLink that watches
        // the live queue snapshot; stub it empty so the platform DB never
        // resolves in this presentation test.
        aiImageQueueSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            const AiImageQueueSnapshot(pending: [], generated: []),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, recordingId: id));
    await tester.pumpAndSettle();

    expect(
      find.text('No text log yet. Paste an English↔Uzbek word list.'),
      findsOneWidget,
    );
    expect(find.text('Add text log'), findsOneWidget);
  });

  testWidgets('with a text log: shows the parsed pairs', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await _seedRecording(db);
    await WordLogRepository(db).setTextLog(id, body: 'cat: mushuk\ndog: it');
    final container = ProviderContainer(
      overrides: [
        wordLogRepositoryProvider.overrideWith(
          (ref) async => WordLogRepository(db),
        ),
        appDocsDirProvider.overrideWith((ref) async => '/tmp'),
        // T18.4: the text body now mounts an _AiImageQueueLink that watches
        // the live queue snapshot; stub it empty so the platform DB never
        // resolves in this presentation test.
        aiImageQueueSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            const AiImageQueueSnapshot(pending: [], generated: []),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, recordingId: id));
    await tester.pumpAndSettle();

    expect(find.text('cat'), findsOneWidget);
    expect(find.text('mushuk'), findsOneWidget);
    expect(find.text('dog'), findsOneWidget);
    expect(find.text('it'), findsOneWidget);
    // No pending images -> the queue link is hidden (clean word-log surface).
    expect(find.byIcon(Icons.auto_awesome_motion_outlined), findsNothing);
  });

  testWidgets('with pending AI images: shows the queue link (T18.4)', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await _seedRecording(db);
    await WordLogRepository(db).setTextLog(id, body: 'cat: mushuk');
    final container = ProviderContainer(
      overrides: [
        wordLogRepositoryProvider.overrideWith(
          (ref) async => WordLogRepository(db),
        ),
        appDocsDirProvider.overrideWith((ref) async => '/tmp'),
        aiImageQueueSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            AiImageQueueSnapshot(
              pending: [
                QueueItem(
                  id: 1,
                  type: 'ai_image',
                  payload: 'cat',
                  attempts: 0,
                  createdAt: DateTime.utc(2026),
                ),
              ],
              generated: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container, recordingId: id));
    await tester.pumpAndSettle();

    // The pending-count link renders + opens the queue-review screen on tap.
    expect(find.text('1 images queued →'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_motion_outlined), findsOneWidget);
  });
}
