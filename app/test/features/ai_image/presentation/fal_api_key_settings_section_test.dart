// FalApiKeySettingsSection widget test. Mounts the section over an in-memory
// Drift KV store (no device, no network) and pins the commit-on-save contract:
// status helper reflects set/not-set, Save persists + clears the field, Clear
// deletes. Presentation is coverage-excluded, so this guards the state shape.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/ai_image/presentation/fal_api_key_settings_section.dart';
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
      home: Scaffold(
        body: SingleChildScrollView(child: FalApiKeySettingsSection()),
      ),
    ),
  );
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('renders title + label and shows the not-set helper when unset', (
    tester,
  ) async {
    await tester.pumpWidget(_host(db));
    await settle(tester);

    expect(find.text('AI image generation'), findsOneWidget);
    expect(find.text('Fal.ai API key'), findsOneWidget);
    expect(find.textContaining('Not set'), findsOneWidget);
    // Clear is hidden until a key is stored.
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('typing a key + Save persists it, clears the field, toasts', (
    tester,
  ) async {
    await tester.pumpWidget(_host(db));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'fal-secret-123');
    await tester.tap(find.text('Save key'));
    await tester.pump();
    await settle(tester);

    // Persisted to the encrypted KV store under the canonical key.
    final kv = KvRepository(db);
    expect(await kv.read('ai_image.fal_api_key'), 'fal-secret-123');
    // Field cleared after save (typed key never lingers in widget state).
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    // Status now reflects "set"; Clear appeared.
    expect(find.textContaining('Not set'), findsNothing);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Key saved'), findsOneWidget);
  });

  testWidgets('a stored key shows the set helper and Clear deletes it', (
    tester,
  ) async {
    final kv = KvRepository(db);
    await kv.write('ai_image.fal_api_key', 'pre-existing');

    await tester.pumpWidget(_host(db));
    await settle(tester);

    expect(find.textContaining('Not set'), findsNothing);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await settle(tester);

    expect(await kv.read('ai_image.fal_api_key'), isNull);
    expect(find.textContaining('Not set'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });
}
