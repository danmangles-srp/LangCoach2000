// AiImageQueueScreen widget test. Mounts the screen over an in-memory Drift
// store seeded with one pending ai_image item (with a failure history) and one
// generated word; pins that the pending word + attempts + Retry/Cancel render,
// the generated word renders, and Cancel hard-deletes the pending item.
// Presentation is coverage-excluded, so this guards the state shape.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/core/queue/queue_repository.dart';
import 'package:rivendell/features/ai_image/application/ai_image_service.dart';
import 'package:rivendell/features/ai_image/data/ai_image_cache_repository.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_payload.dart';
import 'package:rivendell/features/ai_image/presentation/ai_image_queue_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

Widget _host(AppDatabase db) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: AiImageQueueScreen(),
    ),
  );
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('renders pending word + attempts + actions, and the generated '
      'word; Cancel removes the pending item', (tester) async {
    final queue = QueueRepository(db);
    final cache = AiImageCacheRepository(db);
    final id = await queue.enqueue(
      type: aiImageQueueType,
      payload: aiImagePayload('salom'),
    );
    await queue.markFailed(id, error: 'boom');
    await cache.remember(uzbekWord: 'rahmat', relativePath: 'ai_images/x.png');

    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    // Pending section: word, attempts (1 after markFailed), retry + cancel.
    expect(find.text('salom'), findsOneWidget);
    expect(find.text('Attempts: 1'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // The recorded failure is surfaced.
    expect(find.textContaining('boom'), findsOneWidget);
    // Generated section: the cached word.
    expect(find.text('rahmat'), findsOneWidget);

    // Cancel hard-deletes the pending item.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('salom'), findsNothing);
    expect(find.text('No pending images.'), findsOneWidget);
    // Cancel touched only the pending item; the generated word is untouched.
    expect(find.text('rahmat'), findsOneWidget);
    expect(await queue.pendingByType(aiImageQueueType), isEmpty);
  });

  testWidgets('empty states render when nothing is pending or generated', (
    tester,
  ) async {
    await tester.pumpWidget(_host(db));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('No pending images.'), findsOneWidget);
    expect(find.text('No images generated yet.'), findsOneWidget);
  });
}
