// Smoke test — verifies the app builds, the first-run folder gate routes
// correctly, and Material 3 is on. Replaces the generated widget_test.dart.
// Feature tests live under test/features/.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rivendell/app/app.dart';
import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/core/database/kv_repository.dart';
import 'package:rivendell/core/database/platform/database_provider.dart';
import 'package:rivendell/features/audio/data/folder_repository.dart';

void main() {
  ProviderScope hostApp({required AppDatabase db}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) async {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const RivendellApp(),
    );
  }

  testWidgets('routes to onboarding when no folder is set', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(hostApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text('Point Rivendell at your recordings'), findsOneWidget);
  });

  testWidgets('routes home once a folder is set', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await FolderRepository(KvRepository(db)).setFolder('/svr');
    await tester.pumpWidget(hostApp(db: db));
    await tester.pumpAndSettle();

    // Home is the recordings list (T1.4); its AppBar title is localized.
    expect(find.text('Recordings'), findsOneWidget);
  });

  testWidgets('Material 3 is enabled', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(hostApp(db: db));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(MaterialApp).first));
    expect(theme.useMaterial3, isTrue);
  });
}
