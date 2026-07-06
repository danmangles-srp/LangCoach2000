// TasksScreen render + create/complete loop — T5.2 (FR-1.4.1). Presentation is
// coverage-excluded; this guards the empty state, the create-via-dialog flow,
// the complete checkbox, and the overdue pill over a real repo on an in-memory
// db so the read/mutate/invalidate loop is exercised end-to-end.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/tasks/application/fake_task_notification_gateway.dart';
import 'package:rivendell/features/tasks/application/task_providers.dart';
import 'package:rivendell/features/tasks/data/task_repository.dart';
import 'package:rivendell/features/tasks/presentation/tasks_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => db),
      // Mutations route through TaskCommands → the gateway; the real plugin
      // can't run without a device, so swap in the recording fake.
      taskNotificationGatewayProvider.overrideWith(
        (_) => FakeTaskNotificationGateway(),
      ),
    ],
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
    home: TasksScreen(),
  ),
);

void main() {
  testWidgets('with no tasks: shows the empty state', (tester) async {
    await tester.pumpWidget(_host(_container()));
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.textContaining('Memorize Yor-Yor'), findsOneWidget);
  });

  testWidgets('FAB → title → Save creates a task and lists it', (tester) async {
    await tester.pumpWidget(_host(_container()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    // The title field is the first TextField in the dialog.
    await tester.enterText(find.byType(TextField).first, 'Memorize Yor-Yor');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Memorize Yor-Yor'), findsOneWidget);
  });

  testWidgets('tapping the checkbox marks the task complete', (tester) async {
    final container = _container();
    final db = await container.read(appDatabaseProvider.future);
    await TaskRepository(db).create(title: 'Review ch.3');

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('a past-due incomplete task shows the Overdue pill', (
    tester,
  ) async {
    final container = _container();
    final db = await container.read(appDatabaseProvider.future);
    await TaskRepository(
      db,
    ).create(title: 'past due', dueDate: DateTime(2020, 1, 2));

    await tester.pumpWidget(_host(container));
    await tester.pumpAndSettle();

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('past due'), findsOneWidget);
  });
}
