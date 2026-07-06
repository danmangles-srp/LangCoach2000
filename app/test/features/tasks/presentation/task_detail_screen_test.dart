// TaskDetailScreen wiring test (T9.4, M9 AC 4). Presentation is coverage-
// excluded; this guards the read/edit/delete loop over a real repo on an
// in-memory db so the task-by-id read + invalidate-after-mutate path is
// exercised end-to-end. Mirrors the tasks_screen_test host pattern.

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
import 'package:rivendell/features/tasks/presentation/task_detail_screen.dart';
import 'package:rivendell/l10n/app_strings.dart';

ProviderContainer _container() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) async => db),
      taskNotificationGatewayProvider.overrideWith(
        (_) => FakeTaskNotificationGateway(),
      ),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(db.close);
  return container;
}

Widget _host(ProviderContainer container, {required int taskId}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: TaskDetailScreen(taskId: taskId),
      ),
    );

void main() {
  testWidgets('renders the title, description, + due date of the seeded task', (
    tester,
  ) async {
    final container = _container();
    final db = await container.read(appDatabaseProvider.future);
    await TaskRepository(db).create(
      title: 'Memorize Yor-Yor',
      description: 'Lines 1-8 by Friday',
      dueDate: DateTime(2026, 7, 10),
    );

    await tester.pumpWidget(_host(container, taskId: 1));
    await tester.pumpAndSettle();

    expect(find.text('Memorize Yor-Yor'), findsOneWidget);
    expect(find.text('Lines 1-8 by Friday'), findsOneWidget);
    expect(find.textContaining('Jul 10, 2026'), findsOneWidget);
  });

  testWidgets('shows the not-found view when the task id is missing', (
    tester,
  ) async {
    final container = _container();

    await tester.pumpWidget(_host(container, taskId: 999));
    await tester.pumpAndSettle();

    expect(find.text('This task is no longer available.'), findsOneWidget);
  });

  testWidgets(
    'Edit action opens the dialog + saving a new title updates the detail',
    (tester) async {
      final container = _container();
      final db = await container.read(appDatabaseProvider.future);
      await TaskRepository(db).create(title: 'Old title');

      await tester.pumpWidget(_host(container, taskId: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();

      // The dialog's title field is the first TextField; clear + replace.
      await tester.enterText(find.byType(TextField).first, 'New title');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('New title'), findsOneWidget);
      expect(find.text('Old title'), findsNothing);
    },
  );

  testWidgets('Delete action removes the task + surfaces the not-found view', (
    tester,
  ) async {
    final container = _container();
    final db = await container.read(appDatabaseProvider.future);
    await TaskRepository(db).create(title: 'doomed');

    await tester.pumpWidget(_host(container, taskId: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    // After delete the provider re-reads → null → not-found view.
    expect(find.text('This task is no longer available.'), findsOneWidget);
    final repo = TaskRepository(db);
    expect(await repo.getById(1), isNull);
  });
}
