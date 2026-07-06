// CoachBankScreen render + create loop — T5.5 (FR-1.4.3). Presentation is
// coverage-excluded; this guards the empty state, the create-via-dialog flow,
// and that a seeded note renders its title + agenda chips over a real repo on
// an in-memory db so the read/mutate/invalidate loop is exercised end-to-end.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/coach/data/coach_note_repository.dart';
import 'package:rivendell/features/coach/presentation/coach_bank_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWith((ref) async => db)],
  );
  addTearDown(container.dispose);
  addTearDown(db.close);
  return container;
}

Widget _host(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(
    locale: Locale('en'),
    localizationsDelegates: [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: CoachBankScreen(),
  ),
);

void main() {
  testWidgets('with no notes: shows the empty state', (tester) async {
    await tester.pumpWidget(_host(_container()));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);
    expect(find.textContaining('conversation topics'), findsOneWidget);
  });

  testWidgets('FAB → title → Save creates a note and lists it', (tester) async {
    await tester.pumpWidget(_host(_container()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Yor-Yor drill');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Yor-Yor drill'), findsOneWidget);
  });

  testWidgets('a seeded note renders its title and agenda chips', (
    tester,
  ) async {
    final container = _container();
    final db = await container.read(appDatabaseProvider.future);
    final rid = await db
        .into(db.recordings)
        .insert(
          RecordingsCompanion.insert(
            filePath: '/r.m4a',
            name: 'chorus.m4a',
            createdAt: DateTime(2026, 7),
            sizeBytes: 1,
            format: 'm4a',
          ),
        );
    await CoachNoteRepository(db).create(
      title: 'Yor-Yor drill',
      body: 'Run the chorus twice.',
      recordingIds: [rid],
    );

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    expect(find.text('Yor-Yor drill'), findsOneWidget);
    expect(find.text('Run the chorus twice.'), findsOneWidget);
    expect(find.text('1 recordings'), findsOneWidget);
  });
}
