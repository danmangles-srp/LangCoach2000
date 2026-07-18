// LogActivityDialog flow — M11 T11.4 (AC 2). Presentation is coverage-excluded;
// this drives the real [logActivity] seam over an in-memory db so the
// dialog → repo.add (+15 XP) → invalidate list loop is exercised end-to-end.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/progress/application/progress_providers.dart';
import 'package:rivendell/features/progress/presentation/log_activity_dialog.dart';
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
    home: _Host(),
  ),
);

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: IconButton(
          key: const Key('openLogActivity'),
          icon: const Icon(Icons.add),
          onPressed: () => logActivity(context, ref),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('fill title -> Save persists a reading log + awards +15', (
    tester,
  ) async {
    final container = _container();
    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openLogActivity')));
    await tester.pumpAndSettle();

    // Title is the first TextField in the dialog (duration is the second).
    await tester.enterText(find.byType(TextField).first, 'Chapter 1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final logs = await container.read(activityLogsProvider.future);
    expect(logs, hasLength(1));
    expect(logs.single.title, 'Chapter 1');
    expect(logs.single.kind, 'reading');
    expect(logs.single.durationMinutes, isNull);

    final xp = await container.read(xpRepositoryProvider.future);
    expect(await xp.total(), 15);
  });

  testWidgets('picking movie + minutes stores the kind + duration', (
    tester,
  ) async {
    final container = _container();
    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openLogActivity')));
    await tester.pumpAndSettle();

    // Tap the Movie segment label.
    await tester.tap(find.text('Movie'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sevara');
    // Duration is the second TextField.
    await tester.enterText(find.byType(TextField).at(1), '90');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final logs = await container.read(activityLogsProvider.future);
    expect(logs.single.kind, 'movie');
    expect(logs.single.title, 'Sevara');
    expect(logs.single.durationMinutes, 90);
  });

  testWidgets('cancel inserts nothing', (tester) async {
    final container = _container();
    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openLogActivity')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'discarded');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await container.read(activityLogsProvider.future), isEmpty);
  });

  testWidgets('Save with an empty title is a no-op (no insert)', (
    tester,
  ) async {
    final container = _container();
    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openLogActivity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog stays open, nothing persisted.
    expect(find.text('Save'), findsOneWidget);
    expect(await container.read(activityLogsProvider.future), isEmpty);
  });
}
