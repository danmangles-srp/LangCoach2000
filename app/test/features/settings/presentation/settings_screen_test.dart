// SettingsScreen — AI image prompt editor (T19.6). Presentation coverage:
// mounts the screen over a real in-memory store (so the chained providers
// resolve) and asserts the prompt section renders the persisted template +
// the Reset button restores the canonical default end-to-end.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/ai_image/domain/ai_image_prompt.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/features/settings/presentation/settings_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

Widget _host(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: SettingsScreen(),
    ),
  );
}

// The Settings ListView is taller than the default 800x600 viewport, so its
// later children (the prompt editor) aren't materialized until scrolled into
// view. Force a tall surface so the whole list builds and is assertable.
void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  testWidgets(
    'renders the default prompt template in the editor on first run',
    (tester) async {
      _tallSurface(tester);
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_host(container));
      await tester.pumpAndSettle();

      expect(find.text('AI image prompt'), findsOneWidget);
      // The default template body is shown in the editable field.
      expect(find.text(defaultAiImagePrompt), findsOneWidget);
    },
  );

  testWidgets('reset restores the default template after an edit', (
    tester,
  ) async {
    _tallSurface(tester);
    const custom = 'watercolour of {word}';
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    addTearDown(container.dispose);

    // Seed a custom template before the screen mounts so the field hydrates it.
    await container.read(settingsRepositoryProvider.future);
    await container
        .read(appSettingsProvider.notifier)
        .setAiImagePromptTemplate(custom);

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    expect(find.text(custom), findsOneWidget);

    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();

    // Field + persisted state both snap back to the canonical default.
    expect(find.text(defaultAiImagePrompt), findsOneWidget);
    expect(
      container.read(appSettingsProvider).aiImagePromptTemplate,
      defaultAiImagePrompt,
    );
  });

  // Regression: an edit must reach the store as it's typed, without depending
  // on focus loss — a process kill between edit and nav-away lost the change.
  testWidgets('typing into the field persists without a focus change', (
    tester,
  ) async {
    _tallSurface(tester);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'ink drawing of {word}',
    );
    await tester.pump();

    expect(
      container.read(appSettingsProvider).aiImagePromptTemplate,
      'ink drawing of {word}',
    );
  });
}
